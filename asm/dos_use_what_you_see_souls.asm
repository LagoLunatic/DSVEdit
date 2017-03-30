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

.close

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021F31EC ; Code that checks if the current equip menu has no entries in it. If it does, it doesn't let the player change equipment.
  ldr r1, [r0,80h]
  cmp r1, 0Bh ; Instead we check if the current equip menu is the item menu.
  bne 021F3288h ; If it's not the item menu we don't let the player access this menu. This lets the player still change their equipped items, but not their equipped souls.

; TODO when you enter a save/warp room for the first time it also shows the tutorial for all three types of souls. disable setting those flags to begin with.

; TODO getting doppelganger gives you malphas for some reason, even if you have balore. this may be related to the tutorial shown in the save/warp room.

.close

; Make it so that bosses that drop red/blue/yellow souls required for progression don't stay dead. This is so the player can go back and fight them again if they lose a soul they need.
; We do this by deleting the lines that set the boss death flags for each boss.
.open "ftc/overlay9_30", 022FF9C0h ; Flying Armor
.org 0x02300BBC
  nop
.close
.open "ftc/overlay9_25", 022FF9C0h ; Puppet Master
.org 0x022FFDC8
  nop
.org 0x022FFF4C
  nop
.close
.open "ftc/overlay9_33", 022FF9C0h ; Zephyr
.org 0x0230155C
  nop
.close
.open "ftc/overlay9_37", 022FF9C0h ; Bat Company
.org 0x022FFF3C
  nop
.close
.open "ftc/overlay9_35", 022FF9C0h ; Paranoia
.org 0x0230572C
  nop
.close
