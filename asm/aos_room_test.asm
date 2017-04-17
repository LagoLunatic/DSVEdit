.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

.org 0x08002B54 ; Nintendo logo game state update code.
  push r4, r5, r14
  ; Set the game state to 02-06 (file select menu).
  mov r0, 2h
  ldr r1, =02000010h
  strb r0, [r1]
  mov r0, 6h
  strb r0, [r1, 1h]
  
  ; Save file 1.
  mov r0, 1h
  lsl r0, r0, 1h ; Multiply by 2 because 2 means save file 1 and 4 means save file 2.
  ldr r1, =020004F9h ; The selected save file.
  strb r0, [r1]
  
  ; Return -1 so the state manager doesn't change the state to something else besides 02-06.
  mov r0, 1h
  neg r0, r0
  
  pop r4, r5, r15
  .pool

.org 0x080075B4 ; Inside file select menu code.
  nop ; Remove check that the player just pressed the A button; load the save instantly instead.

.close
