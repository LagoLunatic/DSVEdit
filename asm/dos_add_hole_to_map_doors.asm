.nds
.relativeinclude on
.erroronwarning on

; This adds a single pixel hole to all doors drawn on the map to increase visibility, like in PoR and OoE.

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x108

.open "ftc/arm9.bin", 02000000h

.org 0x020240B0
  ; Handles drawing left/right doors on the left edge of even-numbered columns.
  bne @DrawLeftRightDoorEvenColumn
  nop
  nop

.org 0x020240FC
  ; Handles drawing left/right doors on the left edge of odd-numbered columns.
  bne @DrawLeftRightDoorOddColumn
  nop
  nop

.org 0x020242A8
  ; Handles drawing up/down doors in even-numbered columns.
  ; 3 is the index of the door color in the palette, while 1 is the index of the room fill color in the palette.
  .word 0x00003133
.org 0x020242B4
  ; Handles drawing up/down doors in odd-numbered columns.
  .word 0x31330000

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@DrawLeftRightDoorEvenColumn:
  cmp r4, 2 ; On the center pixel of an even-numbered row, skip drawing the door pixel
  beq 2024138h
  cmp r4, 6 ; On the center pixel of an odd-numbered row, skip drawing the door pixel
  beq 2024138h
  
  ; If we're not on a center pixel, simply draw the door pixel like the original code did and return.
  orr r0, r0, 3h
  str r0, [r5, r4, lsl 2h]
  b 2024138h
@DrawLeftRightDoorOddColumn:
  cmp r4, 2 ; On the center pixel of an even-numbered row, skip drawing the door pixel
  beq 2024138h
  cmp r4, 6 ; On the center pixel of an odd-numbered row, skip drawing the door pixel
  beq 2024138h
  
  ; If we're not on a center pixel, simply draw the door pixel like the original code did and return.
  orr r0, r0, 30000h
  str r0, [r5, r4, lsl 2h]
  b 2024138h

.close
