UI:
    #store ra in stackpointer
    sw ra, (sp)
    #t0 is used as a var for the different addresses
    #welcome message
    li a7, 4
    la a0, p1_UI_welcome_message
    ecall
    #Eingabe String fordern
    li a7, 8
    li a0,MESSAGE_CODEWORD_ADDRESS#Hier Adresse vom Inputbuffer reinladen
    addi a0, a0, 0x3 #################### Für späteres Encoden werden 3 Starter Bytes Platz hilfreich  --> plus 3
    li a1,2953    #maximale Anzahl an Zeichen -->Byte-Mode: 40-L max.Characters = 2953
    ecall

    p1_Get_Error_Correction:
        #Error-Correction Level: Nachricht anzeigen
        li a7, 4
        la a0, p1_user_Message2
        ecall
        #Error-Correction Level: Int einlesen
        li a7, 5
        la t0, error_correction_level
        ecall
        sb a0, 0(t0) 

        #control the input
        #t3 is used as a variable for various branch compare statements
        li t3, 3
        bgt a0,t3,p1_Get_Error_Correction.invalidLevel
        bltz a0, p1_Get_Error_Correction.invalidLevel

    #skip wrong-input-section if input was alright
    j p1_Get_String_Length


    p1_Get_Error_Correction.invalidLevel:
        li a7, 4
        la a0, p1_user_Message2_invalidInput
        ecall 
        j p1_Get_Error_Correction




p1_Get_String_Length:
    #a1 equals *string --> adress of string
    li a1, MESSAGE_CODEWORD_ADDRESS
    addi a1, a1, 0x3 #String got saved 3 Bytes later than MESSAGE_CODEWORD_ADDRESS
    #t0 increments with every counted Char
    add t0, zero, zero
    #ascii value for '\n'
    li t3, 10 

p1_loop_Char_Amount_count.start:
    add t1, t0, a1
    lb t1, 0(t1)
    beqz t1, p1_loop_Char_Amount_count.end
    beq t1, t3, p1_loop_Char_Amount_count.end

    addi t0, t0, 1
    j p1_loop_Char_Amount_count.start



p1_loop_Char_Amount_count.end:



#now we have to determine the version based on amount of chars in the string AND the given error correction level
#error correction level is still saved in a0 --> from user input, else can be loaded 
#t3 = comparation value to check which level was set
mv t3, zero
beq a0, t3, p1_switch_statement_error_correction_level.L #L=0

li t3, 1
beq a0, t3, p1_switch_statement_error_correction_level.M

li t3, 2
beq a0, t3, p1_switch_statement_error_correction_level.Q

li t3, 3
beq a0, t3, p1_switch_statement_error_correction_level.H

#################
#Problem with the Error-Correction-Value ! JUMP TO ThHE START OF THE PROGRAMM again!#
j UI
#################


#t0 = str.length(input)
#t3 saves the version
#t4 is the max amount per version
#t5 got the address of the max_message_codeword table --> in qr_data.asm

p1_switch_statement_error_correction_level.L:
    la t5, max_message_codeword
    mv t3, zero
    j p1_for_loop_version_table


p1_switch_statement_error_correction_level.M:
    la t5, max_message_codeword
    mv t3, zero
    addi t5, t5, 2
    j p1_for_loop_version_table

p1_switch_statement_error_correction_level.Q:
    la t5, max_message_codeword
    mv t3, zero
    addi t5,t5, 4
    j p1_for_loop_version_table

p1_switch_statement_error_correction_level.H:
    la t5, max_message_codeword
    mv t3, zero
    addi t5, t5, 6
    j p1_for_loop_version_table


################
p1_for_loop_version_table:
    lh t4, 0(t5)
    addi t3, t3, 1
    ble t0, t4, p1_qr_version 
    addi t5, t5, 8
    j p1_for_loop_version_table
#################

#################
p1_qr_version:

#t3 saves the version Number (1-40)
    la t4, qr_version
    sb t3, 0(t4)





#process for version up until 9 and further differs so here the code will branch
#reminder:
#register t3 still has the version information saved
#

li t6, 9
ble t3, t6, p1_version_OneToNine
j p1_version_GreaterThanNine




#The input is saved 3 Bytes to the left than normally to make space for both character count indicator and select mode indicator
#Both indicators will be saved directly in front of the data and wil be shifted as much as needed to get to the origin address (0x10140000)

#reminder:
#t0 = Character Amount
#t3 = Version Information (0-3)



p1_version_OneToNine:
#Character Count needs to be 8 Bits long -->Store Byte, Amount saved in t0
    li a2, MESSAGE_CODEWORD_ADDRESS
    li s0, 0x4 #Select Mode Indicator --> ByteMode only -> always 0100 or '4'
    sb s0, 0x1(a2)
    sb t0, 0x2(a2)
    #shift by 4 Bits 3 times
    #string is saved 3 Bytes to the right
    #character count directly in front of it
    #select mode directly infront of character Count
    #--> 12 leading zeros that have no information saved
    jal p1_ShiftBy4Bits
    jal p1_ShiftBy4Bits
    jal p1_ShiftBy4Bits

    j p1_PadBytes #next step in encoding the data to process it to the qr code

p1_version_GreaterThanNine:	
    #in ByteMode the Character Count Indicator for Versions 10 Through 26 equals those for v. 27-40
    #Character Count needs to be 16 Bits long
    #--> store as halfword at the address following the select mode indicator
    li a2, MESSAGE_CODEWORD_ADDRESS
    li s0, 0x4 #same as lower Versions, ByteMode is always selected
    sb s0, 0(a2)
    sb t0, 0x2(a2)
    srli s11, t0,8
    sb s11, 0x1(a2)
    #shift by 4 Bits so that Buffer starts directly with the needed information and not with 4 leading zeros
    jal p1_ShiftBy4Bits

    j p1_PadBytes #next step in encoding the data to process it to the qr code




################################################################
#Help-Func. for shifting the values to align Buffer value to required format
#Shiftby4Bits is needed because Select Mode Indicator is only 4 Bits or half a Byte long, but only full Bytes can be stored here. 
p1_ShiftBy4Bits:
    li a2, MESSAGE_CODEWORD_ADDRESS #ADDRESS FOR INPUT BUFFER
    li s0, 0x170 #=368 Dec = 2956/8 ; wird als Counter für for loop benutzt
    #s1 = temp, Speicher für folgenden Byte, um auf a3 aufzuaddieren
    p1_for_loop_4BitShift:

    lb a3, 0(a2)
    andi a3,a3,0xff
    lb a4, 1(a2)
    andi a4,a4,0xff
    slli a3, a3, 4
    srli s1, a4, 4 #get upper for bits and add them to Register above, so no data gets lost in shift process
    add a3, a3, s1
    sb a3, 0(a2)

    addi s0,s0,-1
    beqz s0, p1_BitShift_Done
    addi a2, a2, 1
    j p1_for_loop_4BitShift


p1_BitShift_Done:

    ret


#idea: no terminator Bits needed because: Only Byte Mode -> Character Count already Multiplier of 8
#the left shift already filled the last 4 Bits of the relevant Buffer Location with 4 Zeros 




    #reminder: t0 still has the original amount of Characters saved. But you need to add 2 or 3 Bytes dependent on the version
    # version <=9: add 2 Bytes to t0
    #version >= 10 -> add 3 Bytes to t0




p1_PadBytes:
    #get max. amount of Characters (...) and substract the amount of
    #chars (saved in t0), 
    #then load alternating 236 and 17 (Bit Pattern) in the free space
    #(...)= offset to table adress
    #s0 = qr version
    la s2, error_correction_level
    lb s2, 0(s2)
     
    la s0, qr_version
    lb s0, 0(s0)
    
    addi s0,s0,-1
    slli s0, s0, 2
    add s0, s0, s2
    slli s0, s0, 1
    
    
 

    la s2, max_message_codeword
    add s0, s0, s2
    lh s1, 0(s0)
    li s11, 0xffff
    and s1,s11, s1

    sub s1, s1, t0
	#pad Byte Amount saved in s1
    li s10, 9
    la s9, qr_version
    lb s9, 0(s9)
    ble s9,s10,p1_PadBytes.lower9
    j p1_PadBytes.up10
    
#amount of bytes varies with 1; <=9: 2 Indicator Bytes, 10+:3 Indicator Bytes
p1_PadBytes.lower9:
    addi t0,t0,2
    j p1_PadBytes.continue	
p1_PadBytes.up10:
    addi t0,t0,3
    j p1_PadBytes.continue
p1_PadBytes.continue:   
    li s2, MESSAGE_CODEWORD_ADDRESS
    add s2, s2, t0
    
    #addi s2, s2, 1
    
#s2 got the starting address for the padding bytes
#s3 increments with each step

mv s3, zero

p1_padding_for_loop:
    beq s1, s3 p1_padding_for_loop.end
    jal p1_padding_for_loop.236
    addi s3, s3, 1
    beq s1, s3 p1_padding_for_loop.end
    jal p1_padding_for_loop.17

    addi s3, s3, 1
    j p1_padding_for_loop

    p1_padding_for_loop.236:
    li s4, 236
    sb s4, 0(s2)
    addi s2,s2,1
    ret

    p1_padding_for_loop.17:
    li s4, 17
    sb s4, 0(s2)
    addi s2,s2,1
    ret

p1_padding_for_loop.end:

lw ra, (sp)
jalr zero, 0(ra)
