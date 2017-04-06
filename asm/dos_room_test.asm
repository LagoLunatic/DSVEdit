.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

.org 0x0203E514
  push r1, r14
  mov r0, 0h ; Save file 0.
  bl 02010BC4h ; Load a save file.
  ldr r1, =020F6DF7h
  mov r0, 0h
  strb r0, [r1] ; unknown value we have to set for it to load. TODO: look into this
  ldr r1, =020F7008h
  mov r0, 07h
  strb r0, [r1] ; Sector index, 020F7008
  mov r0, 05h
  strb r0, [r1, 1h] ; Room index, 020F7009
  ; Next set the x,y position in the room (default is 80,60).
  ; The reason for the extra 1 subpixel is so the assembler doesn't optimize these ldr statements into mov statements. If it did that then DSVEdit couldn't change the position at runtime.
  ldr r0, =80001h
  str r0, [r1, 10h] ; X pos, 020F7018
  ldr r0, =60001h
  str r0, [r1, 14h] ; Y pos, 020F701C
  mov r0, 0h ; Return 0 so the state manager sets the state to 0 (loading a save).
  pop r1, r15
  .pool

.close

; TODO: although this loads you into the room fine, there are several bugs, like room entities being gone and menu graphics being messed up
