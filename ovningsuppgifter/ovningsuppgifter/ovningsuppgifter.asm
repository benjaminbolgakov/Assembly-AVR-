START:
	jmp		TASK8

TASK1:
	ldi		r16,198
	ldi		r17,$64
	ldi		r18,0b10010011

TASK2:
	mov		r18,r16

TASK3:
	ldi		r18,0xff
	sts		$110,r18
	lds		r16,$110
	sts		$112,r16

TASK4:
	lds		r16,$110
	lds		r17,$111
	add		r16,r17
	sts		$112,r16

TASK5:
	lds		r16,$110
	lsl		r16
	sts		$111,r16

TASK6:
	ldi		r18,$FF
	andi	r18,0b00001111

TASK7:
	ldi		r16,$00
	ori		r16,0b11100000

TASK8:
	ldi		r18,0b11110000
	sts		$110,r18
	lds		r16,$110		; r16  = 11110000
	mov		r17,r16			; r17  = 11110000
	andi	r16,$F0			; r16  = 11110000
	lsr		r16				; r16  = 01111000
	lsr		r16				; r16  = 00111100
	lsr		r16				; r16  = 00011110
	lsr		r16				; r16  = 00001111
	sts		$111,r16		; $111 = 00001111
	andi	r17,$0F			; r17  = 00000000
	sts		$112,r17		; $112 = 00000000

