Overview
========

Dual is an [AutoHotkey] script that lets you define [dual-role modifier keys][wikipedia-dual-role]
easily. For example, combine the space bar and shift keys. It is heavily inspired by [BigCtrl].

Dual is not just another script you download, auto-run and forget. It is a tool you include and use,
perhaps in an already existing remapping script.

It is currently quite stable and feature complete, but needs more testing. However, until version
1.0.0 is released, the API might (and has) change in backwards incompatible ways without warning.



Usage
=====

The best thing is to put a copy of the files in the library folder of the AutoHotkey file you wish
to use it with (a folder called "Lib" next to your file). Either download it manually, clone with
git (`git clone https://github.com/lydell/dual.git Lib/dual`) or, preferably, add it as a submodule
(`git submodule add https://github.com/lydell/dual.git Lib/dual`).

Then include the script into the AutoHotkey file you chose. That exposes the `Dual` class, which is
used for configuration and setting up your dual-role keys.

    #Include <dual/dual>
    dual := new Dual

    ; Steve Losh shift buttons.
    *LShift::
    *LShift UP::dual.combine(A_ThisHotkey, "(")
    *RShift::
    *RShift UP::dual.combine(A_ThisHotkey, ")")

    ; BigCtrl-like.
    *Space::
    *Space UP::dual.combine("RCtrl", A_ThisHotkey)

    ; Colemak rebinding and Windows key combination.
    *j::
    *j UP::dual.combine("RWin", "n")

You can use [sample.ahk] as a starting point. It works out of the box—just run it!



Pros & Cons
===========

Why use this? Well, to get more characters onto your keyboard. Why can you press for example shift
by itself, and it produces nothing? Let it do something instead!

You can also use Dual to put modifier keys in more convenient places, like on the home row (which I
do).

Normally, all keys send their characters when pressed down. Dual-role keys, on the other hand, sends
their characters when the key is _released_, since they act as modifiers when pressed down. This
might feel a bit laggy. If you make the shift buttons also produce parenthesis, you probably won't
notice it, because you are not used to that the shift keys actually do something when pressed on
their own. But if you put modifiers on the home row you probably will, since this time you _are_
used to seeing the characters pop up immediately on the screen. Moreover, the characters of the
other rows still do, so you will constantly _see_ the difference too, not just remember it.

As I said, I put the modifiers on the home row. My first reaction was: "Ugh, that looks terrible!",
since the home row characters appeared on the screen slower than before. It felt like typing in the
terminal with a somewhat bad ssh connection. Initially that slowed me down. After a while, though, I
learned to ignore the lag, just typing on like before. After yet a while, I didn't think much about
it any longer. So, for me, having the modifiers in really convenient spots is definitely worth the
lag.

Everyone might not stand the lag, though. If so, simply don't make any character keys into dual-role
keys. I can still recommend making the modifier keys and space bar into dual-role keys to anyone.

Also see [Limitations].



API
===

Note that all methods that accepts keys expect keys from the [key list].

The `Dual` class takes an optional settings object as parameter. See [Configuration] for the
available settings.

    dual := new Dual ; Use default settings.
    dual := new Dual({settingName: value}) ; Override some default setting.

Throughout the rest of the documentation, `dual` is assumed to be an instance of the `Dual` class.

`dual.combine(downKey, upKey, settings=false)`
----------------------------------------------

In a nutshell, a dual-role key sends one key when held down—called the "downKey"—and one when
released—called the "upKey."

The method is supposed to be called as such:

    *KeyName
    *KeyName UP::dual.combine(…)

The upKey and downKey may also be combinations of keys, by passing arrays. For example, you could
make right alt put quotation marks around the cursor when pressed by itself, and a ctrl+shift key
when pressed in combination with some other key:

    *RAlt::
    *RAlt UP::dual.combine(["RCtrl", "RShift"], ["'", "'", "Left"])

For convenience, and to keep your setup DRY, you may pass `A_ThisHotkey`.

You may optionally pass a settings object, just like when instantiating the class (see above), but
at key-level:

    *r::
    *r UP::dual.combine("LWin", A_ThisHotkey, {delay: 100})

Key-level settings have been invaluable for me when experimenting with modifiers on the home row.

An older version of Dual provided a method called `set()` instead of `combine()`, which set up the
keys for you, using the `Hotkey` command. That was perhaps a bit more convenient (you didn't have to
write the key name twice for instance), but caused problems with other hotkeys.

`dual.comboKey(remappingKey=false)`
-----------------------------------

The method is supposed to be called as such:

    *KeyName::dual.comboKey()

That turns the key into a _[comboKey]_. It basically means that the key sends information to the
dual-role keys when pressed, and then sends itself—so you won't even notice that a comboKey is
comboKey.

If you want a key to be a comboKey _and_ remap it, pass the key you want to remap it to as a
parameter. For example, if you previously swapped the following keys like so …

    a::b
    b::c
    c::a

… you could change it like so:

    *a::dual.comboKey("b")
    *b::dual.comboKey("c")
    *c::dual.comboKey("a")

An older version of Dual provided a setting called `Dual.comboKeys` instead of this method, which
set up the comboKeys for you, using the `Hotkey` command. That is not possible anymore, because it
depended on the `set()` method which also doesn't exist anymore (see the `combine()` method above).
This way is also more reliable.

`dual.combo()`
--------------

Let's you make a key into a comboKey without sending the key itself, in contrast to the `comboKey()`
method.

    9::
        dual.combo()
        SendInput (){Left}
        return

In fact, the `comboKey()` method (called without parameter) is roughly equivalent to:

    dual.combo()
    SendInput {Blind}%A_ThisHotkey%

`dual.modifier(remappingKey=false)`
-----------------------------------

The method is supposed to be called as such:

    *ModifierName
    *ModifierName UP::dual.modifier()

Let's say you want to press control+shift+a. You press down shift and then control, but then change
your mind: You only want to press control+a. So you release shift and then press a. No problems.

Now, let's say you had combined d and shift, and used that for the above. When you release d
(shift), and you do that before its timeout has passed, d will be sent, causing control+d!

You can solve this edge case by using the following:

    *LCtrl::
    *LCtrl UP::
    *RCtrl::
    *RCtrl UP::dual.modifier()

You can optionally remap just like the `comboKey()` method.

Note that if _only_ normal modifiers or _only_ dual-role keys are involved, this issue can never
occur.

This method also fixes another edge case. I don't think it's very useful, but it's there for
consistency. If you hold down for example d and then press a modifier, d will be sent, and it won't
start/continue to repeat. However, if d is a dual-role key, d would be modified. For example, if the
modifier in question is shift, D would be sent. That's like doing it backwards, d+shift, and it
still works! `dual.modifier()` takes care of this too.

Implementation note: This method actually turns things into dual-role keys with the same downKey and
upKey! The above example is actually equivalent to:

    *LCtrl::
    *LCtrl UP::
    *RCtrl::
    *RCtrl UP::dual.combine(A_ThisHotkey, A_ThisHotkey, {delay: 0, timeout: 0, doublePress: -1})

`dual.Send(string)`
-------------------

`dual.Send()` works exactly like the `Send` command, except that it temporarily releases any dual-
role keys that are down for the moment first. There are also `dual.SendInput()`, `dual.SendEvent()`,
`dual.SendPlay()` and `dual.SendRaw()`. See [Limitations] for usage of this method.

`dual.reset()`
--------------

I strongly recommend that you create a non modifier shortcut that calls this function. Why? Because
in some programs, such as [KeePass] when entering a password in its secure screen, or an elevated
command prompt, AutoHotkey does not work at all. I guess it's a security thing. This can cause your
dual-role keys to be stuck down, which, in the worst case, requires a reboot.

For example: KeePass has a global shortcut to open its window: ctrl-alt-k. If you type that shortcut
using dual-role keys, and your currently open KeePass password database happens to be locked, that
will bring up the KeePass dialog to enter your password for the database, as expected. However, that
will also block AutoHotkey—before you have had time to release your dual-role keys! They will now be
stuck down, which will make it next to impossible to type anything, or actually use your keyboard at
all. Usually, it is enough to turn off the AutoHotkey script, and then press each modifier once. But
in this case, the only solution I've found is to reboot the computer.

That's where `dual.reset()` comes into the picture. It resets all dual-role keys, and sends
{modifier up} for each modifier (shift, ctrl, alt and win—left and right). I recommend binding that
to some key—regardless of which modifiers are down—so that you can press that key if some modifier
is stuck, saving a reboot. Example:

    ; Note the `*`! It allows you to press ScrollLock even if a modifier is stuck.
    *ScrollLock::dual.reset()

I wish that this method wasn't necessary, but unfortunately it sometimes is. If a key gets stuck
down, it's a bug. But in the case where AutoHotkey (or any other program) isn't run for security
reasons, I don't think there is anything I can do.

### KeePass work-around ###

If your database is locked, don't use the ctrl-alt-k shortcut. Instead, use win-b to focus the tray
(by the clock), then navigate to the KeePass icon using the arrow keys and finally hit enter.
Perhaps you could automate that with AutoHotkey ;)


Configuration
=============

While dual-role keys might sound trivial to implement, there are some pretty complicated [details]
to work with. Only _using_ dual-role keys is really easy. Here is a summary and the defaults of the
configuration.

    settings := {delay: 70, timeout: 300, doublePress: 200}

`delay` is the number of milliseconds that you must hold a dual-role key in order for it to count as
a combination with another key (comboKeys only, though). Set it to `0` to turn off the feature (of
course).

`timeout` is the number of milliseconds after which the downKey starts to be sent, and the
upKey won't be sent. Set it to `-1` to turn the feature off—to never timeout.

`doublePress` is the maximum number of milliseconds that can elapse between a release of a dual-role
key and its next press and still be called a doublePress. Set it to `-1` to disable doublePress-ing,
and thus repetition.

_comboKeys_ are keys that enhance the accuracy of the dual-role keys. They can be set as such:

    *a::
    *a UP::dual.comboKey()

See [sample.ahk] for a starting point.

Also note that the settings can be set per dual-role key. See the `combine()` method. This let's you
fine-tune specific keys. After all, our fingers and the possible key combinations of the keyboard
are all different.

Tips
----

To test the timeout and delay, I recommend setting both of them to long times, for example 3 seconds
and 1 second, respectively. Play with it and you'll quickly get the hang of it. Then tweak the
values so that you never ever have to think about them again.

Here's a method to find a good delay:

Find a pair of characters on your keyboard that you type really quickly in succession. Combine the
first of those two characters with a modifier M. Make sure that the other character is a comboKey,
and that an action A is triggered when modified by M. Then type words that contain the two
characters in succession. If action B is triggered when typing those words, you need more delay.
Then also try to activate other hotkeys that you actually would like to be triggered. If they don't,
you have too much delay. If you're really unlucky, you can't satisfy both at the same time.

Example: I type "re" very quickly in QWERTY. So I made "e" a dual-role key, combining it with the
Windows key. (I also made sure that "r" is a comboKey.) I then typed words like "h**er**e" and
"th**er**e". When I had too little delay, the Run prompt popped up while typing (`#r` is the default
shortcut for opening it). When I had too much delay, I wasn't able to activate other Windows
shortcuts, such as `#m` (which minimizes all windows), because I typed the shortcut too quickly:
dual thought that I accidentally made a combination. After I while I found a balance.



Limitations
===========

The `&` combiner
----------------

Consider the following example:

    *j::
    *j UP::dual.combine("F12", A_ThisHotkey)

    F12 & d::SendInput 1337

Pressing d while holding down j should produce 1337, right? I wish it did. In reality, the hotkey
isn't triggered at all. Any already existing hotkeys using the `&` combiner could be rewritten like
the following, to be able to be activated by a dual-role key:

    #If GetKeyState("F12")
    d::SendInput 1337
    #If

Which isn't that bad though.

Modifier hotkeys that send
--------------------------

Consider the following example:

    *j::
    *j UP::dual.combine("RShift", A_ThisHotkey)

    +d::Send1337

Pressing d while holding down j should produce 1337, right? I wish it did. In reality, !##& is sent,
just as if `{Blind}` was used. Any already existing hotkeys that involves modifiers and that **send
input** could be rewritten like the following, to send the input as expected:

    +d::dual.Send("1337")

`dual.Send()` works exactly like the `Send` command, except that it temporarily releases any dual-
role keys that are down for the moment first. There is also `dual.SendInput()`, `dual.SendEvent()`,
`dual.SendPlay()` and `dual.SendRaw()`.



Tests
=====

[YUnit] is used for unit testing. To run the tests, simply run [test/dual.ahk]. (However, there are
no meaningful tests yet.)



Changelog
=========

0.4.1 (2013-09-17)
------------------

- Added: The `reset()` method, to deal with modifiers being stuck down.

0.4.0 (2013-09-04)
------------------

- Added: Initial unit testing.
- Changed: The `Dual` constructor now takes an optional settings object as parameter, just like the
  `combine()` method, instead of setting properties on the instance. This is more consistent, nicer
  and encourages changing the settings before setting up dual-role keys. (Backwards incompatible
  change.)
- Improved: Re-factored some code.
- Added: The `modifier()` method.
- Improved: The `timeout` and `doublePress` can be turned off, by setting them to `-1`.

0.3.2 (2013-09-01)
------------------

- Fixed: Dual-role keys typed rapidly in succession were output backwards. For example, you wanted
  to type fd but got df.
- Improved: If you press down a dual-role key, then another, and then release the first, the full
  press of the first dual-role key is always a no-op.
- Both of the above are explained in detail in the source code.

0.3.1 (2013-08-29)
------------------

- Fixed: The comboKeys sometimes failed to force down downKeys. They now force them down much more
  forcefully.

0.3.0 (2013-08-14)
------------------

- Fixed: The dual-role keys now trigger other hotkeys out of the box (except hotkeys using the `&`
  combiner), with no changes to the other hotkeys required. They also work more reliably.
- Improved: Re-implemented the functionality of `Dual.send()` way more robustly.
- Changed: Replaced `Dual.send()` with the `SendInput()`, `SendEvent()`, `SendPlay()`, `SendRaw()`
  and `Send()` methods. (Backwards incompatible change.)
- Replaced the `Dual.set()` with the `combine()` method, in order to fix the above. (Backwards
  incompatible change.)
- Replaced the `comboKeys` setting with the `comboKey()` (and `combo()`) method, because of the
  above. (Backwards incompatible change.)
- Added: Per-key settings.
- Changed: The script now exports the class `Dual` itself, not an instance of the class. (Backwards
  incompatible change.)

0.2.0 (Unreleased)
------------------

- Comments are no longer allowed in the comboKeys setting. It prevented `;` from being used as a
  comboKey, and it is not worth introducing escape rules. (Backwards incompatible change.)

0.1.1 (2013-07-05)
------------------

- Fixed #3: Now {downKey down} won't be sent until the timeout has passed, in order to support the
  alt and Windows modifiers.

0.1.0 (2013-07-04)
------------------

Initial release.



License
=======

[MIT Licensed]



[AutoHotkey]:          http://www.autohotkey.com/
[BigCtrl]:             https://github.com/benhansenslc/BigCtrl
[comboKey]:            details.ahk#combokeys
[Configuration]:       #configuration
[details]:             details.md
[KeePass]:             http://keepass.info/
[key list]:            http://www.autohotkey.com/docs/KeyList.htm
[Limitations]:         #limitations
[MIT Licensed]:        LICENSE
[sample.ahk]:          sample.ahk
[test/dual.ahk]:       test/dual.ahk
[wikipedia-dual-role]: http://en.wikipedia.org/wiki/Modifier_key#Dual-role_keys
[YUnit]:               https://github.com/Uberi/Yunit
