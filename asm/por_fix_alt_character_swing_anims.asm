.nds
.relativeinclude on
.erroronwarning on

; When Jonathan or Charlotte's sprite gets swapped out for one of the alternate game mode characters, the game still tries to use the weapon-dependent swing animation that Jonathan/Charlotte would use.
; But the alternate characters don't have the proper animations, so they wind up just playing random garbage animations unrelated to attacking.

; This patch makes the game ignore the weapon-dependent animations and just use the default attack animations of whatever sprite Jonathan/Charlotte have.
; But it also preserves the lack of attack animation with the illusion fist attack-while-moving property so that still works correctly.

.open "ftc/overlay9_0", 021CDF60h

.org 0x021FEBD8
  ; We need to preserve argument r0 on the stack since it has the player entity pointer.
  push r0, r4, r5, r14
.org 0x021FEC2C
  popeq r1, r4, r5, r15 ; When popping r0, pop it into r1 so it doesn't overwrite the return value.
.org 0x021FEC34
  ands r0, r0, 8h
  
  ; We just use the weapon-independent swing anim from the player's state animations instead of the usual swing anim.
  ldreq r0, [r13, 4h] ; First load argument r0 off the stack.
  beq 021FEC4Ch ; Then go to the code that reads from the player's state animations.
  
  ; But if this weapon has the illusion fist attack-while-moving bit (bit 8) we still return -1 so that works properly.
  mvnne r0, 0h
  add r13, r13, 4h
  pop r1, r4, r5, r15
.org 0x021FEC58
  pop r1, r4, r5, r15

.close
