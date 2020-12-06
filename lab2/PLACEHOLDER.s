		ldi		r16,HIGH(RAMEND)
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16

		jmp		INIT

//Define the ascii table
BTAB:	.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8

//Message to be printed
TEXT:	.db "BENBO BENBO BENBO",$00

//Define frequency 
.equ	FREQ = 7

STOP:
		breq	STOP


INIT:
		ldi		r16,$FF
		out		DDRB,r16
		ldi		ZH,HIGH(TEXT*2)
		ldi		ZL,LOW(TEXT*2)

//Get a character from string
GET_CHAR:
		lpm		r16,Z+
		cpi		r16,$00			;Determine if the string is empty
		breq	STOP			;Stop if whole byte is empty
		call	SPACECONTROL

//Look up binary eqvuivalent of loaded ASCII char
LOOKUP:
		ldi		r17,$41
		sub		r16,r17			;Find indexing value for the character in BTAB by subtracting $41 (0=A, 1=B, 2=C etc)
		push	r31				;Save the adress for TEXT to the stack
		push	r30				
		ldi		ZH,HIGH(BTAB*2)	
		ldi		ZL,LOW(BTAB*2)

INC_INDEX:
		lpm		r20,Z+
		cpi		r16,$00
		breq	SEND			;Indexing complete, start sending hex-value from r20
		dec		r16
		jmp		INC_INDEX



//Send and process character
SEND:
		lsl		r20				;Shift out msb to carry to be analysed
		brcc	BEEP			;Beep a short signal if carry is equal to 0	
		;-----------------------;At this point the carry is set, which means it might be the end of the char
		cpi		r20,$00			;Determine if the chars binary is empty
		breq	PAUSELONG		;Do long pause if string was empty
		;-----------------------;

BEEPLONG:
		sbi		PORTB,4			
		call	DELAY
		call	DELAY
		call	DELAY
		jmp		PAUSE			;pause after character

BEEP:	
		sbi		PORTB,4		
		call	DELAY
		jmp		PAUSE			;pause after character

//1 unit of silence after each beep
PAUSE:
		cbi		PORTB,4			;Signal Summer to deactivate
		call	DELAY
		jmp		SEND			;Return and continue processing char

PAUSELONG:
		pop		r30				;Finished with Z pointer, pop it back to track TEXT chars
		pop		r31
		call	DELAY
		call	DELAY
		call	DELAY
		jmp		GET_CHAR			;Return and finish the char


SPACECONTROL:
		cpi		r16,$20
		breq	PAUSESPACE
		ret

		
PAUSESPACE:
		call	DELAY
		call	DELAY
		call	DELAY
		call	DELAY
		call	DELAY
		call	DELAY
		call	DELAY
		jmp		GET_CHAR

DELAY:
		ldi		r28,FREQ		
D_3:
		ldi		r27,0
D_2:	
		ldi		r26,0
D_1:
		dec		r26
		brne	D_1
		dec		r27
		brne	D_2
		dec		r28
		brne	D_3
		ret
