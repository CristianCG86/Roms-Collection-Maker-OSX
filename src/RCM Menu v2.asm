; ============================================
; RCM Menu v2.1 - TRANSFORMADO A SCREEN1
; ============================================

; --- Constantes ---
CHAR_SELECTOR	  EQU  0xB0	  ; Caracter de selección (0xCF)
SELECTOR_POS	  EQU  9	  ; Posición del selector
TS	  			  EQU  0x02	  ; Línea de separación superior
TS_POS			  EQU  1 * 32	  ; Posición de la línea de separación superior
BS				  EQU  0x01	  ; Línea de separación inferior
BS_POS			  EQU  22 * 32	  ; Posición de la línea de separación inferior
FREQ_POS		  EQU  23	  ; Posición de la frecuencia
LIST_VIEW_SIZE	  EQU  18	  ; Tamaño de la lista de ROMs
START_LIST		  EQU  3	  ; Inicio de la lista de ROMs
EL1_POS		  	  EQU  2 * 32	  ; Posición de la primera línea de la lista de ROMs

; Main-ROM entries

BASRVN		equ	0002Bh
DISSCR		equ	00041h
ENASCR		equ	00044h
ENASLT		equ	00024h
FILVRM		equ	00056h
INITXT		equ	0006Ch				; Initialize the screen 0
INIT32		equ	0006Fh				; Initialize the screen 1
GTSTCK		equ	000D5h
GTTRIG		equ	000D8h
LDIRVM		equ	0005Ch
MSXVER		equ	0002Dh
RSLREG		equ	00138h
VDP_DR		equ	00006h
VDP_DW		equ	00007h
WRSLT		equ	00014h
WRTVDP		equ	00047h 
WRTVRM		equ	0004Dh

; bios call to print a character on screen
CHPUT      equ 0x00a2        ; BIOS routine that sends to the screen the contents pointed by the A register
CHGMOD     equ 0x005f        ; BIOS routine that changes the screen mode to the value defined by A
CHGET      equ 0x009F        ; BIOS routine that waits for a key to be pressed
ERAFNK     equ 0x00CC        ; BIOS routine that sets the function keys as hidden
DSPFNK     equ 0x00CF        ; BIOS routine that sets the function keys as shown
FNKSB      equ 0x00C9        ; BIOS routine that changes the function keys between hidden and shown

; System variables

BAKCLR		equ	0F3EAh				; Background color (screen 1)
BDRCLR		equ	0F3EBh				; Border color
FORCLR		equ	0F3E9h				; Text color
LINL40		equ	0F3AEh				; Width (NO USADO EN SCREEN1)
TXTATR		equ	0F3B9h				; Character attributs table 
NEWKEY		equ	0FBE5h
EXPTBL		equ	0FCC1h
RG9SAV		equ	0FFE8h				; Current value of the register 9
VOICAQ		equ	0F975h				; Data voice 1 (used as buffer here)

; Hooks

H_STKE	equ	0FEDAh

; Program variables

RamBottom	equ	0E000h
PrgInRam	equ	RamBottom+10h			; Address of the program in RAM
CurrTopName	equ	PrgInRam+(MainPrgEnd-RomSel)	; Address of the first name of the list to display
VramPos		equ	CurrTopName+2			; Vram address to display the list
SettingBits	equ	VramPos+2			; Setting bits after the selected ROM
SegMum		equ	SettingBits+1			; First segment number of the selected ROM
NextSegMum	equ	SegMum+1			; Segment number after the selected ROM
RomSlot		equ	NextSegMum+1			; Slot number
CurrAdr		equ	RomSlot+1			; Data address of the selected ROM
RomSize		equ	CurrAdr+2			; Rom size in number of the segment

; *** CAMBIO: Anchura de 40 a 32 columnas ***
WidthName	equ	32					; 32 columnas para SCREEN1
LineData	equ	34					; 32 + 2 bytes de overhead

; *** NUEVO: Direcciones VRAM para SCREEN1 ***
NAME_TABLE	equ	0x1800				; Name Table en SCREEN1
PATTERN_TABLE	equ	0x0000			; Pattern Table
COLOR_TABLE	equ	0x2000				; Color Table

Offset		equ	0			; 0 Without offset register
							; 1 Offset register (Flash Rom SCC Cartridge popolon-fr)
							; 2 Offset register (MFR SCC+ SD)
							; 3 Offset register (Yamanooto)
	if	Offset==1
OffsetReg	equ	03FFFh
	elif	Offset==2
OffsetReg	equ	07FFDh
	endif

	org	04000h

; Rom header

	db	41h,42h
	dw	Start
	ds	12,0

; Menu program

Start:
	push	af
	push	bc
	; push	de
	push	hl

	ld	hl,BankSel
	ld	de,VOICAQ
	ld	bc,RamPrgEnd-BankSel
	ldir						; Copy the segments selection routine

	ld	hl,RomSel
	ld	de,PrgInRam
	ld	bc,MainPrgEnd-RomSel
	ldir						; Copy the Rom pages selection routine

	call	RSLREG
	rrca
	rrca
	and	3
	ld	c,a
	ld	b,0
	ld	hl,EXPTBL
	add	hl,bc
	ld	a,(hl)
	and	80h
	or	c
	ld	c,a
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(hl)
	and	0Ch
	or	c
	ld	(RomSlot),a				; Get the ROM slot number

	ld	hl,09000h
	ld	e,1
	call	WRSLT					; Select the segment 1 on the page 6000h-7FFFh

	ld	a,1
	ld	(07000h),a

	; *** CAMBIO: Configurar colores para SCREEN1 ***
	ld	a,1						; Fondo azul
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	ld	a,15					; Texto blanco
	ld	(FORCLR),a
	
	; *** CAMBIO: Usar INIT32 para SCREEN1 ***
	call	INIT32				; SCREEN1 32x24
	call	ERAFNK				; Ocultar teclas función

	; *** CAMBIO: Cargar fuente en Pattern Table (0x0000) ***
	call LoadCustomFont

;-- Tests if one Game only to execute it directly

	ld	hl,RomList+45				; Point to the second MSX generation value
	cp	255
	jp	z,RomExec				; Jump if MSX generation value of the second line is 255

	ld	hl,RomList+3				; Point to the first MSX generation value
	ld	de,42
NextMSXgen:
	ld	a,(hl)
	and	3					; Reset unused bits of the MSX generation value
	add	hl,de
	ld	b,a
	ld	a,(MSXVER)
	and	3					; Reset unused bits of MSXVER
	cp	b
	jr	c,NextMSXgen				; Jump if MSXVER < A

	add	hl,de
	cp	255
	jp	z,RomExec				; Jump if MSX generation value of the next line is 255
;--

	ld	hl,RomList
	ld	(CurrTopName),hl

	; *** CAMBIO: En SCREEN1 usamos NAME_TABLE directamente ***
	ld	hl, NAME_TABLE
	ld	de,WidthName*0
	add	hl,de
	ex	hl,de					; DE = posición VRAM línea 0

	call PrintTitle				; Print the title

	call PrintTopSeparator

	call PrintBottomSeparator
	call PrintFreq

MainLoop:



	; *** CAMBIO: Calcular posición de inicio de lista ***
	ld	hl, NAME_TABLE + (WidthName * START_LIST)  ; Línea 4
	ld	(VramPos),hl

	halt
	call	PrintList				; Print the Roms list

	; -- Print separator bottom
	call PrintBottomSeparator
	call PrintFreq

; Keyboard tests (SIN CAMBIOS - ya usa NEWKEY)
	ld	a,(NEWKEY+8)				; Row 8
	and	40h
	call	z,MoveDown				; Call if Down key is pressed

	ld	a,(NEWKEY+8)				; Row 8
	and	20h
	call	z,MoveUp				; Call if Up key is pressed

	ld	a,(NEWKEY+8)				; Row 8
	and	1
	jp	z,RomExec				; Jump if Space key is pressed

	ld	a,(NEWKEY+6)				; Row 6
	and	20h
	call	z,FreqToggle				; Call if F1 key is pressed

; Joystick tests (SIN CAMBIOS)
	ld	a,1
	call	GTSTCK					; Test the joystick 1
	cp	1
	call	z,MoveUp				; Jump if Up is pressed

	ld	a,1
	call	GTSTCK					; Test the joystick 1
	cp	5
	call	z,MoveDown				; Jump if Down is pressed

	ld	a,1
	call	GTTRIG					; Test the button 1 of the joystick 1
	or	a
	jp	nz,RomExec				; Jump if button 1 of the joystick 1 is pressed

	ld	a,3
	call	GTTRIG					; Test the button 2 of the joystick 1
	or	a
	call	nz,FreqTogglJ				; Jump if button 2 of the joystick 1 is pressed
	jr	MainLoop

; ============================================
; FUNCIONES ORIGINALES (CON PEQUEÑOS AJUSTES)
; ============================================

FreqTogglJ:
	ld	a,3
	call	GTTRIG					; Test the button 1 of the joystick 1
	or	a
	jr	nz,FreqTogglJ				; Jump if button 2 of the joystick 1 is pressed

	ld	a,1
	call	GTSTCK					; Test the joystick 1
	cp	3
	ret	nz					; Back if Left of the joystick 1 is not pressed

FreqToggle:
	ld	a,(MSXVER)
	or	a
	ret	z					; Back if MSX1

	ld	a,(NEWKEY+6)
	and	20h
	jr	z,FreqToggle				; Jump if F1 key is pressed

	ld	c,9
	ld	a,(RG9SAV)
	xor	2
	ld	b,a
	call	WRTVDP					; Toggle 50/60 Hz mode
	ret

PrintFreq:
	ld	a,(MSXVER)
	cp	0
	jr z, PrintFreqMSX1 			; Jump if NOT MSX1

	ld	a,(RG9SAV)
	and	2
	jr z, PrintFreq60Hz			; Jump if 60hz mode
	call PrintSMXTeam50Hz
	ret

PrintFreqMSX1:
	call PrintSMXTeam
	ret	

PrintFreq60Hz:
	call PrintSMXTeam60Hz
	ret



RomExec:
	ld	a,(SegMum)
	ld	(RamBottom+15),a			; Temporary SegMum
	ld	(VOICAQ+(RamPrgEnd-BankSel)),a
	ld	c,a
	ld	a,(NextSegMum)
	sub	c					; Calculate the Rom size
	ld	(RomSize),a

	jp	PrgInRam				; Go to the Rom execution program in RAM (RomSel)

MoveDown:
	ld	hl,(CurrAdr)
	inc	hl
	ld	a,(hl)					; Get the MSX generation data
	and	3
	ld	b,a					; Store MSX generation value in B
	bit	7,(hl)
	jr	z,NextName				; Jump if last Rom bit is reset
	ld	a,(MSXVER)
	and	3					; Reset unused bits of MSX generation
	cp	b
	ret	c					; Last line?

CONT:
	ld	de,LineData
	add	hl,de
	ld	a,(hl)					; Get the nMSX generation data
	cp	255
	ret	z

NextName:
	ld	hl,(CurrTopName)
	ld	de,LineData
	add	hl,de
	ld	(CurrTopName),hl			; Set the new current name position
	ret

MoveUp:
	ld	hl,(CurrTopName)
	ld	de,LineData*5
	add	hl,de
	ld	a,(hl)
	or	a
	ret	z					; Back if next ROM segment is 0 (No ROM) 

PrevName:
	ld	hl,(CurrTopName)
	ld	de,LineData
	or	a
	sbc	hl,de
	ld	(CurrTopName),hl			; Set the new current name position
	ret

PrintList:
	ld	b,LIST_VIEW_SIZE					; 20 lines to display
	ld	hl,(CurrTopName)			; HL = Current Top name address

PrintListLP:
	push	bc
	inc	hl					; Points the MSX generation
PrnCond:
	ld	a,(hl)
	and	3					; to keep the bits 0-1
	ld	c,a
	ld	a,(MSXVER)
	cp	c
	jr	nc,PrintOK				; Call if A >= c

	ld	de,LineData
	add	hl,de					; Go to the next name

	jr	PrnCond
PrintOK:
	ld	e,(hl)					; Get the settings bits (Mirror and Boot)
	dec	hl					; Points the Segment number
	pop	bc
	push	bc
	ld	a,LIST_VIEW_SIZE-6
	cp	b
	jr	nz,SkipSegMum
	ld	a,e
	ld	(SettingBits),a				; Store the settings bits at the cursor
	ld	a,(hl)					; Get the Segment number at the cursor
	ld	(SegMum),a				; Store the Segment number at the cursor
	ld	(CurrAdr),hl
	ld	de,LineData
	add	hl,de
	ld	a,(hl)					; Get the next Segment number
	ld	(NextSegMum),a				; Store the next Segment number
	ld	hl,(CurrAdr)
SkipSegMum:
	; *** CAMBIO: Ajustar offset para SCREEN1 ***
	; En SCREEN0 usaban: LineData-WidthName (42-40=2)
	; En SCREEN1: LineData-WidthName (34-32=2) - ¡funciona igual!
	ld	de,LineData-WidthName
	add	hl,de					; Points the current name
	ld	de,(VramPos)
	ld	bc,WidthName
	push	hl
	call	LDIRVM					; Print a name

	ld	hl,(VramPos)
	ld	de,WidthName
	add	hl,de
	ld	(VramPos),hl				; Go to the line

	pop	hl
	ld	de,WidthName
	add	hl,de					; Go to next name

	pop	bc
	djnz	PrintListLP

	; *** CAMBIO: Posición del cursor selector en SCREEN1 ***
	ld	hl, NAME_TABLE + (WidthName * SELECTOR_POS) + 1 ; Línea 10, columna 1
	ld	a,CHAR_SELECTOR
	call	WRTVRM					; Print the selection cursor

	halt
	halt
	halt
	halt
	ret

PrintName:
	pop	hl
	inc	hl
	ld	bc,WidthName*START_LIST
	call	LDIRVM					; Print the current name
	pop	hl
	ret

SetVDPReg:
    LD A, 2              ; Registro 2 del VDP
    OUT (0x99), A        ; Selecciona el registro 2 del VDP
    LD A, 0x08           ; Apunta a la tabla de caracteres en 0x0800
    OUT (0x99), A        ; Escribe el valor en el registro
    RET

RomSel:
	;push	bc
	;push	de

	;ld	a,(BASRVN+1)
	;bit	4,a
	;jr	nz,NoScreen1				; Jump if initial screen mode is screen 0
	;ld	a,1
	;push	hl
	;call	INIT32
	;pop	hl
	ld	hl,(CurrAdr)				; Jump if generation number is not MSX1
	inc	hl
	ld	a,(hl)
	and	3
	jr	nz,NoScreen1

	ld	a,(BASRVN+1)
	bit	4,a
	jr	nz,NoScreen1				; Jump if initial screen mode is screen 0
	ld	a,1
	call	INIT32
NoScreen1:
	ld	a,(RomSize)
	cp	5
	jp	z,PrgInRam+(Rom2pages1_2_3-RomSel)	; Jump if Romsize == 40K (jr Rom2pages1_2_3)
	cp	6
	jp	z,PrgInRam+(Rom2pages1_2_3-RomSel)	; Jump if Romsize == 48K (jr Rom2pages1_2_3)
	cp	4
	jp	nc,PrgInRam+(Rom2pages1_2-RomSel)	; Jump if Romsize >= 32K (jr Rom2pages1_2)

PlainRom8to16K:

; Initialise the Rom mapper segments and pages for 4/8/16kB Roms

	ld	a,(RamBottom+15)
	ld	(05000h),a				; Select the segment 0 on the page 4000h-5FFFh

	ld	a,(04003h)
	bit	7,a
	jp	nz,PrgInRam+(Rom2page2-RomSel)		; Jump if INIT address > 7FFFh
	ld	a,(04009h)
	bit	7,a
	jp	nz,PrgInRam+(Rom2page2-RomSel)		; Jump if TEXT address > 7FFFh
	ld	a,(04003h)
	bit	6,a
	jp	z,PrgInRam+(Rom2page0-RomSel)		; Jump if INIT address < 4000h

Rom2page1:
	ld	a,(RamBottom+15)
	ld	(05000h),a				; Select the segment 0 on the page 4000h-5FFFh
	inc	a
	ld	(07000h),a				; Select the segment 1 on the page 6000h-7FFFh
	ld	e,1
	ld	hl,09000h
	call	WRSLT					; Select the empty segment on the page 8000h-9FFFh
	ld	e,1
	ld	hl,0B000h
	call	WRSLT					; Select the empty segment on the page A000h-BFFFh
	;pop	de
	;pop	bc
	ld	hl,(04002h)
	jp	PrgInRam+(ExeByJump-RomSel)		; Execute the selected Rom with INIT address between 4000h and 7FFFh

; 32kB Rom execution on page 4000h

Rom2pages1_2:
	ld	a,(RamBottom+15)

	if	Offset==2
	ld	e,0
	ld	a,(RomSlot)
	ld	hl,OffsetReg+1
	call	WRSLT					; Sets up the offset segment
	endif

	if	Offset==1
	ld	e,a
	ld	a,(RomSlot)
	push	af
	push	de
	ld	hl,OffsetReg
	call	WRSLT					; Sets up the offset segment
	pop	de
	pop	af
	ld	hl,03FF0h
	call	WRSLT					; Sets up the offset segment
	xor	a
	endif

	ld	(05000h),a				; Select the segment 0 on the page 4000h-5FFFh
	inc	a
	ld	(07000h),a				; Select the segment 1 on the page 6000h-7FFFh
	ld	e,a
	ld	a,(RomSlot)
	inc	e
	ld	hl,09000h
	call	WRSLT					; Select the segment 2 on the page 8000h-9FFFh
	ld	a,(RomSlot)
	inc	e
	ld	hl,0B000h
	call	WRSLT					; Select the segment 3 on the page A000h-BFFFh
	;pop	af

	;ld	hl,(4002h)
	;push	hl
	;bit	7,h
	ld	de,(4002h)
	push	de
	bit	7,d
	jr	z,NoUPTO8000

	ld	a,(EXPTBL)
	ld	h,040h
	call	ENASLT					; Select the Main-ROM on the page 4000h-7fffh
	ld	a,(RomSlot)
	ld	h,080h
	call	ENASLT					; Select the ROM on the page 8000h-Bfffh
NoUPTO8000:
	;pop	hl
	pop	de
	;pop	bc
	jp	PrgInRam+(ExeByJump-RomSel)		; Execute the selected Rom with INIT address between 4000h and 7FFFh

; 32Kb Rom execution on page 8000h

Rom2page2:
	ld	a,1
	ld	(05000h),a				; Select the empty segment on the page 4000h-5FFFh
	ld	(07000h),a				; Select the empty segment on the page 6000h-7FFFh

	;push	hl
	ld	a,(RamBottom+15)
	ld	e,a
	ld	a,(RomSlot)
	ld	hl,09000h
	call	WRSLT					; Select the segment 0 on the page 8000h-9FFFh
	ld	a,(RomSlot)
	inc	e
	ld	hl,0B000h
	call	WRSLT					; Select the segment 1 on the page A000h-BFFFh
	;pop	hl
	;pop	de
	;pop	bc
	jp	PrgInRam+(ExeByRet-RomSel)		; Back to Rom scaning

; 16Kb Rom execution on page 0000h

Rom2page0:
	ld	a,1
	ld	(05000h),a				; Select the empty segment on the page 4000h-5FFFh
	ld	(07000h),a				; Select the empty segment on the page 6000h-7FFFh

	;push	hl
	ld	a,(RamBottom+15)
	ld	e,a
	ld	a,(RomSlot)
	ld	hl,09000h
	call	WRSLT					; Select the segment 0 on the page 8000h-9FFFh
	ld	a,(RomSlot)
	inc	e
	ld	hl,0B000h
	call	WRSLT					; Select the segment 1 on the page A000h-BFFFh
	;pop	hl
	;pop	de
	;pop	bc
	jp	PrgInRam+(ExeByRet-RomSel)		; Back to Rom scaning

; 48Kb Rom execution

Rom2pages1_2_3:
	ld	a,(RamBottom+15)
	ld	(05000h),a				; Select the segment 2 on the page 4000h-5FFFh
	ld	a,(04000h)
	cp	41h
	jp	nz,PrgInRam+(PutOnpages1_2_3-RomSel)	; Jump to PutOnpages1_2_3 if no header on the first segment
	ld	a,(04001h)
	cp	42h
	jp	z,PrgInRam+(Rom2pages1_2-RomSel)	; Jump to Rom2pages1_2 if Header on the first segment

PutOnpages1_2_3:
	ld	a,(RamBottom+15)
	add	a,4
	ld	(05000h),a				; Select the segment 4 on the page 4000h-5FFFh
	inc	a
	ld	(07000h),a				; Select the segment 5 on the page 6000h-7FFFh

	ld	hl,4000h
	ld	de,8000h
	ld	bc,4000h
	ldir

	sub	2
	ld	(07000h),a				; Select the segment 3 on the page 6000h-7FFFh
	dec	a
	ld	(05000h),a				; Select the segment 2 on the page 4000h-5FFFh

	ld	a,(RamBottom+15)
	ld	e,a
	ld	a,(RomSlot)
	ld	hl,09000h
	call	WRSLT					; Select the segment 0 on the page 8000h-9FFFh
	ld	a,(RomSlot)
	inc	e
	ld	hl,0B000h
	call	WRSLT					; Select the segment 1 on the page A000h-BFFFh

	;pop	de
	;pop	bc
	ld	hl,(4002h)
;	jp	(hl)					; Execute the selected Rom with INIT address between 4000h and 7FFFh

ExeByJump:
	;ld	a,(SettingBits)
	;and	020h					; Boot type
	;jp	nz,0					; Bios reboot
	;jp	(hl)					; Execute the selected Rom
	pop	hl
	pop	bc
	pop	af
	push	de
	pop	ix
	jp	(ix)	

ExeByRet:
	;ld	a,(SettingBits)
	;and	020h					; Boot type
	;ret	nz					; Back to Rom scaning
	;rst	0					; Bios reboot
	pop	hl
	pop	bc
	pop	af
	ret

MainPrgEnd:

; These routines have a fixed size and are placed in the music buffer area of channel.
; A patched Megarom calls its routines to change memory pages.

BankSel:

Bk5000:							; F975h Bank 0 8KB
	push	af							; F5
	push	hl							; E5
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)	; 21 C3 F9
	add	a,(hl)							; 86
	endif
	ld	(05000h),a						; 32 00 50
	pop	hl								; E1
	pop	af								; F1
	ret									; C9
	if	Offset
	ds	4,0
	endif
Bk7000:							; F981h Bank 1 8KB
	push	af
	push	hl
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)
	add	a,(hl)
	endif
	ld	(07000h),a
	pop	hl
	pop	af
	ret
	if	Offset
	ds	4,0
	endif
Bk9000:							; F98Dh Bank 2 8KB
	push	af
	push	hl
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)
	add	a,(hl)
	endif
	ld	(09000h),a
	pop	hl
	pop	af
	ret
	if	Offset
	ds	4,0
	endif
BkB000:							; F999h Bank 3 8KB
	push	af
	push	hl
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)
	add	a,(hl)
	endif
	ld	(0B000h),a
	pop	hl
	pop	af
	ret
	if	Offset
	ds	4,0
	endif
AD6000:							; F9A5h Bank 0 16KB
	push	af
	add	a,a
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)
	add	a,(hl)
	endif
	ld	(05000h),a
	inc	a
	ld	(07000h),a
	pop	af
	ret
	if	Offset
	ds	4,0
	endif
AD7000:							; F9B4h Bank 1 16KB
	push	af
	add	a,a
	if	Offset==0
	ld	hl,VOICAQ+(RamPrgEnd-BankSel)
	add	a,(hl)
	endif
	ld	(09000h),a
	inc	a
	ld	(0B000h),a
	pop	af
	ret
	if	Offset
	ds	4,0
	endif
SCC:							; F9C3h SCC CALL
	ld	(9000h),a
	ret
	if	Offset
	ds	4,0
	endif


RamPrgEnd:

LoadCustomFont:
    ; Cargar fuente
    ld hl, CustomFont
    ld de, 0x0000
    ld bc, CustomFontEnd - CustomFont
    call LDIRVM
    
    ; Configurar Color Pattern Table con DEGRADADO
    ; Cada patrón (8 bytes) tendrá un color base diferente
    ld hl, ColorPalettes
    ld de, COLOR_TABLE     ; 0x2000
    ld bc, 32              ; SOLO 32 bytes
    call LDIRVM
    ret
    
ColorPalettes:
    include	"./fonts/colors.asm"
ColorPalettesEnd:

PrintString:
    push hl
    push de
    push bc
    
PrintStringLoop:
    ld a, (de)
    or a
    jp z, PrintStringDone
    
    call WRTVRM
    inc hl
    inc de
    jp PrintStringLoop
    
PrintStringDone:
    pop bc
    pop de
    pop hl
    ret

PrintTitle:
    ld hl, NAME_TABLE + 0
    ld de, Title
    call PrintString
	ret

PrintTopSeparator:
    ld hl, NAME_TABLE + TS_POS
    ld de, SeparatorTopLine
    call PrintString
	ret

PrintBottomSeparator:
    ld hl, NAME_TABLE + BS_POS
    ld de, SeparatorBottomLine
    call PrintString
	ret

PrintEmptyLine1:
	ld hl, NAME_TABLE + EL1_POS
	ld de, EmptyLine
	call PrintString
	ret

PrintSMXTeam:
    ld hl, NAME_TABLE + BS_POS + 32
    ld de, SMXTeam
    call PrintString
	ret

PrintSMXTeam50Hz:
    ld hl, NAME_TABLE + BS_POS + 32
    ld de, F1_50Hz
    call PrintString
	ret

PrintSMXTeam60Hz:
	ld hl, NAME_TABLE + BS_POS + 32
	ld de, F1_60Hz
	call PrintString
	ret

; ============================================
; MENSAJES (AJUSTADOS A 32 COLUMNAS)
; ============================================
Title:
	include	"./RCM Title.asm"  ; Asegúrate que este archivo tenga 32 columnas

CustomFont:
	include	"./fonts/custom.asm"
CustomFontEnd:

EmptyLine:
	db	"                                "  ; 32 espacios

SeparatorTopLine:
	db	TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS,TS, 0
	; 32 caracteres

SeparatorBottomLine:
	db	BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS,BS, 0
	; 32 caracteres

F1_50Hz:
	db	" ", 0xC0,0xC1,0xC2,0xC3,0xC4, "                [F1] 50Hz ", 0
	; Ajustado a 32 caracteres

F1_60Hz:
	db	" ", 0xC0,0xC1,0xC2,0xC3,0xC4, "                [F1] 60Hz ", 0
	; Ajustado a 32 caracteres

SMXTeam:
	db	"             ", 0xC0,0xC1,0xC2,0xC3,0xC4, "              ", 0
	; Ajustado a 32 caracteres

; RomList format is: ROM segment, MSX generation, "Rom name"
RomList:
	ds	LineData*6,0
	include	"./RomList.asm"
	ds	LineData*20,0

EndList:
	ds	02000h-(EndList-04000h),255

; Empty header on the segment 1 to run the Roms that contains a Basic program
	ds	10h,0

; Fill the rest of segment 1 with 255
	ds	01FF0h,255