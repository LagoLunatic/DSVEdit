.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

.org 0x08002B54 ; Nintendo logo game state update code.
  push r4, r5, r14
  
  mov r0, 0h ; Save file 0.
  bl 08012744h ; Call function to load save file.
  
  mov r0, 2h
  mov r1, 7h
  bl 08001980h ; Call function to get room pointer by sector index r0 and room index r1.
  ldr r1, =020003CCh
  str r0, [r1] ; Store it as the current room at 020003CC.
  
  ;ldr r1, =02000524h
  ;ldr r0, =80001h
  ;str r0, [r1]
  ;ldr r0, =60001h
  ;str r0, [r1, 4h]
  
  ; Return 4 so the state manager changes the state to ingame.
  mov r0, 4h
  
  pop r4, r5, r15
  .pool

; Allow skipping events with start.
.org 0x0805B56C
  mov r0, 3h

.close
