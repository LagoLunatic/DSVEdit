.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so you don't need to own a Magic Seal to enter a boss door and you don't need to draw a Magic Seal to kill the boss..

.org 0x021A9AE4 ; Location of the boss door code for loading the current game mode.
  mov r0, 1 ; Always load 1 (meaning Julius mode).

.org 0x02213C04 ; Location of the boss-killed code for loading the current game mode.
  mov r0, 1 ; Always load 1 (meaning Julius mode).

.close
