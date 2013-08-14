Overview
========

Dual is an [AutoHotkey] script that lets you define [dual-role modifier keys][wikipedia-dual-role]
easily. For example, combine the space bar and shift keys. It is heavily inspired by [BigCtrl].

Dual is not just another script you download, auto-run and forget. It is a tool you include and use,
perhaps in an already existing remapping script.

It is currently quite stable and feature complete, but needs more testing.

[AutoHotkey]: http://www.autohotkey.com/
[wikipedia-dual-role]: http://en.wikipedia.org/wiki/Modifier_key#Dual-role_keys
[BigCtrl]: https://github.com/benhansenslc/BigCtrl



Usage
=====

The best thing is to put a copy of the files in a directory next to the AutoHotkey file you wish to
use it with. Either download it manually, clone with git (`git clone
https://github.com/lydell/dual.git`) or, preferably, add it as a submodule (`git submodule add
https://github.com/lydell/dual.git`).

Then include the script into an AutoHotkey file of choice. That exposes the `Dual` class, which is
used for configuration and setting up your dual-role keys.

    #Include dual/dual.ahk
    dual := new Dual

    ; Configure a setting.
    dual.timeout := 400

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

You can use [sample.ahk](sample.ahk) as a starting point.



Pros & Cons
===========

Why use this? Well, to get more characters onto your keyboard. Why can you press for example shift
by itself, and it produces nothing? Let it do something instead!

You can also use Dual to put modifier keys in more convenient places, like on the home row. I'm
currently experimenting with that myself.

The bad part is that the upKey has to be, of course, sent when the key is _released_ (on keyup),
instead of immediately when it is pressed down (on keydown), which might feel a bit laggy. That is a
bigger problem for character keys, than for modifier keys; Making the shift buttons also produce
parenthesis won't be noticed as laggy, but putting modifiers on the home row might, since (when
using the QWERTY layout) asdfjkl; will appear on keyup, unlike the rest of the characters. It's up
to you to weight to benefits against the pitfalls.

Also see [Limitations](#limitations).



API
===

Note that all properties and methods that accepts keys expects keys from the [key list].

The `Dual` class takes no parameters.

    dual := new Dual

Throughout the rest of the documentation, `dual` is assumed to be an instance of the `Dual` class.

[key list]: http://www.autohotkey.com/docs/KeyList.htm

`dual.combine(downKey, upKey, settings=false)`
------------------------------

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

You may optionally pass a settings object to set the same options as described under
[Configuration](#configuration), but at key-level:

    *r::
    *r UP::dual.combine("LWin", A_ThisHotkey, {delay: 100})

An older version of Dual provided a method called `set()` instead of `combine()`, which set up the
keys for you, using the `Hotkey` command. That was perhaps a bit more convenient (you didn't have to
write the key name twice for instance), but caused problems with other hotkeys.

`dual.comboKey(remappingKey="")`
--------------------------------

The method is supposed to be called as such:

    *KeyName::dual.comboKey()

That turns the key into a [_comboKey_](#combokeys). It basically means that the key sends
information to the dual-role keys when pressed, and then sends itself—so you won't even notice that
a comboKey is comboKey.

If you want a key to both to be a comboKey and remap it, pass the key you want to remap it to as a
parameter. For example, if you previously swapped the following keys like so …

    a::b
    b::c
    c::a

… you need to change them into this:

    *a::dual.comboKey("b")
    *b::dual.comboKey("c")
    *c::dual.comboKey("a")

An older version of Dual provided a setting called `Dual.comboKeys` instead of this method, which
set up the comboKeys for you, using the `Hotkey` command. That is not possible anymore, because it
depended on the `set()` method which also doesn't exist anymore (see the `combine()` method above).
This way is also more reliable.

`dual.combo()`
--------------

Let's you make a key into a comboKey without sending the key itself, like the `comboKey()` method
does.

    9::
        dual.combo()
        SendInput (){Left}
        return

In fact, the `comboKey()` method (called without parameter) is roughly equivalent to:

    dual.combo()
    SendInput {Blind}%A_ThisHotkey%

`dual.Send(string)`
-------------------

`dual.Send()` works exactly like the `Send` command, except that it temporarily releases any dual-
role keys that are down for the moment first. There is also `dual.SendInput()`, `dual.SendEvent()`,
`dual.SendPlay()` and `dual.SendRaw()`. See [Limitations](#limitations) for usage of this method.



Configuration
=============

While dual-role keys might sound trivial to implement, there are some pretty complicated details to
work with. Only _using_ dual-role keys is really easy.

_comboKeys_
-----------

What happens in essence when you press a dual-role key, is the following:

You press the dual-role key down. That causes {downKey down} to be sent. You hold the dual-role key
for a while. During that time you might press other keys, which then might be modified, if your
downKey is a modifier. You release the dual-role key. That causes {downKey up} to be sent, as well
as {upKey}.

That achieves what we're after, right? The dual-role key is a modifier (the downKey) when held, and
a character (the upKey) when released! Well, yes but also no. It isn't perfect.

The biggest problem is that if you combine the downKey with another key, you don't want the upKey to
be sent when releasing the dual-role key. For example, if you have combined space and shift, and you
have pressed space+f, you'd expect an F, but in reality you get an F followed by a space. So the
script needs a way of knowing if you have combined a dual-role key with some other key.

That is solved by what I call **"comboKeys."** A comboKey is a key that you have assigned a hotkey
to that runs the `comboKey()` method, which checks if any of the dual-role keys are down. If so, it
tells the dual-role keys in question that they have been combined. The comboKey then sends itself,
so you won't even notice that it is a hotkey. Perfect, problem solved—the dual-role keys now know if
they have been combined, and can therefore skip sending the upKey when released. Note that the dual-
role keys are automatically combo keys. You should not add extra hotkeys to them to run the
`comboKey()` method fact that results in a "duplicate hotkey" error in AutoHotkey.

_timeout_
---------

But, wait! Does the above mean that the downKey only can be combined with a specific set of keys—the
comboKeys? That kinda sucks! Well, yes it does. Fortunately, there is a way to deal with this, so
that the downKey can be combined with _any_ key (however a little bit more limited than with the
comboKeys—why bother with comboKeys at all otherwise?). Phew!

Let me introduce the **"timeout"**. When the dual-role key has been held longer than the timeout,
the upKey won't be sent. When you think about, don't you always hold modifier keys longer than you
press character keys? So if you want to combine a downKey with a non-comboKey, just make sure that
you hold down the dual-role key longer than the timeout (which you probably do anyway). The timeout
can be set via the `timeout` property.

According to the above paragraph, if you combine a dual-role key with some other, non-comboKey
within the timeout, that would result in both the combination _and_ the upKey. Right, I've already
said that. However, that is not true. In reality, _only_ the upKey will be sent.

The timeout actually takes care of one more thing.

In the beginning of this section, I said that the first thing that happens when you press down a
dual-role key is that {downKey down} is sent. That is actually not true. {downKey down} is not sent
until the timeout has passed. That's why only the upKey is sent, and the combination does not occur,
as described above. But why?

As mentioned under [Pros & Cons](#pros--cons), what makes it possible to combine a modifier key with
another key is that the modifier only does something when held down. However, that is not true for
_all_ modifiers. Take the Windows key for example. When released it opens the start menu (in fact,
it is already a dual-role modifier key; a combination of a special modifier and an "open the start
menu" key). Or the alt keys, which might show a hidden menu bar when released.

Alright, what about those modifiers? Well, if you try to use them in dual-role keys, you will get
trouble. For example, if you have combined the "w" and Windows keys, and you tap "w", you'd expect a
"w", but instead the start menu is opened, and a "w" is typed in its search box. Ouch.

That's why the downKey isn't sent down during the timeout. By doing so, {downKey up} is not sent if
the dual-role key is released before the timeout has passed, and therefore does not interfere. Now
you can type "w" again. If you wish to open the start menu, you have to hold the "w" key for longer
than the timeout.

But, wait again! So the dual-role key is not a modifier when held down until the timeout has passed?
What about combinations with the comboKeys? The whole point of them was not having to hold the dual-
role keys for longer than the timeout, right? Don't worry, the comboKeys force {downKey down} if the
timeout hasn't passed. Yet a reason for comboKeys!

The timeout also has yet another positive effect: If you ever change your mind half-way through a
keyboard shortcut—that is, when holding a modifier down—you can just release it without worrying
about having to clean up the upKey that was just sent.

_delay_
-------

Now, let's leave the timeout and move on. When typing quickly, sometimes you might press down
several keys simultaneously for a short period of time. If one of them is a dual-role key, you're in
trouble. For example, let's say you've combined the space and shift keys, and you want to type
"Hello world!". If you type this really quickly, so that the space bar happens to be down when you
type "w", the result would be "HelloWorld!".

The solution to this problem lies in its description. "Sometimes you might press down several keys
simultaneously for a _short period of time._" Thus, let me introduce the **"delay."** It is in
relationship with the comboKeys. Now, the comboKeys have one more check to do. As before, they check
if any dual-role keys are down. If so, they check how long time have elapsed since they were pressed
down. If that time is shorter than the delay, the downKey of the dual-role key in question is
released and its upKey sent instead. Otherwise the dual-role key is told that it has been combined
with another key, just as before. Again, the dual-role keys _work_ with any key combination. But
common keys better be set as comboKeys to reduce mistakes. The delay can be set via the `delay`
property.

_doublePress_
-------------

Lastly, we've got the **"doublePress."** Usually, keys repeat when being held down (if your OS does
so). However, a dual-role key repeats its downKey when held, not the upKey. For example, if you've
combined the space and shift keys, holding down the space bar won't produce a serious of spaces,
perhaps used as indentation. What now?

For this issue, a doublePress is used. Press the dual-role key, release it and press it again,
within the doublePress time. The doublePress time can be set via the `doublePress` property. If you
continue to hold the dual-role key, the upKey will be repeated.

Now, the comboKeys come in handy yet a time. If you type "bob" really quickly, and "b" is a dual-
role key, and you keep holding "b" the last time, "b" will actually start to repeat, even though
another key was pressed in-between the two "b" presses. That's not really a double press, right?
However, if "o" is a comboKey, that won't happen.

Summary and defaults
--------------------

Phew! That was a lot to take in. But it's not that complicated when you actually use the dual-role
keys. It's just handy to know while tweaking the settings, so you never have to be bothered again.
Now, time for some recap and examples. The default values are also shown below.

    dual.timeout     := 300
    dual.delay       := 70
    dual.doublePress := 200

`dual.delay` is the number of milliseconds that you must hold a dual-role key in order for it to
count as a combination with another key (comboKeys only, though).

`dual.timeout` is the number of milliseconds after which the downKey starts to be sent, and the
upKey won't be sent.

`dual.doublePress` is the maximum number of milliseconds that can elapse between a release of a
dual-role key and its next press and still be called a doublePress.

_comboKeys_ are keys that enhance the accuracy of the dual-role keys. They can be set as such:

    *a::
    *a UP::dual.comboKey()

See [sample.ahk](sample.ahk) for a starting point.

Also note that the settings can be set per dual-role key. See the `combine()` method. This let's you
fine-tune specific keys. After all, our fingers and the possible key combinations of the keyboard
are all different.

To test the timeout and delay, I recommend setting both of them to long times, for example 3 seconds
and 1 second, respectively. Play with it and you'll quickly get the hang of it. Then tweak the
values so that you never ever have to think about them again.



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
`dual.SendPlay()` and `dual.SendRaw()`. Simply prepend your Send* commands with "dual.".



Tests
=====

Dual will hopefully be tested in the future, perhaps using [YUnit].

[YUnit]: https://github.com/Uberi/Yunit



Changelog
=========

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

[MIT Licensed](LICENSE)
