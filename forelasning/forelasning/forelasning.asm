
//Defining a table/string called TEXT in flashmemory
TEXT :
	.db "HELLO WORLD",$00
ADDITION:
	//Add lower byte
	lds r16,$120	;Load $120 from SRAM
	lds	r17,$122	;Load $122 from SRAM
	add r16,r17		;Add the lower bytes. Can trigger carry, FLAG=C
	sts $124,r16	;Load result to SRAM

	//Add higher byte
	lds r16,$121	;Load $121 from SRAM
	lds r17,$123	;Load $123 from SRAM
	adc	r16,r17		;Add higher bytes with carry: r16+r17+C.
	sts $125,r16	;Load to SRAM

//Subroutin ----
PARITET:
	ldi r16,9
	clr r18
	clc				;Clear carry
LOOP:	
	ror	r17			;Rotate right
	brcc ZERO
	inc r18
ZERO:
	dec r16
	brne LOOP
	lsr r18
	brcs UNEVEN	
	ori r17,$80
UNEVEN:
	ret
//Subroutin ----

//Call subroutin
lds r17,$110
call PARITET
sts $110,r17

POINT_SRAM:
	//Point to SRAM address $120
	ldi	XH,HIGH($120)		;Load higher byte of string value into adress X (r27, $1B)
	ldi	XL,LOW($120)		;Load lower byte of string value into adress X (r26, $1A)
	ld	r20, X

READFLASH:
	ldi ZH,HIGH(TEXT*2)		;Load higher byte of string value in flashmemory
	ldi ZH,LOW(TEXT*2)		;Load lower byte of string value in flashmemory
NEXT:
	lpm r16,Z		;Load from program memory / flash memory
	cpi r16,$00		;Compare bit with $00 to find the end of the string
	breq EXIT		;Exit if current bit from r16 is =0 
	;process data..
	adiw ZL,1		;16bit addition, looping through the full 2 bytes
	jmp NEXT		;Go 

EXIT:
	