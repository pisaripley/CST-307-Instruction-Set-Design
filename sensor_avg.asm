;=====================================================================
; Program   : SENSOR_AVG.ASM - Sensor average with hex-display output
; Processor : ACC-8 (accumulators A, B = 8-bit, D = 16-bit)
; Course    : CST-307 Computer Architecture - Instruction Set Design
; Authors   : Pisa Ripley, Mathias Alban, Mario Chavez, Ryan Hay
;
; Purpose   : Eight 8-bit temperature readings are stored in user
;             memory. The program
;               1. sums them into a 16-bit total in D   (data transfer,
;                  indexed addressing, arithmetic)
;               2. divides by 8 to get the average       (DIV)
;               3. cross-checks the average with three   (logical shifts,
;                  right shifts of the sum                conversion)
;               4. computes an XOR checksum of the data  (logical)
;               5. raises an alarm if average > 50       (compare/branch)
;               6. converts the average to BCD and shows (conversion,
;                  it on the two-digit hex display        subroutine, I/O)
;             User code cannot touch I/O ports directly: it asks the
;             system-mode kernel through SYSCALL, which is how the
;             12 KB system / 52 KB user partition is enforced.
;
; Memory map: 0x0000-0x2FFF  SYSTEM (12 KB): vectors, kernel, system stack
;             0x3000-0xFFFF  USER   (52 KB): program, data, user stack
; I/O ports : 0x00 = hexadecimal display controller (2 digits)
;             0x01 = alarm LED (bit 0)
;=====================================================================

COUNT     EQU 8            ; number of readings
THRESH    EQU 50           ; alarm threshold (degrees)
DISP      EQU 0x00         ; I/O port: hex display controller
LED       EQU 0x01         ; I/O port: alarm LED
SYS_EXIT  EQU 0            ; SYSCALL service numbers
SYS_SHOW  EQU 1
SYS_LED   EQU 2

;---------------------------------------------------------------------
; SYSTEM MODE AREA (0x0000-0x2FFF) - only reachable when S = 1
;---------------------------------------------------------------------
          ORG 0x0000
          .word RESET_H    ; 0x0000 reset vector
          .word IRQ_H      ; 0x0002 hardware interrupt vector
          .word FAULT_H    ; 0x0004 memory-protection fault vector
          .word FAULT_H    ; 0x0006 illegal/privileged opcode vector

          ORG 0x0020       ; SYSCALL vector table (service n at 0x0020+2n)
          .word K_EXIT     ; SYSCALL #0  end the user program
          .word K_SHOW     ; SYSCALL #1  write A to the hex display
          .word K_LED      ; SYSCALL #2  write A to the alarm LED

          ORG 0x0100
RESET_H:  LDS   #0x2FFF    ; system stack at top of the 12 KB system area
          LDUSP #0xEFFF    ; user stack below the user data area
          CLRA
          OUT   DISP,A     ; blank display shows "00"
          OUT   LED,A      ; alarm LED off
          LDD   #START     ; build a return frame to enter user mode:
          PSHD             ;   PC = START (user program entry)
          CLRA             ;   CCR = 0x00 -> S = 0 (user), I = 0
          PSHA
          RTI              ; "return" into user mode at START

K_SHOW:   OUT   DISP,A     ; privileged I/O done on the user's behalf
          RTI
K_LED:    OUT   LED,A
          RTI
K_EXIT:   HLT              ; stop the processor (end of run)

IRQ_H:    RTI              ; no interrupt sources used in this program
FAULT_H:  LDA   #0xEE      ; show "EE" (error) on the display and stop
          OUT   DISP,A
          HLT

;---------------------------------------------------------------------
; USER MODE AREA (0x3000-0xFFFF)
;---------------------------------------------------------------------
          ORG 0x3000
START:
; --- 1. Sum the readings into 16-bit D --------------------------------
          CLRD             ; D = running total (16 bits: sum can exceed 255)
          LDX   #READINGS  ; X points at the first reading
          LDA   #COUNT     ; A = loop counter
SUMLP:    LDB   0,X        ; B = reading[i]       (indexed addressing)
          ABD              ; D = D + B            (8-bit into 16-bit)
          INX              ; next element
          DECA             ; counter - 1, sets Z when done
          BNE   SUMLP      ; loop until all COUNT readings added
          STD   SUM        ; save 16-bit total (big-endian)

; --- 2. Average = SUM / COUNT -----------------------------------------
          LDB   #COUNT
          DIV   D,B        ; A = quotient (average), B = remainder
          BVS   ERROR      ; V = 1 would mean divide error/overflow
          STA   AVG

; --- 3. Cross-check: SUM >> 3 must equal the average (8 = 2^3) --------
          LDD   SUM
          SHRD             ; /2
          SHRD             ; /4
          SHRD             ; /8
          CVTDA            ; A = low byte of D; V = 1 if high byte not 0
          CMPA  AVG
          BNE   ERROR      ; mismatch -> hardware/logic error

; --- 4. XOR checksum of the readings ------------------------------------
          LDX   #READINGS
          CLRA             ; A = checksum
          LDB   #COUNT     ; B = loop counter
CKLP:     EORA  0,X        ; A = A XOR reading[i]
          INX
          DECB
          BNE   CKLP
          STA   CHKSUM

; --- 5. Alarm if average > THRESH (unsigned compare) ------------------
          LDA   AVG
          CMPA  #THRESH
          BLS   NOALARM    ; average <= threshold -> no alarm
          LDA   #0x01      ; bit 0 = alarm
          BRA   SETST
NOALARM:  CLRA
SETST:    STA   STATUS
          SYSCALL #SYS_LED ; kernel writes A to the LED port

; --- 6. Show the average in decimal on the hex display ----------------
          LDA   AVG
          JSR   SHOWDEC
          SYSCALL #SYS_EXIT ; done

ERROR:    LDA   #0xEE
          SYSCALL #SYS_SHOW
          SYSCALL #SYS_EXIT

;---------------------------------------------------------------------
; SHOWDEC - display A (0-99) as two decimal digits
;   In : A = binary value   Out: display updated   Saves: B
;---------------------------------------------------------------------
SHOWDEC:  PSHB             ; preserve caller's B on the user stack
          BCDA             ; 54 (0x36) -> 0x54 so the hex digits read "54"
          BVC   SHOWOK
          LDA   #0xEE      ; value > 99 cannot be shown in two digits
SHOWOK:   SYSCALL #SYS_SHOW
          PULB
          RTS

;---------------------------------------------------------------------
; USER DATA
;---------------------------------------------------------------------
          ORG 0x4000
READINGS: .byte 42, 55, 61, 48, 70, 39, 58, 66
SUM:      .word 0
AVG:      .byte 0
STATUS:   .byte 0
CHKSUM:   .byte 0
