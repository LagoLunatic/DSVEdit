.nds
.relativeinclude on
.erroronwarning on

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start ; Note: This is intentionally put at the same location as "dos_magical_ticket.asm".

.open "ftc/overlay9_0", 0219E3E0h

; This patch should be applied after "dos_magical_ticket.asm".

; When starting a new game, give the player a Magical Ticket.
; There's not enough space so we overwrite the code where it checks if you already have a potion and skips giving you another three (for new game+).
.org 0x021F61D4
  ; Potions
  mov r2, 3h
  bl 021E78F0h ; SetOwnedItemNum
  ; Magical Ticket
  mov r0, 2h
  mov r1, 2Bh
  bl 021E7870h ; GiveItem
  b 021F61F0h

.close

.open "ftc/overlay9_41", @Overlay41Start

; Change the global flags checked to not care that the game hasn't been saved once yet (bit 0x40000000). In its place we check the bit that makes soul drops have a 100% drop chance (bit 0x10000000), so that the player can't use magical tickets during the prologue.
.org @FreeSpace+0x08
  mov r1, 90000007h

; Don't consume magical tickets on use.
.org @FreeSpace+0x7C
  mov r0, 42h ; This is the SFX that will be played on use (needs to be put in a different register compared to "dos_magical_ticket.asm" because the branch destination is different).
  b 0x021EF264 ; Return to the consumable code after the part where it would remove the item from your inventory.

.close
