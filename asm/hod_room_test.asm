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

.close
