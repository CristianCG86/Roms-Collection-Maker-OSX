
	di
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
	cp	4
	jp	nc,PrgInRam+(Rom2pages1_2-RomSel)	; Jump if Romsize >= 32K (jr Rom2pages1_2)

PlainRom8to16K:
    ; Initialise the Rom mapper segments and pages for 4/8/16kB Roms
	ld	a,(RamBottom+15)
	ld	(05000h),a				; Select the segment 0 on the page 4000h-5FFFh

    ld	a,(RomSize)
    cp	1
    jp	z,PrgInRam+(ExeByJump-RomSel)		; Execute the selected Rom with INIT address between 4000h and 7FFFh

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

ExeByRet:
ExeByJump:

    pop	hl
    pop	bc
    pop	af
    push	de

    ld sp, (SPRegister)     ; SP directamente al valor del KUC
    ld iy, (IYRegister)     ; IY directamente al valor del KUC

;    pop	ix
;    jp	(ix)

    ld h, 0x80
    call 0x0024      ; H.CHRG - Preparación del sistema
    ld sp, (SPRegister)     ; SP directamente al valor del KUC
    ld iy, (IYRegister)     ; IY directamente al valor del KUC
    ld ix, (0x4002)  ; IX = dirección de entrada del juego
    ld a, (SLOT_CART) ; Slot del cartucho
    ld h, 0x40       ; Página 4000h-7FFFh
    ei
    jp 0x001C        ; ENASLT - Activación de slot y salto


	ld	a,(SettingBits)
	and	020h					; Boot type
	ret	nz					; Back to Rom scaning
	rst	0