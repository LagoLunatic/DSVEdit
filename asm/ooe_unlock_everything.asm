.nds
.relativeinclude on
.erroronwarning on

; Unlocks all modes from the start.

.open "ftc/overlay9_20", 021FFFC0h

.org 0x02205F1C
  mov r0, 1h ; Albus mode

.org 0x02205F30
  mov r0, 1h ; Hard mode

.org 0x02205F44
  mov r0, 1h ; Hard mode max level 255

.org 0x0220DD04
  mov r0, 1h ; Boss rush mode

.org 0x0220DD14
  mov r0, 1h ; Sound mode

.close
