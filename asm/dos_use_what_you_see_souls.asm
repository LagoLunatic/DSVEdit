.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Automatically equip every soul you get, and don't allow the player to manually change what soul they have equipped.

.org 0x0202E19C
  b 0202E1CCh ; Always take the branch that means the player has 0 of this soul, even if they actually have more.

.org 0x0202E234
  nop ; Don't return from this function yet, pretend this is the first of this soul the player has gotten, whether it is or not.
  nop
  nop

.org 0x0202E1E0 ; Code for displaying the description of the soul when you get it for the first time.
  nop
.org 0x0202E1F4 ; More code like the above.
  nop

.org 0x0202E304
  b 0202E1A0h ; Jump back to the code we skipped which causes the soul name to display in the upper right corner of the screen.

.org 0x0221024C
  mov r1,0h ; Store the number of this type of soul you have as 0. This causes the player's soul inventory to always be empty, so they can't equip anything manually.
  ; TODO this is bad for ability souls

.close
