.nds
.relativeinclude on
.erroronwarning on

; Disables the special doors of the sliding puzzle in Demon Guest House.

.open "ftc/arm9.bin", 02000000h

.org 0x0202738C
  ; This is where, upon going through any door, the game would start checking your current sector/room indexes to see if the door you went through was a sliding puzzle door.
  ; The original code here had a return that was conditional and only ran if your sector index is not 1 (Demon Guest House).
  ; We change it to an unconditional return so the special behavior of the sliding puzzle doors never activates.
  mov r0, 0h
  pop r4-r8,r14
  bx r14

.close
