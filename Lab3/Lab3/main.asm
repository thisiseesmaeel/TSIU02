;
; Lab3.asm
;
	.dseg
	.org	$200
LINE:
	.byte	9

	.org	$300
TIME:
	.byte	7

	.cseg
	.equ	FN_SET = $28	; 4 bit-mode, 2 line, 5x8 font
	.equ	DISP_ON = $0F	; display on, cursor on, cursor blink
	.equ	LCD_CLR = $01	; clear display
	.equ	E_MODE = $06	; entry mode: increment cursor, no shift
	.equ	RET_HOME = $02	; return cursor to first column of LCD

	.equ	RS = 0			; register select bit
	.equ	E = 1			; E signal bit
	.equ	BLGT = 2		; Backlight bit
	.equ	SECOND_TICKS = 62500 - 1	; correspond 1 second for ATMEGA328p
	
	.org	$0000
	jmp		MAIN

	.org	OC1Aaddr
	jmp		SECOND_INTERRUPT

	.org	INT_VECTORS_SIZE
MAIN:
	; initiate the stack
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	
	ldi		r16, $F0		; corresponds 1111 0000
	out		DDRD, r16		; which means that we configurate MSB in PORTD as output
	
	ldi		r16, $07		; corresponds 0000 0111
	out		DDRB, r16		; which means that we configurate three LSB of PORTB as output

	call	WAIT
	call	LCD_INIT
	call	TIMER_INIT
	sei
	

	ldi		ZH, HIGH(TIME)
	ldi		ZL, LOW(TIME)

	; initiate lcd with 23:59:45
	ldi		r16, 5
	st		Z+, r16

	ldi		r16, 4
	st		Z+, r16

	ldi		r16, 9
	st		Z+, r16

	ldi		r16, 5
	st		Z+, r16

	ldi		r16, 3
	st		Z+, r16

	ldi		r16, 2
	st		Z+, r16

	ldi		r16, 0
	st		Z+, r16

FOREVER:		; update LCD forever
	call	TIME_FORMAT
	call	LINE_PRINT
	jmp		FOREVER


WAIT:
	push	r16
	push	r17

	ldi		r17, 50
D_2:
	ldi		r16, 0
D_1:
	dec		r16
	brne	D_1
	dec		r17
	brne	D_2
	
	pop		r17
	pop		r16

	ret

BACKLIGHT_ON:
	sbi		PORTB, BLGT
	ret

BACKLIGHT_OFF:
	cbi		PORTB, BLGT
	ret
	
LCD_INIT:
	call	BACKLIGHT_ON
	call	WAIT		; wait for LCD ready

	; initiate 4-bit mode
	ldi		r16, $30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4
	

	ldi		r16, $20
	call	LCD_WRITE4

	; display configuration
	ldi		r16, FN_SET		
	call	LCD_COMMAND

	ldi		r16, DISP_ON
	call	LCD_COMMAND

	ldi		r16, LCD_CLR
	call	LCD_COMMAND

	ldi		r16, E_MODE
	call	LCD_COMMAND

	ret

LCD_WRITE4:
	push	r16

	andi	r16, $F0
	out		PORTD, r16
	sbi		PORTB, E
	; 4 nop to make E signal being registered
	nop
	nop
	nop
	nop
	cbi		PORTB, E
	call	WAIT	; waiting for LCD to handle the data (to avoid checking Busy Flag)

	pop		r16
	ret

LCD_WRITE8:
	call	LCD_WRITE4
	lsl		r16
	lsl		r16
	lsl		r16
	lsl		r16
	call	LCD_WRITE4
	ret

LCD_ASCII:
	sbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_COMMAND:
	cbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_HOME:
	ldi		r16, RET_HOME
	call	LCD_COMMAND
	ret

LCD_ERASE:
	ldi		r16, LCD_CLR
	call	LCD_COMMAND
	ret

LCD_PRINT:
NEXT_CHAR:
	ld		r16, Z+
	cpi		r16, 0
	breq	DONE
	call	LCD_ASCII
	jmp		NEXT_CHAR
DONE:
	ret

LINE_PRINT:
	call	LCD_HOME
	ldi		ZH, HIGH(LINE)
	ldi		ZL, LOW(LINE)
	call	LCD_PRINT
	ret

TIME_TICK:
	push	ZH
	push	ZL

	ldi		ZH, HIGH(TIME)
	ldi		ZL, LOW(TIME)	; sS:mM:hH => Z points to first s
	
	ldi		r17, 0
	ldi		r18, $00	; bool variable that represents least significant digit for HH/MM/SS if is 00 and most otherwise.
	

FOR_LOOP:
	ld		r16, Z
	cpi		r17, 4
	breq	LSDH
	cpi		r17, 5
	breq	MSDH
	cpi		r18, 0
	brne	MSD
	jmp		LSD

MSDH:		; most significant digit of hour which means we cant exceed 2
	cpi		r16, 2
	jmp		COMPARE_DIGIT
LSDH:		; least significant digit of hour which means we cant exceed 3
	ldd		r19, Z + 1
	cpi		r19, 2
	brne	LSD
	cpi		r16, 3
	jmp		COMPARE_DIGIT
MSD:		; most significant digit which means we cant exceed 5
	cpi		r16, 5
	jmp		COMPARE_DIGIT
LSD:		; least significant digit which means we cant exceed 9
	cpi		r16, 9

COMPARE_DIGIT:	; compare and branch if needed
	breq	INC_NEXT_DIGIT
	inc		r16
	st		Z, r16
	jmp		END

INC_NEXT_DIGIT:	; increment next digit in Hh:Mm:Ss format if max digit allowed for digit is exceeded
	com		r18
	clr		r16
	st		Z+, r16
	inc		r17
	cpi		r17, 6
	brne	FOR_LOOP

END:
	pop		ZL
	pop		ZH
	ret

TIME_FORMAT:
	ldi		ZH, HIGH(TIME)
	ldi		ZL, LOW(TIME)

	ldi		YH, HIGH(LINE+7)
	ldi		YL, LOW(LINE+7)

	; TIME:
	; sS:mM:hH 0

	; LINE:
	; Hh:Mm:Ss 0
	ldi		r17, 6

CONVERT:
	ld		r16, Z+
	mov		r18, r17
	ori		r16, $30 ; Converts from binary to ASCII 
	st		Y, r16
	sbiw	Y, 1
	cpi		r17, 1
	breq	DONE_CONVERT
	lsr		r18
	brcc	EVEN
	ldi		r16, $3A ; represent ':'
	st		Y, r16
	sbiw	Y, 1
EVEN:
	dec		r17
	jmp		CONVERT

DONE_CONVERT:
	ldi		r16, $00
	std		Y + 9, r16
	ret


TIMER_INIT:
	ldi		r16, (1<<WGM12) | (1<<CS12)
	sts		TCCR1B, r16
	ldi		r16, HIGH(SECOND_TICKS)
	sts		OCR1AH, r16
	ldi		r16, LOW(SECOND_TICKS)
	sts		OCR1AL, r16
	ldi		r16,(1<<OCIE1A)
	sts		TIMSK1, r16
	ret

SECOND_INTERRUPT:
	push	r16
	push	ZH
	push	ZL
	push	YH
	push	YL

	in		r16, SREG
	push	r16

	call	TIME_TICK

	pop		r16
	out		SREG, r16

	pop		YL
	pop		YH
	pop		ZL
	pop		ZH
	pop		r16
	reti