		ldi		r16,HIGH(RAMEND)
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16

		jmp		INIT

//Define the ascii table
BTAB:	
		.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8

//Message to be printed
TEXT:	
		.db "ABC",$00

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
		cpi		r16,$00		;Determine if the string is empty
		breq	STOP		;Stop if whole byte is empty
		call	LOOKUP


//Look up the defining "sound" of an ASCII and return it's binary 
LOOKUP:
		ldi		r17,$41
		sub		r16,r17		;Decode ASCII to binary by subtracting $41 which leaves the indexing values for the table (0,1,2,3...etc)
		call	SEND		;Send with decoded ascii via parameter?
		

//Send and process character
SEND:
		ldi		XH,HIGH(BTAB*2)
		ldi		XL,LOW(BTAB*2)
		ld		r20,X
		add		r20,r16			;Create the correct index
		sbi		PORTB,4			;Signal Summer to activate
		call	DELAY
		call	NOBEEP			;pause after character

//Silence after each character
NOBEEP:
		cbi		PORTB,4		;Signal Summer to deactivate
		call	DELAY
		jmp		GET_CHAR




STOP:
		breq	STOP



TEST:
		ldi		r16,$FF
		out		DDRB,r16
		sbi		PORTB,4

CLOSE:
		cbi		PORTB,4



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
