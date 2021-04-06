.nds
.relativeinclude on
.erroronwarning on

; This patch makes the color at index 2 in Shanoa's palette (the glyph on her back) not glow and switch between colors automatically.

.open "ftc/arm9.bin", 02000000h

.org 0x0208C990
  nop
  
.close
