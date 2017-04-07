.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_20", 021FFFC0h

;.org 0x02213EC8 ; BUG: CRASH
;.org 0x02213060 ; BUG: player can't control anything
.org 0x022132F8 ; BUG: some items aren't equipped. top screen is black
  ;b 0x02213EC8
  push r1, r14
  mov r0, 1h
  ldr r1, =021007D5h
  strb r0, [r1] ; Set this to 1 (loading a save) so equipment stays equipped.
  ; Load the save file.
  mov r0, 0h ; Save file 0.
  ldr r1, =02100144h
  bl 0202C610h
  ;bl 020AD160h
  ldr r1, =0210078Dh
  ldrb r0, [r1]
  mov r1, 10h
  mov r2, 1h
  bl 020657F8h
  ; Set the game state to 08 (ingame).
  mov r0, 8h
  mov r1, 10h
  mov r2, 1h
  bl 0202D7A0h
  ldr r1, =021006C0h
  ; Set the area, sector, and room indexes.
  mov r0, 01h
  strb r0, [r1, 0Ch] ; Area index, 021006CC
  mov r0, 02h
  strb r0, [r1, 0Dh] ; Sector index, 021006CD
  mov r0, 07h
  strb r0, [r1, 0Eh] ; Room index, 021006CE
  ; Next set the x,y position in the room (default is 80,60).
  ; The reason for the extra 1 subpixel is so the assembler doesn't optimize these ldr statements into mov statements. If it did that then DSVEdit couldn't change the position at runtime.
  ldr r0, =80001h
  str r0, [r1, 00h] ; X pos, 021006C0
  ldr r0, =60001h
  str r0, [r1, 04h] ; Y pos, 021006C4
  pop r1, r15
  .pool

.close
