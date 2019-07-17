.nds
.relativeinclude on
.erroronwarning on

; This patch for the boss randomizer prevents the boss in Gergoth's tower from being loaded in until the player enters the top floor of the tower.
; In order for the patch to work correctly, the boss entity should be at index 1 and the tower floors entity should be at index 0 (reversed from how they are in vanilla).

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x288

.open "ftc/overlay9_0", 0219E3E0h

.org 0x0219F08C ; Near the end of the create function for object 18 (tower floors)
  b @LoadOrUnloadTowerBoss

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@LoadOrUnloadTowerBoss:
  ldr r1, =020F70CCh ; Pointer to the current room's entity list
  ldr r1, [r1]
  add r1, r1, 11h ; Add 0x11 (0xC + 0x5) to the start of the entity list to get a pointer to the type byte of the second entity in the list, which is the boss entity.
  
  ; The last check done before the custom code was checking if r0 is equal to 0. If it is it means the player is on the top floor of the tower, so the boss should be loaded.
  beq @AllowTowerBossToBeLoaded
@DoNotAllowTowerBossToBeLoaded:
  mov r0, 0h ; Set the type of the boss entity to 0, so it's doesn't load any entity in.
  b @FinishLoadingOrUnloadingTowerBoss
@AllowTowerBossToBeLoaded:
  mov r0, 1h ; Set the type of the boss entity to 0, so it works properly as an enemy.
@FinishLoadingOrUnloadingTowerBoss:
  strb r0, [r1] ; Store the type to the entity list.
  
  ; Replace the code we overwrote to jump here.
  beq 0x0219F0AC ; Return from function if on the top floor.
  b 0x0219F098 ; If not on the top floor, do some other stuff before returning.

.pool

.close
