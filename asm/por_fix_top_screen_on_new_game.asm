.nds
.relativeinclude on
.erroronwarning on

; This patch changes the top screen shown when you start a new game to be the map screen instead of the cross with inverted bat wings.

.open "ftc/overlay9_0", 021CDF60h

; When starting a new game, change the top screen to 0, the map.
; There's not enough space so we overwrite the code where it checks if you already have a potion and skips giving you another one (for new game+).
.org 0x021FCA68
  ; Give potion
  bl 021E43E4h ; GiveItem
  ; Change top screen
  mov r0, 0h ; Top screen type to set
  bl 020557C8h ; SetTopScreen
  b 021FCA84h

.close
