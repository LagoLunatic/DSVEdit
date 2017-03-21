.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; In Dawn of Sorrow, luck has very little effect on soul/item drop chances. Even a full 99 luck only gives you about +0.04% chance for soul drops or about +0.25% for item drops. (The exact amount it gives depends on the base chance of the drop, but it's never a significant amount.)

; Fixes how luck affects soul drops. With this fixed formula each point of luck gives +0.1% drop chance.
.org 0x021C3A5C
  mov r2, r5, lsl 5h ; Multiply luck by 0x20.
.org 0x021C3A68
  mov r7, r2 ; Put it in r7.
.org 0x021C3A78
  mov r0, 8000h ; Always use 0x8000 as the max random number to generate, instead of basing it off the player's luck. This makes the calculation simpler.
.org 0x021C3A9C
  add r6, r7, r6, lsl 6h ; r6 is the enemy's base soul drop chance defined in its enemy DNA. Multiplying that by 0x40 was already done in the original code, the only thing we change here is also adding r7, which contains (luck*0x20).

; Fixes how luck affects item drops. With this fixed formula each point of luck gives +0.1% drop chance.
.org 0x021C3B80
  nop
.org 0x021C3BA8
  mov r0, 2000h ; Always use 0x2000 as the max random number to generate, instead of basing it off the player's luck. This makes the calculation simpler.
.org 0x021C3BE4
  mov r0, 2000h
.org 0x021C3BD0
  add r9, r0, r7, lsr 2h ; Add luck*8 to drop chance and put it in r9. r7 currently has luck*0x20 (from before) so we actually divide r7 by 4 to get luck*8.
.org 0x021C3BE0
  moveq r9, r9, lsl 1h ; Double drop chance if rare ring is equipped (same as in the original code).

.close
