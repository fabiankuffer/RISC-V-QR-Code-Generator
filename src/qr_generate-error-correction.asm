##########################################################################################################################################
#starts part 2 of the qr code generation: calculating the error correction codes and formatting the message
p2_start:

	#store callee saved register
	addi sp, sp, -20
	sw s1, 0(sp)
	sw s2, 4(sp)
	sw s3, 8(sp)
	sw s4, 12(sp)
	sw ra, 16(sp)

	#get qr version
	la t0, qr_version
	lbu s1, (t0)									#s1: qr version

	#get error correction level
	la t0, error_correction_level
	lbu s2, (t0)									#s2: error correction level

	#calculate adress of correct partitioning adress and the number of error correction codes
	addi t0, s1, -1
	slli t0, t0, 4
	slli t1, s2, 2
	add t2, t1, t0
	la s3, block_partitioning
	add s3, s3, t2									#s3: correct partitioning adress

	#calculate the number of error correction codes
	addi t0, s1, -1
	slli t0, t0, 2
	add t1, t0, s2
	la s4, number_of_ecls
	add s4, s4, t1
	lbu s4, (s4)									#s4: number of error correction codes

	#start encoding the message
	add a1, s3, zero
	add a3, s4, zero
	jal ra, p2_encode
	
	#restore callee saved register
	lw s1, 0(sp)
	lw s2, 4(sp)
	lw s3, 8(sp)
	lw s4, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20

	#return to main
	jalr zero, 0(ra)
##########################################################################################################################################

	
##########################################################################################################################################
#encodes the information in the data adress and stores it in the encoded adress
p2_encode:
	
	#store callee saved register
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s3, 8(sp)
	sw s4, 12(sp)
	sw s5, 16(sp)
	sw s7, 20(sp)
	sw s8, 24(sp)
	sw s9, 28(sp)
	sw s10, 32(sp)
	sw s11, 36(sp)
	sw ra, 40(sp)
	
	#Load function arguments
	add s1, zero, a1							#s1: partitioning adress
	add s3, zero, a3							#s3: number of error codewords per block
	
	#calculate overall number of blocks
	lbu t1, 0(s1)
	lbu t2, 2(s1)
	add s7, t1, t2								#s7: overall number of blocks
	
	#initialize block counter
	li s8, 0								#s8: offset to final data for current block
	
	#iterator of outer loop
	li s11, 1								#s11: current group (iterator of p2_encode_loop_groups)
	
	#iterate through both groups
	p2_encode_loop_groups:
		#calculate partitioning adress for the current group
		addi s10, s11, -1
		slli s10, s10, 1
		add s10, s1, s10						#s10: adress of the partition table for the current group
		
		#prevent loop from reading data when the current group doesnt have blocks
		lbu t1, 0(s10)
		beqz t1, p2_encode_end
		
		#iterator of inner loop
		li s9, 1							#s9: current block, iterator of block loop
		
		#iterate through all blocks in the current group
		p2_encode_loop_blocks:
			#get the message adress of the current block
			add a1, zero, s11
			add a2, zero, s9
			lb a3, 0(s1)
			lb a4, 1(s1)
			lb a5, 1(s10)
			jal ra, p2_get_adress_of_message_block
			add s4, a0, zero					#s4: message adress of the current block
			
			#get the errorcode adress of the current block
			add a1, zero, s11
			add a2, zero, s9
			lb a3, 0(s1)
			add a4, s3, zero
			jal ra, p2_get_adress_of_errorcode_block
			add s5, a0, zero					#s5: errocode adress of the current block
			
			#add message to final data
			add a1, s8, zero
			add a2, s4, zero
			lbu a3, 1(s1)
			add a4, s7, zero
			lbu a5, 2(s1)
			lbu a6, 1(s10)
			jal ra, p2_zip_to_final_data
			
			#encode and save the error correction for the current block
			lb t0, 0(s1)
			add t1, s8, t0 
			add a1, s4, zero
			add a2, s3, zero
			add a3, s5, zero
			lbu a4, 1(s10)
			jal ra, p2_calc_error_correction_code
			
			#get the offset to final data where the errror codes should be stored
			lbu t0, 0(s1)
			lbu t1, 1(s1)
			mul t2, t1, t0
			lbu t0, 2(s1)
			lbu t1, 3(s1)
			mul t3, t1, t0
			add t4, t3, t2
			
			#add error correction code to final data
			add a1, s8, t4
			add a2, s5, zero
			add a3, s3, zero
			add a4, s7, zero
			add a5, s7, zero
			add a6, s3, zero
			jal ra, p2_zip_to_final_data
			
			#condition: only loop when the current block iterator is less or equal than the number of blocks in the current group defined by the partition table
			lb t1, 0(s10)
			addi s9, s9, 1
			addi s8, s8, 1	
			ble s9, t1, p2_encode_loop_blocks
			
		#condition: only loop through both groups
		li, t6, 2
		addi s11, s11, 1
		ble s11, t6, p2_encode_loop_groups
		
	p2_encode_end:
	#calculate offset to last position in final data
	mul t0, s6, s7
	mul t1, s3, s7
	add t2, t1, t0
	
	#restore callee saved registers
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s3, 8(sp)
	lw s4, 12(sp)
	lw s5, 16(sp)
	lw s7, 20(sp)
	lw s8, 24(sp)
	lw s9, 28(sp)
	lw s10, 32(sp)
	lw s11, 36(sp)
	lw ra, 40(sp)
	addi sp, sp, 44
	
	jalr zero, 0(ra)
##########################################################################################################################################



##########################################################################################################################################
#saves input in final data and leaves space for other data
p2_zip_to_final_data:
	
	#store callee saved registers
	addi sp, sp, -32
	sw, s1, 0(sp)
	sw, s2, 4(sp)
	sw, s3, 8(sp)
	sw, s4, 12(sp)
	sw, s5, 16(sp)
	sw, s6, 20(sp)
	sw, s10, 24(sp)
	sw, s11, 28(sp)
	
	#load function arguments								
	add s1, a1, zero									#s1: offset to final data
	add s2, a2, zero									#s2: source adress (message)
	add s3, a3, zero									#s3: number of bytes that should be saved in a full block offset defined by s4
	add s4, a4, zero									#s4: number of full blocks (group 1 and group 2)
	add s5, a5, zero									#s5: number of long blocks (group 2 in partition table)
	add s6, a6, zero									#s6: number of bytes that should be saved in a long block offset defined by s5
	
	#calculate final data adress considering the offset
	li t0, FINAL_DATA
	add s11, s1, t0										#s11: adress of the given block in final data

	#iterator s10 of both loops
	li s10, 0										#s10: bytes saved in full block offset, iterator
	
	sub s11, s11, s4
	#loops through all bytes s3 that should be saved in a full block offset s4
	p2_zip_to_final_data_loop_full_blocks:
		#loop exit condition: all full block data saved
		bge s10, s3, p2_zip_to_final_data_loop_full_blocks_end
		
		#load byte from source
		add t0, s2, s10
		lbu t1, (t0)
		
		#save byte
		add s11, s11, s4
		sb t1, (s11)
		
		#increment iterator s10
		addi s10, s10, 1
		beq zero, zero, p2_zip_to_final_data_loop_full_blocks

	p2_zip_to_final_data_loop_full_blocks_end:
	
	#sub s11, s1, s5
	#loops through all bytes s6 that should be saved in a full block offset s5
	p2_zip_to_final_data_loop_long_blocks:
		#loop exit condition: all long block data saved
		bge s10, s6, p2_zip_to_final_data_loop_long_blocks_end
		
		#load byte from source
		add t0, s2, s10
		lbu t1, (t0)
		
		#save byte
		add s11, s11, s5
		sb t1, (s11)
		
		#increment iterator s10
		addi s10, s10, 1
		beq zero, zero, p2_zip_to_final_data_loop_long_blocks
		  
	p2_zip_to_final_data_loop_long_blocks_end:  
	
	#restore callee saved registers
	lw, s1, 0(sp)
	lw, s2, 4(sp)
	lw, s3, 8(sp)
	lw, s4, 12(sp)
	lw, s5, 16(sp)
	lw, s6, 20(sp)
	lw, s10, 24(sp)
	lw, s11, 28(sp)
	addi sp, sp, 32
	
	jalr zero, 0(ra)
##########################################################################################################################################


##########################################################################################################################################
#returns the first adress of a given block
p2_get_adress_of_message_block:
#inputs:	a1: group that the block is in
#		a2: block that the adress should be returned from
#		a3: number of blocks in group 1
#		a4: number of codewords per block in group 1
#		a5: number of codewords per block in group a1
#returns:	a0: adress of the a2th block in group a1

	li a0, MESSAGE_CODEWORD_ADDRESS
	
	#calculate offset if the block is in goup 2
	mul t0, a3, a4
	addi a1, a1, -1
	mul t0, t0, a1
	add a0, a0, t0

	#calculate offset defined by the block in the given group
	addi t1, a2, -1
	mul t1, a5, t1
	add a0, a0, t1
	
	jalr zero, 0(ra)
##########################################################################################################################################


##########################################################################################################################################
#returns the first adress of a given block
p2_get_adress_of_errorcode_block:
#inputs		a1: group that the block is in
#		a2: block that the adress should be returned from
#		a3: number of blocks in group 1
#		a4: number of errorcodes per block
#returns:	a0: adress of the a2th errcode block in group a1

	li a0, EC_CODEWORD_ADDRESS
	
	#calculate offset if the block is in goup 2
	mul t0, a3, a4
	addi a1, a1, -1
	mul t0, t0, a1
	add a0, a0, t0

	#calculate offset defined by the block in the given group
	addi t1, a2, -1
	mul t1, a4, t1
	add a0, a0, t1
	
	jalr zero, 0(ra)
##########################################################################################################################################


##########################################################################################################################################
#returns an temporary polynomial that is calculated by adding all generator polynomials with the alpha value of the codeword
p2_calc_error_correction_code:

	#store callee saved register
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s6, 20(sp)
	sw s7, 24(sp)
	sw s8, 28(sp)
	sw s10, 32(sp)
	sw s11, 36(sp)
	sw ra, 40(sp)
	
	#load function arguments
	add s1, zero, a1								#s1: adress of the block that should be encoded
	add s2, zero, a2								#s2: number of error correction codes
	add s3, zero, a3								#s3: adress of the target adress (buffer EC_CODEWORD_ADDRESS + offset)
	add s4, zero, a4								#s4: length of the block
	
	#get gpo adress where the generator polynomials are stored
	add a2, zero, s2
	jal ra, p2_get_gpo_adress
	add s11, zero, a0								#s11: adress of the correct gpo array
	
	#calculate max length to initialize target adress
	add s10, zero, s4
	ble s2, s4, p2_calc_error_correction_code_max_end
	add s10, zero, s2								#s10: max of block length and error correction length
	p2_calc_error_correction_code_max_end:
	
	#initialize target adress
	add a1, zero, s3
	add a2, zero, s1
	add a3, zero, s4
	add a4, zero, s10
	jal ra, p2_initialize_ECC
	
	#conditional arguments for outer loop
	add s8, zero, zero								#s8: iteration of solomon encoding done
	
	#outer loop: does one iteration of reed solomon encoding
	p2_calc_error_correction_code_loop_outer:
		#end condition: polynomial is of desired length (s4)
		bge s8, s4, p2_calc_error_correction_code_loop_outer_end
	
		#calculate alpha value of current first byte of target adress
		la t0, i2a
		lbu t1, (s3)
		add t2, t1, t0
		addi t2, t2, -1		
		lbu s7, (t2)								#s7: alpha value of first byte of the target adress
		
		#conditional arguments for inner loop
		add s6, zero, zero							#s6: current byte, iterator
		
		#inner loop: calculates polynomial for each byte
		p2_calc_error_correction_code_loop_inner:
			#end condition: converted as many bytes as the max number
			bgt s6, s10, p2_calc_error_correction_code_loop_inner_end
			
			#set s0 to zero if the current byte is out of range of the gpo array
			add s0, zero, zero						#s0: polynomial for the current byte
			addi t0, s2, 1
			bge s6, t0, p2_calc_error_correction_code_loop_inner_zero
			
			#else: get generator polynomial for current byte
			add t0, s11, s6
			lbu t1, (t0)
			
			#set polynomial to the alpha value plus the generator polynomial
			add s0, t1, s7
			
			#prevent s0 from being larger than 255
			li t2, 256
			blt s0, t2, p2_calc_error_correction_code_loop_inner_skip_modulo
			addi s0, s0, -255
			p2_calc_error_correction_code_loop_inner_skip_modulo:
			
			#convert temporary polynomial to integer
			la t0, a2i
			add t1, t0, s0
			lbu s0, (t1)
			
			p2_calc_error_correction_code_loop_inner_zero:
			#xor temporary polynomial with previous polynomial saved at target adress
			add t0, s6, s3
			lbu t1, (t0)
			xor s0, s0, t1
			sb s0, (t0)
			
			#increment iterator
			addi s6, s6, 1
			beq zero, zero, p2_calc_error_correction_code_loop_inner		
			
		p2_calc_error_correction_code_loop_inner_end:
		
		#move conent of target adress one byte to the left (thus also reduce size by one byte)
		add a1, zero, s3
		addi a2, s10, 1
		jal ra, p2_delete_first_byte_and_move
		
		#increment iterator
		addi s8, s8, 1
		beq zero, zero, p2_calc_error_correction_code_loop_outer
			
	p2_calc_error_correction_code_loop_outer_end:
				
	#restore callee saved register
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s6, 20(sp)
	lw s7, 24(sp)
	lw s8, 28(sp)
	lw s10, 32(sp)
	lw s11, 36(sp)
	lw ra, 40(sp)
	addi sp, sp, 44
	
	jalr zero, 0(ra)
##########################################################################################################################################

	
			
##########################################################################################################################################	
#returns the adress where the generator polynomials are stored
p2_get_gpo_adress:
#input		a2: number of error correction codes
#output		a0: adress of the corresponding gpo table
	
	#jump to the correct branch
	li, t0, 7
	beq a2, t0, p2_gpo7
	li, t0, 10
	beq a2, t0, p2_gpo10
	li, t0, 13
	beq a2, t0, p2_gpo13
	li, t0, 15
	beq a2, t0, p2_gpo15
	li, t0, 16
	beq a2, t0, p2_gpo16
	li, t0, 17
	beq a2, t0, p2_gpo17
	li, t0, 18
	beq a2, t0, p2_gpo18
	li, t0, 20
	beq a2, t0, p2_gpo20
	li, t0, 22
	beq a2, t0, p2_gpo22
	li, t0, 24
	beq a2, t0, p2_gpo24
	li, t0, 26
	beq a2, t0, p2_gpo26
	li, t0, 28
	beq a2, t0, p2_gpo28
	li, t0, 30
	beq a2, t0, p2_gpo30
	
	#exit program with the code 42 if polynomial cant be calculated
	li a7, 93
	li a0, 42
	ecall
	
	#set t1 to the adress of the correct array
	p2_gpo7:
		la a0, gpo7
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo10:
		la a0, gpo10
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo13:
		la a0, gpo13
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo15:
		la a0, gpo15
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo16:
		la a0, gpo16
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo17:
		la a0, gpo17
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo18:
		la a0, gpo18
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo20:
		la a0, gpo20
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo22:
		la a0, gpo22
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo24:
		la a0, gpo24
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo26:
		la a0, gpo26
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo28:
		la a0, gpo28
		beq zero, zero, p2_get_gpo_adress_end
	p2_gpo30:
		la a0, gpo30
		beq zero, zero, p2_get_gpo_adress_end
		
		
	p2_get_gpo_adress_end:	
	jalr zero, 0(ra)
##########################################################################################################################################


##########################################################################################################################################
#deletes first byte and moves all bytes one byte to the left
p2_delete_first_byte_and_move:

	#store callee saved register
	addi sp, sp, -12
	sw s1, 0(sp)
	sw s2, 4(sp)
	sw s11, 8(sp)
	
	#load function arguments
	add s1, zero, a1								#s1: target adress
	add s2, zero, a2								#s2: initial length of the block

	#iterator s11 of loop
	li s11, 1									#s11: position of the next byte
	
	#prevent function from shifting when the length less or equal one
	ble s2, s11, p2_delete_first_byte_and_move_error
	
	#shift all bytes one to the left
	p2_delete_first_byte_and_move_loop:
		#condition: only move when the next byte is still inside the initial length of the block
		bge s11, s2, p2_delete_first_byte_and_move_end
		
		#move next byte into current byte
		add t0, s1, s11
		lbu t1, 0(t0)
		sb t1, -1(t0)
		
		#increment iterators
		addi s11, s11, 1
		beq zero, zero, p2_delete_first_byte_and_move_loop	
	p2_delete_first_byte_and_move_end:
		
		#set last byte to zero
		add t0, s1, s11
		sb zero, -1(t0)
		
	p2_delete_first_byte_and_move_error:
	
	#restore callee saved register
	lw s1, 0(sp)
	lw s2, 4(sp)
	lw s11, 8(sp)
	addi sp, sp, 12
	
	jalr zero, 0(ra)
##########################################################################################################################################	
	
	
##########################################################################################################################################
#initializes target array with a message and fills the rest with zeros
p2_initialize_ECC:

	#store callee saved register
	addi sp, sp, -16
	sw s1, 0(sp)
	sw s2, 4(sp)
	sw s3, 8(sp)
	sw s4, 12(sp)
	sw s11, 16(sp)
	
	#load function arguments
	add s1, zero, a1								#s1: target adress
	add s2, zero, a2								#s2: message adress
	add s3, zero, a3								#s3: message length
	add s4, zero, a4								#s4: desired length

	#check wether the desired length is shorter than the message length -> error
	bgt s3, s4, p2_initialize_ECC_error

	#iterator s11 of both loop
	li s11, 0									#s11: number of bytes copied, iterator
	
	#loop through message and copy to target adress
	p2_initialize_ECC_copy:
		#loop exit condition: all bytes from message copied
		bge s11, s3, p2_initialize_ECC_copy_end
		
		#load message byte
		add t1, s11, s2
		lbu t2, (t1)
		
		#calculate target adress and store byte
		add t3, s11, s1
		sb t2, (t3)
		
		#increment iterator
		addi s11, s11, 1
		beq zero, zero, p2_initialize_ECC_copy
	p2_initialize_ECC_copy_end:
	
	#fill the rest of the target adress with zeros till the desired length is reached
	p2_initialize_ECC_zeros:
		#loop exit condition: desired length reached
		bge s11, s4, p2_initialize_ECC_zeros_end
		
		#calculate target adress and store zero
		add t1, s11, s1
		sb zero, (t1)
		
		#increment iterator
		addi s11, s11, 1
		beq zero, zero, p2_initialize_ECC_zeros	
	p2_initialize_ECC_zeros_end:
	
	#restore callee saved register
	lw s1, 0(sp)
	lw s2, 4(sp)
	lw s3, 8(sp)
	lw s4, 12(sp)
	lw s11, 16(sp)
	addi sp, sp, 16
	
	#return
	jalr zero, 0(ra)
	
	p2_initialize_ECC_error:
	#exit program with code 40
		li a7, 93
		li a0, 40
		ecall
##########################################################################################################################################
