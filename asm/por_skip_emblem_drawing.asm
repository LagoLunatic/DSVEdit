.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_25", 022D7900h

; Skip the screen where the player has to draw an emblem and press OK when starting a new game.

.org 0x022DAAB0 ; Code in the name entry menu after you finished typing in your name that would normally take you to the emblem drawing screen next.
  mov r11, 19h ; We set the return value to 0x19, which is the state for the scrolling prologue introduction.
  nop
  nop
  nop
  nop
  nop
  nop

.close
