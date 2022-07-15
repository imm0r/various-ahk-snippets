class dict {

	; --- Static Variables ---
	__New(param_default:="") {
		
		this.data := []
		this.size := 0

		this.throwExceptions := true
		if (param_default != "") {
			this.data := param_default
		}
	}


	; --- Static Methods ---
	clone() {
		return new dict(this.data.Clone())
	}
	map(param_keyArr, param_valueArr) {
		if !(IsObject(param_array) || IsObject(param_valueArr)) {
			this._typeException()
		}

		; perform
		for _, value in param_keyArr {
			vHash := this._hash(value)
			this.data[vHash] := param_valueArr[A_Index]
		}
		this.size := this.data.Count()
		return this.size
	}
	set(param_key, param_value) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		this.data[vHash] := param_value
		this.size := this.data.Count()
		return this.size
	}
	clear() {

		; perform
		this.data := []
		this.size := this.data.Count()
		return true
	}
	remove(param_key) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		if (this.get(vHash)) {
			this.data.Delete(vHash)
			this.size := this.data.Count()
			return true
		}
		return false
	}
	_typeException() {
		if (this.throwExceptions == true) {
			throw Exception("Type Error", -2)
		}
	}
	; /--\--/--\--/--\--/--\--/--\
	; Internal functions
	; \--/--\--/--\--/--\--/--\--/

	_hash(param_key) {

		; perform
		if (IsObject(param_key)) {
			Hash := &param_key
		} else {
			if param_key is integer
			{
				hash := param_key
			}
			else if param_key is float
			{
				truncatedKey := param_key & -1
				if (Key == truncatedKey) {
					hash := truncatedKey
				} else {
					VarSetCapacity(hash, 8)
					NumPut(param_key, hash,, "Double")
					hash := NumGet(hash,, "Int64")
				}
			} else {
				hash := param_key		; := 0
				/*
				for _, char in StrSplit(param_key) {
					hash := 31 * hash + Ord(Char)
				}
				*/
			}
		}
		return hash
	}
	get(param_key) {
		if (this.data[param_key]) {
			return this.data[param_key]
		}
		return false
	}
	has(param_key) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		if (this.data[vHash]) {
			return true
		}
		return false
	}
	create(param_key, param_value) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		this.data[vHash] := param_value
		this.size := this.data.Count()
		return this.size
	}
	update(param_key, param_value) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		this.data[vHash] := param_value
		this.size := this.data.Count()
		return this.size
	}
	delete(param_key) {

		; prepare
		vHash := this._hash(param_key)

		; perform
		if (this.get(vHash)) {
			this.data.Delete(vHash)
			this.size := this.data.Count()
			return true
		}
		return false
	}
}
