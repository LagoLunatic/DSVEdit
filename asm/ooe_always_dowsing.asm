.nds
.relativeinclude on
.erroronwarning on

; Always have the Dowsing Hat effect of beeping when there's a hidden blue chest, even if you don't have Dowsing Hat equipped.

.open "ftc/overlay9_19", 021FFFC0h

.org 0x0221AE30 ; Where the blue chest loads your currently equipped head armor.
  mov r0, 7h ; Dowsing Hat

.close
