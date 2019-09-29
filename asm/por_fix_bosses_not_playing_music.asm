.nds
.relativeinclude on
.erroronwarning on

; Fixes the boss rush versions of certain bosses so they play the boss music when they're created.
; This is for the boss randomizer.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x4C0

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@InitializeEnemyAndOverridePlayBossMusic:
  push r14
  push r1 ; Preserve the music ID
  
  bl 021D9184h ; InitializeEnemyFromDNA (replaces the line we overwrote to call this custom function)
  
  pop r0 ; Get the music ID out of the stack
  bl 0204D374h ; PlaySongWithVariableUpdatesExceptInBossRush
  
  ; Set bit to make the song that was set override the BGM.
  ldr r0, =0211174Ch
  ldr r1, [r0]
  orr r1, r1, 00040000h
  str r1, [r0]
  
  pop r15

@InitializeEnemyAndOverridePlayBossMusicForLegion:
  push r14
  mov r1, 12h ; Music ID for Destroyer
  bl @InitializeEnemyAndOverridePlayBossMusic
  pop r15

.pool

.close

.open "ftc/overlay9_52", 022D7900h

; Legion
.org 0x022D7A24
  bl @InitializeEnemyAndOverridePlayBossMusicForLegion

.close

.open "ftc/overlay9_64", 022D7900h

; Death
.org 0x022D7BD0
  ; This line usually prevented the code for starting the boss music from running in Jonathan mode.
  ; Just remove it.
  nop

.close

.open "ftc/overlay9_63", 022D7900h

; Stella
.org 0x022D7A4C
  ; This line usually prevented the code for starting the boss music from running in Jonathan mode.
  ; Just remove it.
  nop

.close
