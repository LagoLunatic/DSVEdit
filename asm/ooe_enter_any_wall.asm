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

.org 0x0207C9B0 ; A line that always teleports Shanoa to the left when exiting a wall.
  b 020BE45Ch ; Replace with a jump to our own code below.
.org 0x020BE45C ; More free space.
  ldr r0, [r5, 104h]   ; Load variable for whether Shanoa is exiting a left/right wall.
  tst r0, 4h           ; Test if Shanoa is exiting a left wall.
  ldr r0, [r5, 30h]    ; Load Shanoa's current x pos.
  addne r0, r0, 0A000h ; Increase x pos if Shanoa is exiting a left wall.
  subeq r0, r0, 0A000h ; Decrease x pos if she's not.
  str r0, [r5, 30h]    ; Store it back.
  b 0207C9B4h          ; Go back to where we came from.

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

; Make Shanoa instantly exit Paries mode when she goes above/below the wall, instead of needing to press left/right.
.org 0x0207C808
  mov r0, 1h

; Allow Shanoa to exit up/down out of a floor/ceiling, even if the player is still holding up or down on the d-pad.
.org 0x0207C924
  nop

.close
