.nds
.relativeinclude on
.erroronwarning on

; This patch adds a text popup if the player tries to enter the Forest of Doom portrait before it's unlocked.
; This is necessary for portrait randomizer when the Forest of Doom portrait isn't in the normal location, since the normal event only works in that sector.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ 0x02308EC0

.open "ftc/arm9.bin", 02000000h

.org 0x02079350 ; Location of code normally run when the Forest of Doom portrait is locked. (Or when global game flag 80000000 is set to disable going in all portraits.)
  beq @FreeSpace

.close

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
  push r0-r3
  ldr  r2,=20FC48Eh ; Bitfield of buttons pressed this frame.
  ldrh r2,[r2]
  ands r2,r2,40h ; Up.
  popeq r0-r3
  beq  20793FCh ; If up was not just pressed, continue on with the normal code without showing the message.
  
  ldr r2,=211174Ch ; Bitfield of global game flags.
  ldr r2,[r2]
  ands r2,r2,80000000h ; Bit that disables going into portraits.
  popne r0-r3
  bne  20793FCh ; If the reason we can't enter this portrait is because of that bit, continue on with the normal code without showing the message.
  
  ldr r2,=2111F51h ; Game mode.
  ldrb r2,[r2]
  cmp r2, 0h ; Jonathan mode.
  popne r0-r3
  bne  2079354h ; If in any mode besides Jonathan mode, enter the portrait even if the event flag for talking to Wind is not set (since you can't talk to Wind outside of Jonathan mode).
  
  ldr  r0,=4BEh ; Load text index 4BE. Originally this is just an unused string ("The Lost Village") but this should be changed in the text editor to say:
  ; "You must beat Stella and talk to Wind\nto unlock the Forest of Doom."
  bl   2050544h ; Call ShowTextPopup.
  pop r0-r3
  b    20793FCh ; Then continue on with the rest of the code.
  .pool

.close
