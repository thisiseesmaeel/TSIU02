;
; lab4.asm
;
; Created: 14/12/2021 12:34:27
; Author : hadia
;
	.dseg
	.org	$200
LINE:
	.byte	16 + 1

	.cseg
	.equ	FN_SET = $28	; 4 bit-mode, 2 line, 5x8 font
	.equ	DISP_ON = $0F	; display on, cursor on, cursor blink
	.equ	LCD_CLR = $01	; clear display
	.equ	E_MODE = $06	; entry mode: increment cursor, no shift
	.equ	RET_HOME = $02	; return cursor to first column of LCD
	.equ	CURSOR_RIGHT_SHIFT = $14	; Shifts the cursor position to the right. (AC is incremented by one.)

	.equ	RS = PB0		; register select bit
	.equ	E = PB1			; E signal bit
	.equ	BLGT = PB2		; Backlight bit

	.equ	NULL = 0
	.equ	SELECT = 1
	.equ	LEFT = 2
	.equ	DOWN = 3
	.equ	UP = 4
	.equ	RIGHT = 5

	
	.org	$0000
	jmp		MAIN

	.org	INT_VECTORS_SIZE
MAIN:
	; initiate stack
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	
	call	PORT_INIT
	call	WAIT
	call	LCD_INIT	

BLABLA:
	call	KEY_READ
	call	LCD_COL
	jmp		BLABLA

PORT_INIT:
	ldi		r16, $F0		; corresponds 1111 0000
	out		DDRD, r16		; which means that we configurate MSB in PORTD as output
	
	ldi		r16, $07		; corresponds 0000 0111
	out		DDRB, r16		; which means that we configurate three LSB of PORTB as output

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
	swap	r16
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


ADC_READ8:
	; Configuration
	ldi		r16, (1<<REFS0)|(1<<ADLAR)|0
	sts		ADMUX, r16
	ldi		r16, (1<<ADEN)| 7
	sts		ADCSRA, r16

	; Start ADC
CONVERT:
	lds		r16, ADCSRA
	ori		r16, (1<<ADSC)
	sts		ADCSRA, r16

ADC_BUSY:
	lds		r16, ADCSRA
	sbrc	r16, ADSC
	jmp		ADC_BUSY
	lds		r16, ADCH

	ret

; Write hexadecimal ; In: r16, value
; Out: -
LCD_PRINT_HEX:
	call NIB2HEX

NIB2HEX:
	swap r16
	push r16
	andi r16,$0F
	ori r16,$30
	cpi r16,':'
	brlo NOT_AF
	subi r16,-$07
NOT_AF:
	call LCD_ASCII
	pop r16
	ret

KEY:
	call	ADC_READ8
	cpi		r16, 12
	brcs	RIGHT_BUTTON
	cpi		r16, 43
	brcs	UP_BUTTON
	cpi		r16, 82
	brcs	DOWN_BUTTON
	cpi		r16, 130
	brcs	LEFT_BUTTON
	cpi		r16, 207
	brcs	SELECT_BUTTON
	ldi		r16, NULL
	jmp		DONE

RIGHT_BUTTON:
	ldi		r16, RIGHT
	jmp		DONE
UP_BUTTON:
	ldi		r16, UP
	jmp		DONE
DOWN_BUTTON:
	ldi		r16, DOWN
	jmp		DONE
LEFT_BUTTON:
	ldi		r16, LEFT
	jmp		DONE
SELECT_BUTTON:
	ldi		r16, SELECT
	jmp		DONE

DONE:
	ret

KEY_READ:
	call	KEY
	tst		r16
	brne	KEY_READ ; old key still pressed
	call	LCD_ERASE
KEY_WAIT_FOR_PRESS:
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS ; no key pressed 
	; new key value available

	ret

LCD_COL:
	mov		r17, r16

SHIFT:
	ldi		r16, CURSOR_RIGHT_SHIFT
	call	LCD_COMMAND
	dec		r17
	brne	SHIFT

	ret


	; RIGHT: 00, UP: 24, LEFT:102, DOWN: 63, SELECT:159 otherwise 255
	;
	; Button			None	SELECT		 LEFT		DOWN	  UP    	RIGHT
	;----------------------------------------------------------------------------
	; RETURN VALUE		0		  1			  2			  3		  4 		 5	
	;	INTERVAL	255-208		207-131		130-83		82-44	43-12		12-0
