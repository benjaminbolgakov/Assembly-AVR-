	
	.equ	FN_SET		= 0b00101000			;4-bit mode, 2 line, 5x8 font
	.equ	DISP_ON		= 0b00001111			;Display on, cursor on, cursor blink
	.equ	LCD_CLR		= 0b00000001			;Clear display
	.equ	E_MODE		= 0b00000110			;Increment cursor, no shift		

	.equ	E			= 1

	INIT:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	call	WAIT			;Delay to let LCD start up
	call	PORT_INIT
	call	BACKLIGHT_ON	
	call	FOURBIT_INIT
	call	DISP_CONFIG		;Blinking cursor at this point
	call	WAIT
	call	ADC_READ8
	call	LCD_PRINT_HEX
MAIN:
	;call	KEY_READ
	;call	LCD_COL
	jmp		MAIN

KEY_READ:
	call	KEY
	tst		r16
	brne	KEY_READ
KEY_WAIT_FOR_PRESS:
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS
	ret
KEY:
	;IDLE =		$FF					=	255
	;SELECT =	$9F||$AA||$A4||$99	=	159||170
	;LEFT =		$66					=	102
	;DOWN =		$40||$44			=	64
	;UP =		$18||$11			=	24
	;RIGHT =	$00					=	0
	call	ADC_READ8
	cpi		r16,$FF		;Check for idle state
	breq	IDLE
	//Check for RIGHT btn
	mov		r17,r16
	ldi		r18,12
	sub		r17,r18
	brmi	RIGHT		;0
	//Check for UP btn
	mov		r17,r16
	ldi		r18,44
	sub		r17,r18
	brmi	UP			;24
	//Check for DOWN btn
	mov		r17,r16
	ldi		r18,83
	sub		r17,r18
	brmi	DOWN		;64
	//Check for LEFT btn
	mov		r17,r16
	ldi		r18,130
	sub		r17,r18
	brmi	LEFT		;102
	/*Check for SELECT btn
	mov		r17,r16
	ldi		r18,207
	sub		r17,r18
	brmi	SELECT		;159
	*/
	jmp		SELECT
IDLE:
	ldi		r16,0
	jmp		KEYDONE
SELECT:
	ldi		r16,1
	jmp		KEYDONE
LEFT:
	ldi		r16,2
	jmp		KEYDONE
DOWN:
	ldi		r16,3
	jmp		KEYDONE
UP:
	ldi		r16,4
	jmp		KEYDONE
RIGHT:
	ldi		r16,5
	jmp		KEYDONE
KEYDONE:
	ret

LCD_COL:
	ldi		r17,0b10000000		;Load prerequisite 
	or		r16,r17				;Add together with wanted 
	call	LCD_COMMAND
	ret

//Analog-Digital convertion
ADC_READ8:
	ldi		r16,(1<<REFS0)|(1<<ADLAR)
	sts		ADMUX,r16
	ldi		r16,(1<<ADEN)|7
	sts		ADCSRA,r16
CONVERT:
	lds		r16,ADCSRA
	ori		r16,(1<<ADSC)
	sts		ADCSRA,r16
ADC_BUSY:
	lds		r16,ADCSRA
	sbrc	r16,ADSC
	jmp		ADC_BUSY
	lds		r16,ADCH		;Store result to be processed
	ret

LCD_PRINT:
	call	GET_CHAR
	call	LCD_ASCII
	cpi		r16,$00			;Determine if the string is empty
	brne	LCD_PRINT		
	ret
GET_CHAR:
	ld		r16,Z+
	ret
LCD_WRITE4:
	sbi		PORTB,E			
	out		PORTD,r16		;Output data
	cbi		PORTB,E			;Signals to LCD that new data is available
	call	WAIT			
	ret
LCD_WRITE8:
	call	LCD_WRITE4		;Write first 4 bits
	swap	r16				;Place remaining bits in position
	call	LCD_WRITE4		;Write remaining 4 bits
	ret
LCD_ASCII:
	sbi		PORTB,0			;Config LCD for ASCII
	call	LCD_WRITE8
	ret
LCD_COMMAND:
	cbi		PORTB,0			;Config LCD for commands
	call	LCD_WRITE8
	ret

//INPUT: r16
LCD_PRINT_HEX:
	ldi		r25,$30			;ASCII index offset 0-9
	ldi		r26,$37			;ASCII index offset A-F
	ldi		r27,2
	swap	r16				;To print in correct order, swap the lower and higher bounds.
FORMAT:
	cpi		r27,0
	breq	DONE
	dec		r27
	ldi		r17,0b00001111
	and		r16,r17
	cpi		r16,$0A		
	brmi	NUMHEX
	add		r16,r26			;The hexvalue is larger than 9, add extra offset
	call	LCD_ASCII
	jmp		FORMAT
NEXT:
	swap	r16				;Swap again to process the remaining 4bits
	jmp		FORMAT
NUMHEX:
	add		r16,r25			;Add base offset
	call	LCD_ASCII
	jmp		NEXT
DONE:
	ret

//Set write-pos at column 0 (home/start pos)
LCD_HOME:
	ldi		r16,0b00000010
	call	LCD_COMMAND
	ret

//Erase the content on screen
LCD_ERASE:
	ldi		r16,LCD_CLR
	call	LCD_COMMAND
	ret
BACKLIGHT_ON:
	sbi		PORTB,2
	ret
BACKLIGHT_OFF:
	cbi		PORTB,2
	ret

//Init the ports accordingly
PORT_INIT:
	ldi		r16,$FF
	out		DDRB,r16		;output
	out		DDRD,r16		;output
	ldi		r16,$00
	out		DDRC,r16
	ret

//Configures the display to function according to FN_SET, DISP_ON etc..
DISP_CONFIG:
	ldi		r16,FN_SET
	call	LCD_COMMAND
	ldi		r16,LCD_CLR
	call	LCD_COMMAND
	ldi		r16,DISP_ON
	call	LCD_COMMAND
	ldi		r16,E_MODE
	call	LCD_COMMAND
	ret

//Init the display to receive and process 4bit data
FOURBIT_INIT:
	ldi		r16,$30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4
	ldi		r16,$20
	call	LCD_WRITE4
	ret

WAIT:
	ldi		r20,3
D_3:
	ldi		r19,0
D_2:
	ldi		r18,0
D_1:
	dec		r18
	brne	D_1
	dec		r19
	brne	D_2
	dec		r20
	brne	D_3
	ret