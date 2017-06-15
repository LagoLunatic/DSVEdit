.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Disables the start button exiting the quests menu.
; The B button can be used to exit the quest menu instead.
; This prevents taking quest rewards over and over by exiting before the quest is marked as complete.

; Changes how the quest menu handles button presses.
; Normally the value at [r13,14h] being 2 means B was pressed, and 3 means start was pressed.
; When B is pressed on the quest list, it changes the value to 3 to simulate the player exiting with start.
; Instead we change it so 4 is the value needed to exit the menu, and make B pressed on the quest list set the value to 4 instead of 3.
; Start still just sets it to 3, which is now ignored.
.org 0x02040848
  cmp r0, 4h ; This is the value it must be to exit the quest menu.
.org 0x0204041C
  moveq r0, 4h ; This is the value set when pressing B on the quest list.
.org 0x0204083C
  movle r0, 4h ; This is the value set when the quest list is empty in some cases.
.org 0x0204052C
  mov r0, 4h ; This is the value set when the quest list is empty in other cases.

.close
