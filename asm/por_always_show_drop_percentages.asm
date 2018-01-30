.nds
.relativeinclude on
.erroronwarning on

; This patch causes you to always have the Gambler Glasses effect of showing percentages instead of star ratings for enemy drops.

.open "ftc/arm9.bin", 02000000h

.org 0x02053074 ; Checks if you have Gambler Glasses equipped to see if it should hide the stars.
  mov r0, 2h ; Head armor 2, Gambler Glasses
.org 0x02053790 ; Checks if you have Gambler Glasses equipped to see if it should show the percentages.
  mov r0, 2h ; Head armor 2, Gambler Glasses

.close
