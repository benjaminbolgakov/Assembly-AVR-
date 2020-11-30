.def tmp=r20

START: 
	ldi r16,HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16

HW_INIT:
	ldi r16,0x01	;0b00000001
	out DDRB, r16
	
	ldi	r16, 0x00	; clr r16
	out DDRC,r16

MAIN:
	in r16,PINC
	andi r16,0x00000001		;yyyyyyyy and 00000001 = 0000000y
	breq MAIN				;Loop until PINC is a 1

	ldi r16,0x00000001
	out PORTB, r16

	call DELAY_8bit

	ldi r16, 0x00
	out PORTB,r16

NOT_RELEASED:
	sbic PINC,0
	jmp NOT_RELEASED

	jmp MAIN

DELAY_8bit:
	ldi r18,0
L_1:
	dec r18
	brne L_1
	ret

DELAY_16bit:
	clr r25
	clr r24
L_2:
	adiw r24,1		; Add 1 to r24
	brne L_2		; until r24 is maxed
	ret