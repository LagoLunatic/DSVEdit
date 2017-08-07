.nds
.relativeinclude on
.erroronwarning on

@Overlay41Start equ 0x023E0100
@FreeSpace equ 0x023E0100

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021EEF00
  b @FreeSpace

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
  ; Don't let the player use magical tickets during boss fights.
  ldr r0, =020F6DFCh
  ldr r0, [r0] ; Load the bitfield of global flags.
  ldr r1, =0C0040007h ; Check the flags to make sure we're not in the middle of a boss fight, an event, and that the player has saved the game at least once.
  ands r0, r0, r1
  bne 0x021EF0F8 ; Return to the consumable code if any of those bits are set.
  
  mov r0, 0h ; Sector index
  mov r1, 0Ah ; Room index
  mov r2, 78h ; X pos
  mov r3, 9Fh ; Y pos
  bl 02026AD0h ; SetDestinationRoomSectorAndRoomIndexes
  ldr r1, =020F6DF4h
  mov r0, 6h
  strb r0, [r1] ; We set the current type of transition mode (020F6DF4) to 6, meaning a warp of some kind.
  mov r0, 0h
  strb r0, [r1,1h]
  
  ; Enable control of the player, in case they were using the slide puzzle and controls were disabled.
  bl 021F64BCh
  
  ; Below block is copy pasted, it triggers the game to unpause.
  mov     r0,0h
  mvn     r1,0Fh
  mov     r2,8h
  bl      20080DCh
  mov     r2,3h
  ldr     r0,=208AC20h
  strb    r2,[r9,0Dh]
  ldr     r1,[r0]
  ldrb    r0,[r1,8h]
  cmp     r0,17h
  strneb  r2,[r1,0Ah]
  ; Above block is copy pasted, it triggers the game to unpause.
  
  mov r4, 42h ; This tells the rest of the consumable code to use one of the consumable, and play the consumable-used SFX.
  b 0x021EF0F8 ; Return to the consumable code.
  
  .pool

.close
