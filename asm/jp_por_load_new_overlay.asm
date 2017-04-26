.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Changes the game initialization code to load a new overlay (119) in addition to the ones in the original game.

; First we make a little bit of space to put our new code. To do this we optimize the amount of space used by the code that loads the static overlays (0, 25, 5, 6, 7, 8).
.org 0x020076CC
  mov r0, 0h ; These lines in the original were like ldr r0, =0h. This meant a constant pool was necessary (from 02007704-0200771B). By using mov instead of ldr no constant pool is necessary and we can use that area for our own code.
  bl 020075C0h
  mov r0, 19h
  bl 020075C0h
  mov r0, 5h
  bl 020075C0h
  mov r0, 6h
  bl 020075C0h
  mov r0, 7h
  bl 020075C0h
  mov r0, 8h
  bl 020075C0h

.org 0x020076FC
  b 02007704h ; Then we jump to the now free space.

; Add our code into the free space.
.org 0x02007704
  mov r0, 77h ; Load our new overlay, overlay 119.
  bl 020075C0h
  bl 02007664h ; Replaces the line of code at 020076FC that we overwrote to jump here.
  b 02007700h ; Jump back.

.close


; TODO: below this at 02007728 there's another one, just with overlay 4 instead of overlay 19h. is this actually for anything?
