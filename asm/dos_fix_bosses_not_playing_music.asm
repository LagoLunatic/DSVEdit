.nds
.relativeinclude on
.erroronwarning on

; Fixes the boss rush versions of certain bosses so they play the boss music when they're created.
; This is for the boss randomizer.

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x1F4

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@InitializeEnemyAndOverridePlayBossMusic:
  push r14
  push r1 ; Preserve the music ID
  
  bl 021C34A8h ; InitializeEnemy (replaces the line we overwrote to call this custom function)
  
  pop r0 ; Get the music ID out of the stack
  bl 0202991Ch ; PlaySong
  
  ; Set bit to make the song that was set override the BGM.
  ldr r0, =020F6DFCh
  ldr r1, [r0]
  orr r1, r1, 00040000h
  str r1, [r0]
  
  pop r15

@InitializeEnemyAndOverridePlayBossMusicForFlyingArmor:
  push r14
  ldr r1, =1002h ; Music ID for Evil Invitation
  bl @InitializeEnemyAndOverridePlayBossMusic
  pop r15

@InitializeEnemyAndOverridePlayBossMusic2ForDmitriiAndDario:
  push r14
  ldr r1, =1005h ; Music ID for Scarlet Battle Soul
  bl @InitializeEnemyAndOverridePlayBossMusic
  pop r15

@InitializeEnemyAndOverridePlayBossMusicForZephyr:
  push r14
  
  add r1, r10, 200h
  ldr r1, [r1, 6Eh] ; Read Zephyr's Var A
  cmp r1, 1h ; Normal Zephyr
  beq @ZephyrOnlyInitializeEnemy
  
  ; For boss rush Zephyr, we want to play the music immediately.
  ldr r1, =1003h ; Music ID for Into The Dark Night
  bl @InitializeEnemyAndOverridePlayBossMusic
  b @ZephyrInitializeEnemyEnd
  
  @ZephyrOnlyInitializeEnemy:
  ; For normal Zephyr, we don't want to play music on initialization, or it will bug out because of how he starts the music later.
  bl 021C34A8h ; InitializeEnemy
  
  @ZephyrInitializeEnemyEnd:
  pop r15

@InitializeEnemyAndOverridePlayBossMusicForAguni:
  push r14
  ldr r1, =101Ah ; Music ID for Portal To Dark Bravery
  bl @InitializeEnemyAndOverridePlayBossMusic
  pop r15

.pool

.close

.open "ftc/overlay9_30", 022FF9C0h

; Flying Armor
.org 0x022FFA50
  bl @InitializeEnemyAndOverridePlayBossMusicForFlyingArmor

.close

.open "ftc/overlay9_40", 022FF9C0h

; Dmitrii
.org 0x022FFA54
  bl @InitializeEnemyAndOverridePlayBossMusic2ForDmitriiAndDario

.close

.open "ftc/overlay9_1", 02230A00h

; Dario
.org 0x0225A714
  bl @InitializeEnemyAndOverridePlayBossMusic2ForDmitriiAndDario

.close

.open "ftc/overlay9_33", 022FF9C0h

; Zephyr
.org 0x022FFA80
  bl @InitializeEnemyAndOverridePlayBossMusicForZephyr

.close

.open "ftc/overlay9_1", 02230A00h

; Aguni
.org 0x02243C98
  bl @InitializeEnemyAndOverridePlayBossMusicForAguni

.close
