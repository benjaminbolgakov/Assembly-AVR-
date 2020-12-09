
		ldi		r16,HIGH(RAMEND)
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16

		.equ	FN_SET		= 0b00101000			;4-bit mode, 2 line, 5x8 font
		.equ	DISP_ON		= 0b00001111			;Display on, cursor on, cursor blink
		.equ	LCD_CLR		= 0b00000001			;Clear display
		.equ	E_MODE		= 0b00000110			;Increment cursor, no shift

		.equ	E			= 1

TEXT:	.db		"LIGGA?",$00

LCD_INIT:
		call	WAIT			;Delay to let LCD start up
		call	PORT_INIT
		call	WAIT
		call	BACKLIGHT_ON	
		call	WAIT
		call	FOURBIT_INIT
		call	WAIT
		call	DISP_CONFIG		;Blinking cursor at this point
		ldi		r16,0b01010000
		call	LCD_ASCII

		;call	BACKLIGHT_OFF
		jmp		STOP

LINE_PRINT:
		ldi		ZH,HIGH(TEXT*2)
		ldi		ZL,LOW(TEXT*2)
		call	LCD_PRINT
		ret
//Set write-pos at column 0 (home/start pos)
LCD_HOME:
		
//Erase the content on screen
LCD_ERASE:
		ldi		r16,LCD_CLR
		call	LCD_COMMAND
LCD_PRINT:
		

LCD_WRITE4:
		sbi		PORTB,E			;
		out		PORTD,r16		;Output data
		call	WAIT
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

	
STOP:
		jmp		STOP

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