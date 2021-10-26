.include "qr_data.asm"

.text
#tmp version setzen
la t0, qr_version
li t1, 1
sb t1, 0(t0)

#tmp ecl setzen
la t0, error_correction_level
li t1, 0
sb t1, 0(t0)

#tmp daten setzen
li t3, FINAL_DATA
li t2, 0x41
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x14
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x86
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x56
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xc6
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xc6
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xf2
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xc2
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x07
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x76
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xf7
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x26
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xc6
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x42
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x12
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x03
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x13
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x23
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x30
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x85
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xa9
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x5e
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x07
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x0a
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0x36
sb t2, 0(t3)
addi t3, t3, 1
li t2, 0xc9
sb t2, 0(t3)
addi t3, t3, 1

#zeichnen aufrufen
jal ra, draw

#beendet das programm
li a7, 10
ecall	

#muss am ende stehen sonst wird der code dort drin ausgeführt
.include "qr_draw.asm"
