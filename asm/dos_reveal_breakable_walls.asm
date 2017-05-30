.nds
.relativeinclude on
.erroronwarning on

; Makes breakable walls always have the glow visual.

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021A383C ; Where the breakable wall loads the bitfield of passive effects on the player.
  mov r0, 100h ; Peeping eye bit

.close
