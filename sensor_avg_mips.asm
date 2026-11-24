# ==========================================================
# Program : ACC-8 Sensor Average (MIPS version for CPUlator)
# Authors : Pisa Ripley, Mathias Alban, Mario Chavez, Ryan Hay
# Course  : CST-307 Instruction Set Design
# Registers: $t0 = A, $t1 = B, $t2 = D, $t3 = X
# ==========================================================

.data
readings:   .byte 42, 55, 61, 48, 70, 39, 58, 66
sum:        .half 0
avg:        .byte 0
status:     .byte 0
chksum:     .byte 0

msg_title:  .asciiz "ACC-8 sensor program (MIPS emulation)\n"
msg_sum:    .asciiz "SUM   (D) = "
msg_avg:    .asciiz "AVG   (A) = "
msg_rem:    .asciiz "REM   (B) = "
msg_chk:    .asciiz "SHIFT CHECK = OK\n"
msg_bad:    .asciiz "SHIFT CHECK = ERROR\n"
msg_xor:    .asciiz "CHECKSUM  = "
msg_alarm:  .asciiz "ALARM     = "
msg_disp:   .asciiz "HEX DISPLAY (BCD) = "
msg_end:    .asciiz "Done.\n"

.text
.globl main
main:
        li    $v0, 4
        la    $a0, msg_title
        syscall

# Sum the readings into D
        move  $t2, $zero
        la    $t3, readings
        li    $t0, 8
sumlp:
        lbu   $t1, 0($t3)
        addu  $t2, $t2, $t1
        andi  $t2, $t2, 0xFFFF
        addiu $t3, $t3, 1
        addiu $t0, $t0, -1
        andi  $t0, $t0, 0xFF
        bne   $t0, $zero, sumlp
        nop
        sh    $t2, sum

# Average = SUM / 8
        li    $t1, 8
        divu  $t2, $t1
        mflo  $t0
        mfhi  $t1
        move  $s0, $t1
        sb    $t0, avg

# Check: SUM >> 3 equals the average
        lhu   $t2, sum
        srl   $t2, $t2, 1
        srl   $t2, $t2, 1
        srl   $t2, $t2, 1
        andi  $t0, $t2, 0xFF
        lbu   $t4, avg
        bne   $t0, $t4, error
        nop

# XOR checksum
        la    $t3, readings
        move  $t0, $zero
        li    $t1, 8
cklp:
        lbu   $t4, 0($t3)
        xor   $t0, $t0, $t4
        addiu $t3, $t3, 1
        addiu $t1, $t1, -1
        bne   $t1, $zero, cklp
        nop
        sb    $t0, chksum

# Alarm if average > 50
        lbu   $t0, avg
        sltiu $t4, $t0, 51
        bne   $t4, $zero, noalarm
        nop
        li    $t0, 1
        j     setst
        nop
noalarm:
        move  $t0, $zero
setst:
        sb    $t0, status

# Convert average to BCD for the display
        lbu   $t0, avg
        li    $t4, 10
        divu  $t0, $t4
        mflo  $t5
        mfhi  $t6
        sll   $t5, $t5, 4
        or    $t0, $t5, $t6
        move  $s1, $t0

# Print results
        li    $v0, 4
        la    $a0, msg_sum
        syscall
        li    $v0, 1
        lhu   $a0, sum
        syscall
        li    $v0, 11
        li    $a0, 32
        syscall
        li    $v0, 34
        lhu   $a0, sum
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall

        li    $v0, 4
        la    $a0, msg_avg
        syscall
        li    $v0, 1
        lbu   $a0, avg
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall

        li    $v0, 4
        la    $a0, msg_rem
        syscall
        li    $v0, 1
        move  $a0, $s0
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall

        li    $v0, 4
        la    $a0, msg_chk
        syscall

        li    $v0, 4
        la    $a0, msg_xor
        syscall
        li    $v0, 1
        lbu   $a0, chksum
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall

        li    $v0, 4
        la    $a0, msg_alarm
        syscall
        li    $v0, 1
        lbu   $a0, status
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall

        li    $v0, 4
        la    $a0, msg_disp
        syscall
        li    $v0, 34
        move  $a0, $s1
        syscall
        li    $v0, 11
        li    $a0, 10
        syscall
        j     done
        nop

error:
        li    $v0, 4
        la    $a0, msg_bad
        syscall

done:
        li    $v0, 4
        la    $a0, msg_end
        syscall
        li    $v0, 10
        syscall
