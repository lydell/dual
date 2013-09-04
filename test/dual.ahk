#Include setup.ahk

test(test_Dual)

class test_Dual {
    Before() {
		Dual.sentKeys := [] ; Intentionally global.
    }

    test() {
    	SendEvent ff
        assert(sent("f", "r")*)
    }
}

*f::
*f UP::dual.combine("LShift", A_ThisHotkey)
