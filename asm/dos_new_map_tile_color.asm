.nds
.relativeinclude on
.erroronwarning on

; Implements a new color that the map can use in DoS, like how PoR and OoE have the orange entrance color.

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x168

.open "ftc/arm9.bin", 02000000h

.org 0x020220DC ; In MapDraw
  ands r1, r0, 4000h
  movne r0, r11
  beq @CheckEntranceBitSetInMapTileMetadataForDraw
.org 0x020239E0 ; In MapTileRedrawFillPixels
  ands r1, r0, 4000h
  b @CheckEntranceBitSetInMapTileMetadataForRedraw

.org 0x02024830 ; In MapTileDrawFillPixels
  bne @CheckDrawEntranceFillColorEvenColumn
.org 0x0202491C ; In MapTileDrawFillPixels
  bne @CheckDrawEntranceFillColorOddColumn

; Update color 6 in the map palette. Originally it was an unused black color, change it to orange.
.org 0x02079D5C+0xC
  .halfword 0x021F

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@CheckEntranceBitSetInMapTileMetadataForDraw:
  ands r1, r0, 0800h ; This bit in the tile metadata is for entrances
  movne r0, 3h ; New value to mean entrance tile
  
  ldreq r0, [r13, 10h] ; Replace line overwritten to jump here
  b 0x020220E8 ; Return

@CheckEntranceBitSetInMapTileMetadataForRedraw:
  movne r2, 2h ; Replace line overwritten to jump here
  bne 0x020239E8
  
  ands r1, r0, 0800h ; This bit in the tile metadata is for entrances
  movne r2, 3h ; New value to mean entrance tile
  
  b 0x020239E8 ; Return

@CheckDrawEntranceFillColorEvenColumn:
  cmp r8, 3h ; New value we added meaning entrance tile
  bne 0x02024854 ; Draw the fill color for normal tiles
  
  mov r0, 10000h
  ldr r1, [r5, r4, lsl 2h]
  rsb r0, r0, 0h
  and r1, r1, r0
  ldr r0, =6666h
  orr r0, r1, r0
  str r0, [r5, r4, lsl 2h]
  b 0x020248B8
  .pool

@CheckDrawEntranceFillColorOddColumn:
  cmp r8, 3h ; New value we added meaning entrance tile
  bne 0x02024938 ; Draw the fill color for normal tiles
  
  ldr r0, [r5, r4, lsl 2h]
  and r1, r0, r11
  ldr r0, =66660000h
  orr r0, r1, r0
  str r0, [r5, r4, lsl 2h]
  b 0x02024988
  .pool

.close
