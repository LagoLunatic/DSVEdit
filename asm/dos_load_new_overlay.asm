.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Changes to game initialization code to load a new overlay (41) in addition to the ones in the original game.

; First we make a little bit of space to put our new code. To do this we optimize the amount of space used by the code that loads the static overlays (0, 1, 2, 3, 4, 5).
.org 0x02008578
  mov r0, 0h ; These lines in the original were like ldr r0, =0h. This meant a constant pool was necessary (from 020085C0-020085D7). By using mov instead of ldr no constant pool is neccessary and we can use that area for our own code.
  bl 02008690h
  mov r0, 2h
  bl 02008690h
  mov r0, 3h
  bl 02008690h
  mov r0, 4h
  bl 02008690h
  mov r0, 5h
  bl 02008690h
  mov r0, 1h
  bl 02008690h

.org 0x020085A8
  b 020085C0h ; Then we jump to the now free space.

; Add our code into the free space.
.org 0x020085C0
  mov r0, 29h ; Load our new overlay, overlay 41.
  bl 02008690h
  bl 02008630h ; Replaces the line of code at 020085A8 that we overwrote to jump here.
  b 020085ACh ; Jump back.

.close
