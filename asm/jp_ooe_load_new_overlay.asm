.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Changes the game initialization code to load a new overlay (85) in addition to the ones in the original game.

; To fit our new code we need to make some space. We replace lines like ldr r4, =26h with mov r0, 26h so that a constant pool isn't necessary for them. Most of this code is just the original code shifted up a bit.
.org 0x02099100
  mov r0, 26h
  bl 0203FB7Ch
  bl 022B7FB0h
  ldr r1, =021595F8h
  strh r0,[r1,6h]
  mov r0, 26h
  bl 0203FC4Ch
  
  ; New code:
  mov r0, 55h ; New overlay ID, 85.
  bl 0203FB7Ch ; Load the overlay.
  
  pop r4, r15
  .pool
  
.close
