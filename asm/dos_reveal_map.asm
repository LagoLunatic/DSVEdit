.nds
.relativeinclude on
.erroronwarning on

; Makes the entire map visible but greyed out from the start.

.open "ftc/arm9.bin", 02000000h

.org 0x020220C4
  ; Make the game not care if you have the map items and just always draw unvisited tiles.
  mov r1, r8
  nop

.org 0x02024BE8
  ; Makes rooms never be counted as secret rooms, since secret rooms don't show up even if the game thinks you have the map for that area.
  mvn r0, 0h
  bx r14

.close
