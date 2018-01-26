.nds
.relativeinclude on
.erroronwarning on

; This patch reveals all portrait tiles on the map, even if they're not explored yet.

.open "ftc/arm9.bin", 02000000h

.org 0x0202F2D0
  ; Swap the order of checks so it checks if a tile is a portrait before checking if the tile is explored.
  str r1, [r13,1Ch]
  
  ands r0, r2, 800h
  ldrne r0, =66666666h
  strne r0, [r13, 1Ch]
  bne 0202F3A8h

  cmp r3, 3h
  bne 0202F384h
.org 0x0202FEF4
  .pool

.close
