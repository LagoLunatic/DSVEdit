.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Make all areas on the world map accessible.

.org 0x020AA8E4
  mov r0, 1

.close
