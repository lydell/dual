Overview
========

Dual is an [AutoHotkey] script that lets you define [dual-role modifier keys][wikipedia-dual-role]
easily. For example, combine the space bar and shift keys. It is heavily inspired by [BigCtrl].

Dual is not just another script you download, autorun and forget. It is a tool you include and use,
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

Then include the script into the AutoHotkey file of choice. That exposes the `Dual` object, which is
used for configuration, setting up your dual-role keys and finally launching them. Example:

    #Include dual/dual.ahk

    Dual.comboKeys .= " å ä ö" ; Configuration for Swedish.

    Dual.set("LShift", "(") ; Steve Losh shift buttons.
    Dual.set("RShift", ")")
    Dual.set("Space", _, "RCtrl") ; BigCtrl-like.
    Dual.set("j", "n", "RWin") ; Colemak rebinding and Windows key combination.

    Dual.launch()



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

Also see the [limitations](#limitations).



API
===

The `Dual` object exposes a few configuration properties, the methods mentioned below, the methods
mentioned under [limitations](#limitations), as well as a few other methods and a few labels. While
it is possible to use these extra methods and labels, it is not recommend, since they might change
without warning.

Note that all properties and methods that accepts keys expects keys from the [key list].

[key list]: http://www.autohotkey.com/docs/KeyList.htm

`Dual.set(originalKey, upKey, downKey="")`
------------------------------------------

In a nutshell, a dual-role key sends one key when held down—called the "downKey"—and one when
released—called the "upKey." The key you press on the keyboard is the originalKey.

For convenience, and to keep your setup DRY, you may pass an empty string as the upKey or downKey.
In the example above, this is done by either passing the undefined variable `_` (which, in my
opinion, looks nicer than passing a literal string (`""`), but watch out never to define the
underscore! ;) ), or by omitting the last argument altogether (which has the empty string as default
value). If you pass the empty string, the originalKey will be used for that argument instead. Thus,
the above example is equivalent to:

    Dual.set("LShift", "(", "LShift")
    Dual.set("RShift", ")", "RShift")
    Dual.set("Space", "Space", "RCtrl")
    Dual.set("j", "n", "RWin")

The upKey and downKey may also be combinations of keys, by passing arrays. For example, you could
make right alt put quotation marks around the cursor when pressed by itself, and a ctrl+shift key
when pressed in combination with some other key:

    Dual.set("RAlt", ["'", "'", "Left"], ["RCtrl", "RShift"])

`Dual.launch()`
---------------

Run this method when you're done configuring and setting up dual-role keys. It wires all necessary
hotkeys for you. Just remember that all `Dual`-related stuff, including `Dual.launch()` needs to be
in the [auto-execute section]. While it might tempting to mix rebindings and `Dual.set()`:s, it
won't work!

[auto-execute section]: http://www.autohotkey.com/docs/Scripts.htm#auto



Configuration
=============

While dual-role keys might sound trivial to implement, there are some pretty complicated details to
work with. Only _using_ dual-role keys is really easy.

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

That is solved by what I call **"comboKeys."** All comboKeys get hotkeys assigned to them, which
checks if any of the dual-role keys are down. If so, they tell the dual-role keys in question that
they have been combined. The comboKey then sends itself, so you won't even notice that it is a
hotkey. Perfect, problem solved—the dual-role keys now know if they have been combined, and can
therefore skip sending the upKey when released. The comboKeys can be set via the `Dual.comboKeys`
property. Also, the dual-role keys are automatically combo keys. However, don't worry if they're
also listed in the comboKeys setting—that is taken care of.

But, wait! Does that mean that the downKey only can be combined with a specific set of keys? That
kinda sucks! Well, yes it does. Fortunately, there is a way to deal with this, so that the downKey
can be combined with _any_ key. Phew!

Let me introduce the **"timeout"**. When the dual-role key has been held longer than the timeout,
the upKey won't be sent. When you think about, don't you always hold modifier keys longer than you
press character keys? So if you want to combine a downKey with a non-comboKey, just make sure that
you hold down the dual-role key longer than the timeout (which you probably do anyway). The timeout
can be set via the `Dual.timeout` property.

According to the above paragraph, if you combine a dual-role key with some other, non-comboKey
within the timeout, that would result in both the combination _and_ the upKey. Right, I've already
said that. However, that is not true. In reality, _only_ the upKey will be sent.

The timeout actually takes care of one more thing.

In the beginning of this section, I said that the first thing that happens when you press down a
dual-role key is that {downKey down} is sent. That is actually not true. {downKey down} is not sent
until the timeout has passed. That's why only the upKey is sent, and the combination does not occur,
as described above. But why? Well, here we go:

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

* * *

Now, let's leave the timeout and move on. When typing quickly, sometimes you might press down
several keys simultaneously for a short period of time. If one of them is a dual-role key, you're in
trouble. For example, let's say you've combined the space and shift keys, and you want to type
"Hello world!". You type this really quickly, so that the space bar happens to be down when you type
"w". That would produce "HelloWorld!".

The solution to this problem lies in its description. "Sometimes you might press down several keys
simultaneously for a _short period of time._" Thus, let me introduce the **"delay."** It is in
relationship with the comboKeys. Now, the comboKeys have one more check to do. As before, they check
if any dual-role keys are down. If so, they check how long time have elapsed since the were pressed
down. If that time is shorter than the delay, release the downKey of the dual-role key in question
and send its upKey instead. Otherwise tell the dual-role key that it has been combined with another
key, just as before. Again, the scripts _work_ with any key combination. But common keys better be
set as comboKeys to reduce mistakes. The delay can be set via the `Dual.delay` property.

To test the timeout and delay, I recommend setting both of them to long times, for example 3 seconds
and 1 second, respectively. Play with it and you'll quickly get the hang of it. Then tweak the
values so that you never ever have to think about it again.

Lastly, we've got the **"doublePress."** Usually, keys repeat when being held down (if your OS does
so). However, a dual-role key repeats its downKey when held, not the upKey. For example, if you've
combined the space and shift keys, holding down the space bar won't produce a serious of spaces,
perhaps used as indentation. What now?

For this issue, a doublePress is used. Press the dual-role key, release it and press it again,
within the doublePress time. If you continue to hold it, the upKey will be repeated. Now, the
comboKeys come in handy yet a time. If you type "bob" really quickly, and "b" is a dual-role key,
and you keep holding "b" the last time, "b" will actually start to repeat, even though another key
was pressed in-between the two "b" presses. That's not really a double press, right? However, if "o"
is a comboKey, that won't happen. The doublePress time can be set via the `Dual.doublePress`
property.

Phew! That was a lot to take in. But it's not that complicated when you actually use the dual-role
keys. It's just handy to know while tweaking the settings, so you never have to be bothered by it
again. Now, time for some recap and examples. The default values are also shown below.

    Dual.comboKeys :=
    (
    "
    a b c d e f g h i j k l m n o p q r s t u v w x y z
    0 1 2 3 4 5 6 7 8 9
    . , `; `` ' / \ [ ] - =
    Up Down Left Right Home End PgUp PgDn Insert Delete Backspace Space Enter Tab
    F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
    "
    )
    Dual.timeout := 300
    Dual.delay := 70
    Dual.doublePress := 200

`Dual.comboKeys` is a whitespace delimited string of keys that enhance the accuracy of the dual-role
keys. To list space, type in "Space", rather than a literal space. Same thing for tab. Tip: Rather
than reassigning this setting, it might be easier to append to it. For example, Swedes might want to
do `Dual.comboKeys .= " å ä ö"`.

`Dual.delay` is the number of milliseconds that you must hold a dual-role key in order for it to
count as a combination with another key (comboKeys only, though).

`Dual.timeout` is the number of milliseconds after which the downKey starts to be sent, and the
upKey won't be sent.

`Dual.doublePress` is the maximum number of milliseconds between a release of a dual-role key and
its next press that can elapse and still be called a doublePress.



Limitations
===========

For this script to work with existing remappings and hotkeys you might have, some work is
required. Both solutions feel a bit hacky, but seem to work pretty well. I would gladly accept
better solutions.

Remappings
----------

If you want a key to both to be a comboKey and remap it, you have to put the remapping inside the
comboKeys setting. For example, if you previously swapped the following keys like so …

    a::b
    b::c
    c::a

… you need to change it to this:

    Dual.comboKeys .=
    (
    "
    a::b
    b::c
    c::a
    "
    )

 Alternatively, you can format it in other ways, if you like:

    Dual.comboKeys .=
    (
    "
    a::b    b::c
    c::a
    "
    )

You can of course mix regular comboKeys and such remappings.

You might have noticed that "a", "b", and "c" already are comboKeys by default, and now we're adding
them again! Don't worry, only the last occurrence is used, allowing you to conveniently append the
setting as in the example.

Hotkeys
-------

Modifiers on dual-role keys **will not** trigger any of your AHK hotkeys, unless you modify them.
There are two helper methods to the rescue.

### `Dual.modifiersDown(modifiers*)` ###

Checks if the specified `modifiers`—and those only—are down. It is used to mimic native AHK
behavior, for example `modifiersDown("Ctrl", "Shift")` mimics `^+`. Note that `modifiers` does not
_have_ to be traditional modifiers like Control and Shift. You can use any keys.

### `Dual.send(str)` ###

Like `SendInput %str%`, but releases any modifiers first. (Puts them back down afterwards.)

### Example ###

If you had the following hotkeys defined …

    ^+a::Send 1337
    #n::Run Notepad.exe
    F13 & b::Send ^c

… you need to change them into:

    ^+a::
    #If Dual.modifiersDown("Ctrl", "Shift")
    a::Dual.send("1337")
    #If ; Optional, but makes it easier to read and maintain, in my opinion.

    #n::
    #If Dual.modifiersDown("Win") ; {Win} is a shortcut to easily target either of the Windows keys.
    n::Run Notepad.exe
    #If

    F13 & b::
    #If Dual.modifiersDown("F13")
    b::Dual.send("^c")
    #If

It is a bit clunky, I know, but at least it works. Again, I would really like a better solution.



Tests
=====

Dual will hopefully be tested in the future, perhaps using [YUnit].

[YUnit]: https://github.com/Uberi/Yunit



Changelog
=========

0.2.0 (Unreleased)
------------------

- Comments are no longer allowed in the comboKeys setting. It prevented `;` from being used as a
  comboKey, and it is not worth introducing escape rules.

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
