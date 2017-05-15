.nds
.relativeinclude on
.erroronwarning on

; Unlocks all modes from the start.

.open "ftc/overlay9_25", 022D7900h

.org 0x022D8D20
  mov r0, 40h ; Beat game

.org 0x022D82D4
  mov r0, 40h ; Beat game

.org 0x022D82FC
  mov r0, 2h ; Richter

.org 0x022D8324
  mov r0, 4h ; Sisters

.org 0x022D834C
  mov r0, 8h ; Old Axe Armor

.close

.open "ftc/overlay9_26", 022E01A0h

.org 0x022E15D0
  mov r0, 10h ; Sound mode

.close

.open "ftc/overlay9_32", 022E01A0h

.org 0x022E05A4
  mov r0, 40h ; Boss rush courses 2 and 3

.close
