.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_22", 02223E00h

.org 0x02231A94 ; In Object89Create, for the generic villager in Torpor object
  .word 0x67F ; Fix the text ID for George to say when you rescue him. Originally it was a random garbage number (44010217) instead of this correct number.

.close
