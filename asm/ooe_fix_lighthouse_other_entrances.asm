.nds
.relativeinclude on
.erroronwarning on

; If the player enters the lighthouse from one of the top doors while Brachyura is still alive, they would normally get softlocked.
; This patch teleports the player to the bottom of the room in that case so they can fight Brachyura as normal.
; Also, if the player enters it from the bottom right door the wall there would softlock the player and prevent them from entering, so that wall is removed.

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ 0x022EB1A0

.open "ftc/overlay9_53", 022C1FE0h

.org 0x022C3A68 ; Code that runs if misc flag 0 is not set, before initializing the breakable ceilings.
  b @TeleportPlayerIfAtTop

.org 0x022C331C ; Code that calls GetEntitySlot to create the right wall.
  mov r0, 0h ; Don't create the right wall.

.close

.open "ftc/overlay9_86", @Overlay86Start ; Free space overlay

.org @FreeSpace
@TeleportPlayerIfAtTop:
  ldr r0, =02109850h
  ldr r1, [r0, 4h] ; Load player's Y
  cmp r1, 9C0h*1000h
  movlt r2, 0A70h*1000h
  strlt r2, [r0, 4h] ; If the player's Y is < 9C0 teleport them to the bottom of the room. This is in case they entered from one of the top doors.
  movlt r2, 80h*1000h
  strlt r2, [r0] ; Also change the player's X to be in the middle of the room.
  
  ldr r0, =022CD3F4h ; Replaces the line of code we overwrote to jump to free space
  b 022C3A6Ch ; Return
  .pool

.close
