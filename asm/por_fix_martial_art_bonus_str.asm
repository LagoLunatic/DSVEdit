.nds
.relativeinclude on
.erroronwarning on

; In vanilla PoR Martial Art does not take bonus STR (e.g. from STR Boost) into account when calculating its damage.
; This patch causes it to take bonus STR into account.

.open "ftc/overlay9_0", 021CDF60h

.org 0x022176CC
  ldrsh r1, [r4, 18h] ; Load bonus STR from 02111FEC
  add r0, r0, r1 ; Add base STR (already in r0) to bonus STR
  mov r0, r0, lsl 1h ; Double the strength value to get the damage martial art should do (same as in vanilla, except in vanilla it used float multiplication instead of shifting)
  nop
  nop

.close
