.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This patch makes it so you don't need to draw a Magic Seal to kill a boss.

.org 0x02213C04 ; Location of the seal drawing code for loading the current game mode.
  mov r0, 1 ; Always load 1 (meaning Julius mode).

; The above change causes a bug with the practice seal menu, where attempting to practice a seal will cause the screen to go black and the game to softlock.
.org 0x021F1BF8 ; Location of code in the practice menu to decide which type of seal to do.
  mov r1, 0 ; Instead of setting argument r1 to 2 (meaning a practice seal) we set it to 0 (meaning an automatically drawn example seal). This doesn't softlock the game.

.close
