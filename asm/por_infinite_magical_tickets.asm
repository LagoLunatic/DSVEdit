.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 021CDF60h

; When starting a new game, give the player a Magical Ticket.
; There's not enough space so we overwrite the code where it checks if you already have a high tonic and skips giving you another one (for new game+).
.org 0x021FCA8C
  ; High Tonic
  bl 021E43E4h ; GiveItem
  ; Magical Ticket
  mov r0, 2h
  mov r1, 45h
  bl 021E43E4h ; GiveItem
  b 021FCAA8h

.close

.open "ftc/arm9.bin", 02000000h

; Remove the line that removes a magical ticket from your inventory when you use it.
.org 0x0203A30C
  nop

; Allow use before saving the game once.
.org 0x0203A24C
  ands r0, r0, 80000007h

; Allow use before visiting the shop.
.org 0x0203A26C
  b 0203A27Ch
  
.close
