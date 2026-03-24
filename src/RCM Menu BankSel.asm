Bk5000:							; F975h Bank 0 8KB
	push	af							; F5
	push	hl							; E5
	ld	hl,0x6969
	add	a,(hl)							; 86
	ld	(05000h),a						; 32 00 50
	pop	hl								; E1
	pop	af								; F1
	ret		
								; C9
Bk7000:							; F981h Bank 1 8KB
	push	af
	push	hl
	ld	hl,0x6969
	add	a,(hl)
	ld	(07000h),a
	pop	hl
	pop	af
	ret

Bk9000:							; F98Dh Bank 2 8KB
	push	af
	push	hl
	ld	hl,0x6969
	add	a,(hl)
	ld	(09000h),a
	pop	hl
	pop	af
	ret

BkB000:							; F999h Bank 3 8KB
	push	af
	push	hl
	ld	hl,0x6969
	add	a,(hl)
	ld	(0B000h),a
	pop	hl
	pop	af
	ret

AD6000:							; F9A5h Bank 0 16KB
	push	af
	add	a,a
	ld	hl,0x6969
	add	a,(hl)
	ld	(05000h),a
	inc	a
	ld	(07000h),a
	pop	af
	ret

AD7000:							; F9B4h Bank 1 16KB
	push	af
	add	a,a
	ld	hl,0x6969
	add	a,(hl)
	ld	(09000h),a
	inc	a
	ld	(0B000h),a
	pop	af
	ret
SCC:							; F9C3h SCC CALL
	ld	(9000h),a
	ret
