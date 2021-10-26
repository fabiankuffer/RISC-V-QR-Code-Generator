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
jal ra, draw_test

#beendet das programm
li a7, 10
ecall

#draws the qr-code
draw_test:
	#zunächst müssen alle daten aus dem .data teil auf den stack kopiert werden, da display alle pixel in den .data teil schreibt
	#auch erstmal alle register zwischenspeichern
	addi sp, sp, -88
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	sw s11, 44(sp)
	sw ra, 48(sp)
	
	
	
	#richtige version infos ermitteln und im stack speichern, erst ab version 7 nötig
	#versionsinfo = 52(sp) im stack
	addi s1, zero, 7
	la s2, qr_version
	lb s2, 0(s2) 
	blt s2, s1 draw_save_version_infos_pass_t
		#array element adresse ausrechnen
		addi s3, s2, -7
		#element * 4 für adresse
		slli s3, s3, 2
		la s0, versions_infos
		add s0, s3, s0
		
		lw s4, 0(s0)
		#in stack speichern
		sw s4, 52(sp)
	draw_save_version_infos_pass_t:
	
	
	
	#möglichen format_infos in stack speichern; 8 möglichkeiten abhängig von ecl (enthält mask info)
	#format_infos = 56(sp) im stack
	la s0, error_correction_level
	lb s0, 0(s0)
	#mal 16 rechnen um die richtigen elemente zu erhalten
	slli s0, s0, 4
	
	#for loop für alle 8 möglichkeiten
	addi s1, zero, 8
	addi s2, zero, 0 #zähl variable
	addi s3, sp, 56 #anfangsposition für version_infos im stack
	
	#adressenstart ermitteln
	la s4, format_infos
	add s4, s0, s4
	draw_get_format_infos_loop_t:
	
		lh s5, 0(s4)
		sh s5, 0(s3)
		
		#nächste adresse berechnen
		addi, s4, s4, 2
		#nächste stack adresse berechnen
		addi, s3, s3, 2
		
		#for loop nächster durchlauch
		addi, s2, s2, 1
		blt s2, s1, draw_get_format_infos_loop_t
		
	
	
	#alignment pattern locations in stack speichern; sind jeweils 7 stück
	#alignment pattern = 72(sp) im stack
	la s0, qr_version
	lb s0, 0(s0)
	#richtigen elemente ausrechnen
	addi s0, s0, -1
	addi s1, zero, 7
	mul s0, s0, s1
	
	#for loop für alle 7 elemente
	addi s1, zero, 7
	addi s2, zero, 0 #zähl variable
	addi s3, sp, 72 #anfangsposition für alginment_pattern im stack
	
	#adressenstart ermitteln
	la s4, align_positions
	add s4, s0, s4
	draw_alignment_pattern_loop_t:
		lb s5, 0(s4)
		sb s5, 0(s3)
		
		#nächste adresse berechnen
		addi, s4, s4, 1
		#nächste stack adresse berechnen
		addi, s3, s3, 1
		
		#for loop nächster durchlauf
		addi s2, s2, 1
		blt s2, s1, draw_alignment_pattern_loop_t
	
	
	
	#qr version in stack speichern
	#qr version = 79(sp)
	la s0, qr_version
	lb s0, 0(s0)
	sb s0, 79(sp)
	
	
	
	#error_correction_level in stack speichern
	#ecl = 80(sp)
	la s0, error_correction_level
	lb s0, 0(s0)
	sb s0, 80(sp)
	
	#SCHRITT 1: display leeren (EINE STUFE NEBEN WEIß DAMIT MAN ZWISCHEN FINALEN UND NICHT FINALEN MODULEN UNTERSCHEIDEN KANN)
	li a1, 0xFeFeFe
	jal ra, clear_screen
	
	#SCHRITT 2: ermitteln wie groß die qr code module sein dürfen
	#ein module ist ein rechteck im qr code
	lb a1, 79(sp)
	jal ra, get_module_size
	#zeichnen kann abgebrochen werden wenn modul größe kleiner 1 pixel ist
	addi, s0, zero, 0
	beq s0, a0, end_t
	#modul größe zwischenspeichern
	sw a0, 84(sp)
	
	#SCHRITT 3: rechts und unten pixel final füllen die nicht verwendet werden im display
	#anfang von x/y berechnen (module_width*((version-1)*4+21))
	lb s0, 79(sp)
	addi s0, s0, -1
	addi s1, zero, 4
	mul s1, s1, s0
	addi s1, s1, 21
	lw s2, 84(sp)
	mul s1, s1, s2
	#rechten teil final zeichnen
	mv a1, s1
	li a2, 0
	li a3, DISPLAY_WIDTH
	li a4, DISPLAY_HEIGHT
	li a5, 0xffffff
	jal ra, draw_rectangle
	#unteren teil final zeichnen
	li a1, 0
	mv a2, s1
	li a3, DISPLAY_WIDTH
	li a4, DISPLAY_HEIGHT
	li a5, 0xffffff
	jal ra, draw_rectangle
	
	#SCHRITT 4: FINDER PATTERN erzeugen
	#x/y anfang raussuchen für rechts oben und links unten
	lb s1, 79(sp)
	addi s1, s1, -1
	slli s1, s1, 2
	addi s1, s1, 13
	lw s2, 84(sp)
	addi s3, s1, 1
	#hintergrund ist jeweils ein 8*8 weißes feld
	lw s0, 84(sp)
	#links oben
	addi a1, zero, 0
	addi a2, zero, 0
	slli a3, s0, 3
	li a4, 0xFFFFFF
	jal ra, draw_square
	#finderpattern erstellen
	addi a1, zero, 0
	addi a2, zero, 0
	lw a3, 84(sp)
	jal ra, draw_finder_pattern
	#rechts oben
	mul a1, s1, s2
	addi a2, zero, 0
	slli a3, s0, 3
	li a4, 0xFFFFFF
	jal ra, draw_square
	#finderpattern erstellen
	mul a1, s3, s2
	addi a2, zero, 0
	lw a3, 84(sp)
	jal ra, draw_finder_pattern
	#links unten
	addi a1, zero, 0
	mul a2, s1, s2
	slli a3, s0, 3
	li a4, 0xFFFFFF
	jal ra, draw_square
	#finderpattern erstellen
	addi a1, zero, 0
	mul a2, s3, s2
	lw a3, 84(sp)
	jal ra, draw_finder_pattern
	
	#SCHRITT 5: ALIGNMENT PATTERN hinzufügen
	addi a1, sp, 72
	lw a2, 84(sp)
	jal ra, alignment_pattern
	
	#SCHRITT 6: TIMING PATTERN hinzufügen
	lw a1, 84(sp)
	lb a2, 79(sp)
	jal ra, timing_pattern
	
	#SCHRITT 7: ORT für FORMAT Infos reservieren (4 STUFEN NEBEN WEIß DAMIT MAN SIE IDENTIFIZIEREN KANN)
	lw a1, 84(sp)
	lb a2, 79(sp)
	jal ra, reserve_format_info_space
	
	#SCHRITT 8: ADD DARK module
	lw a1, 84(sp)
	lb a2, 79(sp)
	jal ra, single_dark_module
	
	#SCHRITT 9: Versionsinfos hineinschreiben
	lw a1, 84(sp)
	lb a2, 79(sp)
	lw a3, 52(sp)
	jal ra, place_version_infos
	
	
	#SCHRITT 10: Daten reinschreiben (2 STUFEN NEBEN WEIß = WEIßES FELD, 3 STUFEN NEBEN WEIß = schwarzes FELD; zum volläufigen reinschreiben)
	lw a1, 84(sp)
	lb a2, 79(sp)
	li a3, FINAL_DATA
	jal ra, place_data
	
	#SCHRITT 11: masken anwenden (vorläufig)
	lw a1, 84(sp)
	lb a2, 79(sp)
	addi a3, zero, 0
	jal ra, mask_data
	
	#SCHRITT 12: FORMATINFOS reinschreiben
	lw a1, 84(sp)
	lb a2, 79(sp)
	addi a3, zero, 0
	addi a4, sp, 56 #anfangsposition für version_infos im stack
	jal ra, write_format_infos
	
	#SCHRITT 13: Penalty berechnen
	#version, modulesize, rückgabe=penalty score
	lw a1, 84(sp)
	lb a2, 79(sp)
	jal ra, calc_penalty
	
	end_t:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	lw s11, 44(sp)
	lw ra, 48(sp)
	addi sp, sp, 88
	ret

#muss am ende stehen sonst wird der code dort drin ausgeführt
.include "qr_draw.asm"