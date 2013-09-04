class Dual {
	;;; Settings.
	; They are described in detail in the readme. Remember to mirror the defaults there.

	timeout     := 300
	delay       := 70
	doublePress := 200


	;;; Public methods.
	; They are described in the readme. Remember to mirror the function headers there.

	keys := {}
	combine(downKey, upKey, settings=false) {
		currentKey := A_ThisHotkey

		cleanKey := Dual.cleanKey(currentKey)
		if (this.keys[cleanKey]) {
			keys := this.keys[cleanKey]
		} else {
			keys := {downKey: new this.Key(downKey), upKey: new this.Key(upKey)}
			keys.timeout     := this.timeout
			keys.delay       := this.delay
			keys.doublePress := this.doublePress
			for setting, value in settings {
				keys[setting] := value
			}
			this.keys[cleanKey] := keys
		}

		; A single `=` means case insensitive comparison. `-1` means the last two characters.
		if (SubStr(currentKey, -1) = "UP") {
			this.keyup(keys)
		} else {
			this.keydown(keys)
		}
	}

	comboKey(remappingKey="") {
		this.combo()

		if (remappingKey == "") {
			key := Dual.cleanKey(A_ThisHotkey)
		} else {
			key := remappingKey
		}
		Dual.sendInternal(key)
	}

	; `justReleasedDownKeyTimeDown` is not documented in the readme, since it is only used internally.
	combo(justReleasedDownKeyTimeDown=-1) {
		shorterTimeDownKeys := []
		for originalKey, keys in this.keys {
			upKey := keys.upKey
			downKey := keys.downKey
			if (downKey.isDown) {
				downKeyTimeDown := downKey.timeDown()
				withinDelay := (downKeyTimeDown < keys.delay)
				if (downKeyTimeDown < justReleasedDownKeyTimeDown) {
					; Let's say you've combined f with shift and d with control. You press down f,
					; and then d, as to use a shift-control shortcut. However, you change your mind:
					; You want to to use just a control shortcut. So you release f. Even if the
					; timout has not passed, we do not want the upKey of f to be sent now, causing
					; control-f in effect (you still hold down d). That would be weird: It's like
					; you've pressed the shortcut backwards, f-control, and it still works! So if
					; there is at least one other dual-role key that has been down for a shorter
					; period of time than a just released dual-role key, return `false` to indicate
					; that the upKey of the just released dual-role key shouldn't be sent.
					if (not withinDelay) {
						; However, notice the `not withinDelay` check above. When you released f
						; above, what if the delay of d hasn't passed yet? That means that you
						; likely wanted to type fd, and typed that very quickly. You pressed down f,
						; and before even releasing f you pressed d, which means that f was released
						; while d was down. That usually means either control-f, or, if the delay
						; hasn't passed, df. Therefore, in that case, we should _not_ return
						; `false`. We _want_ the upKey of the just released dual-role to be sent.
						return false
					}
					; Instead, we collect the keys of the dual-role key that has been down for a
					; shorter period of time than the just released dual-role key (d in the above
					; example). These will be returned later on, so that they can be sent _after_
					; the upKey of the just released dual-role key (f in the above example), which
					; finally sends fd as we wanted.
					shorterTimeDownKeys.Insert(keys)
				} else if (withinDelay) {
					this.abortDualRole(keys)
				} else {
					downKey.down(true) ; Force it down, no matter what.
					downKey.combo := true
				}
			}
		}
		return shorterTimeDownKeys
	}

	SendInput(string) {
		this.SendAny(string, "input")
	}
	SendEvent(string) {
		this.SendAny(string, "event")
	}
	SendPlay(string) {
		this.SendAny(string, "play")
	}
	SendRaw(string) {
		this.SendAny(string, "raw")
	}
	Send(string) {
		this.SendAny(string, "")
	}


	;;; Private.

	SendAny(string, mode="") {
		blind := (InStr(string, "{Blind}") == 1) ; Case insensitive. Perfect!
		temporarilyReleasedKeys := []
		if (not blind) {
			for originalKey, keys in this.keys {
				downKey := keys.downKey
				if (downKey.isDown) {
					downKey.up(true) ; Only send the key strokes; Don't reset times and such-like.
					temporarilyReleasedKeys.Insert(downKey)
				}
			}
		}

		if (mode == "input") {
			SendInput % string
		} else if (mode == "event") {
			SendEvent % string
		} else if (mode == "play") {
			SendPlay % string
		} else if (mode == "raw") {
			SendRaw % string
		} else {
			Send % string
		}

		for index, downKey in temporarilyReleasedKeys {
			downKey.down()
		}
	}

	; Releases a dual-role key that is held down, and sends its upKey, so that it behaves as if it
	; was a normal key. In other words, its dual nature is aborted.
	abortDualRole(keys) {
		downKey := keys.downKey
		upKey := keys.upKey
		downKey.up()
		upKey.send()
		upKey.alreadySend := true
	}

	; Note that a key might mean a combination of many keys, however it is referred to as if it was
	; only one key, to simplify things. Sometimes, though, a key is referred to as a set of subKeys.
	class Key {
		__New(key) {
			; As mentioned above, a key might mean a combination of many keys. Therefore, `key` is
			; an array. However, mostly a single key will be used so a bare string is also accepted.
			if (not IsObject(key)) {
				key := [key]
			}

			; Support subKeys coming from `A_ThisHotkey`.
			for index, subKey in key {
				key[index] := Dual.cleanKey(subKey)
			}

			this.key := key
		}

		isDown := false
		subKeysDown := {}
		down(sendActualKeyStrokes=true) {
			if (this.isDown == false) { ; Don't update any of this on OS simulated repeats.
				this.isDown := true
				this._timeDown := A_TickCount
			}

			; In order to support modifiers that do something when released, such as the alt and
			; Windows keys, it is possible to skip the for loop below, which sends the actual key
			; strokes.
			if (not sendActualKeyStrokes) {
				return
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
				; might not: The user can release it while holding the dual-role key.
				if (this.subKeysDown[key] or not GetKeyState(key)) {
					this.subKeysDown[key] := true
					Dual.sendInternal(key " down")
				}
			}
		}

		up(sendOnly=false) {
			if (not sendOnly) {
				this.isDown := false
				this._timeDown := false
				this._lastUpTime := A_TickCount
			}
			for index, key in this.key { ; (*)
				; Only send the subKey up if it was down. It might not have been sent down, due to
				; that another identical key was already down by then. Or, `up()` might already have
				; been called.
				if (this.subKeysDown[key]) {
					Dual.sendInternal(key " up")
				}
			}
			this.subKeysDown := {}
		}

		send() {
			this._lastUpTime := A_TickCount
			for index, key in this.key { ; (*)
				Dual.sendInternal(key)
			}
		}

		; (*) The `down()`, `up()` and `send()` methods send input in a loop, since a key might be
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

	keydown(keys) {
		upKey := keys.upKey
		downKey := keys.downKey

		timeSinceLastUp := upKey.timeSinceLastUp()
		if (timeSinceLastUp != false
			and timeSinceLastUp <= keys.doublePress ; (*1)
			and Dual.cleanKey(A_PriorHotkey) == Dual.cleanKey(A_ThisHotkey)) { ; (*2)
			upKey.repeatMode  := true
			upKey.alreadySend := true
		}
		; (*) The first line checks if a second press was quick enough to be a double-press.
		; However, another key might have been pressed in between, such as when writing "bob" (if b
		; is a dual-role key). The second line tries to work around that. It is not perfect though.
		; As usual, it only works with the comboKeys.

		if (upKey.repeatMode) {
			upKey.send()
			return
		}

		; Only send the actual key strokes if the timeout has passed, in order to support modifiers
		; that do something when released, such as the alt and Windows keys. The comboKeys will
		; force the downKey down, if they are combined before the timeout has passed.
		downKey.down(downKey.timeDown() >= keys.timeout)
	}

	keyup(keys) {
		upKey := keys.upKey
		downKey := keys.downKey

		downKeyTimeDown := downKey.timeDown() ; `downKey.up()` below resets it; better do it before!

		downKey.up()

		; Determine if the upKey should be sent.
		if (not downKey.combo
			and (downKeyTimeDown < keys.timeout or keys.timeout == 0)
			and not upKey.alreadySend) {
			; Dual-role keys are automatically comboKeys.
			shorterTimeDownKeys := this.combo(downKeyTimeDown)
			; At this point, the upKey should be sent, mostly. However, there is one exception,
			; explained in `combo()`.
			if (shorterTimeDownKeys != false) { ; The exception referred to above.
				upKey.send()
				; The call of `combo()` above might call `abortDualRole()` for some other dual-role
				; keys, before the upKey was sent in the line above. However, sometimes that needs
				; to been done _after_ the upKey was sent. See `combo()` for an explaination.
				for index, keys in shorterTimeDownKeys {
					this.abortDualRole(keys)
				}
			}
		}

		downKey.combo     := false
		upKey.alreadySend := false
		upKey.repeatMode  := false
	}


	;;; Utilities
	; Call via `Dual.<method>`.

	; Cleans keys coming from `A_ThisHotkey`, which might look like `*j UP`.
	cleanKey(key) {
		return RegExReplace(key, "i)^[#!^+<>*~$]+| up$", "")
	}

	static sentKeys
	sendInternal(string) {
		if (this.sentKeys) {
			this.sentKeys.Insert(string)
			; MsgBox added!
		} else {
			SendInput {Blind}{%string%}
		}
	}
}
