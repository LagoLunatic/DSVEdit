.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

.org 0x02051F90 ; Where the original game's code for loading area/sector/room indexes is.
  b 020BFC00h ; Jump to some free space, where we will put our own code for loading the area/sector/room indexes.

.org 0x020BFC00 ; Free space.
  mov r5,0h        ; Load the area index into r5.
  strb r5,[r0,515h] ; Store the area index to the ram address where r0 will read it later. (0x02111785)
  mov r5,0h        ; Load the sector index into r5.
  mov r4,0h        ; Load the room index into r4.
  b 02051F94h      ; Return to where we came from.

.org 0x02051F80 ; The case statement for Old Axe Armor mode's starting room initialization.
  b 0x02051F88 ; Change it to take the same branch as the other three modes.

.close
