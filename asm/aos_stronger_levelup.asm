.gba
.relativeinclude on
.erroronwarning on

.open "ftc/rom.gba", 08000000h

; By Xanthus
; roughly 1.5x levelup

.org 0x08033cea
	; health per level is 0xc (12) by default
	; .byte 12
	.byte 18

.org 0x80e1e08
	; mp level up uses a table of 20 values depending on your current level (5 levels per number)
	; defaults commented out below
	; .byte 5, 5, 6, 8, 10, 11, 12, 12, 13, 13, 13, 14, 15, 16, 16, 16, 17, 18, 19, 20
	.byte 7, 8, 9, 12, 15, 16, 18, 18, 19, 19, 19, 21, 22, 24, 24, 24, 25, 27, 28, 30

.org 0x080e1dcc
	; str level up uses a table of 20 values depending on your current level (5 levels per number)
	; defaults commented out below, between 1 and 3
	; .byte 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 3, 3, 2, 2, 2, 2, 2, 2

.org 0x080e1de0
	; con level up uses a table of 20 values depending on your current level (5 levels per number)
	; defaults commented out below, between 1 and 3
	; .byte 1, 1, 1, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 2, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2

.org 0x080e1df4
	; int level up uses a table of 20 values depending on your current level (5 levels per number)
	; defaults commented out below, between 1 and 3
	; .byte 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 2, 2

.org 0x08033d5e
	; every third level uses this instead for Int level up
	; default is 1
	; .byte 1
	.byte 2

.org 0x8033d64
	; Luck gets 1 added to it each level by default
	; .byte 1
	.byte 2

.close
