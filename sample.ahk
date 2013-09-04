SendMode Input
#NoEnv
#SingleInstance force


#Include dual.ahk
dual := new Dual


;;; dual-role keys

*Space::
*Space UP::dual.combine("RCtrl", A_ThisHotkey)


;;; comboKeys

*a::
*b::
*c::
*d::
*e::
*f::
*g::
*h::
*i::
*j::
*k::
*l::
*m::
*n::
*o::
*p::
*q::
*r::
*s::
*t::
*u::
*v::
*w::
*x::
*y::
*z::
*0::
*1::
*2::
*3::
*4::
*5::
*6::
*7::
*8::
*9::
*.::
*,::
*`;::
*`::
*'::
*/::
*\::
*[::
*]::
*-::
*=::
*Up::
*Down::
*Left::
*Right::
*Home::
*End::
*PgUp::
*PgDn::
*Insert::
*Delete::
*Backspace::
; *Space:: ; Commented out since space is set as a dual-role key above.
*Enter::
*Tab::
*F1::
*F2::
*F3::
*F4::
*F5::
*F6::
*F7::
*F8::
*F9::
*F10::
*F11::
*F12::
	dual.comboKey()
	return
