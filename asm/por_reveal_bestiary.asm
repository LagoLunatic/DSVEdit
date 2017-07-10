.nds
.relativeinclude on
.erroronwarning on

; Reveals all entries in the bestiary from the start of the game.

.open "ftc/arm9.bin", 02000000h

.org 0x02033970 ; Check before adding this enemy's drops to the "Rate" completion percentage in the enemy list.
  mvn r1, 0h ; Set all bits.

.org 0x0203809C ; Check before making the enemy's name white instead of grey in the enemy list.
  mvn r1, 0h

.org 0x02038170 ; Check for whether to display the enemy name or ??? in the enemy list.
  mvn r0, 0h

.org 0x020381F8 ; Check for whether to display "Select an enemy to view." below the enemy list instead of "This enemy cannot be viewed yet."
  mvn r0, 0h

.org 0x02037C78 ; Check for whether to allow the player to enter a specific enemy's entry by pressing A on the enemy list.
  mvn r0, 0h

.org 0x020534FC ; Check for whether to display the enemy name, drops, HP, EXP and SP instead of ??? on the enemy entry.
  mvn r1, 0h

.org 0x0203782C ; Check for whether to display the enemy description instead of "This enemy cannot be viewed yet." at the bottom of the enemy entry.
  mvn r0, 0h

.org 0x02037960 ; Check for whether to display the left pointing arrow on a specific enemy entry to indicate you can go to the previous enemy entry.
  mvn r1, 0h

.org 0x020379CC ; Check for whether to display the right pointing arrow on a specific enemy entry to indicate you can go to the next enemy entry.
  mvn r0, 0h

.org 0x02053028 ; Check for whether to display enemy weaknesses and resistances on the enemy entry.
  mvn r1, 0h

.org 0x020375AC ; Checks for if you can press right to go to the next entry.
  mvn r0, 0h

.org 0x0203761C ; Checks for if you can press left to go to the previous entry.
  mvn r0, 0h

.org 0x02037464 ; Something on the enemy entry, if the bestiary is empty this tries to decrease which entry you're on every frame until you're on the Zombie entry.
  mvn r0, 0h

.close
