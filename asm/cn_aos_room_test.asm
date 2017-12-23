.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

.org 0x0800298C ; Nintendo logo game state update code. us 0x08002B54 cn 0x0800298C
  push r4, r5, r14
  
  mov r0, 0h ; Save file 0.
  bl 08011938h ; Call function to load save file. us 08012744h cn 08011938h
  
  mov r0, 2h
  mov r1, 7h
  bl 0800197Ch ; Call function to get room pointer by sector index r0 and room index r1. us 08001980h cn 0800197Ch
  ldr r1, =020003CCh
  str r0, [r1] ; Store it as the current room at 020003CC.
  
  ; Overrides the X/Y pos loaded from the save file.
  ; Unlike the DSVanias these are halfwords.
  ldr r1, =02000338h
  ldr r0, =80h
  strh r0, [r1]
  ldr r0, =60h
  strh r0, [r1,2h]
  
  ; Return 4 so the state manager changes the state to ingame.
  mov r0, 4h
  
  pop r4, r5, r15
  .pool

; Allow skipping events with start. us 0x0805B56C cn 0x08059B30
.org 0x08059B30
  mov r0, 3h

.close
