.include "qr_data.asm"
.data
message: .byte 0x40 0xD4 0x86 0x56 0xC6 0xC6 0xF2 0xC2 0x07 0x76 0xF7 0x26 0xC6 0x42 0x10 0xEC
expected_ECC: .byte 0x9C 0x4D 0x2E 0x6D 0x6C 0xEC 0x9B 0x4B 0x30 0x5E

.text
li gp, EC_CODEWORD_ADDRESS

#load message from message array to MESSAGE_CODEWORD_ADDRESS buffer
li t1, 16				#t1: number of message bytes
li t6, MESSAGE_CODEWORD_ADDRESS		#t2: message destination
la t5, message				#t5: message source
add t0, zero, zero			#t0: number of bytes loaded
load_message:
	beq t0, t1, load_message_end
	lbu t2, (t5)
	sb t2, (t6)
	addi t5, t5, 1
	addi t6, t6, 1
	addi t0, t0, 1
	beq zero, zero, load_message
load_message_end:

#run
li a1, MESSAGE_CODEWORD_ADDRESS		#arg: message adress
li a2, 10				#arg: number of error correction codes
li a3, EC_CODEWORD_ADDRESS		#arg: target adress
li a4, 16				#arg: number of message bytes
jal ra, p2_calc_error_correction_code

#test wether the content of EC_CODEWORD_ADDRESS buffer is equal to expected_ECC
li t1, 10				#t1: number of error bytes to test
li t2, EC_CODEWORD_ADDRESS		#t2: adress of buffer where output of the function is located
la t3, expected_ECC			#t3: adress where expected output is stored
add t0, zero, zero			#t0: number of bytes tested
add a0, zero, zero			#a0: number of errors
test_ecc:
	beq t0, t1, test_ecc_end
	lbu t4, (t2)
	lbu t5, (t3)
	beq t4, t5, correct_result
	addi a0, a0, 1
	correct_result:
	addi t2, t2, 1
	addi t3, t3, 1
	addi t0, t0, 1
	beq zero, zero, test_ecc
test_ecc_end:

#ends test
li a7, 10
ecall

#includes file that contains the function that should be tested
.include "qr_generate-error-correction.asm"
