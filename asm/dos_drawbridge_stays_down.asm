.nds
.relativeinclude on
.erroronwarning on

; This patch makes the drawbridge in DoS stay down permanently once you've lowered it once.
; The button will stay depressed, so that you don't need to worry about hitting it every time you walk into the room from the right.

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021A27C8 ; When Soma walks/jumps off the button after pressing it, this line would normally re-raise the button.
  nop ; Remove it so the button doesn't instantly come up.
.org 0x021A2260 ; This line runs when the drawbridge is created, if the drawbridge has already been lowered previously.
  ; Originally this line was doing something useless, storing 0 to a value which is just 0 by default anyway. So we can replace it.
  strb r3, [r4, 5h] ; Store 1 to the button's "pressed" state so the player can't press it again.

.close
