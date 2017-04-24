.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

.org 0x0203E534
  push r1, r14
  mov r0, 4h
  bl 0203BF88h ; Set the top screen to 4 (cross with bat wings).
  mov r0, 0h ; Save file 0.
  bl 02010C1Ch ; Load a save file.
  ldr r1, =020F6E97h
  mov r0, 0h
  strb r0, [r1] ; unknown value we have to set for it to load. TODO: look into this
  ldr r1, =020F72F6h ; Game mode.
  strb r0, [r1] ; Must set to 0 in case it's 3 in the save file.
  ldr r1, =020F70A8h
  mov r0, 07h
  strb r0, [r1] ; Sector index, 020F70A8
  mov r0, 05h
  strb r0, [r1, 1h] ; Room index, 020F70A9
  ; Next set the x,y position in the room (default is 80,60).
  ; The reason for the extra 1 subpixel is so the assembler doesn't optimize these ldr statements into mov statements. If it did that then DSVEdit couldn't change the position at runtime.
  ldr r0, =80001h
  str r0, [r1, 10h] ; X pos, 020F70B8
  ldr r0, =60001h
  str r0, [r1, 14h] ; Y pos, 020F70BC
  mov r0, 0h ; Return 0 so the state manager sets the state to 0 (loading a save).
  pop r1, r15
  .pool

.close
