.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

; Allow skipping events with start, even if you haven't beaten the game once yet.
.org 0x0805B56C
  mov r0, 3h

.close
