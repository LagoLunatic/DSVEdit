.nds
.relativeinclude on
.erroronwarning on

; This patch adds a text popup if the player tries to enter the Forest of Doom portrait before it's unlocked.
; This is necessary for portrait randomizer when the Forest of Doom portrait isn't in the normal location, since the normal event only works in that sector.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ 0x02308EC0

.open "ftc/arm9.bin", 02000000h

.org 0x02079350 ; Location of code normally run when the Forest of Doom portrait is locked. (todo test if it affects other locked portraits)
  beq @FreeSpace

.close

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
  ldr  r2,=20FC48Eh ; Bitfield of buttons pressed this frame.
  ldrh r2,[r2]
  ands r2,r2,40h ; Up.
  beq  20793FCh ; If up was not just pressed, continue on with the normal code without showing the message.
  
  ldr  r0,=4BEh ; Load text index 4BE. Originally this is just an unused string ("The Lost Village") but this should be changed in the text editor to say:
  ; "You must beat Stella and talk to Wind\nto unlock the Forest of Doom."
  bl   2050544h ; Call ShowTextPopup.
  b    20793FCh ; Then continue on with the rest of the code.
  .pool

.close
