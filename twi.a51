$NOMOD51
$INCLUDE (reg_C51.inc)		;To add SFR definition in the ASEM-51 assembler
$INCLUDE (LCD.a51)

;Variables and Flags
TWI_BUSY		BIT 2fh.0
TWI_READ		BIT 2fh.1
TWI_FAIL		BIT 2fh.2
TWI_DATA		equ 70h
TWI_DATA_SIZE	equ 71h

RTC_ADDRESS			equ 49h
RTC_SECONDS			equ 50h
RTC_MINUTES			equ 51h
RTC_HOURS			equ 52h
RTC_DAY				equ 53h
RTC_DATE			equ 54h
RTC_MONTH			equ 55h
RTC_YEAR			equ 56h
RTC_CONTROL			equ 57h
RTC_ALARM_SECONDS	equ 58h
RTC_ALARM_MINUTES	equ 59h
RTC_ALARM_HOURS		equ 5ah
RTC_YEAR_HIGH		equ 5bh
RTC_OLD_YEAR		equ 5ch

;Constants

;TWI SSCON bits
STA		equ 20h
STO		equ 10h
SI		equ 08h
AA		equ 04h

org 000bh
	ljmp TIMER0

org 0043h
	ljmp TWI_IT

org 0100h
MAIN:
	call LCD_SETUP
	clr TWI_BUSY
	mov SSCON, #01000000b	;TWI Master mode with Fosc/256
	orl IEN1, #00000010b	;Enable ETWI
	
	mov IPL1, #00h
	mov IPH1, #02h			;TWI interrupt as high priority
	
	mov TMOD, #01h
	mov TH0, #00h
	mov TL0, #00h
	setb TR0
	setb ET0
	setb EA					;Enable EA
	
	call CLOCK_INIT
	
	jmp $

;Write data to RTC
;IN		RTC_ADDR		<- Address to write on the RTC RAM
;IN		TWI_DATA		<- Pointer to transfer buffer
;IN		TWI_DATA_SIZE	<- Number of bytes to transfer
;OUT	TWI_FAIL		<- Set if failed occoured
RTC_WRITE:
	push 5
	push 4
	push 3
	mov r4, TWI_DATA
	INC TWI_DATA_SIZE
	mov r5, TWI_DATA_SIZE
	mov r3, #02h						;Number of tries if error occoured
	clr TWI_READ						;Just to be sure
	RTC_WRITE_ERROR:
		clr TWI_FAIL
		setb TWI_BUSY
		orl SSCON, #STA					;Start
		jb TWI_BUSY, $
		jnb TWI_FAIL, RTC_WRITE_EXIT
		mov TWI_DATA, r4
		mov TWI_DATA_SIZE, r5
		djnz r3, RTC_WRITE_ERROR
	RTC_WRITE_EXIT:
	pop 3
	pop 4
	pop 5
	ret

;Read data from RTC
;IN		RTC_ADDR		<- Address to read on the RTC RAM
;IN		TWI_DATA		<- Pointer to transfer buffer
;IN		TWI_DATA_SIZE	<- Number of bytes to transfer
;OUT	TWI_FAIL		<- Set if failed occoured
RTC_READ:
	push 5
	push 4
	push 3
	mov r4, TWI_DATA
	mov r5, TWI_DATA_SIZE
	mov r3, #02h						;Number of tries if error occoured
	RTC_READ_ERROR:
		setb TWI_READ					;We are reading
		clr TWI_FAIL
		setb TWI_BUSY
		orl SSCON, #STA					;Start
		jb TWI_BUSY, $
		jnb TWI_FAIL, RTC_READ_EXIT
		mov TWI_DATA, r4
		mov TWI_DATA_SIZE, r5
		djnz r3, RTC_READ_ERROR
	RTC_READ_EXIT:
	clr TWI_READ
	pop 3
	pop 4
	pop 5
	ret

;Clock init
;Makes sure that the hour is in the correct format
;Loads the RTC
;Sees if the year is in the correct format as well
CLOCK_INIT:
	;Lets be sure that CH is cleared
	mov RTC_ADDRESS, #00h
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #01h
	call RTC_READ
	anl RTC_SECONDS, #07Fh
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #01h
	call RTC_WRITE
	
	;Now lets be sure that the hour is in the 24 format
	mov RTC_ADDRESS, #02h
	mov TWI_DATA, #RTC_HOURS
	mov TWI_DATA_SIZE, #01h
	call RTC_READ
	orl RTC_HOURS, #40h
	mov TWI_DATA, #RTC_HOURS
	mov TWI_DATA_SIZE, #01h
	call RTC_WRITE
	
	mov RTC_ADDRESS, #00h
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #0dh
	call RTC_READ
	
	ret

PRINT_DATE:
	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR

	mov A, RTC_HOURS
	swap A
	anl A, #03h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_HOURS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_MINUTES
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_MINUTES
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_SECONDS
	swap A
	anl A, #07h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_SECONDS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR

	mov A, #LCD_LINE2
	add A, #01h
	call LCD_MOVE_CURSOR
	
	mov A, RTC_DATE
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_DATE
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	
	mov A, RTC_MONTH
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_MONTH
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	
	mov A, RTC_YEAR_HIGH
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR_HIGH
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #' '
	call LCD_PRINT_CHAR
	
	;Converts 0-7 in 'DOM' - 'SAB'
	clr C
	mov A, RTC_DAY
	subb A, #01h
	mov B, #04h
	mul AB
	mov DPTR, #DAY_MSG
	add A, DPL
	mov DPL, A
	mov A, DPH
	addc A, #00h
	mov DPH, A
	call LCD_PRINT_MSG
	ret


;Timer0 interrupt handler
TIMER0:
	mov TH0, #00h
	mov TL0, #00h
	
	mov RTC_ADDRESS, #00h
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #0dh
	
	call RTC_READ
	
	mov A, RTC_YEAR
	jz CHECK_CENTURY
	
	TIMER0_EXIT:
	call PRINT_DATE
	reti
	
CHECK_CENTURY:
	xrl A, RTC_OLD_YEAR
	jz	TIMER0_EXIT			;We didn't just changed centuries
	
	mov A, RTC_YEAR_HIGH
	add A, #01h
	da A					;Fix BCD
	mov RTC_YEAR_HIGH, A
	mov A, RTC_YEAR
	mov RTC_OLD_YEAR, A
	
	mov RTC_ADDRESS, #0ch
	mov TWI_DATA, #RTC_YEAR_HIGH
	mov TWI_DATA_SIZE, #02h
	call RTC_WRITE			;Let's write our changes
	
	jmp TIMER0_EXIT
	

;Handle TWI interrupts
TWI_IT:
	push ACC
	push PSW
	
	mov A, SSCS
	jz TWI_ERROR		;Code is 00h, error in the BUS
	
	mov A, SSCS
	xrl A, #08h
	jz TWI_START		;Code is 08h, Start codition has been transmitted
	
	mov A, SSCS
	xrl A, #10h
	jz TWI_RESTART		;Code is 10h, Repeated start codition has been transmitted
	
	mov A, SSCS
	xrl A, #18h
	jz TWI_SLAW_ACK		;Code is 18h, SLA+W transmitted with ACK received
	
	mov A, SSCS
	xrl A, #20h
	jz TWI_ERROR		;Code is 20h, SLA+W transmitted with NACK received
	
	mov A, SSCS
	xrl A, #28h
	jz TWI_W_DATA_ACK	;Code is 28h, Data transmitted with ACK received
	
	mov A, SSCS
	xrl A, #30h
	jz TWI_ERROR		;Code is 30h, Data transmitted with NACK received
	
	mov A, SSCS
	xrl A, #38h
	jz TWI_ERROR		;Code is 38h, Arbitration lost in SLAW or Data
	
	mov A, SSCS
	xrl A, #40h
	jz TWI_SLR_ACK		;Code is 40h, SLA+R transmitted with ACK received
	
	mov A, SSCS
	xrl A, #48h
	jz TWI_ERROR		;Code is 48h, SLA+R transmitted with NACK received
	
	mov A, SSCS
	xrl A, #50h
	jz TWI_R_DATA_ACK	;Code is 50h, Data read with ACK returned
	
	mov A, SSCS
	xrl A, #58h
	jz TWI_R_DATA_NACK	;Code is 58h, Data read with NACK returned
	
	TWI_EXIT:
	pop PSW
	pop ACC
	reti

TWI_ERROR:
	anl SSCON, #(NOT (STA OR SI OR AA))		;Clear STA, SI and AA, Just to be sure
	orl SSCON, #STO							;Stop
	clr TWI_BUSY
	setb TWI_FAIL
	jmp TWI_EXIT

TWI_START:
	mov SSDAT, #11010000b					;RTC Address + W
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_RESTART:
	mov SSDAT, #11010001b					;RTC Address + R
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_SLAW_ACK:
	mov SSDAT, RTC_ADDRESS
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_W_DATA_ACK:
	jb TWI_READ, TWDAR
	djnz TWI_DATA_SIZE, TWDAW
	
	anl SSCON, #(NOT (STA OR SI))
	orl SSCON, #STO
	clr TWI_BUSY
	jmp TWI_EXIT
	
	TWDAW:
		mov r0, TWI_DATA
		mov SSDAT, @r0
		anl SSCON, #(NOT (STO OR STA OR SI))	;CLEAR STO, STA and SI
		inc TWI_DATA
		jmp TWI_EXIT
	
	TWDAR:
		anl SSCON, #(NOT (STO OR SI))
		orl SSCON, #STA						;Restart
		jmp TWI_EXIT

TWI_SLR_ACK:
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO
	djnz TWI_DATA_SIZE, TSAR
	
	anl SSCON, #(NOT AA)
	jmp TWI_EXIT
	
	TSAR:
		orl SSCON, #AA
		jmp TWI_EXIT

TWI_R_DATA_ACK:
	mov r0, TWI_DATA
	mov @r0, SSDAT
	anl SSCON, #(NOT (STA OR STO OR SI))
	djnz TWI_DATA_SIZE, TRDAR
	
	anl SSCON, #(NOT AA)
	inc TWI_DATA
	jmp TWI_EXIT
	TRDAR:
		orl SSCON, #AA
		inc TWI_DATA
		jmp TWI_EXIT

TWI_R_DATA_NACK:
	mov r0, TWI_DATA
	mov @r0, SSDAT
	anl SSCON, #(NOT (STA OR SI OR AA))
	orl SSCON, #STO
	clr TWI_BUSY
	jmp TWI_EXIT

DAY_MSG:	db	'DOM', 00h, 'SEG', 00h, 'TER', 00h, 'QUA', 00h, 'QUI', 00h, 'SEX', 00h, 'SAB', 00h
	
end
