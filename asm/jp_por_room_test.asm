.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_27", 022D2840h

.org 0x022D2A9C
  push r4, r5, r14
  ; Set the game state to 00 (loading a save file).
  mov r0, 0h
  ldr r4, =020EAE64h
  str r0, [r4]
  ; Load the save file.
  mov r0, 0h ; Save file 0.
  bl 0203EDECh
  ldr r4, =02106580h
  ; Set the area, sector, and room indexes.
  mov r0, 01h
  strb r0, [r4, 0Ah] ; Area index, 0210658A
  mov r0, 02h
  strb r0, [r4, 0Bh] ; Sector index, 0210658B
  mov r0, 07h
  strb r0, [r4, 0Ch] ; Room index, 0210658C
  ; Next set the x,y position in the room (default is 80,60).
  ; The reason for the extra 1 subpixel is so the assembler doesn't optimize these ldr statements into mov statements. If it did that then DSVEdit couldn't change the position at runtime.
  ldr r0, =80001h
  str r0, [r4, 1Ch] ; X pos, 0210659C
  ldr r0, =60001h
  str r0, [r4, 20h] ; Y pos, 021065A0
  mov r0, 0h
  pop r4, r5, r15
  .pool

.close
