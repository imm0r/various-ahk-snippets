#Requires AutoHotkey v2.0
#Include ProcessMemory.ahk
#Include StaticOffsetsPatterns.ahk
#Include PoE2ComponentDecoders.ahk
#Include PoE2EntityReader.ahk
#Include PoE2PlayerComponentsReader.ahk
#Include PoE2PlayerReader.ahk
#Include PoE2InventoryReader.ahk
#Include PoE2Offsets.ahk

class PoE2GameStateReader extends PoE2InventoryReader
{
    ; Initializes the reader state, pattern scan report, entity sample limits, and item name dictionaries.
    __New(processName := "PathOfExileSteam.exe")
    {
        this.Mem := ProcessMemory(processName)
        this.GameStatesAddress := 0
        this.StaticAddresses := Map()
        this.MemChrMode := -1
        this.PatternScanReport := Map(
            "missingCritical", [],
            "missingOptional", [],
            "duplicateCritical", [],
            "duplicateOptional", [],
            "found", []
        )
        this.StateNames := [
            "AreaLoadingState",
            "ChangePasswordState",
            "CreditsState",
            "EscapeState",
            "InGameState",
            "PreGameState",
            "LoginState",
            "WaitingState",
            "CreateCharacterState",
            "SelectCharacterState",
            "DeleteCharacterState",
            "LoadingState"
        ]
        this.LastAreaInstanceAddress := 0
        this.LastAreaHash := 0
        this.LastAreaLevel := -1
        this.LastInGameStateAddress := 0
        this.LastEntityReadMode := "direct"
        this.LastEntityFallbackTick := 0
        this.LastEntityReadOffset := PoE2Offsets.AreaInstance["AwakeEntities"]

        ; Fixed sampling limits (legacy sample-mode toggle removed).
        this.AwakeEntitySampleLimit := 32
        this.SleepingEntitySampleLimit := 16
        this._radarMode := false

        ; Radar-specific limits — smaller than full snapshot for faster 100ms updates.
        ; Sleeping entities are outside the active simulation range and carry stale world positions,
        ; so they are intentionally excluded from radar reads to prevent ghost dots.
        this.RadarAwakeEntityLimit := 20
        this.RadarSleepingEntityLimit := 0

        ; Stale-entity cleanup (port of upstream commit 75d48872).
        ; Tracks entities seen as dead/invalid for consecutive ticks.
        ; At 100ms/tick and threshold=3, an entity is blacklisted after ~300ms of being dead.
        this.StaleEntityFrameThreshold := 3
        ; addr → consecutive dead-frame count (isValid=false OR isAlive=false)
        this._staleEntityMap := Map()
        ; addr → true: permanently filtered for current area, never rendered again
        this._deadEntityBlacklist := Map()
        ; last seen areaInstance address — blacklist is reset on area change
        this._lastAreaInstanceAddr := 0

        ; Cached UI element data for radar (re-read every 400ms instead of every 100ms).
        this._radarUiCache := 0
        this._radarUiCacheTick := 0

        ; Cached InGameState address for radar (re-resolved every 800ms instead of every 100ms).
        this._radarInGameStateCache := 0
        this._radarInGameStateTick := 0

        ; Cached StaticPtr for the Charges component type (populated on first named-lookup hit)
        this._chargesStaticPtr := 0

        ; Load item name dictionaries from TSV files
        this.ModNameMap := Map()
        this.BaseItemNameMap := Map()
        this.UniqueItemNameMap := Map()
        this.LoadModNameMap(A_ScriptDir "\\data\\mod_name_map.tsv")
        this.LoadBaseItemNameMap(A_ScriptDir "\\data\\base_item_name_map.tsv")
        this.LoadUniqueItemNameMap(A_ScriptDir "\\data\\unique_item_name_map.tsv")
    }

    ; Opens the process and resolves the GameStates address via pattern scan, falling back to heuristic scan.
    ; Params: strictPatterns - if true, returns false when any critical pattern is missing or duplicated.
    ; Returns: true if GameStatesAddress was successfully resolved.
    Connect(strictPatterns := false)
    {
        if !this.Mem.Open()
            return false

        if (!strictPatterns)
        {
            this.GameStatesAddress := this.ResolveGameStatesAddressFromStaticPattern()
            if (this.GameStatesAddress && this.ValidateGameStatesAddress(this.GameStatesAddress))
                return true

            this.GameStatesAddress := this.ResolveGameStatesAddressFallback()
            if (this.GameStatesAddress && this.ValidateGameStatesAddress(this.GameStatesAddress))
                return true
        }

        this.StaticAddresses := this.FindStaticAddresses()

        if (strictPatterns && this.HasPatternScanCriticalIssues())
            return false

        this.GameStatesAddress := this.StaticAddresses.Has("Game States") ? this.StaticAddresses["Game States"] : 0

        if (!this.GameStatesAddress)
            this.GameStatesAddress := this.ResolveGameStatesAddressFallback()
        else if (!this.ValidateGameStatesAddress(this.GameStatesAddress))
            this.GameStatesAddress := this.ResolveGameStatesAddressFallback()

        return this.GameStatesAddress != 0
    }

    ; Scans the .text section in 2 MB chunks for the Game States RIP-relative signature.
    ; Returns: resolved absolute GameStates address, or 0 if not found or deadline exceeded.
    ResolveGameStatesAddressFromStaticPattern()
    {
        if (!this.Mem.ModuleBase || !this.Mem.ModuleSize)
            return 0

        this.Mem.GetScanRegion(true)
        scanBase := this.Mem.ScanBase ? this.Mem.ScanBase : this.Mem.ModuleBase
        scanSize := this.Mem.ScanSize ? this.Mem.ScanSize : this.Mem.ModuleSize

        parsed := this.ParsePattern("48 39 2D ^ ?? ?? ?? ?? 0F 85 16 01 00 00")
        patternLen := parsed["data"].Length
        chunkSize := 2 * 1024 * 1024
        overlap := Max(0, patternLen - 1)
        currentOffset := 0
        deadline := A_TickCount + 15000

        while (currentOffset < scanSize)
        {
            if (A_TickCount > deadline)
                break

            remaining := scanSize - currentOffset
            readSize := Min(chunkSize, remaining)
            buffer := this.Mem.ReadBytes(scanBase + currentOffset, readSize, true)
            if (buffer && Type(buffer) = "Buffer" && buffer.Size >= patternLen)
            {
                matches := this.FindPatternAddressesInBuffer(
                    buffer,
                    buffer.Size,
                    scanBase + currentOffset,
                    parsed,
                    64,
                    deadline)

                for matchAddr in matches
                {
                    relOperandAddress := matchAddr + parsed["bytesToSkip"]
                    relValue := this.Mem.ReadInt(relOperandAddress)
                    candidate := relOperandAddress + relValue + 4
                    if (!this.IsProbablyValidPointer(candidate))
                        continue

                    gsPtr := this.Mem.ReadPtr(candidate)
                    if (!this.IsProbablyValidPointer(gsPtr))
                        continue

                    if (this.ValidateGameStatesAddress(candidate))
                        return candidate
                }
            }

            if (readSize <= overlap)
                break
            currentOffset += (readSize - overlap)
        }

        return 0
    }

    ; Runs all named patterns from GetStaticPatterns() against the cached module snapshot.
    ; Resolves each match's RIP-relative operand to a final address and categorises results into
    ; found, missingCritical, missingOptional, duplicateCritical, and duplicateOptional buckets.
    ; Returns: Map of pattern name → resolved address for every uniquely matched pattern.
    FindStaticAddresses()
    {
        result := Map()
        patterns := this.GetStaticPatterns()
        optionalNames := PoE2StaticOffsetsPatterns.GetOptionalNames()
        missingCritical := []
        missingOptional := []
        duplicateCritical := []
        duplicateOptional := []
        found := []
        scanDeadline := A_TickCount + 30000

        moduleBytes := this.Mem.GetModuleSnapshot(true)
        moduleSize := moduleBytes ? moduleBytes.Size : 0

        for patternInfo in patterns
        {
            if (A_TickCount > scanDeadline)
                break

            parsed := this.ParsePattern(patternInfo["pattern"])
            matchAddresses := []
            if (moduleBytes)
                matchAddresses := this.FindPatternAddressesInBuffer(moduleBytes, moduleSize, this.Mem.ModuleSnapshotBase, parsed, 2, scanDeadline)

            if (matchAddresses.Length = 0)
            {
                if optionalNames.Has(patternInfo["name"])
                    missingOptional.Push(patternInfo["name"])
                else
                    missingCritical.Push(patternInfo["name"])
                continue
            }

            if (matchAddresses.Length > 1)
            {
                if optionalNames.Has(patternInfo["name"])
                    duplicateOptional.Push(patternInfo["name"])
                else
                    duplicateCritical.Push(patternInfo["name"])
                continue
            }

            matchAddress := matchAddresses[1]

            if (parsed["bytesToSkip"] < 0)
            {
                if optionalNames.Has(patternInfo["name"])
                    missingOptional.Push(patternInfo["name"])
                else
                    missingCritical.Push(patternInfo["name"])
                continue
            }

            relOperandAddress := matchAddress + parsed["bytesToSkip"]
            relValue := this.Mem.ReadInt(relOperandAddress)
            finalAddress := relOperandAddress + relValue + 4

            if this.IsProbablyValidPointer(finalAddress)
            {
                result[patternInfo["name"]] := finalAddress
                found.Push(patternInfo["name"])
            }
            else
            {
                if optionalNames.Has(patternInfo["name"])
                    missingOptional.Push(patternInfo["name"])
                else
                    missingCritical.Push(patternInfo["name"])
            }
        }

        this.PatternScanReport := Map(
            "missingCritical", missingCritical,
            "missingOptional", missingOptional,
            "duplicateCritical", duplicateCritical,
            "duplicateOptional", duplicateOptional,
            "found", found
        )

        return result
    }

    ; Returns true if any critical pattern had zero matches or more than one match after scanning.
    HasPatternScanCriticalIssues()
    {
        return this.PatternScanReport["missingCritical"].Length > 0 || this.PatternScanReport["duplicateCritical"].Length > 0
    }

    ; Collects GameStates address candidates via a broader heuristic scan and returns the first valid one.
    ; Returns: first validated candidate address, or the first raw candidate if none validate.
    ResolveGameStatesAddressFallback()
    {
        candidates := this.ScanForGameStatesCandidates()
        for candidate in candidates
        {
            if this.ValidateGameStatesAddress(candidate["calculated"])
                return candidate["calculated"]
        }

        return candidates.Length ? candidates[1]["calculated"] : 0
    }

    ; Returns the full list of named byte-signature patterns from PoE2StaticOffsetsPatterns.
    GetStaticPatterns()
    {
        return PoE2StaticOffsetsPatterns.GetAll()
    }

    ; Parses a hex byte pattern string into data, mask, bytesToSkip, and anchorIndex arrays.
    ; Params: patternText - space-separated hex bytes, optional "??" wildcards, and "^" RIP-offset marker.
    ; Returns: Map with "data", "mask", "bytesToSkip", and "anchorIndex" keys.
    ParsePattern(patternText)
    {
        tokens := StrSplit(Trim(patternText), " ")
        data := []
        mask := []
        bytesToSkip := -1
        anchorIndex := -1

        for token in tokens
        {
            token := Trim(token)
            if (token = "")
                continue

            if (token = "^")
            {
                bytesToSkip := data.Length
                continue
            }

            if (token = "??" || token = "?")
            {
                data.Push(0)
                mask.Push(false)
            }
            else
            {
                data.Push(Integer("0x" token))
                mask.Push(true)
                if (anchorIndex < 0)
                    anchorIndex := data.Length - 1
            }
        }

        if (anchorIndex < 0)
            anchorIndex := 0

        return Map(
            "data", data,
            "mask", mask,
            "bytesToSkip", bytesToSkip,
            "anchorIndex", anchorIndex
        )
    }

    ; Returns the first pattern match address in the cached module snapshot, or 0 if none found.
    FindPatternAddressInModule(parsedPattern)
    {
        matches := this.FindPatternAddressesInModule(parsedPattern, 1)
        return matches.Length ? matches[1] : 0
    }

    ; Finds up to maxMatches occurrences of parsedPattern in the cached module snapshot.
    ; Returns: array of matching absolute addresses (may be empty).
    FindPatternAddressesInModule(parsedPattern, maxMatches := 1)
    {
        moduleBytes := this.Mem.GetModuleSnapshot()
        if !moduleBytes
            return []

        return this.FindPatternAddressesInBuffer(
            moduleBytes,
            moduleBytes.Size,
                this.Mem.ModuleSnapshotBase,
            parsedPattern,
            maxMatches)
    }

            ; Searches buffer for all occurrences of parsedPattern, returning up to maxMatches results.
            ; Uses MemChr on the anchor byte as a fast pre-filter before running the full mask comparison.
            ; Returns: array of absolute addresses (baseAddress + buffer offset of each match).
            FindPatternAddressesInBuffer(buffer, bufferSize, baseAddress, parsedPattern, maxMatches := 1, deadlineTick := 0)
    {
        if (!buffer || bufferSize <= 0)
            return []

        patternData := parsedPattern["data"]
        patternMask := parsedPattern["mask"]
        anchorIndex := parsedPattern["anchorIndex"]
        patternLen := patternData.Length
        if (patternLen <= 0)
            return []

        matches := []

        lastStart := bufferSize - patternLen
        ptr := buffer.Ptr
        anchorByte := patternData[anchorIndex + 1]
        i := 0
        while (i <= lastStart)
        {
            if (deadlineTick > 0 && A_TickCount > deadlineTick)
                break

            searchStart := ptr + i + anchorIndex
            remaining := (lastStart - i) + 1
            foundPtr := this.MemChr(searchStart, anchorByte, remaining)
            if (!foundPtr)
            {
                k := i
                while (k <= lastStart)
                {
                    if (deadlineTick > 0 && A_TickCount > deadlineTick)
                        break

                    if (NumGet(ptr, k + anchorIndex, "UChar") = anchorByte)
                    {
                        foundPtr := ptr + k + anchorIndex
                        break
                    }
                    k += 1
                }
            }

            if !foundPtr
                break

            i := foundPtr - ptr - anchorIndex
            if (i < 0 || i > lastStart)
                break

            matched := true
            j := 1
            while (j <= patternLen)
            {
                if (patternMask[j])
                {
                    b := NumGet(ptr, i + (j - 1), "UChar")
                    if (b != patternData[j])
                    {
                        matched := false
                        break
                    }
                }
                j += 1
            }

            if (matched)
            {
                matchAddress := baseAddress + i
                if (matches.Length = 0 || matches[matches.Length] != matchAddress)
                    matches.Push(matchAddress)

                if (maxMatches > 0 && matches.Length >= maxMatches)
                    return matches
            }

            i += 1
        }

        return matches
    }

    ; Searches for byteValue in a raw memory region via ucrtbase or msvcrt memchr, auto-detecting DLL.
    ; Returns: pointer to the first matching byte, or 0 if not found or no CRT DLL is available.
    MemChr(startPtr, byteValue, byteCount)
    {
        if (byteCount <= 0)
            return 0

        if (this.MemChrMode = 1)
            return DllCall("ucrtbase.dll\\memchr", "Ptr", startPtr, "Int", byteValue, "UPtr", byteCount, "Ptr")

        if (this.MemChrMode = 2)
            return DllCall("msvcrt.dll\\memchr", "Ptr", startPtr, "Int", byteValue, "UPtr", byteCount, "Ptr")

        if (this.MemChrMode = 0)
            return 0

        try
        {
            ptr := DllCall("ucrtbase.dll\\memchr", "Ptr", startPtr, "Int", byteValue, "UPtr", byteCount, "Ptr")
            this.MemChrMode := 1
            return ptr
        }
        catch
        {
            try
            {
                ptr := DllCall("msvcrt.dll\\memchr", "Ptr", startPtr, "Int", byteValue, "UPtr", byteCount, "Ptr")
                this.MemChrMode := 2
                return ptr
            }
            catch
            {
                this.MemChrMode := 0
                return 0
            }
        }
    }

    ; Scans all known patterns and writes a human-readable debug log of every match and resolved address.
    ; Returns: path to the written log file, or "" on failure.
    ExportPatternMatchesDebug(maxMatchesPerPattern := 0, outputPath := "")
    {
        if (!this.Mem.Handle)
            return ""

        if (outputPath = "")
        {
            stamp := FormatTime(, "yyyyMMdd_HHmmss")
            outputPath := A_ScriptDir "\\PatternScanDebug_" stamp ".log"
        }

        patterns := this.GetStaticPatterns()
        report := []
        report.Push("PoE2 AHK Pattern Debug Export")
        report.Push("Generated: " FormatTime(, "yyyy-MM-dd HH:mm:ss"))
        report.Push("PID: " this.Mem.Pid)
        report.Push("ModuleBase: " PoE2GameStateReader.Hex(this.Mem.ModuleBase))
        report.Push("ModuleSize: " this.Mem.ModuleSize)
        report.Push("")

        for patternInfo in patterns
        {
            parsed := this.ParsePattern(patternInfo["pattern"])
            matches := this.FindPatternAddressesInModule(parsed, maxMatchesPerPattern)

            report.Push("[Pattern] " patternInfo["name"])
            report.Push("  Signature: " patternInfo["pattern"])
            report.Push("  BytesToSkip: " parsed["bytesToSkip"])
            report.Push("  Matches: " matches.Length)

            for addr in matches
                report.Push("    - " PoE2GameStateReader.Hex(addr))

            if (parsed["bytesToSkip"] >= 0 && matches.Length = 1)
            {
                relOperandAddress := matches[1] + parsed["bytesToSkip"]
                relValue := this.Mem.ReadInt(relOperandAddress)
                finalAddress := relOperandAddress + relValue + 4
                report.Push("  ResolvedAddress: " PoE2GameStateReader.Hex(finalAddress))
            }

            report.Push("")
        }

        outFile := FileOpen(outputPath, "w", "UTF-8")
        if !IsObject(outFile)
            return ""

        for line in report
            outFile.WriteLine(line)
        outFile.Close()

        return outputPath
    }

    ; Scans all known patterns and writes each match result as a CSV row.
    ; Returns: path to the written CSV file, or "" on failure.
    ExportPatternMatchesCsv(maxMatchesPerPattern := 0, outputPath := "")
    {
        if (!this.Mem.Handle)
            return ""

        if (outputPath = "")
        {
            stamp := FormatTime(, "yyyyMMdd_HHmmss")
            outputPath := A_ScriptDir "\\PatternScanDebug_" stamp ".csv"
        }

        patterns := this.GetStaticPatterns()
        outFile := FileOpen(outputPath, "w", "UTF-8")
        if !IsObject(outFile)
            return ""

        outFile.WriteLine("PatternName,Signature,BytesToSkip,MatchIndex,MatchAddress,ResolvedAddress")

        for patternInfo in patterns
        {
            parsed := this.ParsePattern(patternInfo["pattern"])
            matches := this.FindPatternAddressesInModule(parsed, maxMatchesPerPattern)

            if (matches.Length = 0)
            {
                outFile.WriteLine(this.CsvCell(patternInfo["name"]) ","
                    . this.CsvCell(patternInfo["pattern"]) ","
                    . parsed["bytesToSkip"] ",0,,")
                continue
            }

            for idx, addr in matches
            {
                resolved := ""
                if (parsed["bytesToSkip"] >= 0)
                {
                    relOperandAddress := addr + parsed["bytesToSkip"]
                    relValue := this.Mem.ReadInt(relOperandAddress)
                    finalAddress := relOperandAddress + relValue + 4
                    resolved := PoE2GameStateReader.Hex(finalAddress)
                }

                outFile.WriteLine(this.CsvCell(patternInfo["name"]) ","
                    . this.CsvCell(patternInfo["pattern"]) ","
                    . parsed["bytesToSkip"] ","
                    . idx ","
                    . this.CsvCell(PoE2GameStateReader.Hex(addr)) ","
                    . this.CsvCell(resolved))
            }
        }

        outFile.Close()
        return outputPath
    }

    ; Wraps a value in double-quotes and escapes any internal double-quotes for safe CSV embedding.
    CsvCell(value)
    {
        text := value ""
        text := StrReplace(text, '"', '""')
        return '"' text '"'
    }

    ; Heuristic fallback scanner: searches for a common function prologue near "48 39 2D" to extract
    ; GameStates address candidates by reading the following RIP-relative operand.
    ; Returns: array of Maps with "pattern" (match addr) and "calculated" (resolved addr) keys.
    ScanForGameStatesCandidates()
    {
        result := []
        if (!this.Mem.ModuleBase || !this.Mem.ModuleSize)
            return result

        this.Mem.GetScanRegion(true)
        scanBase := this.Mem.ScanBase ? this.Mem.ScanBase : this.Mem.ModuleBase
        scanSize := this.Mem.ScanSize ? this.Mem.ScanSize : this.Mem.ModuleSize

        parsed := this.ParsePattern("48 83 EC ?? 48 8B F1 33 ED 48 39 2D")
        patternLen := parsed["data"].Length
        chunkSize := 2 * 1024 * 1024
        overlap := Max(0, patternLen - 1)
        currentOffset := 0
        deadline := A_TickCount + 12000

        while (currentOffset < scanSize)
        {
            if (A_TickCount > deadline)
                break

            remaining := scanSize - currentOffset
            readSize := Min(chunkSize, remaining)
            buffer := this.Mem.ReadBytes(scanBase + currentOffset, readSize, true)
            if (buffer && Type(buffer) = "Buffer" && buffer.Size >= patternLen)
            {
                matches := this.FindPatternAddressesInBuffer(
                    buffer,
                    buffer.Size,
                    scanBase + currentOffset,
                    parsed,
                    32,
                    deadline)

                for patternAddr in matches
                {
                    relOffset := this.Mem.ReadInt(patternAddr + 3)
                    nextInstruction := patternAddr + 7
                    gameStatesAddr := nextInstruction + relOffset

                    if this.IsProbablyValidPointer(gameStatesAddr)
                    {
                        result.Push(Map(
                            "pattern", patternAddr,
                            "calculated", gameStatesAddr
                        ))
                    }
                }

                if (result.Length >= 16)
                    break
            }

            if (readSize <= overlap)
                break
            currentOffset += (readSize - overlap)
        }

        return result
    }

    ; Validates a candidate GameStates address by dereferencing known offsets down to AreaInstanceData.
    ; Returns: true if the pointer chain resolves to plausible InGameState data.
    ValidateGameStatesAddress(address)
    {
        if !this.IsProbablyValidPointer(address)
            return false

        ; Preferred path for current reader model:
        ; address -> GameStateOffset* at +0x00 (GameStateStaticOffset.GameState)
        ; GameStateOffset.States at +0x48, each entry is 16 bytes, index 4 => InGameState
        gameStateOffsetPtr := this.Mem.ReadPtr(address)
        if this.IsProbablyValidPointer(gameStateOffsetPtr)
        {
            inGameStatePtr := this.Mem.ReadPtr(gameStateOffsetPtr
                + PoE2Offsets.GameState["States"]
                + (PoE2Offsets.GameState["InGameStateIndex"] * PoE2Offsets.GameState["StateEntrySize"]))
            if this.IsProbablyValidPointer(inGameStatePtr)
            {
                areaInstanceData := this.Mem.ReadPtr(inGameStatePtr + PoE2Offsets.InGameState["AreaInstanceData"])
                if this.IsProbablyValidPointer(areaInstanceData)
                    return true
            }
        }

        return false
    }

    ; Reads the full game state snapshot: all 12 named states, active state, and complete InGameState tree.
    ; Returns: Map with gameStates address, current/active state info, inGameState subtree; or 0 on error.
    ReadSnapshot()
    {
        if (!this.Mem.Handle || !this.GameStatesAddress)
            return 0

        staticGameStatePtr := this.Mem.ReadPtr(this.GameStatesAddress)
        if !this.IsProbablyValidPointer(staticGameStatePtr)
            return 0

        currentStateVecLast := this.Mem.ReadInt64(staticGameStatePtr + PoE2Offsets.GameState["CurrentStateVecLast"])

        statesByIndex := []
        statesByAddress := Map()
        statesBase := staticGameStatePtr + PoE2Offsets.GameState["States"]
        loop 12
        {
            idx := A_Index - 1
            stateAddr := this.Mem.ReadPtr(statesBase + (idx * PoE2Offsets.GameState["StateEntrySize"]))
            stateName := this.StateNames[A_Index]
            statesByIndex.Push(Map("index", idx, "name", stateName, "address", stateAddr))
            if (stateAddr)
                statesByAddress[stateAddr] := stateName
        }

        currentStateAddress := 0
        currentStateName := "GameNotLoaded"
        if (currentStateVecLast > 0x10)
        {
            currentStateAddress := this.Mem.ReadPtr(currentStateVecLast - 0x10)
            if (currentStateAddress && statesByAddress.Has(currentStateAddress))
                currentStateName := statesByAddress[currentStateAddress]
        }

        inGameStateAddress := this.ResolveInGameStateAddress(statesByIndex, currentStateAddress)
        inGameStateData := this.ReadInGameState(inGameStateAddress)

        return Map(
            "gameStatesAddress", this.GameStatesAddress,
            "staticAddresses", this.StaticAddresses,
            "patternScanReport", this.PatternScanReport,
            "gameStateObject", staticGameStatePtr,
            "currentStateAddress", currentStateAddress,
            "currentStateName", currentStateName,
            "inGameStateAddress", inGameStateAddress,
            "inGameState", inGameStateData,
            "allStates", statesByIndex
        )
    }

    ; Reads a lightweight snapshot optimised for the AutoFlask overlay, skipping the full entity scan.
    ; Returns: Map with flask slots, vitals, buffs, server data, and state info; or 0 on error.
    ReadAutoFlaskSnapshot()
    {
        if (!this.Mem.Handle || !this.GameStatesAddress)
            return 0

        staticGameStatePtr := this.Mem.ReadPtr(this.GameStatesAddress)
        if !this.IsProbablyValidPointer(staticGameStatePtr)
            return 0

        currentStateVecLast := this.Mem.ReadInt64(staticGameStatePtr + PoE2Offsets.GameState["CurrentStateVecLast"])

        statesByIndex := []
        statesByAddress := Map()
        statesBase := staticGameStatePtr + PoE2Offsets.GameState["States"]
        loop 12
        {
            idx := A_Index - 1
            stateAddr := this.Mem.ReadPtr(statesBase + (idx * PoE2Offsets.GameState["StateEntrySize"]))
            stateName := this.StateNames[A_Index]
            statesByIndex.Push(Map("index", idx, "name", stateName, "address", stateAddr))
            if (stateAddr)
                statesByAddress[stateAddr] := stateName
        }

        currentStateAddress := 0
        currentStateName := "GameNotLoaded"
        if (currentStateVecLast > 0x10)
        {
            currentStateAddress := this.Mem.ReadPtr(currentStateVecLast - 0x10)
            if (currentStateAddress && statesByAddress.Has(currentStateAddress))
                currentStateName := statesByAddress[currentStateAddress]
        }

        inGameStateAddress := this.ResolveInGameStateAddress(statesByIndex, currentStateAddress)
        inGameStateData := this.ReadInGameStateAutoFlask(inGameStateAddress)

        return Map(
            "snapshotMode", "autoflask-performance",
            "gameStatesAddress", this.GameStatesAddress,
            "gameStateObject", staticGameStatePtr,
            "currentStateAddress", currentStateAddress,
            "currentStateName", currentStateName,
            "inGameStateAddress", inGameStateAddress,
            "inGameState", inGameStateData,
            "allStates", statesByIndex
        )
    }

    ; Scores each state entry by validating its pointer chains and name, then returns the best InGameState address.
    ; Params: currentStateAddress - currently active state pointer used as a scoring hint.
    ; Returns: best InGameState address found, falling back to the cached or index-5 address.
    ResolveInGameStateAddress(statesByIndex, currentStateAddress := 0)
    {
        bestAddress := 0
        bestScore := -1

        if !(statesByIndex && Type(statesByIndex) = "Array")
            return 0

        for _, stateInfo in statesByIndex
        {
            if !(stateInfo && Type(stateInfo) = "Map" && stateInfo.Has("address"))
                continue

            stateAddress := stateInfo["address"]
            if !this.IsProbablyValidPointer(stateAddress)
                continue

            score := 0
            if (stateInfo.Has("name") && stateInfo["name"] = "InGameState")
                score += 6
            if (currentStateAddress && stateAddress = currentStateAddress)
                score += 2
            if (this.LastInGameStateAddress && stateAddress = this.LastInGameStateAddress)
                score += 4

            areaInstanceData := this.Mem.ReadPtr(stateAddress + PoE2Offsets.InGameState["AreaInstanceData"])
            worldData := this.Mem.ReadPtr(stateAddress + PoE2Offsets.InGameState["WorldData"])

            if this.IsProbablyValidPointer(areaInstanceData)
                score += 3
            if this.IsProbablyValidPointer(worldData)
                score += 1

            if this.IsProbablyValidPointer(areaInstanceData)
            {
                areaLevel := this.Mem.ReadUChar(areaInstanceData + PoE2Offsets.AreaInstance["CurrentAreaLevel"])
                areaHash := this.Mem.ReadUInt(areaInstanceData + PoE2Offsets.AreaInstance["CurrentAreaHash"])
                if (areaLevel >= 1 && areaLevel <= 100)
                    score += 1
                if (areaHash != 0)
                    score += 1

                playerInfoPtr := areaInstanceData + PoE2Offsets.AreaInstance["PlayerInfo"]
                localPlayerRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["LocalPlayerPtr"])
                localPlayerPtr := this.ResolveEntityPointer(localPlayerRawPtr)
                if this.IsPlausibleEntityPointer(localPlayerPtr)
                    score += 2
            }

            if (score > bestScore)
            {
                bestScore := score
                bestAddress := stateAddress
            }
        }

        if this.IsProbablyValidPointer(bestAddress)
        {
            this.LastInGameStateAddress := bestAddress
            return bestAddress
        }

        if this.IsProbablyValidPointer(this.LastInGameStateAddress)
            return this.LastInGameStateAddress

        return (statesByIndex.Length >= 5 && statesByIndex[5].Has("address")) ? statesByIndex[5]["address"] : 0
    }

    ; Re-scans for the GameStates address and resets all cached area, entity, and state pointers.
    RefreshStateAnchors()
    {
        candidate := this.ResolveGameStatesAddressFromStaticPattern()
        if !(candidate && this.ValidateGameStatesAddress(candidate))
            candidate := this.ResolveGameStatesAddressFallback()

        if (candidate && this.ValidateGameStatesAddress(candidate))
            this.GameStatesAddress := candidate

        this.LastInGameStateAddress := 0
        this.LastAreaInstanceAddress := 0
        this.LastAreaHash := 0
        this.LastAreaLevel := -1
    }

    ; Reads a slim InGameState containing only area instance and world data pointers for the AutoFlask path.
    ReadInGameStateAutoFlask(inGameStateAddress)
    {
        if !this.IsProbablyValidPointer(inGameStateAddress)
            return 0

        areaInstanceData := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["AreaInstanceData"])
        worldData := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["WorldData"])

        return Map(
            "address", inGameStateAddress,
            "areaInstanceData", areaInstanceData,
            "areaInstance", this.ReadAreaInstanceAutoFlask(areaInstanceData),
            "worldData", worldData,
            "worldDataDetails", this.ReadWorldDataAutoFlask(worldData)
        )
    }

    ; Reads the world area details pointer chain for the AutoFlask snapshot (no full WorldAreaDat decode).
    ReadWorldDataAutoFlask(worldDataAddress)
    {
        if !this.IsProbablyValidPointer(worldDataAddress)
            return 0

        worldAreaDetailsPtr := this.Mem.ReadPtr(worldDataAddress + PoE2Offsets.WorldData["WorldAreaDetailsPtr"])
        worldAreaDetailsRowPtr := 0
        worldAreaDat := 0
        if this.IsProbablyValidPointer(worldAreaDetailsPtr)
        {
            worldAreaDetailsRowPtr := this.Mem.ReadPtr(worldAreaDetailsPtr + PoE2Offsets.WorldData["WorldAreaDetailsRowPtr"])
            worldAreaDat := this.ReadWorldAreaDat(worldAreaDetailsRowPtr)
        }

        return Map(
            "address", worldDataAddress,
            "worldAreaDetailsPtr", worldAreaDetailsPtr,
            "worldAreaDetailsRowPtr", worldAreaDetailsRowPtr,
            "worldAreaDat", worldAreaDat
        )
    }

    ; Reads player vitals, flask slots, buffs, and server data for the AutoFlask snapshot.
    ; Resolves the local player pointer via direct struct lookup, falling back to an area search.
    ReadAreaInstanceAutoFlask(areaInstanceAddress)
    {
        if !this.IsProbablyValidPointer(areaInstanceAddress)
            return 0

        currentAreaLevel := this.Mem.ReadUChar(areaInstanceAddress + PoE2Offsets.AreaInstance["CurrentAreaLevel"])
        currentAreaHash := this.Mem.ReadUInt(areaInstanceAddress + PoE2Offsets.AreaInstance["CurrentAreaHash"])
        playerInfoPtr := areaInstanceAddress + PoE2Offsets.AreaInstance["PlayerInfo"]
        serverDataRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["ServerDataPtr"])
        localPlayerRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["LocalPlayerPtr"])
        localPlayerPtr := this.ResolveEntityPointer(localPlayerRawPtr)
        if !this.IsPlausibleEntityPointer(localPlayerPtr)
        {
            localPlayerPtr := this.FindLocalPlayerEntityFromArea(areaInstanceAddress, 128)
            if this.IsProbablyValidPointer(localPlayerPtr)
                localPlayerRawPtr := localPlayerPtr
        }
        serverDataPtr := this.ResolveServerDataPointer(playerInfoPtr, serverDataRawPtr)

        playerVitals := this.ReadPlayerVitals(localPlayerPtr)
        playerBuffsComponent := this.ReadPlayerBuffsComponent(localPlayerPtr)
        flaskSlotsFromBuffs := (playerBuffsComponent && playerBuffsComponent.Has("flaskSlots"))
            ? playerBuffsComponent["flaskSlots"]
            : this.ReadFlaskSlotsFromBuffs(localPlayerPtr)

        serverData := this.ReadServerData(serverDataPtr, true)
        if (serverData && serverData.Has("flaskInventory"))
        {
            flaskInventory := serverData["flaskInventory"]
            if (flaskInventory && flaskInventory.Has("flaskSlots") && flaskSlotsFromBuffs)
                this.MergeFlaskSlotsWithBuffs(flaskInventory["flaskSlots"], flaskSlotsFromBuffs)
        }

        playerStructCompat := Map(
            "localPlayerPtr", localPlayerPtr,
            "localPlayerRawPtr", localPlayerRawPtr,
            "vitalStruct", playerVitals,
            "playerVitals", playerVitals
        )

        return Map(
            "address", areaInstanceAddress,
            "currentAreaLevel", currentAreaLevel,
            "currentAreaHash", currentAreaHash,
            "serverDataPtr", serverDataPtr,
            "serverDataRawPtr", serverDataRawPtr,
            "localPlayerPtr", localPlayerPtr,
            "localPlayerRawPtr", localPlayerRawPtr,
            "vitalStruct", playerVitals,
            "playerStruct", playerStructCompat,
            "playerVitals", playerVitals,
            "playerBuffsComponent", playerBuffsComponent,
            "flaskSlotsFromBuffs", flaskSlotsFromBuffs,
            "serverData", serverData
        )
    }

    ; Root reader: reads the full InGameState tree including area instance, world data, and UI elements.
    ; Falls back to ReadAreaInstanceAutoFlask to populate missing player vitals when needed.
    ; Returns: Map with address, area/world/UI subtrees; or 0 if inGameStateAddress is invalid.
    ReadInGameState(inGameStateAddress)
    {
        if !this.IsProbablyValidPointer(inGameStateAddress)
            return 0

        areaInstanceData := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["AreaInstanceData"])
        worldData := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["WorldData"])
        uiRootStructPtr := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["UiRootStructPtr"])
        worldDataDetails := this.ReadWorldData(worldData)
        areaInstanceDetails := this.ReadAreaInstanceBasic(areaInstanceData)

        needsPlayerFallback := true
        if (areaInstanceDetails && Type(areaInstanceDetails) = "Map")
        {
            if (areaInstanceDetails.Has("playerVitals") && areaInstanceDetails["playerVitals"])
                needsPlayerFallback := false
            else if (areaInstanceDetails.Has("vitalStruct") && areaInstanceDetails["vitalStruct"])
                needsPlayerFallback := false
        }

        if needsPlayerFallback
        {
            areaInstanceFallback := this.ReadAreaInstanceAutoFlask(areaInstanceData)
            if (areaInstanceFallback && Type(areaInstanceFallback) = "Map")
            {
                if !(areaInstanceDetails && Type(areaInstanceDetails) = "Map")
                    areaInstanceDetails := Map()

                mergeKeys := [
                    "localPlayerPtr",
                    "localPlayerRawPtr",
                    "playerVitals",
                    "vitalStruct",
                    "playerStruct",
                    "playerBuffsComponent",
                    "flaskSlotsFromBuffs",
                    "serverData",
                    "serverDataPtr",
                    "serverDataRawPtr"
                ]

                for _, key in mergeKeys
                {
                    if areaInstanceFallback.Has(key)
                        areaInstanceDetails[key] := areaInstanceFallback[key]
                }
            }
        }

        uiRootPtr := 0
        gameUiPtr := 0
        gameUiControllerPtr := 0
        activeGameUiPtr := 0
        isControllerMode := false

        if this.IsProbablyValidPointer(uiRootStructPtr)
        {
            uiRootPtr := this.Mem.ReadPtr(uiRootStructPtr + PoE2Offsets.UiRootStruct["UiRootPtr"])
            gameUiPtr := this.Mem.ReadPtr(uiRootStructPtr + PoE2Offsets.UiRootStruct["GameUiPtr"])
            gameUiControllerPtr := this.Mem.ReadPtr(uiRootStructPtr + PoE2Offsets.UiRootStruct["GameUiControllerPtr"])
            if (!gameUiPtr && gameUiControllerPtr)
            {
                isControllerMode := true
                activeGameUiPtr := gameUiControllerPtr
            }
            else
            {
                activeGameUiPtr := gameUiPtr
            }
        }

        importantUiElements := this.ReadImportantUiElements(activeGameUiPtr, isControllerMode)

        return Map(
            "address", inGameStateAddress,
            "areaInstanceData", areaInstanceData,
            "areaInstance", areaInstanceDetails,
            "worldData", worldData,
            "worldDataDetails", worldDataDetails,
            "uiRootStructPtr", uiRootStructPtr,
            "uiRootPtr", uiRootPtr,
            "gameUiPtr", gameUiPtr,
            "gameUiControllerPtr", gameUiControllerPtr,
            "activeGameUiPtr", activeGameUiPtr,
            "isControllerMode", isControllerMode,
            "importantUiElements", importantUiElements
        )
    }

    ; Reads map UI pointers (MiniMap, LargeMap) and chat background alpha to detect the chat-open state.
    ; Params: isControllerMode - if true, prefers ControllerModeMapParentPtr over MapParentPtr.
    ReadImportantUiElements(gameUiPtr, isControllerMode := false)
    {
        if !this.IsProbablyValidPointer(gameUiPtr)
            return 0

        chatParentPtr     := this.Mem.ReadPtr(gameUiPtr + PoE2Offsets.ImportantUiElements["ChatParentPtr"])
        passiveTreePanel  := this.Mem.ReadPtr(gameUiPtr + PoE2Offsets.ImportantUiElements["PassiveSkillTreePanel"])
        mapParentPtr      := this.Mem.ReadPtr(gameUiPtr + PoE2Offsets.ImportantUiElements["MapParentPtr"])
        ctrlMapParentPtr  := this.Mem.ReadPtr(gameUiPtr + PoE2Offsets.ImportantUiElements["ControllerModeMapParentPtr"])

        ; Pick the active map parent depending on controller mode
        activeMapParentPtr := (isControllerMode && this.IsProbablyValidPointer(ctrlMapParentPtr))
            ? ctrlMapParentPtr
            : mapParentPtr

        largeMapPtr := 0
        miniMapPtr  := 0
        miniMapData := 0
        largeMapData := 0
        if this.IsProbablyValidPointer(activeMapParentPtr)
        {
            largeMapPtr := this.Mem.ReadPtr(activeMapParentPtr + PoE2Offsets.MapParentStruct["LargeMapPtr"])
            miniMapPtr  := this.Mem.ReadPtr(activeMapParentPtr + PoE2Offsets.MapParentStruct["MiniMapPtr"])

            ; Cache location can become stale (same issue as PassiveSkillTree).
            ; Fall back to navigating the children StdVector directly if both pointers are equal.
            if (largeMapPtr = miniMapPtr && this.IsProbablyValidPointer(largeMapPtr))
            {
                childrenDataPtr := this.Mem.ReadPtr(activeMapParentPtr + PoE2Offsets.UiElementBase["ChildrenFirst"])
                if this.IsProbablyValidPointer(childrenDataPtr)
                {
                    largeMapPtr := this.Mem.ReadPtr(childrenDataPtr + 0 * 8)  ; 1st child
                    miniMapPtr  := this.Mem.ReadPtr(childrenDataPtr + 1 * 8)  ; 2nd child
                }
            }

            if this.IsProbablyValidPointer(miniMapPtr)
                miniMapData := this.ReadMapUiElementData(miniMapPtr)
            if this.IsProbablyValidPointer(largeMapPtr)
                largeMapData := this.ReadMapUiElementData(largeMapPtr)
        }

        ; ChatParentUiElement — IsChatActive: backgroundColor.W * 255 >= 0x8C
        chatBgColor   := 0
        chatAlpha     := 0
        isChatActive  := false
        if this.IsProbablyValidPointer(chatParentPtr)
        {
            chatBgColor  := this.Mem.ReadUInt(chatParentPtr + PoE2Offsets.UiElementBase["BackgroundColor"])
            chatAlpha    := (chatBgColor >> 24) & 0xFF
            isChatActive := chatAlpha >= 0x8C
        }

        return Map(
            "chatParentPtr",              chatParentPtr,
            "chatBgColor",                chatBgColor,
            "chatAlpha",                  chatAlpha,
            "isChatActive",               isChatActive,
            "passiveSkillTreePanel",      passiveTreePanel,
            "mapParentPtr",               mapParentPtr,
            "controllerModeMapParentPtr", ctrlMapParentPtr,
            "activeMapParentPtr",         activeMapParentPtr,
            "largeMapPtr",                largeMapPtr,
            "miniMapPtr",                 miniMapPtr,
            "miniMapData",                miniMapData,
            "largeMapData",               largeMapData
        )
    }

    ; Reads position, size, shift and zoom from a MapUiElement pointer.
    ; Position is computed via a full parent-chain traversal (replicating C# GetUnScaledPosition()).
    ; Returned unscaledPosX/Y are in UI base coords (2560×1600).  Caller must apply GameWindowScale.
    ; For MiniMap the position is the TOP-LEFT; for LargeMap it is the MAP CENTER.
    ReadMapUiElementData(mapElemPtr)
    {
        if !this.IsProbablyValidPointer(mapElemPtr)
            return 0

        ; ── Walk parent chain (element → parent → … → root) ──────────────────────
        ; chain[1]=element, chain[2]=parent, ..., chain[N]=root
        chain := []
        curPtr := mapElemPtr
        Loop 10 {
            if !this.IsProbablyValidPointer(curPtr)
                break
            relX    := this.Mem.ReadFloat(curPtr + PoE2Offsets.UiElementBase["RelativePosition"])
            relY    := this.Mem.ReadFloat(curPtr + PoE2Offsets.UiElementBase["RelativePosition"] + 4)
            flags   := this.Mem.ReadUInt( curPtr + PoE2Offsets.UiElementBase["Flags"])
            posModX := this.Mem.ReadFloat(curPtr + PoE2Offsets.UiElementBase["PositionModifier"])
            posModY := this.Mem.ReadFloat(curPtr + PoE2Offsets.UiElementBase["PositionModifier"] + 4)
            parentP := this.Mem.ReadPtr(  curPtr + PoE2Offsets.UiElementBase["ParentPtr"])
            chain.Push(Map(
                "relX", relX, "relY", relY,
                "flags", flags,
                "posModX", posModX, "posModY", posModY
            ))
            if !this.IsProbablyValidPointer(parentP)
                break
            curPtr := parentP
        }

        ; ── Simulate C# GetUnScaledPosition() from root → element ─────────────────
        ; Root element returns its own relativePosition; each child adds its relativePosition
        ; and, if its own ShouldModifyPos flag (bit 10) is set, also its parent's positionModifier.
        N := chain.Length
        accX := 0.0
        accY := 0.0
        if N > 0 {
            accX := chain[N]["relX"]    ; root starts from its own relPos
            accY := chain[N]["relY"]
            Loop N - 1 {
                childIdx  := N - A_Index    ; walks N-1, N-2, …, 1
                parentIdx := childIdx + 1
                child  := chain[childIdx]
                parent := chain[parentIdx]
                if (child["flags"] >> 10) & 1 {    ; ShouldModifyPos = bit 10
                    accX += parent["posModX"]
                    accY += parent["posModY"]
                }
                accX += child["relX"]
                accY += child["relY"]
            }
        }

        ; ── Scale info from the map element itself ─────────────────────────────────
        ; GameWindowScale: v1 = (gwW-2*cull)/2560, v2 = gwH/1600
        ;   scaleIdx 1 → wScale = lMult*v1, hScale = lMult*v1
        ;   scaleIdx 2 → wScale = lMult*v2, hScale = lMult*v2
        ;   scaleIdx 3 → wScale = lMult*v1, hScale = lMult*v2  (most UI elements)
        scaleIdx  := this.Mem.ReadUChar(mapElemPtr + PoE2Offsets.UiElementBase["ScaleIndex"])
        localMult := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.UiElementBase["LocalScaleMultiplier"])

        ; ── Map element fields ─────────────────────────────────────────────────────
        flags     := (N > 0) ? chain[1]["flags"] : 0
        isVisible := (flags >> 11) & 1
        sizeW     := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.UiElementBase["UnscaledSize"])
        sizeH     := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.UiElementBase["UnscaledSize"] + 4)
        shiftX    := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.MapUiElement["Shift"])
        shiftY    := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.MapUiElement["Shift"] + 4)
        defShiftX := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.MapUiElement["DefaultShift"])
        defShiftY := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.MapUiElement["DefaultShift"] + 4)
        zoom      := this.Mem.ReadFloat(mapElemPtr + PoE2Offsets.MapUiElement["Zoom"])

        return Map(
            "ptr",           mapElemPtr,
            "unscaledPosX",  accX,       ; UI-coord position (apply GameWindowScale to get screen pixels)
            "unscaledPosY",  accY,
            "scaleIdx",      scaleIdx,   ; for GameWindowScale lookup
            "localMult",     localMult,
            "flags",         flags,
            "isVisible",     isVisible,
            "sizeW",         sizeW,      ; unscaled element size (UI coords)
            "sizeH",         sizeH,
            "shiftX",        shiftX,     ; already in screen-pixel units (no additional scaling needed)
            "shiftY",        shiftY,
            "defaultShiftX", defShiftX,
            "defaultShiftY", defShiftY,
            "zoom",          zoom,
            "chainDepth",    N,
            "relX",          (N > 0) ? chain[1]["relX"] : 0   ; debug: element's own relPos
        )
    }

    ; Reads world area details and the .dat row pointer for use in area name and property resolution.
    ReadWorldData(worldDataAddress)
    {
        if !this.IsProbablyValidPointer(worldDataAddress)
            return 0

        worldAreaDetailsPtr := this.Mem.ReadPtr(worldDataAddress + PoE2Offsets.WorldData["WorldAreaDetailsPtr"])
        worldAreaDetailsRowPtr := 0
        worldAreaDat := 0
        if this.IsProbablyValidPointer(worldAreaDetailsPtr)
        {
            worldAreaDetailsRowPtr := this.Mem.ReadPtr(worldAreaDetailsPtr + PoE2Offsets.WorldData["WorldAreaDetailsRowPtr"])
            worldAreaDat := this.ReadWorldAreaDat(worldAreaDetailsRowPtr)
        }

        return Map(
            "address", worldDataAddress,
            "worldAreaDetailsPtr", worldAreaDetailsPtr,
            "worldAreaDetailsRowPtr", worldAreaDetailsRowPtr,
            "worldAreaDat", worldAreaDat
        )
    }

    ; Collects awake and sleeping entities, all player components, flask slots, and server data.
    ; Scans AwakeEntities and SleepingEntities maps up to their respective configured sample limits.
    ; Returns: Map with entity arrays, all player component subtrees, flask data, and server data.
    ReadAreaInstanceBasic(areaInstanceAddress)
    {
        if !this.IsProbablyValidPointer(areaInstanceAddress)
            return 0

        currentAreaLevel := this.Mem.ReadUChar(areaInstanceAddress + PoE2Offsets.AreaInstance["CurrentAreaLevel"])
        currentAreaHash := this.Mem.ReadUInt(areaInstanceAddress + PoE2Offsets.AreaInstance["CurrentAreaHash"])

        this.LastAreaInstanceAddress := areaInstanceAddress
        this.LastAreaHash := currentAreaHash
        this.LastAreaLevel := currentAreaLevel

        playerInfoPtr := areaInstanceAddress + PoE2Offsets.AreaInstance["PlayerInfo"]
        serverDataRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["ServerDataPtr"])
        localPlayerRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["LocalPlayerPtr"])
        localPlayerPtr := this.ResolveEntityPointer(localPlayerRawPtr)
        if !this.IsPlausibleEntityPointer(localPlayerPtr)
        {
            localPlayerPtr := this.FindLocalPlayerEntityFromArea(areaInstanceAddress, 160)
            if this.IsProbablyValidPointer(localPlayerPtr)
                localPlayerRawPtr := localPlayerPtr
        }

        serverDataPtr := this.ResolveServerDataPointer(playerInfoPtr, serverDataRawPtr)
        awakeLimit := this.AwakeEntitySampleLimit ? this.AwakeEntitySampleLimit : 16
        sleepingLimit := this.SleepingEntitySampleLimit ? this.SleepingEntitySampleLimit : 8
        playerRenderComponent := this.ReadPlayerRenderComponent(localPlayerPtr)
        playerOrigin := this.ExtractWorldPositionFromRenderComponent(playerRenderComponent)

        entityListOffset := PoE2Offsets.AreaInstance["AwakeEntities"]
        awakeMapAddress := areaInstanceAddress + entityListOffset
        sleepingMapAddress := awakeMapAddress + 0x10
        awakeEntities := this.ReadAreaEntityMapSummary(awakeMapAddress, awakeLimit, playerOrigin)
        sleepingEntities := this.ReadAreaEntityMapSummary(sleepingMapAddress, sleepingLimit, playerOrigin)

        this.LastEntityReadOffset := entityListOffset
        this.LastEntityReadMode := "direct"

        serverData := this.ReadServerData(serverDataPtr)
        playerVitals := this.ReadPlayerVitals(localPlayerPtr)
        playerComponent := this.ReadPlayerComponent(localPlayerPtr)
        playerStatsComponent := this.ReadPlayerStatsComponent(localPlayerPtr)
        playerBuffsComponent := this.ReadPlayerBuffsComponent(localPlayerPtr)
        playerChargesComponent := this.ReadPlayerChargesComponent(localPlayerPtr)
        playerPositionedComponent := this.ReadPlayerPositionedComponent(localPlayerPtr)
        playerTransitionableComponent := this.ReadPlayerTransitionableComponent(localPlayerPtr)
        playerStateMachineComponent := this.ReadPlayerStateMachineComponent(localPlayerPtr)
        playerTargetableComponent := this.ReadPlayerTargetableComponent(localPlayerPtr)
        playerActorComponent := this.ReadPlayerActorComponentBasic(localPlayerPtr)
        flaskSlotsFromBuffs := (playerBuffsComponent && playerBuffsComponent.Has("flaskSlots"))
            ? playerBuffsComponent["flaskSlots"]
            : this.ReadFlaskSlotsFromBuffs(localPlayerPtr)

        if (serverData && serverData.Has("flaskInventory"))
        {
            flaskInventory := serverData["flaskInventory"]
            if (flaskInventory && flaskInventory.Has("flaskSlots") && flaskSlotsFromBuffs)
                this.MergeFlaskSlotsWithBuffs(flaskInventory["flaskSlots"], flaskSlotsFromBuffs)
        }

        playerStructCompat := Map(
            "localPlayerPtr", localPlayerPtr,
            "localPlayerRawPtr", localPlayerRawPtr,
            "vitalStruct", playerVitals,
            "playerVitals", playerVitals
        )

        return Map(
            "address", areaInstanceAddress,
            "currentAreaLevel", currentAreaLevel,
            "currentAreaHash", currentAreaHash,
            "entityListOffset", entityListOffset,
            "awakeMapAddress", awakeMapAddress,
            "sleepingMapAddress", sleepingMapAddress,
            "serverDataPtr", serverDataPtr,
            "serverDataRawPtr", serverDataRawPtr,
            "localPlayerPtr", localPlayerPtr,
            "localPlayerRawPtr", localPlayerRawPtr,
            "awakeEntities", awakeEntities,
            "sleepingEntities", sleepingEntities,
            "vitalStruct", playerVitals,
            "playerStruct", playerStructCompat,
            "playerVitals", playerVitals,
            "playerComponent", playerComponent,
            "playerStatsComponent", playerStatsComponent,
            "playerBuffsComponent", playerBuffsComponent,
            "playerChargesComponent", playerChargesComponent,
            "playerPositionedComponent", playerPositionedComponent,
            "playerRenderComponent", playerRenderComponent,
            "playerTransitionableComponent", playerTransitionableComponent,
            "playerStateMachineComponent", playerStateMachineComponent,
            "playerTargetableComponent", playerTargetableComponent,
            "playerActorComponent", playerActorComponent,
            "flaskSlotsFromBuffs", flaskSlotsFromBuffs,
            "serverData", serverData
        )
    }

    ; Filters ghost entities from a radar entity summary using consecutive-invalid-frame tracking.
    ; Port of upstream commit 75d48872: entities invalid for StaleEntityFrameThreshold consecutive
    ; radar ticks are dropped from the sample entirely to prevent ghost dots in the renderer.
    ; - Valid entities reset their stale counter.
    ; - Addresses no longer present in the sample are pruned from the stale map.
    ; Mutates entitySummary["sample"] and ["sampleCount"] in place; returns the filtered summary.
    ; Filters ghost/dead entities from a radar entity summary using consecutive-dead-frame tracking.
    ; Port of upstream commit 75d48872, extended to also track isAlive=false (not just isValid=false).
    ;
    ; An entity is considered "dead" if:
    ;   - isValid=false (game engine removed it), OR
    ;   - life component decoded successfully AND isAlive=false (HP reached 0)
    ;
    ; Entities dead for StaleEntityFrameThreshold consecutive ticks are added to _deadEntityBlacklist.
    ; Blacklisted entities are immediately dropped regardless of current state — this handles the case
    ; where dead monsters remain in the awake entity map with isValid=true indefinitely.
    ;
    ; areaInstanceAddr is used to detect area transitions and reset both maps.
    _FilterStaleRadarEntities(entitySummary, areaInstanceAddr)
    {
        if !(entitySummary && entitySummary.Has("sample"))
            return entitySummary

        ; Reset both maps on area change (new map = fresh entity set).
        if (areaInstanceAddr != this._lastAreaInstanceAddr)
        {
            this._staleEntityMap      := Map()
            this._deadEntityBlacklist := Map()
            this._lastAreaInstanceAddr := areaInstanceAddr
        }

        threshold   := this.StaleEntityFrameThreshold
        staleMap    := this._staleEntityMap
        blacklist   := this._deadEntityBlacklist
        sample      := entitySummary["sample"]
        newSample   := []
        seenAddrs   := Map()

        for _, sampleEntry in sample
        {
            entity := (sampleEntry && sampleEntry.Has("entity")) ? sampleEntry["entity"] : 0
            if !entity
            {
                newSample.Push(sampleEntry)
                continue
            }

            addr := entity.Has("address") ? entity["address"] : 0

            ; Permanently blacklisted from a previous tick — drop immediately.
            if (addr > 0 && blacklist.Has(addr))
                continue

            if (addr > 0)
                seenAddrs[addr] := true

            ; Determine dead status: isValid=false OR (life decoded && isAlive=false).
            isDead := false
            if (entity.Has("isValid") && !entity["isValid"])
                isDead := true
            if (!isDead && entity.Has("decodedComponents"))
            {
                dc := entity["decodedComponents"]
                if (dc && dc.Has("life"))
                {
                    life := dc["life"]
                    if (life && Type(life) = "Map" && life.Has("isAlive") && !life["isAlive"])
                        isDead := true
                }
            }

            if !isDead
            {
                ; Entity is live — clear any accumulated stale count and keep it.
                if (addr > 0 && staleMap.Has(addr))
                    staleMap.Delete(addr)
                newSample.Push(sampleEntry)
            }
            else
            {
                ; Entity is dead — increment counter; blacklist once threshold is reached.
                count := (addr > 0 && staleMap.Has(addr)) ? staleMap[addr] : 0
                count += 1
                if (addr > 0)
                    staleMap[addr] := count

                if (count >= threshold)
                {
                    ; Threshold reached — permanently blacklist this address for the current area.
                    if (addr > 0)
                    {
                        blacklist[addr] := true
                        if staleMap.Has(addr)
                            staleMap.Delete(addr)
                    }
                    ; Drop: do not push to newSample.
                }
                else
                    newSample.Push(sampleEntry)   ; grace period: keep for a few ticks
            }
        }

        ; Prune stale map entries for addresses that disappeared from the BFS entirely.
        pruneKeys := []
        for addr, _ in staleMap
            if !seenAddrs.Has(addr)
                pruneKeys.Push(addr)
        for _, addr in pruneKeys
            if staleMap.Has(addr)
                staleMap.Delete(addr)

        entitySummary["sample"]      := newSample
        entitySummary["sampleCount"] := newSample.Length
        return entitySummary
    }

    ; Reads a lightweight snapshot for the radar overlay: player position, entity positions, and map UI data.
    ; Much faster than ReadSnapshot() — skips inventory, stats, buffs, server data, and world area details.
    ; InGameState address is re-resolved every 800ms; UI element data is re-read every 400ms.
    ; Returns: snapshot Map compatible with RadarOverlay.Render(), or 0 on error.
    ReadRadarSnapshot()
    {
        if (!this.Mem.Handle || !this.GameStatesAddress)
            return 0

        t0 := A_TickCount

        ; Re-resolve InGameState address every 800ms — the 12-state loop is expensive at 100ms.
        nowTick := A_TickCount
        if (!this._radarInGameStateCache || (nowTick - this._radarInGameStateTick) > 800)
        {
            staticGameStatePtr := this.Mem.ReadPtr(this.GameStatesAddress)
            if !this.IsProbablyValidPointer(staticGameStatePtr)
                return 0

            currentStateVecLast := this.Mem.ReadInt64(staticGameStatePtr + PoE2Offsets.GameState["CurrentStateVecLast"])

            statesByIndex   := []
            statesByAddress := Map()
            statesBase := staticGameStatePtr + PoE2Offsets.GameState["States"]
            loop 12
            {
                idx       := A_Index - 1
                stateAddr := this.Mem.ReadPtr(statesBase + (idx * PoE2Offsets.GameState["StateEntrySize"]))
                stateName := this.StateNames[A_Index]
                statesByIndex.Push(Map("index", idx, "name", stateName, "address", stateAddr))
                if stateAddr
                    statesByAddress[stateAddr] := stateName
            }

            currentStateAddress := 0
            if (currentStateVecLast > 0x10)
            {
                currentStateAddress := this.Mem.ReadPtr(currentStateVecLast - 0x10)
                if !(currentStateAddress && statesByAddress.Has(currentStateAddress))
                    currentStateAddress := 0
            }

            resolved := this.ResolveInGameStateAddress(statesByIndex, currentStateAddress)
            if !resolved
                return 0
            this._radarInGameStateCache := resolved
            this._radarInGameStateTick := nowTick
        }
        t1 := A_TickCount  ; after state resolution
        inGameStateAddress := this._radarInGameStateCache

        areaInstanceData := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["AreaInstanceData"])
        if !this.IsProbablyValidPointer(areaInstanceData)
            return 0

        ; Player world position
        playerInfoPtr     := areaInstanceData + PoE2Offsets.AreaInstance["PlayerInfo"]
        localPlayerRawPtr := this.Mem.ReadPtr(playerInfoPtr + PoE2Offsets.LocalPlayerStruct["LocalPlayerPtr"])
        localPlayerPtr    := this.ResolveEntityPointer(localPlayerRawPtr)
        playerRenderComponent := this.ReadPlayerRenderComponent(localPlayerPtr)
        t2 := A_TickCount  ; after player read

        ; Map UI element data — re-read only every 400ms to avoid expensive UI tree walk at 100ms.
        ; Map positions/zoom rarely change mid-frame; re-reading less often has no visible impact.
        if (!this._radarUiCache || (nowTick - this._radarUiCacheTick) > 400)
        {
            uiRootStructPtr := this.Mem.ReadPtr(inGameStateAddress + PoE2Offsets.InGameState["UiRootStructPtr"])
            importantUiElements := 0
            if this.IsProbablyValidPointer(uiRootStructPtr)
            {
                gameUiPtr           := this.Mem.ReadPtr(uiRootStructPtr + PoE2Offsets.UiRootStruct["GameUiPtr"])
                gameUiControllerPtr := this.Mem.ReadPtr(uiRootStructPtr + PoE2Offsets.UiRootStruct["GameUiControllerPtr"])
                isControllerMode    := (!gameUiPtr && gameUiControllerPtr)
                activeGameUiPtr     := isControllerMode ? gameUiControllerPtr : gameUiPtr
                importantUiElements := this.ReadImportantUiElements(activeGameUiPtr, isControllerMode)
            }
            this._radarUiCache := importantUiElements
            this._radarUiCacheTick := nowTick
        }
        t3 := A_TickCount  ; after UI cache

        ; Entity positions using radar-only decode (Render + Life + Positioned).
        ; Radar uses smaller limits than the full snapshot for faster 100ms updates.
        entityListOffset   := PoE2Offsets.AreaInstance["AwakeEntities"]
        awakeMapAddress    := areaInstanceData + entityListOffset
        sleepingMapAddress := awakeMapAddress + 0x10
        awakeLimit         := this.RadarAwakeEntityLimit
        sleepingLimit      := this.RadarSleepingEntityLimit
        playerOrigin       := this.ExtractWorldPositionFromRenderComponent(playerRenderComponent)

        emptyEntitySummary := Map("address", 0, "size", 0, "sample", [], "sampleCount", 0)
        try
        {
            awakeEntities := this.ReadAreaEntityMapSummaryForRadar(awakeMapAddress, awakeLimit, playerOrigin)
        }
        catch
        {
            awakeEntities := emptyEntitySummary
        }
        t4 := A_TickCount  ; after awake entity read

        try
        {
            ; Skip sleeping entity read entirely when limit is 0.
            ; Sleeping entities are outside the active simulation range and carry stale positions.
            if (sleepingLimit > 0)
                sleepingEntities := this.ReadAreaEntityMapSummaryForRadar(sleepingMapAddress, sleepingLimit, playerOrigin)
            else
                sleepingEntities := emptyEntitySummary
        }
        catch
        {
            sleepingEntities := emptyEntitySummary
        }
        t5 := A_TickCount  ; after sleeping entity read

        ; Apply stale-entity filter (port of upstream commit 75d48872):
        ; entities dead for StaleEntityFrameThreshold consecutive ticks are permanently blacklisted.
        awakeEntities    := this._FilterStaleRadarEntities(awakeEntities,    areaInstanceData)
        sleepingEntities := this._FilterStaleRadarEntities(sleepingEntities, areaInstanceData)
        t6 := A_TickCount  ; after filter

        ; Store sub-timings for display in status bar (all in ms).
        this.RadarTimings := Map(
            "state",   t1 - t0,
            "player",  t2 - t1,
            "ui",      t3 - t2,
            "awake",   t4 - t3,
            "sleep",   t5 - t4,
            "filter",  t6 - t5,
            "total",   t6 - t0
        )

        return Map(
            "inGameState", Map(
                "address",             inGameStateAddress,
                "importantUiElements", importantUiElements,
                "areaInstance", Map(
                    "address",               areaInstanceData,
                    "playerRenderComponent", playerRenderComponent,
                    "awakeEntities",         awakeEntities,
                    "sleepingEntities",      sleepingEntities
                )
            )
        )
    }

}
