	
	.equ	FN_SET		= 0b00101000			;4-bit mode, 2 line, 5x8 font
	.equ	DISP_ON		= 0b00001111			;Display on, cursor on, cursor blink
	.equ	LCD_CLR		= 0b00000001			;Clear display
	.equ	E_MODE		= 0b00000110			;Increment cursor, no shift		

	.equ	E			= 1

.dseg
CUR_POS:	.db $00
LINE:		.byte 17
.cseg

	INIT:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	call	MEM_INIT
	call	WAIT			;Delay to let LCD start up
	call	PORT_INIT
	call	BACKLIGHT_ON	
	call	FOURBIT_INIT
	call	DISP_CONFIG		;Blinking cursor at this point
	call	WAIT
MAIN:
	;call	LINE_PRINT
	call	LCD_COL			;Update current column
	call	SWITCH_BACKLIGHT
	call	KEY_READ			
	
	/*call	LINE_UPDATE
	ldi		r16,5
	call	LCD_COL
	ldi		r16,5
	call	LCD_COL
	ldi		r16,3
	call	LINE_UPDATE
	ldi		r16,4
	call	LINE_UPDATE*/
	jmp		MAIN
	
LCD_COL:
	ldi		XH,HIGH(CUR_POS)
	ldi		XL,LOW(CUR_POS)
	cpi		r16,2
	breq	BACK
	cpi		r16,5
	breq	FORWARD
	ld		r16,X
	jmp		LCD_COl_DONE
BACK:
	ld		r16,X
	cpi		r16,0b10000000
	breq	LCD_COL_DONE
	dec		r16
	st		X,r16
	jmp		LCD_COl_DONE
FORWARD:
	ld		r16,X
	cpi		r16,0b10001111
	breq	LCD_COL_DONE
	inc		r16
	st		X,r16
LCD_COl_DONE:
	call	LCD_COMMAND
	ret

LINE_UPDATE:
	ldi		ZH,HIGH(LINE)
	ldi		ZL,LOW(LINE)
	ldi		XH,HIGH(CUR_POS)
	ldi		XL,LOW(CUR_POS)
	ld		r20,X			;Loop index to change data on correct position in LINE
	andi	r20,0b00011111
	cpi		r16,3
	breq	BROWSE_DOWN
	cpi		r16,4
	breq	BROWSE_UP
	jmp		UPDATED
BROWSE_DOWN:
	ld		r17,Z+			;Get LINE value from current cursor position
	dec		r20
	brne	BROWSE_DOWN
	cpi		r17,' '			;Check for lowest bound
	breq	UPDATED			
	cpi		r17,'A'
	breq	UPDATED
	dec		r17
	st		Z,r17
	jmp		UPDATED
BROWSE_UP:
	ld		r17,Z+			;Get LINE value from current cursor position
	dec		r20
	brne	BROWSE_UP
	ld		r17,Z			
	cpi		r17,'Z'			;Check for highest bound
	breq	UPDATED	
	ldi		r20,' '
	cpse	r17,r20
	jmp		LETTERS
	ldi		r17,$41
	st		Z,r17
	jmp		UPDATED
LETTERS:
	inc		r17
	st		Z,r17
UPDATED:
	ret

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
	//Check for RIGHT btn
	mov		r17,r16
	cpi		r17,12
	brlo	RIGHT		;0
	//Check for UP btn
	mov		r17,r16
	cpi		r17,44
	brlo	UP			;24
	//Check for DOWN btn
	mov		r17,r16
	cpi		r17,83
	brlo	DOWN		;64
	//Check for LEFT btn
	mov		r17,r16
	cpi		r17,130
	brlo	LEFT		;102
	//Check for SELECT btn
	mov		r17,r16
	cpi		r17,207
	brlo	SELECT		;159
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

SWITCH_BACKLIGHT:
	cpi		r16,1
	brne	SWITCH_DONE
	sbic	PORTB,2
	jmp		OFF
ON:
	call	BACKLIGHT_ON
	jmp		SWITCH_DONE
OFF:
	call	BACKLIGHT_OFF
	jmp		SWITCH_DONE
SWITCH_DONE:
	ret

LINE_PRINT:
	call	LCD_HOME
	ldi		ZH,HIGH(LINE)
	ldi		ZL,LOW(LINE)
	call	LCD_PRINT
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

MEM_INIT:
	ldi		ZH,HIGH(LINE)
	ldi		ZL,LOW(LINE)
	ldi		XH,HIGH(CUR_POS)
	ldi		XL,LOW(CUR_POS)
	ldi		r16,0b10000000	;Load prerequisite instruction form
	st		X,r16			;Store initial cursor position 0
	ldi		r21,16			;Loop-index LINE
	ldi		r20,' '
	call	MEM_WRITE_LINE
	ret
//Writes spaces for one full line to SRAM(LINE)
MEM_WRITE_LINE:
	st		Z+,r20
	dec		r21
	cpi		r21,0
	brne	MEM_WRITE_LINE
	ldi		r20,$00
	st		Z,r20
	ldi		r21,6			;Set loop-index	TIME
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