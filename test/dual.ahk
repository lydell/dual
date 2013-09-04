#Include setup.ahk

dual1 := new Dual

test(test_Dual)

class test_Dual {
    Before() {
		Dual.sentKeys := [] ; Intentionally global.
    }

    test() {
    	SendEvent ff
        assert(sent("f", "f")*)
    }
}

*f::
*f UP::dual1.combine("LShift", A_ThisHotkey)
