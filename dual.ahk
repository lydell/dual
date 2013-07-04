class Dual {
	; Settings. They are described in the readme (*). Remember to mirror the defaults there.
	comboKeys :=
	(
	"
	a b c d e f g h i j k l m n o p q r s t u v w x y z
	0 1 2 3 4 5 6 7 8 9
	. , `; `` ' / \ [ ] - =
	Up Down Left Right Home End PgUp PgDn Insert Delete Backspace Space Enter Tab
	F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
	"
	)
	timeout := 300
	delay := 70
	doublePress := 200
	modifiers := ["LCtrl", "RCtrl", "LShift", "RShift", "LAlt", "RAlt", "LWin", "RWin"] ; (*)

	; (*) Note that `Dual.modifiers` is not documented in the readme. I don't think anyone needs to
	; modify that setting. If so, why bother the users with more options to understand? In the event
	; that anyone needs to, they could read it here. It is used by `Dual.modifiersDown()` and
	; `Dual.send()` to check all possible modifiers.

	; Public methods. They are described in the readme. Remember to mirror the function headers there.

	keys := {}
	set(originalKey, upKey, downKey="") {
		if (upKey == "") {
			upKey := originalKey
		}
		if (downKey == "") {
			downKey := originalKey
		}
		this.keys[originalKey] := {upKey: new this.Key(upKey), downKey: new this.Key(downKey)}
	}

	launch() {
		for originalKey in this.keys {
			Hotkey *%originalKey%, Dual_keydown
			Hotkey *%originalKey% UP, Dual_keyup
		}

		for comboKey in this.getFilteredComboKeys() {
			Hotkey *%comboKey%, Dual_comboKey
		}
	}

	; Below are two functions that exist to make regular AHK shortcuts work with Dual. They are a
	; little bit buggish. I just haven't nailed down exactly how yet.

	; Checks if the specified `modifiers` -- and those only -- are down. It is used to mimic native
	; AHK behavior, for example `modifiersDown("Ctrl", "Shift")` mimics `^+`.
	modifiersDown(modifiers*) {
		approvedModifiers := {}
		for index, modifier in modifiers {
			; Support custom {win} shortcut for either Windows key.
			StringLower modifier, modifier
			if (modifier == "win" and not GetKeyState("LWin") and not GetKeyState("RWin")) {
				return false
			}

			if (not GetKeyState(modifier)) {
				return false
			}

			; Support "Control" as an alias for "Ctrl". Moreover, it replaces the first occurrence
			; only, case insensitive. Perfect!
			StringReplace modifier, modifier, "Control", "Ctrl"
			; Mark the `modifier` as OK to be down. Also support shorthands such as "Ctrl" by
			; prepending "L" and "R". It doesn't matter that we also mark trash (such as "LF1" and
			; even "Ctrl" itself) this way; it is not likely that it would cause any side effects,
			; and therefore not worth checking. Also, property lookup is case insensitive. Perfect!
			approvedModifiers["L" modifier] := true
			approvedModifiers["R" modifier] := true
			approvedModifiers[modifier] := true
		}

		for index, modifier in this.modifiers {
			if (not approvedModifiers[modifier] and GetKeyState(modifier)) {
				return false
			}
		}
		return true
	}

	; Like `SendInput %str%`, but releases any modifiers first. (Puts them back down afterwards.)
	send(str) {
		modifiersUp := ""
		modifiersDown := ""
		for index, modifier in this.modifiers {
			if (GetKeyState(modifier)) {
				modifiersUp .= "{" modifier " up}"
				modifiersDown .= "{" modifier " down}"
			}
		}
		SendInput %modifiersUp%%str%%modifiersDown%
	}

	; Private methods. (Still accessible by the user, though.)

	comboKeyRemappings := {}
	getFilteredComboKeys() {
		comboKeys := this.comboKeys
		filteredComboKeys := {}

		; Remove comments. `[^\n\r]` is used since the dot matches newlines, even though it
		; shouldn't. Weird.
		comboKeys := RegExReplace(comboKeys, "[ \t];[^\n\r]*", "")

		; This parsing loop splits on whitespace.
		Loop parse, comboKeys, %A_Space%%A_Tab%`n, `r
		{
			comboKey := A_LoopField

			; Take care of several spaces in a row, as well as leading and trailing spaces. The user
			; does not need to worry about perfect formatting of the comboKeys setting.
			if (comboKey == "") {
				continue
			}

			; Support remappings. Unfortunately, this seems to be the only way. If the user has
			; remapped keys they need to move those into the comboKeys setting.
			doubleColonPos := InStr(comboKey, "::")
			if (doubleColonPos) {
				remappingPair := comboKey
				theTwoColons := 2
				comboKey := SubStr(remappingPair, 1, doubleColonPos - 1)
				remapKey := SubStr(remappingPair, doubleColonPos + theTwoColons)
				this.comboKeyRemappings[comboKey] := remapKey
			}

			; A dual-role key cannot be a comboKey at the same time (dual-role keys do the same
			; thing as comboKeys automatically), so skip them. Again, this is convenient for the
			; user, who doesn't need to change the comboKeys setting each time he or she added a new
			; dual-role key that already was a comboKey.
			if (not this.keys[comboKey]) {
				; Duplicates are also filtered out, as yet a convenience.
				filteredComboKeys[comboKey] := true ; Property lookup is case insensitive. Perfect!
			}
		}

		return filteredComboKeys
	}

	; Note that a key might mean a combination of many keys, however it is referred to as if it was
	; only one key, to simplify things. Sometimes, though, a key is referred to as a set of subKeys.
	class Key {
		__New(key) {
			; As mentioned above, a key might mean a combination of many keys. Therefore, `key` is
			; an array. However, mostly a single key will be used, so a bare string is also
			; accepted. If so, wrap it in an array.
			if (not IsObject(key)) {
				key := [key]
			}
			this.key := key
		}

		isDown := false
		subKeysDown := {}
		down() {
			if (this.isDown == false) { ; Don't update any of this on OS simulated repeats.
				this.isDown := true
				this._timeDown := A_TickCount
			}
			for index, key in this.key { ; (*)
				; Let's say you've made j also a shift key. Pressing j would then cause the
				; following: shift down, shift up, j down+up. Now let's say you hold down one of the
				; regular shift keys and then press j. That should result in a J, right? Yes, but it
				; doesn't, since the j-press also sent a shift up. So if an identical subKey is
				; already pressed, don't send it. That will also prevent the `up()` method from
				; sending it up.
				;
				; Remember that the OS repeats keys held down. So if a subKey is already marked as
				; down, we must send it again. Likewise, we must check every time if an identical
				; subKey is already pressed. The first time one might have been, but the second it
				; might not. The user can release it while holding the dual-role key.
				if (this.subKeysDown[key] or not GetKeyState(key)) {
					this.subKeysDown[key] := true
					SendInput {Blind}{%key% down}
				}
			}
		}

		up() {
			this.isDown := false
			this._timeDown := false
			this._lastUpTime := A_TickCount
			for index, key in this.key { ; (*)
				; Only send the subKey up if it was down. It might not have been sent down, due to
				; that another identical key was already down by then. Or, `up()` might already have
				; been called.
				if (this.subKeysDown[key]) {
					SendInput {Blind}{%key% up}
				}
			}
			this.subKeysDown := {}
		}

		send() {
			this._lastUpTime := A_TickCount
			for index, key in this.key { ; (*)
				SendInput {Blind}{%key%}
			}
		}

		; (*) The `down()`, `up()` and `send()` methods sends input in a loop, since a key might be
		; a combination of keys, as mentioned before.

		_timeDown := false
		timeDown() {
			if (this._timeDown == false) {
				return false
			} else {
				return A_TickCount - this._timeDown
			}
		}

		_lastUpTime := false
		timeSinceLastUp() {
			if (this._lastUpTime == false) {
				return false
			} else {
				return A_TickCount - this._lastUpTime
			}
		}
	}

	getKeysFor(originalKey) {
		; `A_ThisHotkey` is supposed to be sent in, which needs cleaning. See `cleanKey()`.
		originalKey := this.cleanKey(originalKey)
		keys := this.keys[originalKey]
		return keys
	}

	; Cleans keys coming from `A_ThisHotkey`, which might look like `*j UP`.
	cleanKey(key) {
		return RegExReplace(key, "i)^[#!^+<>*~$]+| up$", "")
	}

	; Run by comboKeys, and the dual-role keys, since they do the same thing as comboKeys
	; automatically.
	combo() {
		for originalKey, keys in this.keys {
			upKey := keys.upKey
			downKey := keys.downKey
			if (downKey.isDown) {
				if (downKey.timeDown() < this.delay) {
					downKey.up()
					upKey.send()
					upKey.alreadySend := true
				} else {
					downKey.combo := true
				}
			}
		}
	}
}

; Overwrite the class with a new instance of it, since it is only supposed to be instantiated once.
; The labels below need an instance to work with. Moreover, the user does not need to instantiate
; it themselves, which means less boilerplate.
Dual := new Dual

; Skip past label declarations. `return` cannot be used since this file is supposed to be included.
Goto Dual_end

Dual_keydown:
	keys := Dual.getKeysFor(A_ThisHotkey)
	upKey := keys.upKey
	downKey := keys.downKey

	timeSinceLastUp := upKey.timeSinceLastUp()
	if (timeSinceLastUp != false
		and timeSinceLastUp < Dual.doublePress ; (*1)
		and (Dual.cleanKey(A_PriorHotkey) == Dual.cleanKey(A_ThisHotkey))) { ; (*2)
		upKey.repeatMode := true
		upKey.alreadySend := true
	}
	; (*) The first line checks if a second press was quick enough to be a double-press. However,
	; another key might have been pressed in between, such as when writing "bob" (if b is a
	; dual-role key). The second line tries to work around that. It is not perfect though. As
	; usual, it only works with the comboKeys.

	if (upKey.repeatMode) {
		upKey.send()
		return
	}

	downKey.down()

	return

Dual_keyup:
	keys := Dual.getKeysFor(A_ThisHotkey)
	upKey := keys.upKey
	downKey := keys.downKey

	downKeyTimeDown := downKey.timeDown() ; `downKey.up()` below resets it; better do it before!

	downKey.up()

	if (not downKey.combo
		and (downKeyTimeDown < Dual.timeout or Dual.timeout == 0)
		and not upKey.alreadySend) {
		Dual.combo() ; Dual-role keys are automatically comboKeys.
		upKey.send()
	}

	downKey.combo := false
	upKey.alreadySend := false
	upKey.repeatMode := false

	return

Dual_comboKey:
	Dual.combo()

	key := Dual.cleanKey(A_ThisHotkey)
	if (Dual.comboKeyRemappings[key]) {
		key := Dual.comboKeyRemappings[key]
	}
	SendInput {Blind}{%key%}

	return

Dual_end:
