#SingleInstance force
#Include %A_ScriptDir%

#Include Yunit/Yunit.ahk
#Include Yunit/Window.ahk

#Include ../dual.ahk

assert(args*) {
	Yunit.Assert(args*)
}

sent(keys*) {
	waitForKeys()
	message := "Expected: [" . join(keys) . "]. Actual: [" . join(Dual.sentKeys) . "]."
	for index, key in keys {
		if (Dual.sentKeys[index] != key) {
			return [false, message]
		}
	}
	return [true]
}

waitForKeys() {
	Sleep 30
}

join(array, separator=",") {
	string := ""
	for index, key in array {
		string .= key . separator
	}
	return SubStr(string, 1, -StrLen(separator))
}

SendLevel 1
SetKeyDelay -1

tests := []
test(aTests*) {
	global tests
	tests := aTests
	SetTimer test, -0
}

Hotkey, F4, exit

Goto end

test:
	Yunit.Use(YunitWindow).Test(tests*)
	return

exit:
	ExitApp
	return

end:
