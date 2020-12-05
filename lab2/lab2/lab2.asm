		ldi		r16,HIGH(RAMEND)
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16

		jmp		INIT

//Define the ascii table
BTAB:	.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8

//Message to be printed
TEXT:	.db "ACE",$00

//Define frequency 
.equ	FREQ = 20


INIT:
		ldi		r18,$FF
		out		DDRB,r18
		ldi		ZH,HIGH(TEXT*2)
		ldi		ZL,LOW(TEXT*2)

//Get a character from string
GET_CHAR:
		lpm		r16,Z+
		cpi		r16,$00			;Determine if the string is empty
		breq	STOP			;Stop if whole byte is empty

//Look up the defining "sound" of an ASCII
LOOKUP:
		ldi		r17,$41
		sub		r16,r17			;Find indexing value for the character in BTAB by subtracting $41 (0=A, 1=B, 2=C etc)
		push	r31				;Save the adress for TEXT to the stack
		push	r30				;Save the adress for TEXT to the stack
		ldi		ZH,HIGH(BTAB*2)
		ldi		ZL,LOW(BTAB*2)
		call	INDEX
				
		pop		r30
		pop		r31

INDEX:
		lpm		r20,Z+
		cpi		r16,$00
		breq	LOOKUP
		dec		r16
//Send and process character
SEND:
		lsl		r20				;Shift out msb to carry to be analysed
		brcc	BEEP			;Beep a short signal if carry is equal to 0	
								;At this point the carry is set, which means it might be the end of the char
		cpi		r20,$00			;Determine if the string is empty
		breq	PAUSELONG		;Do long pause if string was empty
		
BEEPLONG:
		sbi		PORTB,4			
		;call	DELAY
		;call	DELAY
		;call	DELAY
		jmp		PAUSE			;pause after character

BEEP:	;Fix with argument, to beep long or short here
		sbi		PORTB,4			
		;call	DELAY
		jmp		PAUSE			;pause after character


//Silence after each character
PAUSE:
		cbi		PORTB,4			;Signal Summer to deactivate
		;call	DELAY
		jmp		SEND			;Return and continue processing char

PAUSELONG:
		;call	DELAY
		;call	DELAY
		;call	DELAY
		jmp		GET_CHAR			;Return and finish the char
		
STOP:
		ldi		r16,$FF
		brne	STOP

DELAY:
		ldi		r18,3
D_3:
		ldi		r17,0
D_2:	
		ldi		r16,0
D_1:
		dec		r16
		brne	D_1
		dec		r17
		brne	D_2
		dec		r18
		brne	D_3
		ret
