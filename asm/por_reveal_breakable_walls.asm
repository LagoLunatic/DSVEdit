.nds
.relativeinclude on
.erroronwarning on

; Makes breakable walls always have the glow visual.

.open "ftc/arm9.bin", 02000000h

.org 0x0206EAA0 ; Where the breakable wall calls a function to check if you have Eye for Decay equipped.
  mov r0, 1h ; True

.close

.open "ftc/overlay9_111", 022E8820h

; Breakable ceiling that lets rain through from Dark Academy.
.org 0x022E8FEC
  mov r0, 1h

.close
