.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

.org 0x0204E5B8 ; Where the original game's code for loading area/sector/room indexes is.
  b 020B3E48h ; Jump to some free space, where we will put our own code for loading the area/sector/room indexes.

.org 0x020B3E48 ; Free space.
  mov r5,0h        ; Load the area index into r5.
  strb r5,[r0,515h] ; Store the area index to the ram address where r0 will read it later. (0x02106365)
  mov r4,0h        ; Load the sector index into r4.
  mov r5,0h        ; Load the room index into r5.
  b 0204E5BCh      ; Return to where we came from.

.close
