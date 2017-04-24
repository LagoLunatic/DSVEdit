.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_19", 021FFDE0h

.org 0x022130E8 ; Code run for the intro logos.
  push r1, r14
  mov r0, 1h
  ldr r1, =021075F1h
  strb r0, [r1] ; Set this to 1 (loading a save) so equipment stays equipped.
  ; Load the save file.
  mov r0, 0h ; Save file 0.
  ldr r1, =02106F60h ; TODO 3C
  bl 020393B4h
  ; Set the game state to 08 (ingame).
  mov r0, 8h
  mov r1, 10h
  mov r2, 1h
  bl 0203A544h
  ldr r1, =021074DCh
  ; Set the area, sector, and room indexes.
  mov r2, 01h
  strb r2, [r1, 0Ch] ; Area index, 021074E8
  mov r0, 02h
  strb r0, [r1, 0Dh] ; Sector index, 021074E9
  mov r0, 07h
  strb r0, [r1, 0Eh] ; Room index, 021074EA
  ; Next set the x,y position in the room (default is 80,60).
  ; The reason for the extra 1 subpixel is so the assembler doesn't optimize these ldr statements into mov statements. If it did that then DSVEdit couldn't change the position at runtime.
  ldr r0, =80001h
  str r0, [r1, 00h] ; X pos, 021074DC
  ldr r0, =60001h
  str r0, [r1, 04h] ; Y pos, 021074E0
  
  cmp r2, 1h ; Check if area is Wygol or not.
  ldr r1, =021075A9h
  ldrb r0, [r1] ; Load top screen from save file.
  bne @NotInWygol
  @InWygol:
    cmp r0, 5h
    moveq r0, 8h ; If the save file had the normal map, set it to Wygol map.
    streqb r0, [r1] ; Store it back to 0210078D in case the player spawns in a warp room.
    b @AfterWygol
  @NotInWygol:
    cmp r0, 8h
    moveq r0, 5h ; If the save file had the Wygol map, set it to the normal map.
    streqb r0, [r1] ; Store it back to 0210078D in case the player spawns in a warp room.
  @AfterWygol:
  mov r1, 10h
  mov r2, 1h
  bl 0208C7F8h ; Change the top screen to that value.
  
  pop r1, r15
  .pool

.close
