.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

.org 0x08002138 ; Nintendo logo game state update code.
  push r14
  
  mov r0, 0h ; Save file 0.
  bl 800B7A8h ; LoadSave
  
  ldr r0, =849F588h ; Room pointer
  ldr r1, =2000068h ; Location of pointer to current room
  str r0, [r1]
  
  ; Return 3 so the state manager changes the state to ingame.
  mov r0, 3h
  pop r15
  .pool

@SetCameraPositionAndChangeRoom:
  mov r0, r4
  ldr r1, =100h ; Camera X pos
  ldr r2, =200h ; Camera Y pos
  bl 08009398h ; ChangeRoom
  ldr r0, =08008D84h | 1h ; OR 1 to mark this as THUMB code for bx
  bx r0 ; Jump back to the normal code
  .pool

.org 0x08008D7A ; Code run when loading a save
  ; Normally this loads the room with the camera at the upper left corner of the room.
  ; The X and Y pos are both just simple mov instructions, so we can't change them to large values freely.
  ; Therefore we need to jump to free space so we have enough room to put the camera X and Y pos.
  ldr r0, =@SetCameraPositionAndChangeRoom | 1h ; OR 1 to mark this as THUMB code for bx
  bx r0 ; Jump to free space
  .pool

.close
