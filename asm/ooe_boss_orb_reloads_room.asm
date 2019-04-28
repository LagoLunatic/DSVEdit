.nds
.relativeinclude on
.erroronwarning on

; This patch makes it so getting a boss orb in Mystery Manor or Ecclesia will reload the room.
; This is because the cutscene after beating Albus/Barlowe won't play until the room is reloaded.
; Albus/Barlowe normally reload the room on defeat, but in boss randomizer something else needs to do it.

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ @Overlay86Start + 0x48

.open "ftc/arm9.bin", 02000000h

.org 0x02061254 ; At the end of the function for the boss orb being picked up
  b @BossOrbCheckReloadRoom

.close

.open "ftc/overlay9_86", @Overlay86Start ; Free space overlay

.org @FreeSpace
@BossOrbCheckReloadRoom:
  ldr r0, =02100790h
  ldrb r0, [r0] ; Read the current game mode
  cmp r0, 0h ; Shanoa mode
  bne @BossOrbCheckReloadRoomEnd
  
  ldr r0, =020FFCB9h
  ldrb r0, [r0] ; Read the current area index
  cmp r0, 0Eh ; Mystery Manor
  beq @BossOrbReloadRoomMysteryManor
  cmp r0, 2h ; Ecclesia
  bne @BossOrbCheckReloadRoomEnd

@BossOrbReloadRoomEcclesia:
  mov r0, 2h ; Area, Ecclesia
  mov r1, 0h ; Sector
  mov r2, 6h ; Room
  b @BossOrbReloadRoom

@BossOrbReloadRoomMysteryManor:
  mov r0, 0Eh ; Area, Mystery Manor
  mov r1, 0h ; Sector
  mov r2, 9h ; Room

@BossOrbReloadRoom:
  mov r3, 0C0h ; X pos
  mov r4, 0B0h ; Y pos
  str r3, [r13]
  bl 0203AFD0h ; TeleportPlayer
  bl 0203B014h ; TriggerRoomTransition

@BossOrbCheckReloadRoomEnd:
  ; Return to the normal boss orb code
  add r13, r13, 34h ; Replace line overwritten to jump here
  b 2061258h
  .pool

.close
