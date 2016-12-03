.nds
.relativeinclude on
.erroronwarning on

.open "ftc/arm9.bin", 02000000h

; Allow entering any wall with Paries.
.org 0x0207BFC4
  mov r0, 8000h
.org 0x0207C908
  mov r0, 8000h

; Remove line that teleports Shanoa's y position to the last seen Paries wall when entering a wall.
.org 0x0207C09C
  nop

; Move Shanoa left (if entering a left wall) or right (if entering a right wall).
.org 0x0207C094 ; A line that teleports Shanoa's x position to the last seen Paries wall when entering a wall.
  b 020BE440h ; Replace with a jump to our own code below.
.org 0x020BE440 ; Free space.
  ldr r1, [r5, 108h]   ; Load variable for whether Shanoa is touching left/right wall.
  tst r1, 80h          ; Test if Shanoa is touching a right wall.
  ldr r1, [r5, 30h]    ; Load Shanoa's current x pos.
  addne r1, r1, 0A000h ; Increase x pos if Shanoa is touching a right wall.
  subeq r1, r1, 0A000h ; Decrease x pos if she's not.
  str r1, [r5, 30h]    ; Store it back.
  b 0207C098h          ; Go back to where we came from.

; Allow Shanoa to go up/down out of floors/ceilings.
; This is necessary because otherwise walls that are less than 3 blocks tall will cause Shanoa to get permanently stuck with no way to get out.
.org 0x0207C8A4 ; Going up out of a floor.
  nop
.org 0x0207C8C0 ; Going up out of a floor.
  nop
.org 0x0207C8E8 ; Going down out of a ceiling.
  nop
.org 0x0207C900 ; Going down out of a ceiling.
  nop

; Make Shanoa instantly enter/exit the wall when she touches the edge of it, instead of having to hold left/right for half a second.
.org 0x0207C048 ; Entering.
  cmp r0, 2h ; 2 frames delay before entering.
.org 0x0207C98C ; Exiting.
  cmp r0, 1h ; 1 frame delay before exiting.

; Allow Shanoa to go in thin floors/ceilings she normally wouldn't be able to fit in.
.org 0x0207C820
  nop

; Don't require Shanoa to press left or right when exiting out of a floor/ceiling.
.org 0x0207C810
  nop

; Fix Shanoa being teleported left or right when exiting a wall/floor/ceiling, and sometimes being put out of bounds.
.org 0x0207C83C
  nop
.org 0x0207C850
  nop

; Allow Shanoa to exit up/down out of a floor/ceiling, even if the player is still holding up or down on the d-pad.
.org 0x0207C924
  nop

.close
