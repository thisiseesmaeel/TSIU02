;
; Lab2.asm
;
; Created: 06/12/2021 14:16:08
;
	jmp		MORSE
MESSAGE:
	.db		"DATORTEKNIK", $00
	.equ	SLOWNESS = 1
	.equ	FREQUENCY = 6

BTAB:
	.db		$60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8

MORSE:
	; Initierar stacken
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	; sätter Z-pekaren till första byte i Message
	ldi		ZH, HIGH(MESSAGE << 1)
	ldi		ZL, LOW(MESSAGE << 1)

	; Initierar PORTB4
	ldi		r17, $10	; Motsvarar 0001 0000 
	out		DDRB, r17	; så vi kan konfigurera bit 4 som utgång
	
	call	GET_CHAR
	call	SEND_IT
	
DONE:
	rjmp	DONE

GET_CHAR:
	lpm		r16, Z+
	cpi		r16, $00
	ret

SEND_IT:
WHILE_CHAR:
	call	ONE_CHAR
	brne	WHILE_CHAR
	ret

ONE_CHAR:
	call	BEEP_CHAR
	call	GET_CHAR
	ret

BEEP_CHAR:
	call		LOOKUP
	brmi		SPACE
	call		SEND
	ldi			r17, 2 * FREQUENCY
	rjmp		NO_SPACE

SPACE:
	ldi			r17, 6 * FREQUENCY

NO_SPACE:
	push		r17
	call		NOBEEP ; 2 * FREQUENCY eller 6 * FREQUENCY baserad på om det är mellanslag eller inte
	pop			r17
	ret

LOOKUP:
	subi	r16, $41
	brmi	END_LOOKUP		; när mellanslag förekommer blir resultatet negativt. $20 - $41

	push	ZH
	push	ZL

	ldi		ZH, HIGH(BTAB << 1)
	ldi		ZL, LOW(BTAB << 1)

	add		ZL, r16
	clr		r17
	adc		ZH, r17
	lpm		r16, Z

	pop		ZL
	pop		ZH

END_LOOKUP:
	ret

SEND:
	call	GET_BIT
	call	SEND_BITS
	ret

NOBEEP:
	in		YH, SPH
	in		YL, SPL

	cbi		PORTB, 4
	ldd		r18, Y+3
	push	r18
	call	DELAY
	pop		r18
	ret

GET_BIT:
	lsl		r16
	ret

SEND_BITS:
WHILE_BIT:
	call	BIT
	brne	WHILE_BIT
	ret

BIT:
	call	BEEP
	ldi		r17, 1 * FREQUENCY
	push	r17
	call	NOBEEP ; 1 * FREQUENCY
	pop		r17
	call	GET_BIT
	ret

BEEP:
	brcc	SHORT_BEEP
	ldi		r18, 3 * FREQUENCY
	rjmp	LONG_BEEP
SHORT_BEEP:
	ldi		r18, 1 * FREQUENCY
LONG_BEEP:
	sbi		PORTB, 4
	push	r18
	call	DELAY
	pop		r18

	ret

DELAY:
	in		YH, SPH
	in		YL, SPL

	push	r16
	push	r17
	push	r18
	push	r0		; Detta används för att spara multiplikations resultatet
	push	r1		; därför skyddar vi dem i stacken.

	ldd		r16, Y+3

	ldi		r18, SLOWNESS
	mul		r18, r16	; r16 är argumentet som avgör
	mov		r18, r0		; hur länge loopen ska dröja
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
	
	pop		r1
	pop		r0
	pop		r18
	pop		r17
	pop		r16

	ret