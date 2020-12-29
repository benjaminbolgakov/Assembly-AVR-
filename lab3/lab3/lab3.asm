	.org	$0000
	jmp		INIT
	.org	OC1Aaddr
	jmp		TIME_TICK

	.equ	FN_SET		= 0b00101000			;4-bit mode, 2 line, 5x8 font
	.equ	DISP_ON		= 0b00001111			;Display on, cursor on, cursor blink
	.equ	LCD_CLR		= 0b00000001			;Clear display
	.equ	E_MODE		= 0b00000110			;Increment cursor, no shift
	.equ	SECOND_TICKS = 62500 - 1			

	.equ	E			= 1

CTR_LIM:	.db 9,5,9,5,9,2
.dseg
.org		$100
TIME:		.byte 6
.org		$120
LINE:		.byte 17
.cseg


INIT:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	call	MEM_INIT
	call	TIME_FORMAT

	;call	MAIN

	call	WAIT			;Delay to let LCD start up
	call	PORT_INIT
	call	BACKLIGHT_ON	
	call	FOURBIT_INIT
	call	DISP_CONFIG		;Blinking cursor at this point
	call	TIMER_INIT

MAIN:
	;call	TIME_TICK
	jmp		MAIN

TIME_TICK:
	ldi		XH,HIGH(TIME+5)
	ldi		XL,LOW(TIME+5)
	ldi		ZH,HIGH(CTR_LIM*2)
	ldi		ZL,LOW(CTR_LIM*2)
	push	r17
	in		r17,SREG
	push	XH
	push	XL
	push	ZH
	push	ZL
	push	r16
	push	r18
TIME_LOOP:
	lpm		r18,Z
	ld		r16,X
	cpi		r16,3			;Control for the hour 23
	breq	CONTROL			;Control for the hour 23
	cp		r16,r18
	brne	TICK
	call	CLEAR
	lpm		r18,Z+
	ld		r16,-X
	jmp		TIME_LOOP
CONTROL:
	dec		XL
	ld		r16,X
	inc		XL
	cpi		r16,2
	brne	TICK
	clr		r16
	st		X+,r16
	inc		ZL
	dec		XL
	dec		XL
	jmp		TIME_LOOP
TICK:
	ld		r16,X
	inc		r16
	jmp		TICK_DONE
CLEAR:
	clr		r16
	st		X,r16
	ret
TICK_DONE:
	st		X,r16
	call	TIME_FORMAT
	call	LINE_PRINT
	pop		r18
	pop		r16
	pop		ZL
	pop		ZH
	pop		XL
	pop		XH
	out		SREG,r17
	pop		r17
	reti
	
TIMER_INIT:
	ldi		r16,(1<<WGM12)|(1<<CS12)
	sts		TCCR1B,r16
	ldi		r16,HIGH(SECOND_TICKS)
	sts		OCR1AH,r16
	ldi		r16,LOW(SECOND_TICKS)
	sts		OCR1AL,r16
	ldi		r16,(1<<OCIE1A)
	sts		TIMSK1,r16
	sei
	ret
MEM_INIT:
	ldi		ZH,HIGH(LINE)
	ldi		ZL,LOW(LINE)
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	ldi		r20,' '
	ldi		r21,16			;Loop-index LINE
	call	MEM_WRITE_LINE
	call	MEM_WRITE_CLK
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
//Writes a starting time into SRAM(TIME)
MEM_WRITE_CLK:
	ldi		r20,$02			
	st		X+,r20
	ldi		r20,$03			
	st		X+,r20
	ldi		r20,$05			
	st		X+,r20
	ldi		r20,$09			
	st		X+,r20
	ldi		r20,$05			
	st		X+,r20
	ldi		r20,$06			
	st		X+,r20
	ldi		r20,0
	st		X+,r20
	ret


TIME_FORMAT:
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	ldi		ZH,HIGH(LINE)
	ldi		ZL,LOW(LINE)
	ldi		r21,8			;Loop-index for clock 00:00:00
	ldi		r22,2			;Loop-index for colons
	ldi		r17,0b00111010	;ASCII colon
TIME_WRITE_NMB:
	ld		r16,X+
	ldi		r25,$30
	add		r16,r25			;Convert the number in r16 to ASCII and place in r16
	st		Z+,r16
	dec		r22
	dec		r21
	cpi		r22,0
	brne	TIME_WRITE_NMB
	cpi		r21,0
	breq	DONE
	call	TIME_WRITE_COL
	jmp		TIME_WRITE_NMB
DONE:
	ret
TIME_WRITE_COL:
	st		Z+,r17
	ldi		r22,2			;Reset loop-index for colons
	dec		r21
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