.nds
.relativeinclude on
.erroronwarning on

; This patch slightly changes the code that calculates what percentage of the map you have explored so that the total number of tiles can be easily changed, allowing the percentage to be correct with modded maps.

.open "ftc/arm9.bin", 02000000h

.org 0x02026B54
  mul r0, r0, r1 ; Multiplies the number of explored map tiles (in r0) by 0d1000 (in r1) (for 100.0%, 4 digits including the decimal point).
  ldr r1, =401h ; The total number of map tiles. (The base game has 0x400 tiles, but we put 401 instead because the assembler would optimize 400 into a shifted immediate and then the randomizer couldn't easily change this later on.)
  bl 02075B28h ; Divide
  add r13, r13, 4h
  pop r15
  .pool

.close
