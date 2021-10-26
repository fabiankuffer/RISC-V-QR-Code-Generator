#draws the qr-code
draw:
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
	blt s2, s1 draw_save_version_infos_pass
		#array element adresse ausrechnen
		addi s3, s2, -7
		#element * 4 für adresse
		slli s3, s3, 2
		la s0, versions_infos
		add s0, s3, s0
		
		lw s4, 0(s0)
		#in stack speichern
		sw s4, 52(sp)
	draw_save_version_infos_pass:
	
	
	
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
	draw_get_format_infos_loop:
	
		lh s5, 0(s4)
		sh s5, 0(s3)
		
		#nächste adresse berechnen
		addi, s4, s4, 2
		#nächste stack adresse berechnen
		addi, s3, s3, 2
		
		#for loop nächster durchlauch
		addi, s2, s2, 1
		blt s2, s1, draw_get_format_infos_loop
		
	
	
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
	draw_alignment_pattern_loop:
		lb s5, 0(s4)
		sb s5, 0(s3)
		
		#nächste adresse berechnen
		addi, s4, s4, 1
		#nächste stack adresse berechnen
		addi, s3, s3, 1
		
		#for loop nächster durchlauf
		addi s2, s2, 1
		blt s2, s1, draw_alignment_pattern_loop
	
	
	
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
	beq s0, a0, end
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
	
	#####loop um schritt 10 bis 13
	#größtmögliche penalty abspeichern
	li s3, 0x7FFFFFFF
	addi s5, zero, 0 #speichern der maske mit geringster penalty
	addi s4, zero, 0 #zähler für maske
	
	draw_loop_through_masks:
		#SCHRITT 10: Daten reinschreiben (2 STUFEN NEBEN WEIß = WEIßES FELD, 3 STUFEN NEBEN WEIß = schwarzes FELD; zum volläufigen reinschreiben)
		lw a1, 84(sp)
		lb a2, 79(sp)
		li a3, FINAL_DATA
		jal ra, place_data
	
		#SCHRITT 11: masken anwenden (vorläufig)
		lw a1, 84(sp)
		lb a2, 79(sp)
		mv a3, s4
		jal ra, mask_data
	
		#SCHRITT 12: FORMATINFOS reinschreiben
		lw a1, 84(sp)
		lb a2, 79(sp)
		mv a3, s4
		addi a4, sp, 56 #anfangsposition für version_infos im stack
		jal ra, write_format_infos
	
		#SCHRITT 13: Penalty berechnen
		#version, modulesize, rückgabe=penalty score
		lw a1, 84(sp)
		lb a2, 79(sp)
		jal ra, calc_penalty
		
		bge a0, s3, draw_loop_through_masks_skip
			mv s3, a0
			mv s5, s4
		draw_loop_through_masks_skip:
		#loop bedingung
		addi s4, s4, 1
		addi s6, zero, 8
		blt s4, s6, draw_loop_through_masks
	
	#SCHRITT 14: daten mit geringster penalty zeichnen
	#ÜBERSPRINGEN WENN MASKE BEREITS 7 ist
	addi s6, zero, 7
	beq s6, s5, draw_skip_redraw_of_data
		lw a1, 84(sp)
		lb a2, 79(sp)
		li a3, FINAL_DATA
		jal ra, place_data
		#maske
		lw a1, 84(sp)
		lb a2, 79(sp)
		mv a3, s5
		jal ra, mask_data
		#FORMATINFOS reinschreiben
		lw a1, 84(sp)
		lb a2, 79(sp)
		mv a3, s5
		addi a4, sp, 56 #anfangsposition für version_infos im stack
		jal ra, write_format_infos
	draw_skip_redraw_of_data:
	
	#SCHRITT 15: final Zeichnen
	lw a1, 84(sp)
	lb a2, 79(sp)
	jal ra, draw_final_qr
	
	end:
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

#a0: size of one square in qr code in pixel
#a1: qr_version
get_module_size:
	#werte in stack schreiben
	addi sp, sp, -20
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw a1, 16(sp)
	
	#übergebene qr_version kopieren
	mv s0, a1
	
	#anzahl der module berechnen
	#formel = (version-1)*4+21
	li s1, 4
	addi s0, s0, -1
	mul s0, s0, s1
	addi s0, s0, 21
	li s1, DISPLAY_WIDTH
	li s2, DISPLAY_HEIGHT
	
	#zwischen speichern der kleineren seite
	blt s1, s2, get_module_size_side_if
		mv s3, s2
		j get_module_size_side_both
	get_module_size_side_if:
		mv s3, s1
	get_module_size_side_both:
	
	#ermitteln der module größe in pixel
	div a0, s3, s0
	
	#werte aus stack laden
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw a1, 16(sp)
	addi sp, sp 20
	
	ret

#a1: x links oben, a2: y links oben, a3: module width in pixel
draw_finder_pattern:
	#werte in stack zwischenspeichern
	addi sp, sp, -24
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw ra, 8(sp)
	sw a1, 12(sp)
	sw a2, 16(sp)
	sw a3, 20(sp)
	
	#als erstes schwarzes rechteck
	#calc how much pixel to draw
	addi, s0, zero, 7
	mul s0, a3, s0
	#draw square
	mv a1, a1
	mv a2, a2
	mv a3, s0
	li a4, 0x000000
	jal ra, draw_square
	#daten wieder zurückladen da sie sich durch funktion geändert haben können
	lw a1, 12(sp)
	lw a2, 16(sp)
	lw a3, 20(sp)
	
	#zweitens ein weißes rechteck
	#calc how much pixel to draw
	addi, s0, zero, 5
	mul s0, a3, s0
	#draw square
	add a1, a1, a3
	add a2, a2, a3
	mv a3, s0
	li a4, 0xFFFFFF
	jal ra, draw_square
	#daten wieder zurückladen da sie sich durch funktion geändert haben können
	lw a1, 12(sp)
	lw a2, 16(sp)
	lw a3, 20(sp)
	
	#als letztes ein schwarzes rechteck
	#calc how much pixel to draw
	addi, s0, zero, 3
	mul s0, a3, s0
	#calc padding from start
	addi, s1, zero, 2
	mul s1, s1, a3
	#draw square
	add a1, a1, s1
	add a2, a2, s1
	mv a3, s0
	li a4, 0x000000
	jal ra, draw_square
	#daten wieder zurückladen da sie sich durch funktion geändert haben können
	lw a1, 12(sp)
	lw a2, 16(sp)
	lw a3, 20(sp)
	
	#werte aus stack laden
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw ra, 8(sp)
	lw a1, 12(sp)
	lw a2, 16(sp)
	lw a3, 20(sp)
	addi sp, sp, 24
	
	ret

#a1: pointer zu alignment data; a2: module width in pixel
alignment_pattern:
	addi sp, sp, -52
	sw a1, 0(sp)
	sw ra, 4(sp)
	sw a2, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s5, 32(sp)
	sw s6, 36(sp)
	sw s7, 40(sp)
	sw s8, 44(sp)
	sw s9, 48(sp)
	
	addi s0, zero, 7 #endbedingung für dim1&2
	addi s6, zero, 2 #endbedingung für dim3&4
	
	#durch alle möglichkeiten durchloopen x&y
	addi s1, zero, 0 #zähler dim1
	alignment_pattern_dim1:
		addi s2, zero, 0 #zähler dim2
		alignment_pattern_dim2:
		
			#element adresse in array ermitteln
			add s8, a1, s1
			add s9, a1, s2
			#daten auslesen aus array von möglichen patterpositionen
			lb s8, 0(s8)
			andi s8, s8, 0xFF #sonst gibt es fehler da er denkt das es negativ ist
			lb s9, 0(s9)
			andi s9, s9, 0xFF
			#bei version 1 muss schon davor einmal überprüft werden da es dort kein pattern gibt
			beq s8, zero, alignment_pattern_dim1_end
			beq s9, zero, alignment_pattern_dim1_end
		
			#überprüfen ob an möglicher position alle pixel für das alignment pattern frei sind
			#mit einen loop da 25 module überprüft werden müssen
			addi s4, s1, -2 #zähler dim3
			alignment_pattern_dim3:
				addi s5, s2, -2 #zähler dim4
				alignment_pattern_dim4:
				
					#modul raussuchen zum überprüfen ob farbe 0xfefefe, wenn dann ist in ordnung
					
					add a1, s8, s4
					add a2, s9, s5
					lw a3, 8(sp)
					jal ra, get_module_color
					lw a1, 0(sp)
					lw a2, 8(sp)
					
					#schauen ob frei
					li s7, 0x00fefefe
					bne s7, a0, alignment_pattern_draw_end
					
					#for loop bedingung
					addi, s5, s5, 1
					blt s5, s6, alignment_pattern_dim4
				
				#for loop bedingung	
				addi, s4, s4, 1
				blt s4, s6, alignment_pattern_dim3
				
			#alignment pattern zeichnen da es keine ungewollten pixel gibt
			#zuerst schwarzer kasten größe 5
			lw s4, 8(sp)
			addi a1, s8, -2
			mul a1, a1, s4
			addi a2, s9, -2
			mul a2, a2, s4
			addi s5, zero, 5
			mul a3, s5, s4
			li a4, 0x000000
			jal ra, draw_square
			lw a1, 0(sp)
			lw a2, 8(sp)
			
			#zweitens weißer kasten größe 3
			lw s4, 8(sp)
			addi a1, s8, -1
			mul a1, a1, s4
			addi a2, s9, -1
			mul a2, a2, s4
			addi s5, zero, 3
			mul a3, s5, s4
			li a4, 0xffffff
			jal ra, draw_square
			lw a1, 0(sp)
			lw a2, 8(sp)
			
			#drittens schwarzer kasten größe 1
			lw s4, 8(sp)
			mv a1, s8
			mul a1, a1, s4
			mv a2, s9
			mul a2, a2, s4
			mv a3, s4
			li a4, 0x000000
			jal ra, draw_square
			lw a1, 0(sp)
			lw a2, 8(sp)	
				
			#benötigt wenn pattern nicht gezeichnet werden kann
			alignment_pattern_draw_end:
		
			#for loop bedingung; beenden wenn ende von array erreicht ist oder eine 0 kommt
			addi s2, s2, 1
			#schauen ob nächstes element 0 ist
			add s3, s2, a1
			lb s3, 0(s3)
			beq s3, zero, alignment_pattern_dim2_end
			blt s2, s0, alignment_pattern_dim2
		alignment_pattern_dim2_end:
			
		#for loop bedingung; beenden wenn ende von array erreicht ist oder eine 0 kommt
		addi s1, s1, 1
		#schauen ob nächstes element 0 ist
		add s3, s1, a1
		lb s3, 0(s3)
		beq s3, zero, alignment_pattern_dim1_end
		blt s1, s0, alignment_pattern_dim1
	alignment_pattern_dim1_end:

	lw a1, 0(sp)
	lw ra, 4(sp)
	lw a2, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s5, 32(sp)
	lw s6, 36(sp)
	lw s7, 40(sp)
	lw s8, 44(sp)
	lw s9, 48(sp)
	addi sp, sp, 52
	ret

#a1: x, a2: y, a3: module width in pixel
#a0: returns color	
get_module_color:
	addi sp, sp, -32
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw ra, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	
	#relative adresse ausrechnen
	#erst y
	mul s1, a2, a3
	li s2, DISPLAY_WIDTH
	mul s1, s1, s2
	slli s1, s1, 2
	#jetzt noch den x teil dazu
	mul s2, a1, a3
	slli s2, s2, 2
	add s3, s2, s1
	
	#absolute adresse ausrechnen und farbe ermitteln
	li s4, DISPLAY_ADDRESS
	add s3, s3, s4
	lw a0, 0(s3)

	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw ra, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	addi sp, sp, 32
	ret
	
#a1: module width in pixel, a2: qr_version
timing_pattern:
	addi sp, sp, -36
	sw a1, 0(sp)
	sw ra, 4(sp)
	sw a2, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s7, 32(sp)
	
	#x/y koordinate berechnen
	addi s1, zero, 6
	#y/x max
	addi s2, a2, -1
	slli s2, s2, 2
	addi s2, s2, 13
	#y/x min & loop counter
	addi s3, zero, 8
	
	#register zum togglen zwischen schwarz und weiß
	li s4, 0x000000
	
	timing_pattern_loop:
		
		#vertikales modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s1
		mv a2, s3
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a2, 8(sp)
					
		#schauen ob frei
		li s7, 0x00fefefe
		bne s7, a0, timing_pattern_skip_draw_v
		
		#modul zeichnen
		mv a3, a1
		mul a1, s1, a3
		mul a2, s3, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		timing_pattern_skip_draw_v:
		
		#horizontal modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s3
		mv a2, s1
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a2, 8(sp)
					
		#schauen ob frei
		li s7, 0x00fefefe
		bne s7, a0, timing_pattern_skip_draw_h
		
		#modul zeichnen
		mv a3, a1
		mul a1, s3, a3
		mul a2, s1, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		timing_pattern_skip_draw_h:
		
		#xor zum togglen der bits
		li s0, 0xFFFFFF
		xor s4, s4, s0
		
		#for loop bedingung
		addi s3, s3, 1
		blt s3, s2, timing_pattern_loop
	
	lw a1, 0(sp)
	lw ra, 4(sp)
	lw a2, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s7, 32(sp)
	addi sp, sp, 36
	ret

#a1: module size in pixel; a2: qr-version
reserve_format_info_space:
	addi sp, sp, -32
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	
	#color
	li s4, 0xfbfbfb
	
	#ausrechnen unten links & oben rechts
	addi s0, a2, -1
	slli s0, s0, 2
	#y/x max
	addi s1, s0, 21
	#y/x min
	addi s0, s0, 13	
	#x/y
	addi s2, zero, 8
	
	reserve_format_info_space_lul:
		#unten links
		#modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s2
		mv a2, s0
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a4, 8(sp)
					
		#schauen ob frei
		li s3, 0x00fefefe
		bne s3, a0, reserve_format_info_space_skip_draw_ul
		
		#modul zeichnen
		mv a3, a1
		mul a1, s2, a3
		mul a2, s0, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		reserve_format_info_space_skip_draw_ul:
		
		#oben rechts
		#modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s0
		mv a2, s2
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a4, 8(sp)
					
		#schauen ob frei
		li s3, 0x00fefefe
		bne s3, a0, reserve_format_info_space_skip_draw_or
		
		#modul zeichnen
		mv a3, a1
		mul a1, s0, a3
		mul a2, s2, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		reserve_format_info_space_skip_draw_or:
		
		#loop bedingung
		addi s0, s0, 1
		blt s0, s1, reserve_format_info_space_lul
	
	#ausrechnen oben links
	#y/x max
	addi s1, zero, 9
	#y/x min
	addi s0, zero, 0
	#x/y
	addi s2, zero, 8
	
	reserve_format_info_space_ol:
		#unten links
		#modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s2
		mv a2, s0
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a4, 8(sp)
					
		#schauen ob frei
		li s3, 0x00fefefe
		bne s3, a0, reserve_format_info_space_skip_draw_olv
		
		#modul zeichnen
		mv a3, a1
		mul a1, s2, a3
		mul a2, s0, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		reserve_format_info_space_skip_draw_olv:
		
		#oben rechts
		#modul schauen ob beschreibbar
		mv a3, a1
		mv a1, s0
		mv a2, s2
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a4, 8(sp)
					
		#schauen ob frei
		li s3, 0x00fefefe
		bne s3, a0, reserve_format_info_space_skip_draw_olh
		
		#modul zeichnen
		mv a3, a1
		mul a1, s0, a3
		mul a2, s2, a3
		mv a4, s4
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 8(sp)
		
		reserve_format_info_space_skip_draw_olh:
		
		#loop bedingung
		addi s0, s0, 1
		blt s0, s1, reserve_format_info_space_ol
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	addi sp, sp, 32
	ret
	
#a1: module size in pixel; a2: qr-version
single_dark_module:
	addi sp, sp, -20
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	
	#dark_module befindet sich immer an der gleichen stelle links unten in der nähe des finder patterns
	mv a3, a1
	addi s0, zero, 8
	mul a1, a3, s0
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 13
	mul a2, s1, a3
	addi a4, zero, 0x000000
	jal ra, draw_square
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	addi sp, sp, 20
	ret

#a1: module width in pixel, a2: qr-version, a3:version-infos
#version infos are store above the lower finder pattern and on the left side of the right finder pattern
#only necessary above version 6
place_version_infos:
	addi sp, sp, -52
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw ra, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s5, 32(sp)
	sw s6, 36(sp)
	sw s7, 40(sp)
	sw s8, 44(sp)
	sw s9, 48(sp)
	
	#überprüfen ob version größer gleich 7, wenn kleiner kann mit der funktion aufgehört werden
	addi s1, zero, 7
	blt a2, s1 place_version_infos_end
		#zeichnen der versionsinfos
		addi s1, zero, 0 #zähler loop x
		addi s3, zero, 6 #loop x endwert
		addi s4, zero, 3 #loop y endwert
		addi s5, zero, 0 #register how much to shift for the necessary bit
		addi s8, a2, -1 #y startposition berechnen
		slli s8, s8, 2
		addi s8, s8, 10
		place_version_infos_loop_x_l:
			addi s2, zero, 0 #zähler loop y
			place_version_infos_loop_y_l:
				#first get one bit of the information
				addi s6, zero, 1 #bit to shift as reference
				sll s6, s6, s5 #an die zu überprüfende stelle shiften
				and s6, s6, a3 #schauen ob an der stelle eine 1
				srl s6, s6, s5 #wieder an erste stelle zurück schieben
				beq s6, zero, place_version_infos_l_white
					li s7, 0x000000
					j place_version_infos_l_both
				place_version_infos_l_white:
					li s7, 0xFFFFFF
				place_version_infos_l_both:
				
				#modul zeichnen rechts
				add s9, s8, s2
				mv a3, a1
				mul a1, s9, a3
				mul a2, s1,a3
				mv a4, s7
				jal ra, draw_square
				lw a1, 0(sp)
				lw a2, 4(sp)
				lw a3, 8(sp)
				
				#modul zeichnen links
				add s9, s8, s2
				mv a3, a1
				mul a1, s1, a3
				mul a2, s9,a3
				mv a4, s7
				jal ra, draw_square
				lw a1, 0(sp)
				lw a2, 4(sp)
				lw a3, 8(sp)
				
				#shift um 1 vergrößer für nächste stelle
				addi s5, s5, 1
				
				#loop y bedingung
				addi s2, s2, 1
				blt s2, s4, place_version_infos_loop_y_l
				
			#loop x bedingung
			addi s1, s1, 1
			blt s1, s3, place_version_infos_loop_x_l
	
	place_version_infos_end:
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw ra, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s5, 32(sp)
	lw s6, 36(sp)
	lw s7, 40(sp)
	lw s8, 44(sp)
	lw s9, 48(sp)
	addi sp, sp, 52
	ret

#a1: module width in pixel, a2: qr-version, a3: start of data
#es muss geschaut werden ob farbe ungleich #ffffff, #000000 oder #fbfbfb
place_data:
	addi sp, sp, -64 
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw ra, 12(sp)
	sw s0, 16(sp)
	sw s1, 20(sp)
	sw s2, 24(sp)
	sw s3, 28(sp)
	sw s4, 32(sp)
	sw s5, 36(sp)
	sw s6, 40(sp)
	sw s7, 44(sp)
	sw s8, 48(sp)
	sw s9, 52(sp)
	sw s10, 56(sp)
	sw s11, 60(sp)

	#maximale positon für module ausrechnen (x/y max)
	addi s0, a2, -1
	slli s0, s0, 2
	addi s0, s0, 20 #x max
	mv s1, s0	#y max
	mv s11, a3	#aktuelle adresse
	
	mv s2, s0 #xpos
	mv s3, s1 #ypos
	addi s4, zero, 0 #zeigen ob hoch oder runter 1:runter 0:hoch
	
	#so lange daten durchlaufen solang x >= 0 ist
	place_data_while_main:
		addi s5, zero, 7 #abspeichern wie weit zu shiften
		
		lb s9, 0(s11)	#aktuelles byte zum anschauen
		
		#data adresse auf das nächste byte erhöhen
		addi s11, s11, 1
		
		#zig zag von unten rechts durchlaufen
		place_data_while_zz:
		
			#wenn am linken unteren rand angekommen komplettes einfügen beenden
			bne s2, zero, place_data_while_zz_skip_check
				beq s3, s1, place_data_while_main_end
			place_data_while_zz_skip_check:
		
			#prüfen ob diese position gültig
			mv a3, a1
			mv a1, s2
			mv a2, s3
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			lw a3, 8(sp)
						
			#schauen ob frei, wenn nicht frei nächste position ausrechnen und nächster durchlauf
			li s7, 0x00ffffff
			beq s7, a0, place_data_zz_skip_bad_module
			li s7, 0x00000000
			beq s7, a0, place_data_zz_skip_bad_module
			li s7, 0x00fbfbfb
			beq s7, a0, place_data_zz_skip_bad_module
			li s7, 0x00fafafa
			beq s7, a0, place_data_zz_skip_bad_module
		
			#HIER WENN GÜLTIGE POSITION
			addi s8, zero, 1 #bit to shift as reference
			sll s8, s8, s5 #an die zu überprüfende stelle shiften
			and s8, s8, s9 #schauen ob an der stelle eine 1
			srl s8, s8, s5 #wieder an erste stelle zurück schieben
			beq s8, zero, place_data_zz_white
				li s10, 0xFDFDFD
				j place_data_zz_both
			place_data_zz_white:
				li s10, 0xFCFCFC
			place_data_zz_both:
			
			#modul zeichnen
			mv a3, a1
			mul a1, s2, a3
			mul a2, s3, a3
			mv a4, s10
			jal ra, draw_square
			lw a1, 0(sp)
			lw a2, 4(sp)
			lw a3, 8(sp)
			
			#shift um 1 veringern
			addi s5, s5, -1
			
			#HIER IMMER HIN GEHEN UM NÄCHSTE POSITION ZU ERMITTELN
			place_data_zz_skip_bad_module:
				#x modulo 2 zeigt an ob rechte oder linke seite vom zigzag
				#ergebniss = 0 : rechte seite
				#ergebniss = 1 : linke seite
				addi s8, zero, 2
				rem s8, s2, s8
				#wenn kleiner 6 muss es invertiert werden
				addi, s6, zero, 6
				bgt s2, s6 place_data_zz_skip_invert
					xori s8, s8, 0x01
				place_data_zz_skip_invert:
				
				#schauen ob nach oben geht
				bne s4, zero, place_data_zz_skip_up
					#wenn hoch geht
					#schauen ob linke seite
					beq s8, zero, place_data_zz_skip_left_up
						#wenn linke seite
						#schauen ob y 0 ist
						bne s3, zero, place_data_zz_skip_left_up_y_not_zero
							#wenn y=0
							addi s4, zero, 1 #togglen von s4, da es in andere richtung geht
							j place_data_zz_skip_left_up_y_not_zero_both
						place_data_zz_skip_left_up_y_not_zero:
							#wenn y nicht 0
							addi s3, s3, -1
							addi s2, s2, 1
							j place_data_zz_skip_up_both
						place_data_zz_skip_left_up_y_not_zero_both:
							
					#wenn es rechts ist
					place_data_zz_skip_left_up:
						addi s2, s2, -1
						j place_data_zz_skip_up_both
				place_data_zz_skip_up:
					#wenn es nach unten geht
					#schauen ob linke seite
					beq s8, zero, place_data_zz_skip_left_down
						#wenn linke seite
						#schauen ob y ymax ist
						blt s3, s1, place_data_zz_skip_left_down_y_not_ymax
							#wenn y = ymax
							addi s4, zero, 0 #togglen von s4, da es in andere richtung geht
							j place_data_zz_skip_left_up_y_not_max_both
						place_data_zz_skip_left_down_y_not_ymax:
							#wenn nicht y = ymax
							addi s3, s3, 1
							addi s2, s2, 1
							j place_data_zz_skip_up_both
						place_data_zz_skip_left_up_y_not_max_both:
						
					#wenn es rechts ist
					place_data_zz_skip_left_down:
						addi s2, s2, -1
						j place_data_zz_skip_up_both
						
				place_data_zz_skip_up_both:
					#wenn spalte 7 kommt von links diese überspringen
					addi s6, zero, 6
					bne s2, s6, place_data_while_if_not_coloum_7_skip
						addi s2, s2, -1
					place_data_while_if_not_coloum_7_skip:
		
			#while bedingung solang shift >= 0 ist müssen noch bits untersucht werden
			bge s5, zero, place_data_while_zz

		#while bedingung immer laufen bis oben bedingung beendet
		beq zero, zero, place_data_while_main
		
	place_data_while_main_end:

	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw ra, 12(sp)
	lw s0, 16(sp)
	lw s1, 20(sp)
	lw s2, 24(sp)
	lw s3, 28(sp)
	lw s4, 32(sp)
	lw s5, 36(sp)
	lw s6, 40(sp)
	lw s7, 44(sp)
	lw s8, 48(sp)
	lw s9, 52(sp)
	lw s10, 56(sp)
	lw s11, 60(sp)
	addi sp, sp, 64
	ret

#a1: module with in pixel; a2: qr-version; a3:mask-pattern-index
mask_data:
	addi sp, sp, -40
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw ra, 12(sp)
	sw s0, 16(sp)
	sw s1, 20(sp)
	sw s2, 24(sp)
	sw s3, 28(sp)
	sw s4, 32(sp)
	sw s5, 36(sp)

	#loop über alle module um jedes zu vergleichen und zu schauen ob es ein datenmodul ist
	#modulanzahl bestimmen
	addi s0, a2, -1
	slli s0, s0, 2
	addi s0, s0, 21	
	
	addi s1, zero, 0 # y zähler
	
	mask_data_loopy:
		addi s2, zero, 0 # x zähler
		mask_data_loopx:
		
			mask_data_switch.0:
				addi s3, zero, 0
				bne s3, a3, mask_data_switch.1
				
				#ergebnis der maske berechnen
				#(y+x)%2
				add s4, s1, s2
				addi s3, zero, 2
				rem s4, s4, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.1:
				addi s3, zero, 1
				bne s3, a3, mask_data_switch.2
				
				#ergebnis der maske berechnen
				#y%2
				addi s3, zero, 2
				rem s4, s1, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.2:
				addi s3, zero, 2
				bne s3, a3, mask_data_switch.3
				
				#ergebnis der maske berechnen
				#x%3
				addi s3, zero, 3
				rem s4, s2, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.3:
				addi s3, zero, 3
				bne s3, a3, mask_data_switch.4
				
				#ergebnis der maske berechnen
				#(y+x)%3
				add s4, s1, s2
				addi s3, zero, 3
				rem s4, s4, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.4:
				addi s3, zero, 4
				bne s3, a3, mask_data_switch.5
				
				#ergebnis der maske berechnen
				#((y/2)+(x/3))%2
				addi s3, zero, 2
				div s4, s1, s3
				addi s3, zero, 3
				div s3, s2, s3
				add s4, s3, s4
				addi s3, zero, 2
				rem s4, s4, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.5:
				addi s3, zero, 5
				bne s3, a3, mask_data_switch.6
				
				#ergebnis der maske berechnen
				#(y*x)%2+(y*x)%3
				mul s5, s1, s2
				addi s3, zero, 2
				rem s4, s5, s3
				addi s3, zero, 3
				rem s5, s5, s3
				add s4, s4, s5
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.6:
				addi s3, zero, 6
				bne s3, a3, mask_data_switch.7
				
				#ergebnis der maske berechnen
				#((y*x)%2+(y*x)%3)%2
				mul s5, s1, s2
				addi s3, zero, 2
				rem s4, s5, s3
				addi s3, zero, 3
				rem s5, s5, s3
				add s4, s4, s5
				addi s3, zero, 2
				rem s4, s4, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.7:
				addi s3, zero, 7
				bne s3, a3, mask_data_switch.end
				
				#ergebnis der maske berechnen
				#((y+x)%2+(y*x)%3)%2
				add s5, s1, s2
				addi s3, zero, 2
				rem s4, s5, s3
				mul s5, s1, s2
				addi s3, zero, 3
				rem s5, s5, s3
				add s4, s4, s5
				addi s3, zero, 2
				rem s4, s4, s3
				
				beq zero, zero mask_data_switch.end
			mask_data_switch.end:

			bne s4, zero, mask_data_loop_skip_module
				#farbe des feldes invertieren wenn ergebnis der rechnung eine 0 ist
				#farbe des moduls ermitteln
				mv a3, a1
				mv a1, s2
				mv a2, s1
				jal ra, get_module_color
				lw a1, 0(sp)
				lw a2, 4(sp)
				lw a3, 8(sp)
			
				#wenn es ein temporäres schwarzes modul ist
				li s5, 0xFDFDFD
				bne a0, s5, mask_data_loop_try_white
					li a4, 0xFCFCFC
					j mask_data_loop_try_both
				
				#wenn es ein temporäres weißes modul ist
				mask_data_loop_try_white:
				li s5, 0xFCFCFC
				bne a0, s5, mask_data_loop_skip_module
					li a4, 0xFDFDFD
				mask_data_loop_try_both:
				#farbe ändern des modules
				mv a3, a1
				mul a1, s2, a3
				mul a2, s1, a3
				jal ra, draw_square
				lw a1, 0(sp)
				lw a2, 4(sp)
				lw a3, 8(sp)
			
			mask_data_loop_skip_module:
			
			#loopx bedingung
			addi s2, s2, 1
			blt s2, s0, mask_data_loopx
	
		#loopy bedingung
		addi s1, s1, 1
		blt s1, s0, mask_data_loopy
	

	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw ra, 12(sp)
	lw s0, 16(sp)
	lw s1, 20(sp)
	lw s2, 24(sp)
	lw s3, 28(sp)
	lw s4, 32(sp)
	lw s5, 36(sp)
	addi sp, sp, 40
	ret
	
#a1: module with in pixel; a2: qr-version; a3: mask-index; a4: pointer to format infos
write_format_infos:
	addi sp, sp, -52
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw a4, 12(sp)
	sw ra, 16(sp)
	sw s0, 20(sp)
	sw s1, 24(sp)
	sw s2, 28(sp)
	sw s3, 32(sp)
	sw s4, 36(sp)
	sw s5, 40(sp)
	sw s6, 44(sp)
	sw s8, 48(sp)
	
	#richtigen format infos laden abhängig von der maske
	slli a3, a3, 1	#mal zwei nehmen da format infos half-word ist
	add a4, a4, a3
	lh s0, 0(a4)
	
	#register für aktuelle shift stelle
	addi s2, zero, 14
	addi s3, zero, 0 #for counter
	addi s5, zero, 0 #x
	addi s6, zero, 8 #y
	
	#format infos links oben setzen
	write_format_infos_upper_left:
	
		#prüfen ob diese position gültig
		mv a3, a1
		mv a1, s5
		mv a2, s6
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a2, 4(sp)
		lw a3, 8(sp)
		lw a4, 12(sp)
		
		li s7, 0x00ffffff
		beq s7, a0, write_format_infos_skip_bad_module
		li s7, 0x00000000
		beq s7, a0, write_format_infos_skip_bad_module
		
		#schauen was aktuelles bit ist
		addi s8, zero, 1 #bit to shift as reference
		sll s8, s8, s2 #an die zu überprüfende stelle shiften
		and s8, s8, s0 #schauen ob an der stelle eine 1
		srl s8, s8, s2 #wieder an erste stelle zurück schieben
		beq s8, zero, write_format_infos_white
			li s8, 0xFBFBFB
			j write_format_infos_both
		write_format_infos_white:
			li s8, 0xFAFAFA
		write_format_infos_both:	
			
		#modul zeichnen
		mv a3, a1
		mul a1, s5, a3
		mul a2, s6, a3
		mv a4, s8
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 4(sp)
		lw a3, 8(sp)
		lw a4, 12(sp)
			
		#shift um 1 veringern
		addi s2, s2, -1
		
		#jedes  mal ausführen um nächste position zu ermitteln
		write_format_infos_skip_bad_module:
		#wenn x < 7 x um eins erhöhen
		addi s4, zero, 7
		bgt s5, s4, write_format_infos_go_upwards
			addi s5, s5, 1
			j write_format_infos_go_upwards_both
		#sonst y um eins veringern
		write_format_infos_go_upwards:
			addi s6, s6, -1
			
		write_format_infos_go_upwards_both:
		
		#for bedingung
		bge, s2, zero, write_format_infos_upper_left
	
	
	#format infos links unten und rechts oben setzen
	#register für aktuelle shift stelle
	addi s2, zero, 14
	addi s3, zero, 0 #for counter
	addi s5, zero, 8 #x
	#y berechnen
	addi s6, a2, -1
	slli s6, s6, 2
	addi s6, s6, 20
	mv s1, s6
	addi s1, s1, -6 #wann muss gesprungen werden an die andere stelle
	
	#format infos links oben setzen
	write_format_infos_left_and_right:
	
		#prüfen ob diese position gültig
		mv a3, a1
		mv a1, s5
		mv a2, s6
		jal ra, get_module_color
		lw a1, 0(sp)
		lw a2, 4(sp)
		lw a3, 8(sp)
		lw a4, 12(sp)
		
		li s7, 0x00ffffff
		beq s7, a0, write_format_infos_skip_bad_module_left_and_right
		li s7, 0x00000000
		beq s7, a0, write_format_infos_skip_bad_module_left_and_right
		
		#schauen was aktuelles bit ist
		addi s8, zero, 1 #bit to shift as reference
		sll s8, s8, s2 #an die zu überprüfende stelle shiften
		and s8, s8, s0 #schauen ob an der stelle eine 1
		srl s8, s8, s2 #wieder an erste stelle zurück schieben
		beq s8, zero, write_format_infos_white_left_and_right
			li s8, 0xFBFBFB
			j write_format_infos_both_left_and_right
		write_format_infos_white_left_and_right:
			li s8, 0xFAFAFA
		write_format_infos_both_left_and_right:	
			
		#modul zeichnen
		mv a3, a1
		mul a1, s5, a3
		mul a2, s6, a3
		mv a4, s8
		jal ra, draw_square
		lw a1, 0(sp)
		lw a2, 4(sp)
		lw a3, 8(sp)
		lw a4, 12(sp)
			
		#shift um 1 veringern
		addi s2, s2, -1
		
		#jedes  mal ausführen um nächste position zu ermitteln
		write_format_infos_skip_bad_module_left_and_right:
		#wenn Y > ymax - 6 y um eins veringern
		ble s6, s1, write_format_infos_go_downwards
			addi s6, s6, -1
			j write_format_infos_go_downwards_both
		#sonst x um eins vergrößern
		write_format_infos_go_downwards:
			addi s9, zero, 8
			bne s5, s9 write_format_infos_left_and_right_x_changed
				addi s5, s1, -2 
			write_format_infos_left_and_right_x_changed:
			addi s5, s5, 1
			addi s6, zero, 8
			
		write_format_infos_go_downwards_both:
		
		#for bedingung
		bge, s2, zero, write_format_infos_left_and_right
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw a4, 12(sp)
	lw ra, 16(sp)
	lw s0, 20(sp)
	lw s1, 24(sp)
	lw s2, 28(sp)
	lw s3, 32(sp)
	lw s4, 36(sp)
	lw s5, 40(sp)
	lw s6, 44(sp)
	lw s8, 48(sp)
	addi sp, sp, 52
	ret
	
#a1: modul width in pixel, a2: qr-version
draw_final_qr:
	addi sp, sp, -32
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp) 
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	
	#maximal wert für loops bestimmen
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 21

	#alle module durchgehen und falsche farben ersetzen durch finale werte
	addi s2, zero, 0 #y zähler
	draw_final_qr_loop_y:
		addi s3, zero, 0 #x zähler
		draw_final_qr_loop_x:
		
			#modulfarbe ermitteln
			mv a3, a1
			mv a1, s3
			mv a2, s2
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
		
			#wenn es 0xfbfbfb oder 0xfdfdfd ist durch schwarz ersetzen
			li s4, 0xfbfbfb
			beq s4, a0 draw_final_qr_module_black
			
			li s4, 0xfdfdfd
			beq s4, a0 draw_final_qr_module_black
			
			#wenn es 0xfafafa oder 0xfcfcfc ist durch weiß ersetzen
			li s4, 0xfafafa
			beq s4, a0 draw_final_qr_module_white
			
			li s4, 0xfcfcfc
			beq s4, a0 draw_final_qr_module_white
			
			j draw_final_qr_nothing_to_do
			
			#schwarze farbe auswählen
			draw_final_qr_module_black:
			li a4, 0x000000
			j draw_final_qr_draw_module
			
			#weiße farbe auswählen
			draw_final_qr_module_white:
			li a4, 0xffffff
			j draw_final_qr_draw_module
			
			draw_final_qr_draw_module:
			mv a3, a1
			mul a1, s3, a3
			mul a2, s2, a3
			jal ra, draw_square
			lw a1, 0(sp)
			lw a2, 4(sp)
			lw a3, 8(sp)
			
			draw_final_qr_nothing_to_do:
			#loopx bedingung
			addi s3, s3, 1
			blt s3, s1, draw_final_qr_loop_x
		
		#loopy bedingung
		addi s2, s2, 1
		blt s2, s1, draw_final_qr_loop_y
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp) 
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	addi sp, sp, 32
	ret
	
#a1: modul with in pixel, a2: qr-version
calc_penalty:
	addi sp, sp, -16
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	
	#rückgabewert für penaltys
	addi s0, zero, 0
	
	#alle 4 penalty regeln aufrufen und werte addieren
	lw a1, 0(sp)
	lw a2, 4(sp)
	jal ra, penalty1
	add s0, s0, a0
	lw a1, 0(sp)
	lw a2, 4(sp)
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	jal ra, penalty2
	add s0, s0, a0
	lw a1, 0(sp)
	lw a2, 4(sp)
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	jal ra, penalty3
	add s0, s0, a0
	lw a1, 0(sp)
	lw a2, 4(sp)
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	jal ra, penalty4
	add s0, s0, a0
	lw a1, 0(sp)
	lw a2, 4(sp)
	
	#rückgabe wert setzen
	mv a0, s0
	
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	addi sp, sp, 16
	ret

#a1: modul with in pixel, a2: qr-version
#3 penalty punkte wenn mehr als 5 gleiche module hintereinander in einer reihe oder spalte (+1 für jedes weitere modul in der farbe)
penalty1:
	addi sp, sp, -40
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s5, 32(sp)
	sw s6, 36(sp)
	
	#rückgabewert für penalty
	addi s0, zero, 0
	
	#modulanzahl ermitteln
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 21
	
	#schleife durch alle module für horzitonale streifen
	addi s2, zero, 0#zähler y
	penalty1_loopy_h:
		addi s3, zero, 0#zähler x
		addi s4, zero, 0#vorhergehende farbe
		addi s5, zero, 0#wie oft farbe hintereinander
		penalty1_loopx_h:
			#aktuelle modulfarbe ermitteln
			mv a3, a1
			mv a1, s3
			mv a2, s2
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			
			beq s3, zero, penalty1_x_zero_h
				#wenn x > 0
				bne a0, s4 penalty1_color_mismatch_h
					#wenn farben identisch; counter um 1 erhöhen
					addi s5, s5, 1
					addi s6, zero, 5
					blt s5, s6, penalty1_color_mismatch_both_h
					bgt s5, s6, penalty1_count_greater_5_h
						addi s0, s0, 3
						j penalty1_color_mismatch_both_h
					penalty1_count_greater_5_h:
						addi s0, s0, 1
					j penalty1_color_mismatch_both_h
				penalty1_color_mismatch_h:
					#wenn farben nicht identisch farbe zwischenspeichern & s5 auf 1 setzen
					mv s4, a0
					addi s5, zero, 1
				penalty1_color_mismatch_both_h:
				j penalty1_x_zero_both_h
			penalty1_x_zero_h:
				#wenn x = 0 nur farbe zwischenspeichern und s5 um 1 erhöhen
				mv s4, a0
				addi s5, zero, 1
			penalty1_x_zero_both_h:
			
			#x bedingung
			addi s3, s3, 1
			blt s3, s1, penalty1_loopx_h
		
		#y bedingung
		addi s2, s2, 1
		blt s2, s1, penalty1_loopy_h
		
	#schleife durch alle module für vertikale streifen
	addi s2, zero, 0#zähler x
	penalty1_loopx_v:
		addi s3, zero, 0#zähler y
		addi s4, zero, 0#vorhergehende farbe
		addi s5, zero, 0#wie oft farbe hintereinander
		penalty1_loopy_v:
			#aktuelle modulfarbe ermitteln
			mv a3, a1
			mv a1, s2
			mv a2, s3
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			
			beq s3, zero, penalty1_y_zero_v
				#wenn y > 0
				bne a0, s4 penalty1_color_mismatch_v
					#wenn farben identisch; counter um 1 erhöhen
					addi s5, s5, 1
					addi s6, zero, 5
					blt s5, s6, penalty1_color_mismatch_both_v
					bgt s5, s6, penalty1_count_greater_5_v
						addi s0, s0, 3
						j penalty1_color_mismatch_both_v
					penalty1_count_greater_5_v:
						addi s0, s0, 1
					j penalty1_color_mismatch_both_v
				penalty1_color_mismatch_v:
					#wenn farben nicht identisch farbe zwischenspeichern & s5 auf 1 setzen
					mv s4, a0
					addi s5, zero, 1
				penalty1_color_mismatch_both_v:
				j penalty1_y_zero_both_v
			penalty1_y_zero_v:
				#wenn y = 0 nur farbe zwischenspeichern und s5 um 1 erhöhen
				mv s4, a0
				addi s5, zero, 1
			penalty1_y_zero_both_v:
			
			#y bedingung
			addi s3, s3, 1
			blt s3, s1, penalty1_loopy_v
		
		#x bedingung
		addi s2, s2, 1
		blt s2, s1, penalty1_loopx_v
	
	#rückgabe wert setzen
	mv a0, s0
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s5, 32(sp)
	lw s6, 36(sp)
	addi sp, sp, 40
	ret

#a1: modul with in pixel, a2: qr-version
#3 penalty punkte für jedes 2*2 feld der gleichen farbe (dürfen sich überlagern die blöcke)
penalty2:
	addi sp, sp, -32
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	
	#rückgabewert für penalty
	addi s0, zero, 0
	
	#durch alle module durch laufen
	#ymax & xmax um eins kleiner als modul anzahl damit nicht ganz am rand gesucht wird
	#modul anzahl ermitteln
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 20
	
	addi s2, zero, 0 #zähler y
	penalty2_loopy:
		addi s3, zero, 0 #zähler x
		penalty2_loopx:
		
			#eigene farbe ermitteln
			mv a3, a1
			mv a1, s3
			mv a2, s2
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			mv s4, a0 #farbe zwischenspeichern
		
			#schauen was die farbe rechts ist
			mv a3, a1
			addi a1, s3, 1
			mv a2, s2
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			bne s4, a0 penalty2_skip_penalty
			
			#schauen was die farbe unten drunter ist
			mv a3, a1
			mv a1, s3
			addi a2, s2, 1
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			bne s4, a0 penalty2_skip_penalty
			
			#schauen was die farbe unten rechts ist
			mv a3, a1
			addi a1, s3, 1
			addi a2, s2, 1
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			bne s4, a0 penalty2_skip_penalty
			
			#alle felder gleich = penalty von 3 hinzufügen
			addi s0, s0, 3
			
			penalty2_skip_penalty:
			
			#x bedingung
			addi s3, s3, 1
			blt s3, s1, penalty2_loopx
		
		#y bedingung
		addi s2, s2, 1
		blt s2, s1, penalty2_loopy
	
	#rückgabe wert setzen
	mv a0, s0
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	addi sp, sp, 32
	ret
	
#ein switchcase um alle temporären farben in finale farben umzuändern
#a1 farbe des modules
penalty_tmp_color_to_final:
	addi sp, sp, -12
	sw a1, 0(sp)
	sw ra, 4(sp)
	sw s0, 8(sp)
	
	penalty_tmp_color_to_final_case_fbfbfb:
		li s0, 0xfbfbfb
		bne a1, s0, penalty_tmp_color_to_final_case_fdfdfd
			li a0, 0x000000
		j penalty_tmp_color_to_final_end
	penalty_tmp_color_to_final_case_fdfdfd:
		li s0, 0xfdfdfd
		bne a1, s0, penalty_tmp_color_to_final_case_fafafa
			li a0, 0x000000
		j penalty_tmp_color_to_final_end
	penalty_tmp_color_to_final_case_fafafa:
		li s0, 0xfafafa
		bne a1, s0, penalty_tmp_color_to_final_case_fcfcfc
			li a0, 0xffffff
		j penalty_tmp_color_to_final_end
	penalty_tmp_color_to_final_case_fcfcfc:
		li s0, 0xfcfcfc
		bne a1, s0, penalty_tmp_color_to_final_default
			li a0, 0xffffff
		j penalty_tmp_color_to_final_end
	penalty_tmp_color_to_final_default:
		mv a0, a1
	penalty_tmp_color_to_final_end:	
	lw a1, 0(sp)
	lw ra, 4(sp)
	lw s0, 8(sp)
	addi sp, sp, 12
	ret
	

#a1: modul with in pixel, a2: qr-version
#40 penalty punkte wenn folgendes pattern vorhanden ist s,w,s,s,s,w,s,w,w,w,w horizontal oder vertikal (s=schwarz, w=weiß)(dürfen überlappen)
penalty3:
	addi sp, sp, -100
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s5, 32(sp)
	sw s6, 36(sp)
	sw s8, 40(sp)
	sw s9, 44(sp)
	sw s10, 48(sp)
	sw s11, 52(sp)
	
	#Muster in stack zwischenspeichern
	li s0, 0x000000
	li s1, 0xffffff
	sw s0, 56(sp)
	sw s1, 60(sp)
	sw s0, 64(sp)
	sw s0, 68(sp)
	sw s0, 72(sp)
	sw s1, 76(sp)
	sw s0, 80(sp)
	sw s1, 84(sp)
	sw s1, 88(sp)
	sw s1, 92(sp)
	sw s1, 96(sp)
	
	#rückgabewert für penalty
	addi s0, zero, 0
	
	#modulanzahl berechnen
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 21
	
	#loop für horizontalen durchlauf
	addi s2, zero, 0 #y zähler
	penalty3_loopy_h:
		addi s3, zero, 0 #x zähler
		penalty3_loopx_h:
			#schauen ob man rechts zu nah an der grenze ist
			addi s4, s1, -11
			bge s3, s4, penalty3_too_close_end_h
				#noch im gültigen bereich
				addi s4, zero, 0#zähler für musterdurchlauf
				penalty3_loop_pattern_end_h:
					#farbe des jeweiligen modules ermitteln
					mv a3, a1
					add a1, s3, s4#nach rechts module durchschauen
					mv a2, s2
					jal ra, get_module_color
					lw a1, 0(sp)
					lw a2, 4(sp)
			
					mv a1, a0
					jal ra, penalty_tmp_color_to_final
					lw a1, 0(sp)
					
					#position im stack ermitteln & farbe lesen
					slli s5, s4, 2 
					addi s5, s5, 56
					add s5, s5, sp
					lw s6, 0(s5)
					
					#schauen ob identisch auf stack
					bne a0, s6, penalty3_too_close_end_h
					#wenn identisch ist schauen ob es das letzt zu vergleichende zeichen ist
					addi s6, zero, 10
					beq s4, s6, penalty3_skip_penalty_end_h 
						#wenn nicht letzten zeichen
						addi s4, s4, 1
						j penalty3_loop_pattern_end_h
					penalty3_skip_penalty_end_h:
						#wenn letzten zeichen
						addi s0, s0, 40
			
			penalty3_too_close_end_h:
			#schauen ob man zu nah links ist
			addi s4, zero, 10
			blt s3, s4, penalty3_too_close_begin_h
				#im gültigen bereich
				addi s4, zero, 0#zähler für musterdurchlauf
				penalty3_loop_pattern_begin_h:
					#farbe des jeweiligen modules ermitteln
					mv a3, a1
					sub a1, s3, s4#nach links module durchschauen
					mv a2, s2
					jal ra, get_module_color
					lw a1, 0(sp)
					lw a2, 4(sp)
			
					mv a1, a0
					jal ra, penalty_tmp_color_to_final
					lw a1, 0(sp)
					
					#position im stack ermitteln & farbe lesen
					slli s5, s4, 2 
					addi s5, s5, 56
					add s5, s5, sp
					lw s6, 0(s5)
					
					#schauen ob identisch auf stack
					bne a0, s6, penalty3_too_close_begin_h
					#wenn identisch ist schauen ob es das letzt zu vergleichende zeichen ist
					addi s6, zero, 10
					beq s4, s6, penalty3_skip_penalty_begin_h 
						#wenn nicht letzten zeichen
						addi s4, s4, 1
						j penalty3_loop_pattern_begin_h
					penalty3_skip_penalty_begin_h:
						#wenn letzten zeichen
						addi s0, s0, 40
		
			penalty3_too_close_begin_h:
			#x bedingung
			addi s3, s3, 1
			blt s3, s1, penalty3_loopx_h
			
		#y bedingung
		addi s2, s2, 1
		blt s2, s1, penalty3_loopy_h
		
	#loop für vertikalen durchlauf
	addi s2, zero, 0 #x zähler
	penalty3_loopx_v:
		addi s3, zero, 0 #y zähler
		penalty3_loopy_v:
			#schauen ob man unten zu nah an der grenze ist
			addi s4, s1, -11
			bge s3, s4, penalty3_too_close_end_v
				#noch im gültigen bereich
				addi s4, zero, 0#zähler für musterdurchlauf
				penalty3_loop_pattern_end_v:
					#farbe des jeweiligen modules ermitteln
					mv a3, a1
					add a2, s3, s4#nach unten module durchschauen
					mv a1, s2
					jal ra, get_module_color
					lw a1, 0(sp)
					lw a2, 4(sp)
			
					mv a1, a0
					jal ra, penalty_tmp_color_to_final
					lw a1, 0(sp)
					
					#position im stack ermitteln & farbe lesen
					slli s5, s4, 2 
					addi s5, s5, 56
					add s5, s5, sp
					lw s6, 0(s5)
					
					#schauen ob identisch auf stack
					bne a0, s6, penalty3_too_close_end_v
					#wenn identisch ist schauen ob es das letzt zu vergleichende zeichen ist
					addi s6, zero, 10
					beq s4, s6, penalty3_skip_penalty_end_v 
						#wenn nicht letzten zeichen
						addi s4, s4, 1
						j penalty3_loop_pattern_end_v
					penalty3_skip_penalty_end_v:
						#wenn letzten zeichen
						addi s0, s0, 40
			
			penalty3_too_close_end_v:
			#schauen ob man zu nah oben ist
			addi s4, zero, 10
			blt s3, s4, penalty3_too_close_begin_v
				#im gültigen bereich
				addi s4, zero, 0#zähler für musterdurchlauf
				penalty3_loop_pattern_begin_v:
					#farbe des jeweiligen modules ermitteln
					mv a3, a1
					sub a2, s3, s4#nach oben module durchschauen
					mv a1, s2
					jal ra, get_module_color
					lw a1, 0(sp)
					lw a2, 4(sp)
			
					mv a1, a0
					jal ra, penalty_tmp_color_to_final
					lw a1, 0(sp)
					
					#position im stack ermitteln & farbe lesen
					slli s5, s4, 2 
					addi s5, s5, 56
					add s5, s5, sp
					lw s6, 0(s5)
					
					#schauen ob identisch auf stack
					bne a0, s6, penalty3_too_close_begin_v
					#wenn identisch ist schauen ob es das letzt zu vergleichende zeichen ist
					addi s6, zero, 10
					beq s4, s6, penalty3_skip_penalty_begin_v
						#wenn nicht letzten zeichen
						addi s4, s4, 1
						j penalty3_loop_pattern_begin_v
					penalty3_skip_penalty_begin_v:
						#wenn letzten zeichen
						addi s0, s0, 40
		
			penalty3_too_close_begin_v:
			#x bedingung
			addi s3, s3, 1
			blt s3, s1, penalty3_loopy_v
			
		#y bedingung
		addi s2, s2, 1
		blt s2, s1, penalty3_loopx_v
	
	#rückgabe wert setzen
	mv a0, s0
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s5, 32(sp)
	lw s6, 36(sp)
	lw s8, 40(sp)
	lw s9, 44(sp)
	lw s10, 48(sp)
	lw s11, 52(sp)
	addi sp, sp, 100
	ret

#a1: modul with in pixel, a2: qr-version
#penalty punkte für den vielfachen von 5 prozentsatz von der farbe die weniger vorhanden ist (zu 50%), den wert *10 rechnen
penalty4:
	addi sp, sp, -44
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw ra, 8(sp)
	sw s0, 12(sp)
	sw s1, 16(sp)
	sw s2, 20(sp)
	sw s3, 24(sp)
	sw s4, 28(sp)
	sw s5, 32(sp)
	sw s6, 36(sp)
	sw s7, 40(sp)
	
	#rückgabewert für penalty
	addi s0, zero, 0
	
	#alle schwarzen module zählen
	#modul anzahl ermitteln
	addi s1, a2, -1
	slli s1, s1, 2
	addi s1, s1, 21
	
	addi s2, zero, 0#zähler für schwarzen module
	addi s3, zero, 0#zähler y
	penalty4_loopy:
		addi s4, zero, 0#zähler x
		penalty4_loopx:
		
			#modulfarbe ermitteln
			mv a3, a1
			mv a1, s4
			mv a2, s3
			jal ra, get_module_color
			lw a1, 0(sp)
			lw a2, 4(sp)
			
			mv a1, a0
			jal ra, penalty_tmp_color_to_final
			lw a1, 0(sp)
			
			li s5, 0x000000
			bne s5, a0, penalty4_skip
				#farbe ist schwarz deswegen um 1 erhöhen
				addi s2, s2, 1
			penalty4_skip:
			#loopx bedingung
			addi s4, s4, 1
			blt s4, s1, penalty4_loopx
			
		#loopy bedingung
		addi s3, s3, 1
		blt s3, s1, penalty4_loopy
			
	#gesamt modul anzahl ermitteln
	mul s1, s1, s1 #mal 2 gerechnet
	
	#prozentsatz von schwarzen ausrechnen
	addi s5, zero, 100
	mul s6, s2, s5
	add s7, s2, s1
	srli s7, s7, 1
	add s7, s6, s7
	div s7, s7, s1
	
	#vorhergendes vielfaches von 5
	addi s5, zero, 5
	div s6, s7, s5
	mul s6, s6, s5
	
	#nachfolgendes vielfaches von 5
	add s5, s6, s5
	
	#betrag von s6-50
	addi s6, s6, -50
	bge s6, zero, penalty4_betrag_1_already
		addi s7, zero, -1
		mul s6, s6, s7
	penalty4_betrag_1_already:
	
	#betrag von s5-50
	addi s5, s5, -50
	bge s5, zero, penalty4_betrag_2_already
		addi s7, zero, -1
		mul s5, s5, s7
	penalty4_betrag_2_already:
	
	#kleinere der beiden zahlen nehmen
	blt s6, s5, penalty4_end
	mv s6, s5
	
	
	#ergebnis mal 10 als rückgabe wert
	penalty4_end:
	addi s7, zero, 10
	mul a0, s6, s7
	
	#rückgabe wert setzen
	mv a0, s0
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw ra, 8(sp)
	lw s0, 12(sp)
	lw s1, 16(sp)
	lw s2, 20(sp)
	lw s3, 24(sp)
	lw s4, 28(sp)
	lw s5, 32(sp)
	lw s6, 36(sp)
	lw s7, 40(sp)
	addi sp, sp, 44
	ret

#muss am ende stehen sonst wird der code dort drin ausgeführt
.include "draw_fun.asm"
