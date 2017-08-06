.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; When starting a new game, give the player a Magical Ticket.
.org 0x0204E3E8
  ; Potion
  mov r0, 76h
  bl 020633F0h ; GetOwnedItemNum
  cmp r0, 0h
  bne @AfterPotion ; Don't give them if the player already has some (new game+)
  mov r0, 76h
  bl 020635A4h ; GiveItem
  mov r0, 76h ; Give a second one
  bl 020635A4h ; GiveItem
@AfterPotion:
  ; High Tonic
  mov r0, 7Ah
  bl 020633F0h ; GetOwnedItemNum
  cmp r0, 0h
  bne @AfterHighTonic ; Don't give them if the player already has some (new game+)
  mov r0, 7Ah
  bl 020635A4h ; GiveItem
@AfterHighTonic:
  ; Magical Ticket
  mov r0, 7Dh
  bl 020633F0h ; GetOwnedItemNum
  cmp r0, 0h
  bne 0x0204E470 ; Don't give them if the player already has some (new game+)
  mov r0, 7Dh
  bl 020635A4h ; GiveItem

.close

.open "ftc/overlay9_22", 02223E00h

; Remove the line that removes a magical ticket from your inventory when you use it.
.org 0x0222949C
  nop

; Remove the line that restricts you from using magic tickets before reaching the village.
.org 0x02229884
  nop

.close
