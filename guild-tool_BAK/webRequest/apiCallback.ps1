# Restart script with admin rights if user doesnt have em yet.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe '-NoProfile -ExecutionPolicy remotePC -File `"$PSCommandPath`" -Verb RunAs'; exit }


# Start-Process pwsh.exe '-NoProfile -ExecutionPolicy remotePC -FilePath `"F:\ahk\guild tool\apiCallback.ps1`" -WorkingDirectory `"F:\ahk\guild tool`" -Verb RunAs'

# misc preperations
Clear-Host

# description:
Write-Host "1. Script retrieves the entire list of members in our Guild."
Write-Host "2. Script retrieves the entire list of all currently available classes in the game."
Write-Host "3. Script saves members list aswell as the classes to json files"
Write-Host "4. see: list_Members.json and list_Classes.json inside the root directory of this powerhsell script."
Write-Host "5. Script archives old json files. So we got a way to see if there are any changes made."
Write-Host "`n====================================================================================================`n"

# setting up some main variables
## Setting up directories and filenames
$ScriptPath = Get-Item -Path .\
$ArchiveDateTime = Get-Date -Format 'yyyy-MM-dd_hh-mm-ss'
$ArchivePath = "$ScriptPath\archive"
$Filename_test = "list_test.json"
$Filename_Members = "list_Members.json"
$Filename_Classes = "list_Classes.json"
$PathToFile_test = "$ScriptPath\$Filename_test"
$PathToFile_Members = "$ScriptPath\$Filename_Members"
$PathToFile_Classes = "$ScriptPath\$Filename_Classes"
$PathToArchiveFile_test = "$ArchivePath\list_test_$ArchiveDateTime.json"
$PathToArchiveFile_Members = "$ArchivePath\list_Members_$ArchiveDateTime.json"
$PathToArchiveFile_Classes = "$ArchivePath\list_Classes_$ArchiveDateTime.json"

## Setting up webRequest related variables
$webReq_MembersUrl = "https://forum.netmarble.com/api/game/lin2ws/guild/6338289276228415498/member/list" # ?_=1676059252800"
$webReq_ClassesUrl = "https://forum.netmarble.com/api/game/lin2ws/official/forum/lin2ws_en/profile/meta?languageCd"
$WebReq_authority = "forum.netmarble.com"
$WebReq_path = "/api/game/lin2ws/guild/6338289276228415498/member/list"     # ?_=1676059252800"
$WebReq_ref = "https://forum.netmarble.com/lin2ws/groups/6338289276228415498/member"

# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Archiving existing json files.
## If the file "list_Members.json" exists.
if (Get-Item -Path $PathToFile_Members -ErrorAction Ignore) {
    try {
        ### If the Archive folder does not exist, create it now.
        if (-not(Test-Path -Path $ArchivePath -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $ArchivePath -ErrorAction STOP
            Write-Host "No existing archive folder.`nCreating $ArchivePath`n"
        }
        ### Move the existing list_Members.json file to the archive and add the current date & time to the filename.
        Move-Item -Path $PathToFile_Members -Destination $PathToArchiveFile_Members -Force -ErrorAction STOP
        Write-Host "Existing $Filename_Members detected!`n`tMoving it to: $PathToArchiveFile_Members"

        ### Check if the file "list_Classes.json" exists.
        if (Get-Item -Path $PathToFile_Classes -ErrorAction Ignore) {
            try {
                #### Move the existing list_Classes.json file to the archive and add the current date & time to the filename.
                Move-Item -Path $Filename_Classes -Destination $PathToArchiveFile_Classes -Force -ErrorAction STOP
                Write-Host "`nExisting $Filename_Classes detected!`n`tMoving it to: $PathToArchiveFile_Classes"
            }
            catch {
                throw $_.Exception.Message
            }
        }
        ### Check if the file "list_test.json" exists.
        if (Get-Item -Path $PathToFile_test -ErrorAction Ignore) {
            try {
                #### Move the existing list_test.json file to the archive and add the current date & time to the filename.
                Move-Item -Path $Filename_test -Destination $PathToArchiveFile_test -Force -ErrorAction STOP
                Write-Host "`nExisting $Filename_test detected!`n`tMoving it to: $PathToArchiveFile_test"
            }
            catch {
                throw $_.Exception.Message
            }
        }
    }
    catch {
        throw $_.Exception.Message
    }
}

# Setting up a session for the webRequest
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
$session.Cookies.Add((New-Object System.Net.Cookie("forumToken", "CFB38FA692C814B6C8449789BE34F1D2659E5F956369AD2D7F9EA83B79366AB305E1F1B42954B4579562CD39098CEC4AB09D7EFF1185A1C29BE5C03C8C22A544E695F69CF00272E7EFC652FA7C500F98BD165004F11963485E89DB4D7983F48EE5C4CDA8E33F22234D0B3ADC77A35EA65C854250D9664A4BB233E67E4E8C61B0CF287690C94A575D20262CB238B71A16807F7B9C39CAF095156B5F5F4E187EBFA0BFC78444CE28892D11B2A88A39BA58BAC5D68F20F91373C0A149890127F5E3268BF573825113B97CDF9977612B29BE8CA3EF6DA75F4781A33540AA8A5AC41D47F20610B32E27C5582DB33FD2366A096268073AF39D25ADD88E8DCF86E87724A86E22C57187F271406E6F846AE7996050CD6332AB9A25574127399AA2457E36479B88E27088302800382BF701EBFD56C8F3C83DFE939CD4823766ABB4B565C10009F4832DDF3299130D5470812733F5799F736AE0378088F59DCE43431A72B725050A5F1372ADD5D084A36765BDEEC5409D060BC25C9469", "/", ".forum.netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("FORUM_SES", "CFB38FA692C814B6C8449789BE34F1D2659E5F956369AD2D7F9EA83B79366AB305E1F1B42954B4579562CD39098CEC4AB09D7EFF1185A1C29BE5C03C8C22A54440EC76F59D01980377E7A1FFCD9DE9F51F8C3D01A226A7076574EFFADEBB3CC6808F27E7A174FEA656221486EE6DAA035EB0965F1ED1A4923FB99E3D92D354CB37A2D756875594A2A133897B2ACFBC4978EB2E586575DADFA78ADC54DC248F1BBA7DC3D502245281536B526C5061EF2831CC979590F273127DE0C079A1FEFEFD9415487080AD5D0B7B879779BC6B2BB631071403DB7422FAF84E794CF006EAD9E1CCFEAF127151736922E71DF7F93714606D8030B23CB8ACADE8BB7EEF3AD48AD653BF7681E22CD9469BF1899EC2B00F99A45188681E6A43FC09FAC8CBC3820A332C0CB9F843FE6537416F3399591BEF", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("fLang", "en_US", "/", "forum.netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_ga_MREW6HJ2MV", "GS1.1.1675463720.2.1.1675464789.0.0.0", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_gid", "GA1.2.1812519381.1676050305", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_gat", "1", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_dc_gtm_UA-150344003-7", "1", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_ga_HB2CH4H2HK", "GS1.1.1676057572.13.1.1676059254.0.0.0", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_gat_error_log", "1", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_gali", "lmmember", "/", ".netmarble.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("_ga", "GA1.2.1912757985.1675459902", "/", ".netmarble.com")))

# Invoking the WebRequest for the guild members list
$tmpJson = Invoke-WebRequest -UseBasicParsing -Uri $webReq_MembersUrl `
    -WebSession $session `
    -Headers @{
    "authority"          = $WebReq_authority
    "method"             = "GET"
    "path"               = $WebReq_path
    "scheme"             = "https"
    "accept"             = "application/json, text/javascript, */*; q=0.01"
    "accept-encoding"    = "gzip, deflate, br"
    "accept-language"    = "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"
    "referer"            = $WebReq_ref
    "sec-ch-ua"          = "`"Not_A Brand`";v=`"99`", `"Google Chrome`";v=`"109`", `"Chromium`";v=`"109`""
    "sec-ch-ua-mobile"   = "?0"
    "sec-ch-ua-platform" = "`"Windows`""
    "sec-fetch-dest"     = "empty"
    "sec-fetch-mode"     = "cors"
    "sec-fetch-site"     = "same-origin"
    "x-requested-with"   = "XMLHttpRequest"
}
Write-Output "`n----------------------------------------------------------------------------------------------------`n`nThe WebRequest for the members returns the following:"$tmpJson
Write-Host "----------------------------------------------------------------------------------------------------`n";

# test if the string recieved from the webRequest is a valid json string
## if ($tmpJson | Test-Json) {
    ## If the string is valid we convert it to a json file.
    ## $powershellRepresentation = ConvertFrom-Json $tmpJson -ErrorAction Stop;
    ## Set-Content -Path $PathToFile_test -Value $powershellRepresentation;
    ## Write-Host "The string returned from the WebRequest was successfully convertred to JSON and was written to:`n`t"$PathToFile_test;
    Set-Content -Path $PathToFile_Members -Value $tmpJson;
    Write-Host "The string returned from the WebRequest was successfully convertred to JSON and was written to:`n`t"$PathToFile_Members;
## }
## else {
    ## If string is not valid display error msg.
##     Write-Host "Provided string is not a valid JSON string";
## }

# Clearing the variable holding the temp json string and displaying a divider line for better visivility
$tmpJson = ""
Write-Host "`n====================================================================================================`n";

# Invoking the WebRequest for the class list
$tmpJson = Invoke-WebRequest -UseBasicParsing -Uri $webReq_ClassesUrl `
    -WebSession $session `
    -Headers @{
    "authority"          = $WebReq_authority
    "method"             = "GET"
    "path"               = $WebReq_path
    "scheme"             = "https"
    "accept"             = "application/json, text/javascript, */*; q=0.01"
    "accept-encoding"    = "gzip, deflate, br"
    "accept-language"    = "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"
    "referer"            = $WebReq_ref
    "sec-ch-ua"          = "`"Not_A Brand`";v=`"99`", `"Google Chrome`";v=`"109`", `"Chromium`";v=`"109`""
    "sec-ch-ua-mobile"   = "?0"
    "sec-ch-ua-platform" = "`"Windows`""
    "sec-fetch-dest"     = "empty"
    "sec-fetch-mode"     = "cors"
    "sec-fetch-site"     = "same-origin"
    "x-requested-with"   = "XMLHttpRequest"
}
Write-Output "The WebRequest for the classes returns the following:`n"$tmpJson
Write-Host "----------------------------------------------------------------------------------------------------`n";

# test if the string recieved from the webRequest is a valid json string
##if ($tmpJson | Test-Json) {
    ## If the string is valid we convert it to a json file.
    ## $powershellRepresentation = ConvertFrom-Json $tmpJson -ErrorAction Stop;
    Set-Content -Path $PathToFile_Classes -Value $tmpJson;
    Write-Host "The string returned from the WebRequest was successfully convertred to JSON and was written to:`n`t"$PathToFile_Classes;
## }
## else {
    ## If string is not valid display error msg.
##     Write-Host "Provided srting is not a valid JSON string";
## }
Write-Host "`n====================================================================================================`n`nAll jobs done, exiting the script.";