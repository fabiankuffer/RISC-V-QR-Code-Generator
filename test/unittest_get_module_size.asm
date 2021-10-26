.include "qr_data.asm"

.text
addi a1, zero, 1
jal ra, get_module_size

#beendet das programm
li a7, 10
ecall	

#muss am ende stehen sonst wird der code dort drin ausgeführt
.include "qr_draw.asm"
