.nds
.relativeinclude on
.erroronwarning on

; Reveals all entries in the bestiary from the start of the game.

.open "ftc/overlay9_22", 02223E00h

.org 0x0222D424 ; Check for whether to display the enemy name or ??? in the enemy list.
  mvn r1, 0h ; Set all bits.

.org 0x0222CF38 ; Check for whether to allow the player to enter a specific enemy's entry by pressing A on the enemy list.
  mvn r0, 0h

.org 0x0222A964 ; Checks for if you can press right to go to the next entry.
  mvn r3, 0h

.org 0x0222A9D8 ; Checks for if you can press left to go to the previous entry.
  mvn r8, 0h

.org 0x0222AF6C ; Check for whether to display the enemy HP and EXP or ??? on the enemy entry.
  mvn r2, 0h

.org 0x0222B1E0 ; Check for whether to display the enemy description or ??? at the bottom of the enemy entry.
  mvn r2, 0h

.close

.open "ftc/arm9.bin", 02000000h

.org 0x020AF3D0 ; Check for whether to display the enemy HP and EXP or ??? on the top screen.
  mvn r2, 0h

.org 0x020AF7B8 ; Check for whether to display enemy weaknesses and resistances on the top screen.
  mvn r2, 0h

.org 0x020AF2C0 ; Check for whether to display enemy HP or ??? on the top screen.
  mvn r2, 0h

.org 0x020AF2EC ; Check for whether to display enemy EXP on the top screen.
  mvn r2, 0h

.close
