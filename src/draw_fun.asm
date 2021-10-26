#a1: x, a2:y, a3: color
draw_pixel:
	#werte auf stack speichern
	addi sp, sp, -20
	sw s0, 0(sp)	#für relative position & später finale position
	sw s1, 4(sp)	#zum zwischenspeichern der display_adresse
	sw a1, 8(sp)
	sw a2, 12(sp)
	sw a3, 16(sp)
	
	#richtige zeile ermitteln
	li s0, DISPLAY_WIDTH
	mul s0, a2, s0
	#stelle in der zeile ermitteln
	add s0, a1, s0
	
	#mal 4 rechnen da ein wert immer aus rgb- besteht
	slli s0, s0, 2
	
	#benötigte adresse ermitteln
	li s1, DISPLAY_ADDRESS
	add s0, s0, s1

	#farbe an die gewünschte stelle setzen
	sw a3, 0(s0)

	#stack gespeicherte werte wieder laden
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw a1, 8(sp)
	lw a2, 12(sp)
	lw a3, 16(sp)
	addi sp, sp, 20
	ret

#a1: x link oben, a2: y rechts oben, a3: width in pixel, a4: color
draw_square:
	#werte auf stack speichern
	addi sp, sp, -28
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw a4, 12(sp)
	sw s0, 16(sp)	#zähler y achse
	sw s1, 20(sp)	#zähler x achse
	sw ra, 24(sp)	#ra ist caller saved
	
	addi s1, zero, 0	#zähler y setzen
	draw_square_loopy:
		addi s0, zero, 0	#zähler x setzen
		draw_square_loopx:	
			#parameter für draw pixel setzen
			add a1, a1, s0
			add a2, a2, s1
			add a3, zero, a4
			jal ra, draw_pixel
			#werte wieder vom stack laden da sie sich verändern haben könnten
			lw a1, 0(sp)
			lw a2, 4(sp)
			lw a3, 8(sp)
			lw a4, 12(sp)
			
			#laufvariable für x um eins hochzählen
			addi s0, s0, 1
			#loopx bedingung
			blt s0, a3, draw_square_loopx
		#x wieder an anfang des quadrads setzen setzen
		add s0, zero, a3
		
		#laufvariable für y um eins hochzählen
		addi s1, s1, 1
		#loopy bedingung			
		blt s1, a3, draw_square_loopy

	#werte aus stack laden
	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw a4, 12(sp)
	lw s0, 16(sp)
	lw s1, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28

	ret
	
#a1: x links oben, a2: y links oben, a3: x rechts unten, a4: y rechts unten, a5: color
draw_rectangle:
	#werte auf stack speichern
	addi sp, sp, -32
	sw a1, 0(sp)
	sw a2, 4(sp)
	sw a3, 8(sp)
	sw a4, 12(sp)
	sw a5, 16(sp)
	sw s0, 20(sp)
	sw s1, 24(sp)
	sw ra, 28(sp)
	
	add s1, zero, a2 #zähler y setzen
	
	draw_rectangle_loopy:
	
		add s0, zero, a1 #zähler x setzen
		draw_rectangle_loopx:	
			#draw pixel aufrufen
			add a1, zero, s0
			add a2, zero, s1
			add a3, zero, a5
			jal ra, draw_pixel
			#daten wieder vom stack laden die sich verändert haben könnten
			lw a1, 0(sp)
			lw a2, 4(sp)
			lw a3, 8(sp)
			lw a4, 12(sp)
			lw a5, 16(sp)
			
			#for loopx bedingung
			addi s0, s0, 1
			bne s0, a3, draw_rectangle_loopx
		
		#for loopy bedingung	
		addi s1, s1, 1			
		bne s1, a4, draw_rectangle_loopy


	lw a1, 0(sp)
	lw a2, 4(sp)
	lw a3, 8(sp)
	lw a4, 12(sp)
	lw a5, 16(sp)
	lw s0, 20(sp)
	lw s1, 24(sp)
	lw ra, 28(sp)
	addi sp, sp, 32

	ret
	
#a1: color
clear_screen:
	#werte auf stack speichern
	addi sp, sp, -24
	sw a1, 0(sp)
	sw s0, 4(sp)	#y zähler
	sw s1, 8(sp)	#x zähler
	sw s2, 12(sp)	#display_width
	sw s3, 16(sp)	#display_height
	sw ra, 20(sp)
	
	li s2, DISPLAY_WIDTH
	li s3, DISPLAY_HEIGHT
	
	addi s0, zero, 0	# y zähler setzen
	clear_screen_loopy:
		addi s1, zero, 0	#x zähler setzen
		clear_screen_loopx:
			#parameter für functionsaufruf setzen
			add a3, zero, a1
			add a1, zero, s1
			add a2, zero, s0
			jal ra, draw_pixel
			#register wiederherstellen
			lw a1, 0(sp)
			
			#zähler x um eins erhöhen
			addi s1, s1, 1
			#loopx bedingung
			blt s1, s2, clear_screen_loopx
		
		#zähler y um eins erhöhen
		addi s0, s0, 1
		blt s0, s3, clear_screen_loopy			
	
	#werte aus stack laden
	lw a1, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	lw ra, 20(sp)
	addi sp, sp, 24
	
	ret
