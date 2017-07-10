.nds
.relativeinclude on
.erroronwarning on

; Reveals all entries in the bestiary from the start of the game.

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021ED08C ; Check for whether to display the enemy name or ??? in the enemy list.
  mvn r0, 0h

.org 0x021ED8F0 ; Check for whether to allow the player to enter a specific enemy's entry by pressing A on the enemy list.
  mvn r0, 0h

.org 0x021ECC94 ; Checks for if you can press right to go to the next entry.
  mvn r1, 0h

.org 0x021ECC3C ; Checks for if you can press left to go to the previous entry.
  mvn r1, 0h

.close

.open "ftc/arm9.bin", 02000000h

.org 0x0203A6E4 ; Check for whether to display enemy weaknesses and resistances.
  mvn r0, 0h

.close
