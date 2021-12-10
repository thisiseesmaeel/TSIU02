;
; Lab3_delmoment.asm
;
; Created: 08/12/2021 20:52:19
; Author : hadia
;
	.dseg
	.org	$100
LINE:
	.byte	9

	.org	$150
TIME:
	.byte	7

	.cseg

	.equ	FN_SET = $28
	.equ	DISP_ON = $0F
	.equ	LCD_CLR = $01
	.equ	E_MODE = $06
	.equ	RET_HOME = $02

	.equ	RS = 0
	.equ	E = 1
	.equ	BLGT = 2
	.equ	SECOND_TICKS = 62500 - 1
	
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
	
	ldi		r16, $F0		; Corresponds 1111 0000
	out		DDRD, r16		; which means that we configurate MSB in PORTD as output
	
	ldi		r16, $07		; Corresponds 0000 0111
	out		DDRB, r16		; which means that we configurate three LSB of PORTB as output

	call	WAIT
	call	LCD_INIT
	
	
	ldi		r16, 9
	sts		$150, r16

	ldi		r16, 5
	sts		$151, r16

	ldi		r16, 9
	sts		$152, r16

	ldi		r16, 5
	sts		$153, r16

	ldi		r16, 0
	sts		$154, r16

	ldi		r16, 2
	sts		$155, r16

	ldi		r16, 0
	sts		$156, r16

	; 20:59:59
	call	TIMER_INIT
	sei
	
FOREVER:
	
	jmp		FOREVER


	; For ATMEGA326 with clock frequency of 16 MHz WAIT takes
	; approximately 3 ms
WAIT:
	push	r16
	push	r17
	push	r18

	ldi		r18, 3
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
	
	pop		r18
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
	call	WAIT

	ldi		r16, $30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4

	ldi		r16, $20
	call	LCD_WRITE4

	; Display configuration
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
	nop
	nop
	nop
	nop
	cbi		PORTB, E
	call	WAIT

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
AGAIN:
	ld		r16, Z+
	cpi		r16, 0
	breq	DONE
	call	LCD_ASCII
	jmp		AGAIN
DONE:
	ret

LINE_PRINT:
	call	LCD_HOME
	ldi		ZH, HIGH(LINE)
	ldi		ZL, LOW(LINE)
	call	LCD_PRINT
	ret

TIME_TICK:
	ldi		ZH, HIGH(TIME)
	ldi		ZL, LOW(TIME)	; Hh:Mm:Ss => Z points to last s
	
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
	cpi		r16, 9
	jmp		BLABLA

MSDH:
	cpi		r16, 2
	jmp		BLABLA
LSDH:
	cpi		r16, 3
	jmp		BLABLA
MSD:
	cpi		r16, 5

BLABLA:
	breq	INC_NEXT
	inc		r16
	st		Z, r16
	jmp		END

INC_NEXT:
	com		r18
	clr		r16
	st		Z+, r16
	inc		r17
	cpi		r17, 6
	brne	FOR_LOOP


END:
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
	in		r16, SREG

	call	TIME_TICK
	call	TIME_FORMAT
	call	LINE_PRINTcd

	out		SREG, r16
	pop		r16
	reti