.nds
.relativeinclude on
.erroronwarning on

; Makes breakable walls always have the glow visual.

.open "ftc/overlay9_22", 02223E00h

.org 0x02297C7C ; Where the breakable wall loads your currently equipped head armor.
  mov r0, 1h ; Eye for Decay

.close
