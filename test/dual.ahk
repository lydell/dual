#Include setup.ahk

dual1 := new Dual

test(defaults)

class defaults {
	Begin() {
		Dual.sentKeys := []
	}

	tap() {
		SendEvent a
		assert(sent("a")*)
	}
	long_tap() {
		SendEvent {a down}
		Sleep 290
		SendEvent {a up}
		assert(sent("a")*)
	}
	timeout() {
		SendEvent {a down}
		Sleep 510
		SendEvent {a up}
		assert(sent("LShift")*)
	}
	no_repetition() {
		SendEvent {a down}
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 20
		SendEvent {a down}
		SendEvent {a up}
		assert(sent("a")*)
	}
	doublePress_repetition() {
		SendEvent a
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a up}
		Sleep 10
		assert(sent("a", "a", "a", "a", "a")*)
	}
	not_doublePress() {
		SendEvent a
		Sleep 200
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a down}
		Sleep 10
		SendEvent {a up}
		Sleep 10
		assert(sent("a", "a")*)
	}
}

*a::
*a UP::dual1.combine("LShift", A_ThisHotkey)
