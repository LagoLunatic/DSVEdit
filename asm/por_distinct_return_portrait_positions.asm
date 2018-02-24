.nds
.relativeinclude on
.erroronwarning on

; Normally when you go through a portrait, you are placed at a hardcoded X/Y position (usually 0x80,0xA0). This is difficult to change.
; This patch recodes the way portraits decide the X/Y position to put you at so that return portraits read from an easily changeable list.
; Portraits other than return portraits still use the usual hardcoded positions.
; In order to distinguish between return portraits and regular portraits, bit 0x8000 of the portrait's var B is set for return portraits by the randomizer.
; Using that bit doesn't interfere with the sector/room indexes, which only use the 10 lowest bits of var B.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0xBC

.open "ftc/arm9.bin", 02000000h

.org 0x02079874 ; Code that would normally call TeleportPlayer to bring the player to the destination.
  bl @TeleportPlayerWithProperPosition

.close

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@TeleportPlayerWithProperPosition:
  push r0-r3 ; Preserve arguments r0-r3 to TeleportPlayer
  push r14
  sub r13, r13, 4h
  
  ; First check the highest bit of var B.
  ; If it's set, this is a return portrait.
  add r0, r5, 100h
  ldrh r0, [r0, 3Eh] ; Var B
  ands r0, 8000h
  bne @TeleportPlayerWithReturnPosition
  
  ; But if it's not set, we don't modify dest x/y at all, we just teleport the player and return.
  ldr r0, [r13,18h] ; Load Y pos
  str r0, [r13] ; Store Y pos as argument [r13] to TeleportPlayer
  ldr r0, [r13, 8h] ; Load argument r0 to TeleportPlayer
  ldr r1, [r13, 0Ch] ; Load argument r1 to TeleportPlayer
  ldr r2, [r13, 10h] ; Load argument r2 to TeleportPlayer
  ldr r3, [r13, 14h] ; Load X pos as argument r3 to TeleportPlayer
  bl 02032D90h ; TeleportPlayer
  add r13, r13, 4h
  pop r14
  pop r0-r3
  bx r14
  
@TeleportPlayerWithReturnPosition:
  ldr r0, =@ReturnXAndYPositionsForEachArea
  ldr r1, =02111785h
  ldrb r1, [r1] ; Current area index
  mov r2, r1, lsl 2h ; List ReturnXAndYPositionsForEachArea has entry length 4 (two halfwords for each area)
  add r0, r0, r2
  ldrh r3, [r0] ; Load X pos as argument r3 to TeleportPlayer
  ldrh r0, [r0, 2h] ; Load Y pos
  str r0, [r13] ; Store Y pos as argument [r13] to TeleportPlayer
  
  ldr r0, [r13, 8h] ; Load argument r0 to TeleportPlayer
  ldr r1, [r13, 0Ch] ; Load argument r1 to TeleportPlayer
  ldr r2, [r13, 10h] ; Load argument r2 to TeleportPlayer
  bl 02032D90h ; TeleportPlayer
  
  add r13, r13, 4h
  pop r14
  pop r0-r3
  bx r14
  .pool
@ReturnXAndYPositionsForEachArea:
  ; List of X and Y positions for each area's return portrait to put you at.
  .halfword 0x80,0xA0 ; Dracula's Castle
  .halfword 0x80,0xA0 ; City of Haze
  .halfword 0x80,0xA0 ; 13th Street
  .halfword 0x80,0xA0 ; Sandy Grave
  .halfword 0x80,0xA0 ; Forgotten City
  .halfword 0x80,0xA0 ; Nation of Fools
  .halfword 0x80,0xA0 ; Burnt Paradise
  .halfword 0x80,0xA0 ; Forest of Doom
  .halfword 0x80,0xA0 ; Dark Academy
  .halfword 0x80,0xA0 ; Nest of Evil
  .halfword 0x80,0xA0 ; Boss Rush
  .halfword 0x80,0xA0 ; Lost Gallery

.close
