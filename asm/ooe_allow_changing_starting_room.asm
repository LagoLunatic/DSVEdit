.nds
.relativeinclude on
.erroronwarning on

; In the code for setting the starting room, r5 has the sector index put in it with a mov instruction.
; Then in the later code r5 is used for 4 different things unrelated to the sector index, as r5 is supposed to have 0 in it as that's the starting sector in the vanilla game.
; If the sector index is not 0, this causes several bugs, including an enormous max hearts count, no volume, and probably other issues.
; So we need to manually put 0 into r5 and slightly change the order of the code so it works properly when the sector index is not 0.

.open "ftc/arm9.bin", 02000000h

.org 0x020AC16C ; Right after the code for setting the starting room.
  mov r5, 0h
  add r12, r4, 570h
  str r5, [r12]
  str r5, [r12, 4h]
  str r5, [r12, 8h]
  nop

.close
