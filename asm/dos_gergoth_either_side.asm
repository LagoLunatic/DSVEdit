.nds
.relativeinclude on
.erroronwarning on

; This patch makes Gergoth appear on the right half of his room when the player enters from the left so he's not on top of the player.

.open "ftc/overlay9_36", 022FF9C0h

.org 0x022FFAF0 ; Code in Gergoth's initialization that normally floors him in different ways depending on his var A.
  ; First we simplify the flooring code (to make room for new code) by always doing the same thing instead of having 4 different possibilities for 4 different var As.
  mov r0, 0B0000h
  str r0, [r5, 30h] ; Set Gergoth's Y pos to 0xB0.
  
  ldr r0, =020CA95Ch
  ldr r0, [r0] ; Load player's X pos.
  cmp r0, 80000h ; Check if player came in on the left half of the room.
  movlt r0, 0C0000h
  strlt r0, [r5, 2Ch] ; Move Gergoth's X pos to 0xC0, close to the right wall.
  b 022FFB48h
  .pool

.close
