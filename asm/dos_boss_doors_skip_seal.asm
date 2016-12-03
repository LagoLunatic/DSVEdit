.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so you don't need a Magic Seal to enter a boss door.

.org 0x021A9AE4 ; Location of the door code for loading the boolean for whether the player is in Julius mode or not.
  mov r0, 1 ; Always load 1 (meaning it is Julius mode).

.close
