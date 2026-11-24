# CST-307 Instruction Set Design: ACC-8

**CLC members:** Pisa Ripley, Mathias Alban, Mario Chavez, Ryan Hay

ACC-8 is an instruction set designed for the hypothetical accumulator processor in the CST-307 Instruction Set Design Guide. It has 8-bit accumulators A and B, a 16-bit accumulator D, a 16-bit address bus (A0–A15), an 8-bit data bus (D0–D7), 12 KB of system memory and 52 KB of user memory, and a hexadecimal display controller on an isolated I/O port.

**Repository:** https://github.com/pisaripley/CST-307-Instruction-Set-Design

## Files

| File | Purpose |
|---|---|
| `sensor_avg.asm` | Part B program written in ACC-8 assembly: averages 8 sensor readings, raises an alarm, and shows the result on the hex display |
| `CST-307_Instruction_Set_Design.docx` | Full report: instruction set (Part A), design choices, program and CPUlator screenshots (Part B) |
| `sensor_avg_mips.asm` | The same program translated to MIPS so it runs on CPUlator ($t0 = A, $t1 = B, $t2 = D, $t3 = X) |

## How to run on CPUlator

1. Open https://cpulator.01xz.net/?sys=mipsr5-spim
2. Paste the contents of `sensor_avg_mips.asm` into the Editor.
3. Click **Compile and Load**, then **Continue**.
4. The results appear in the Terminal under Devices.

## Expected Terminal output

```
ACC-8 sensor program (MIPS emulation)
SUM   (D) = 439 000001b7
AVG   (A) = 54
REM   (B) = 7
SHIFT CHECK = OK
CHECKSUM  = 9
ALARM     = 1
HEX DISPLAY (BCD) = 00000054
Done.
```

## Memory map

| Range | Size | Use |
|---|---|---|
| `0x0000–0x2FFF` | 12 KB | System mode: vectors, kernel, system stack |
| `0x3000–0xFFFF` | 52 KB | User mode: programs, data, user stack |
