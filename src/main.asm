.include "qr_data.asm"

.text
#tmp version setzen
la t0, qr_version
li t1, 5
sb t1, 0(t0)

#tmp ecl setzen
la t0, error_correction_level
li t1, 3
sb t1, 0(t0)

#tmp daten setzen
#text: "Hallo ich bin"
#ecl und qr version siehe oben
##########################################################################################################################################
li t0, MESSAGE_CODEWORD_ADDRESS
li t1, 0
li t2, 46
la t3, p2_message
p2_data_start:
lbu t4, (t3)
sb t4, (t0)
addi t0, t0, 1
addi t3, t3, 1
addi t1, t1, 1
blt t1, t2, p2_data_start
li gp, FINAL_DATA
##########################################################################################################################################

#call encoding
jal ra, p2_start

#zeichnen aufrufen
jal ra, draw

#beendet das programm
li a7, 10
ecall	

#muss am ende stehen sonst wird der code dort drin ausgeführt
.include "generate_error-correction.asm"
.include "qr_draw.asm"
