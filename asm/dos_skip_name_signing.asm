.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Skip the screen where the player has to sign their name and press OK when starting a new game.

.org 0x02045E8C ; Code that sets the name signing menu's state to 3 after zeroing out the name pixel data.
  movne r0, 6h ; Instead set the state to 6, meaning the state where the player has pressed OK and the new game is now starting.

.org 0x02045E78 ; Code that displays the name signing menu on the screen.
  nop ; Delete it to prevent the name signing screen from being visible for a split second when starting a new game.

.close
