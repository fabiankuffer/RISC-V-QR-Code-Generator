.include "qr_data.asm"
.data
message: .byte 0x40 0xD4 0x86 0x56 0xC6 0xC6 0xF2 0xC2 0x07 0x76 0xF7 0x26 0xC6 0x42 0x10 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC 0x11 0xEC
expected_zipped: .byte 0x40 0x26 0x11 0x11 0xD4 0xC6 0xEC 0xEC 0x86 0x42 0x11 0x11 0x56 0x10 0xEC 0xEC 0xC6 0xEC 0x11 0x11 0xC6 0x11 0xEC 0xEC 0xF2 0xEC 0x11 0x11 0xC2 0x11 0xEC 0xEC 0x07 0xEC 0x11 0x11 0x76 0x11 0xEC 0xEC 0xF7 0xEC 0x11 0x11 0xEC 0xEC

.text
li gp, FINAL_DATA

#load message from message array to MESSAGE_CODEWORD_ADDRESS buffer
li t1, 46				#t1: number of message bytes
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

#run first short block
li a1, 0				#arg: offset
li a2, MESSAGE_CODEWORD_ADDRESS		#arg: source
li a3, 11				#arg: bytes in full block
li a4, 4				#arg: number of full blocks
li a5, 2				#arg: number of long blocks
li a6, 11				#arg: bytes in long block
jal ra, p2_zip_to_final_data

#run second short block
li a1, 1				#arg: offset
li t0, MESSAGE_CODEWORD_ADDRESS
addi t0, t0, 11
add a2, t0, zero				#arg: source
li a3, 11				#arg: bytes in full block
li a4, 4				#arg: number of full blocks
li a5, 2				#arg: number of long blocks
li a6, 11				#arg: bytes in long block
jal ra, p2_zip_to_final_data

#run first long block
li a1, 2				#arg: offset
li t0, MESSAGE_CODEWORD_ADDRESS
addi t0, t0, 22
add a2, t0, zero			#arg: source
li a3, 11				#arg: bytes in full block
li a4, 4				#arg: number of full blocks
li a5, 2				#arg: number of long blocks
li a6, 12				#arg: bytes in long block
jal ra, p2_zip_to_final_data

#run first long block
li a1, 3				#arg: offset
li t0, MESSAGE_CODEWORD_ADDRESS
addi t0, t0, 34
add a2, t0, zero			#arg: source
li a3, 11				#arg: bytes in full block
li a4, 4				#arg: number of full blocks
li a5, 2				#arg: number of long blocks
li a6, 12				#arg: bytes in long block
jal ra, p2_zip_to_final_data


#test wether the content of EC_CODEWORD_ADDRESS buffer is equal to expected_ECC
li t1, 46				#t1: number of bytes to test
li t2, FINAL_DATA			#t2: adress of buffer where output of the function is located
la t3, expected_zipped			#t3: adress where expected output is stored
add t0, zero, zero			#t0: number of bytes tested
add a0, zero, zero			#a0: number of errors
test_zip:
	beq t0, t1, test_zip_end
	lbu t4, (t2)
	lbu t5, (t3)
	beq t4, t5, correct_result
	addi a0, a0, 1
	correct_result:
	addi t2, t2, 1
	addi t3, t3, 1
	addi t0, t0, 1
	beq zero, zero, test_zip
test_zip_end:

#ends test
li a7, 10
ecall

#includes file that contains the function that should be tested
.include "qr_generate-error-correction.asm"