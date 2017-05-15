.nds
.relativeinclude on
.erroronwarning on

; Unlocks all modes from the start.

.open "ftc/arm9.bin", 02000000h

.org 0x0203E3B0
  mov r0, 1h ; Boss rush mode

.org 0x0203E3E0
  mov r0, 2h ; Sound mode

.org 0x0203E410
  mov r0, 4h ; Julius mode

.close
