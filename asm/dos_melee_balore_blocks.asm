.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so that all melee weapons can break balore blocks, not just Julius's whip.

.org 0x02212AB0 ; Branch of a switch statement taken for all melee weapons except Julius's whip.
  b 02212D64h ; Instead take the branch taken for Julius's whip.

.close
