;----------------------------------------------------------------------------
;       PREFIX_UNA.ASM
;
;       PUT AT THE HEAD OF BOOT.BIN TO XFER TO A FLOPPY DISK
;
;----------------------------------------------------------------------------

#INCLUDE "std.asm"

BYT		.EQU	1	; used to describe METADATA_SIZE below
WRD		.EQU	2

SECTOR_SIZE	.EQU	512
BLOCK_SIZE	.EQU	128
PREFIX_SIZE	.EQU	(3 * SECTOR_SIZE)	; 3 SECTORS
METADATA_SIZE	.EQU	BYT+WRD+(4*BYT)+16+BYT+WRD+WRD+WRD+WRD	; (as defined below)

	.ORG	$8000
	JR	BOOT
;
BOOT:
	LD	DE,STR_LOAD	; LOADING STRING
	CALL	PRTSTR		; PRINT
	CALL	PRTDOT		; PROGRESS
;
	LD	BC,$00FC	; UNA FUNC: GET BOOTSTRAP HISTORY
	CALL	$FFFD		; CALL UNA
	JR	NZ,ERROR	; HANDLE ERROR
	CALL	PRTDOT		; PROGRESS
	LD	B,L		; MOVE BOOT UNIT ID TO B
;
	LD	C,$41		; UNA FUNC: SET LBA
	LD	DE,0		; HI WORD ALWAYS ZERO
	LD	HL,3		; IMAGE STARTS AT FOURTH SECTOR
	CALL	$FFFD		; SET LBA
	JR	NZ,ERROR	; HANDLE ERROR
	CALL	PRTDOT		; PROGRESS
;
	LD	C,$42		; UNA FUNC: READ SECTORS
	LD	DE,$D000	; STARTING ADDRESS FOR IMAGE
	LD	L,22		; READ 22 SECTORS
	CALL	$FFFD		; DO READ
	JR	NZ,ERROR	; HANDLE ERROR
	CALL	PRTDOT		; PROGRESS
;
	LD	DE,STR_DONE	; DONE MESSAGE
	CALL	PRTSTR		; PRINT IT
;
	LD	D,B		; PASS BOOT UNIT TO OS
	LD	E,0		; ASSUME LU IS ZERO
	JP	CPM_ENT		; GO TO CPM
;
PRTCHR:
	PUSH	BC
	PUSH	DE
	LD	BC,$0012	; UNIT 0, WRITE CHAR
	LD	E,A		; CHAR TO PRINT
	CALL	$FFFD		; PRINT
	POP	DE
	POP	BC
	RET
;
PRTSTR:
	PUSH	BC
	PUSH	HL
	LD	BC,$0015	; UNIT 0, WRITE CHARS UNTIL TERMINATOR
	LD	L,0		; TERMINATOR IS NULL
	CALL	$FFFD		; PRINT
	POP	HL
	POP	BC
	RET
;
PRTDOT:
	LD	A,'.'		; DOT CHARACTER
	JR	PRTCHR		; PRINT AND RETURN
;
; PRINT THE HEX BYTE VALUE IN A
;
PRTHEXBYTE:
	PUSH	AF
	PUSH	DE
	CALL	HEXASCII
	LD	A,D
	CALL	PRTCHR
	LD	A,E
	CALL	PRTCHR
	POP	DE
	POP	AF
	RET
;
; CONVERT BINARY VALUE IN A TO ASCII HEX CHARACTERS IN DE
;
HEXASCII:
	LD	D,A
	CALL	HEXCONV
	LD	E,A
	LD	A,D
	RLCA
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV
	LD	D,A
	RET
;
; CONVERT LOW NIBBLE OF A TO ASCII HEX
;
HEXCONV:
	AND	0FH	     ;LOW NIBBLE ONLY
	ADD	A,90H
	DAA	
	ADC	A,40H
	DAA	
	RET	
;
ERROR:
	LD	DE,STR_ERR	; POINT TO ERROR STRING
	CALL	PRTSTR		; PRINT IT
	HALT			; HALT
;
STR_LOAD	.DB	"\r\nLoading",0
STR_DONE	.DB	"\r\n",0
STR_ERR		.DB	" Read Error!",0
;
		.ORG	$ - $8000
;
		.FILL	(SECTOR_SIZE) - $ - 2
		.DW	$AA55
;
		.FILL	((PREFIX_SIZE - BLOCK_SIZE) - $),00H
PR_SIG		.DW	0A55AH				; SIGNATURE GOES HERE

PR_PLATFORM	.DB	0	
PR_DEVICE	.DB	0
PR_FORMATTER	.DB	0,0,0,0,0,0,0,0
PR_DRIVE	.DB	0
PR_LOG_UNIT	.DW	0

;
		.FILL	((PREFIX_SIZE - METADATA_SIZE) - $),00H
		.DB	0		; write protect boolean
		.DW	0		; starting update number
		.DB	RMJ,RMN,RUP,RTP
		.DB	"Unlabeled Drive ","$"
		.DW	0		; PTR TO LOCATION TO STORE DISKBOOT & BOOTDRIVE (SEE CNFGDATA)
		.DW	CPM_LOC		; CCP START
		.DW	CPM_END		; END OF CBIOS
		.DW	CPM_ENT		; COLD BOOT LOCATION

		.END