
		ldi		r16,HIGH(RAMEND)
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16

		.equ	FN_SET = $0000
		.equ	DISP_ON = $0000
		.equ	LCD_CLEAR = $0000
		.equ	E_MODE = $0000
LCD_INIT:
		;call	WAIT			;Delay to let LCD start up
		call	LCD_PORT_INIT
		call	BACKLIGHT_ON	



LCD_WRITE4:
		sbi		PORTB,E			;
		out		PORTD,r16		;Output data
		cbi		PORTB,E			;Signals to LCD that new data is available
		call	WAIT			
		ret
LCD_WRITE8:

LCD_ASCII:

LCD_COMMAND:

BACKLIGHT_ON:
		sbi		PORTB,2
BACKLIGHT_OFF:

LCD_PORT_INIT:
		ldi		r16,$FF
		out		DDRB,r16		;output
		out		DDRD,r16		;output
	
STOP:
		brne	STOP

WAIT:
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