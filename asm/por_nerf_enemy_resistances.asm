.nds
.relativeinclude on
.erroronwarning on

; This patch makes resistances in PoR act like resistances in DoS and OoE.
; In vanilla PoR, if an enemy resists even one element of an attack, it will resist the attack.
; This changes it so the enemy must resist all elements of the attack to resist the attack.

.open "ftc/overlay9_0", 021CDF60h

.org 0x021DA1F8
  mvn r0, r5 ; Negate the bitfield of resistances.
  and r0, r0, r7 ; AND the attack's damage types with the negated resistances to find what elements were not resisted.
  ands r0, r0, 0FFh ; Only consider the first 8 resistances. Others have no effect.
  bne 021DA224h ; If any elements were not resisted, do not resist the attack.
  mov r0, r1, asr 1h ; Resisted, so halve the damage. (This was originally a float multiply by 0.5x, but we used up too much space so simplify it to a shift instead.)
  nop
  nop
  nop

.close
