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

	.equ	RS = 0			; register select bit
	.equ	E = 1			; E signal bit
	.equ	BLGT = 2		; Backlight bit
	.equ	SECOND_TICKS = 62500 - 1	; correspond 1 second for ATMEGA328p
	
	.org	$0000
	jmp		MAIN

	.org	INT_VECTORS_SIZE
MAIN:
	ldi		r16, 2
STOP:
	jmp		STOP


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
