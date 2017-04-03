.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Changes the game initialization code to load a new overlay (86) in addition to the ones in the original game.

; To fit our new code we need to make some space. We replace lines like ldr r4, =27h with mov r0, 27h so that a constant pool isn't necessary for them. Most of this code is just the original code shifted up a bit.
.org 0x0208B5EC
  mov r0, 27h
  bl 02032DD8h
  bl 022BA230h
  ldr r1, =021527D8h
  strh r0,[r1,6h]
  mov r0, 27h
  bl 02032EA8h
  
  ; New code:
  mov r0, 56h ; New overlay ID, 86.
  bl 02032DD8h ; Load the overlay.
  
  pop r4, r15
  .pool
  
.close
