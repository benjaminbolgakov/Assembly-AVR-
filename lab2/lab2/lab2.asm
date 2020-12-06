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

START:
		call	GET_CHAR
		call	LOOKUP
		call	SEND
		call	PAUSE			;Do a pause of 2+1 time-units between chars

//GET_CHAR-------------------------------------------------------------------------//
GET_CHAR:
		lpm		r16,Z+
		cpi		r16,$00			;Determine if the string is empty
		breq	STOP			;Stop if whole byte is empty

SPACECONTROL:
		cpi		r16,$20
		breq	PAUSESPACE
		ret
//-------------------------------------------------------------------------GET_CHAR//

//LOOKUP------------------------------------------------------------------------//
LOOKUP:
		ldi		r17,$41
		sub		r16,r17			;Find indexing value for the character in BTAB by subtracting $41 (0=A, 1=B, 2=C etc)
		push	r31				;Save the address for TEXT to the stack
		push	r30				
		ldi		ZH,HIGH(BTAB*2)	
		ldi		ZL,LOW(BTAB*2)

//Increments to the correct index of BTAB
INC_INDEX:
		lpm		r20,Z+
		dec		r16
		cpi		r16,$FF
		brne	INC_INDEX
		pop		r30				;Finished with Z pointer, pop it back to track TEXT chars
		pop		r31
		ret	
//-------------------------------------------------------------------------LOOKUP//

//SEND-------------------------------------------------------------------------//
SEND:
		lsl		r20				;Shift out msb to carry to be analysed
		brcc	SHORT			;Beep a short signal if carry is equal to 0	
		;-----------------------;At this point the carry is set, which means it might be the end of the char
		cpi		r20,$00			
		breq	END				;The char is processed, apply the proper pause
		;-----------------------;
LONG:	
		ldi		r21,3			;Set the length of the beep to 3N
		sbi		PORTB,4
		jmp		BEEP
		
SHORT:
		ldi		r21,1			;Set the length of the beep to 1N
		sbi		PORTB,4
		jmp		BEEP

BEEP:
		call	DELAY
		dec		r21
		brne	BEEP
		cbi		PORTB,4
		call	DELAY
		jmp		SEND

END:
		ldi		r22,3			;Set pause-time to 3 units, for the end of this char
		ret
//-------------------------------------------------------------------------SEND//

PAUSESPACE:
		ldi		r22,7
		jmp		PAUSE

PAUSE:
		call	DELAY
		dec		r22
		brne	PAUSE
		jmp		START			;Start over the process to get next char



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
