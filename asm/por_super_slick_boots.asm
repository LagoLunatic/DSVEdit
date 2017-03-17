.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 021CDF60h

; Makes the player slide very far and fast when the Slick Boots are equipped.

.org 0x02204DD0 ; In the slide code for when the player has Slick Boots equipped. It multiplies the player's base slide speed by 1.125.
  mov r1, 3h
  mul r0, r0, r1 ; Multiply by 3 instead.
  nop
  nop

.close
