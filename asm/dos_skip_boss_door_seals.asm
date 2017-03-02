.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so you don't need to own a Magic Seal to enter a boss door.

.org 0x021A9AE4 ; Location of the boss door code for loading the current game mode.
  mov r0, 1 ; Always load 1 (meaning Julius mode).

.close
