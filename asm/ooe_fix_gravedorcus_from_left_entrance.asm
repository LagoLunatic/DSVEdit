.nds
.relativeinclude on
.erroronwarning on

; This patch makes Gravedorcus not immediately damage the player if they enter from the left door.

.open "ftc/overlay9_33", 022B73A0h

.org 0x022BA230
  ; Remove branch that would make Gravedorcus's intro cutscene play if you enter the room from the right.
  nop

.org 0x022BA250
.area 0x20 ; Lines 022BA258-022BA26C were for the cutscene we skipped over, so we get 0x18 extra bytes to work with from that.
  ; Set Gravedorcus's state to 5 instead of 1.
  ; This causes Gravedorcus to start at X position 0x100 and shooting projectiles to the left, which is dodgeable, while spawning right on top of the player and moving to the right is not dodgeable.
  mov r0, 5h
  strb r0, [r5, 0Dh]
  
  ; Replace the two lines we overwrote at the start (return)
  add r13, r13, 10h
  pop r3-r5,r15
.endarea

.close
