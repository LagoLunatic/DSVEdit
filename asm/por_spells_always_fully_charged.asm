.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 021CDF60h

; This patch makes Charlotte always use spells at full power, even when only half-charged.

.org 0x02214DC8 ; Where the base multiplier for a spell is located (usually 1).
  addne r2, r4, 2h ; Change it to 2.

.org 0x021F1C40 ; Where the bonus multiplier you get for fully charging a spell is located (usually 1).
  movge r0, 0h ; Change it to 0. This is so fully charging a spell won't get a 3x multiplier, and instead it will stay at simply 2x (fully charged).
; You can remove the above two lines if you want fully charged spells to have a 3x multiplier, which actually does work correctly, making spells do 3x damage, and depending on the spell can even do other things like increasing the number of projectiles or the size of the projectiles past the normal limit.
; There are a few minor bugs if you choose to have spells with a 3x multiplier. For example, Spirit of Light will fire only 1 projectile instead of 3 like you'd expect, Ice Needles will all be grouped together instead of spread out among a circle, and Nightmare will use the smaller size instead of the bigger one.

.close
