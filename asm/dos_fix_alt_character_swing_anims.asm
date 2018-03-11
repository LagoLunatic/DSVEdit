.nds
.relativeinclude on
.erroronwarning on

; When Soma's sprite gets swapped out for a Julius mode character, the game still tries to use the weapon-dependent swing animation that Soma would use.
; But the alternate characters don't have the proper animations, so they wind up just playing random garbage animations unrelated to attacking.

; This patch makes the game ignore the weapon-dependent animations and just use the default attack animations of whatever sprite Soma has.
; But it also preserves the lack of attack animation with the valmanway attack-while-moving property so that still works correctly.

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021F8178
  ; We need to preserve argument r0 on the stack since it has the player entity pointer.
  push r0, r4, r14
.org 0x021F81BC
  ; We just use the weapon-independent swing anim from the player's state animations instead of the usual swing anim.
  ; But only if this weapon does not have the valmanway attack-while-moving bit, in that case we leave the code that returns -1 alone.
  ldreq r0, [r13] ; First load argument r0 off the stack.
  beq 021F81CCh ; Then go to the code that reads from the player's state animations.
  
  pop r1, r4, r14 ; When popping r0, pop it into r1 so it doesn't overwrite the return value.
.org 0x021F81D8
  pop r1, r4, r14

.close
