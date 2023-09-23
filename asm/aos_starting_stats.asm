.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

; Soma's default starting stats. Change the numbers in the section below.
.definelabel Base_MaxHP, 160 ; This number gets doubled by Double_MaxHP times. (Max: 255)
.definelabel Double_MaxHP, 1 ; number of times to double the BaseMaxHP.
.definelabel MaxMP, 80 ; Max: 255
.definelabel Stat_STR, 10 ; Max 255
.definelabel Stat_CON, 12 ; Max 255
.definelabel Stat_INT, 11 ; Max 255
.definelabel Stat_LCK, 9 ; Max 255

; Change Soma's starting hp
.org 0x08033db8
	; default value is 0xA0, which is 160. This gets doubled to default value of 320
	mov r0, Base_MaxHP
	lsl r0, Double_MaxHP

.org 0x08033dbe
	.byte MaxMP

.org 0x08033dc2
	.byte Stat_STR

.org 0x08033dc6
	.byte Stat_CON

.org 0x08033dca
	.byte Stat_INT

.org 0x08033dce
	.byte Stat_LCK

.close
