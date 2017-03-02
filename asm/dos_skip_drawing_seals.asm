.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so you don't need to draw a Magic Seal to kill a boss.

.org 0x02213C04 ; Location of the boss-killed code for loading the current game mode.
  mov r0, 1 ; Always load 1 (meaning Julius mode).

.close
