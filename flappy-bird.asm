[org 0x0100]
jmp start

;variables
birdX: dw 60
birdY: dw 90
pipeX: dw 220
pipeY: dw 140
upipeX: dw 220
upipeY: dw 50

; Function to set the VGA mode
setVGA:
    mov ax, 0x0013    ; Set video mode to 320x200, 16 colors (0x0013)
    int 0x10          ; BIOS interrupt to set video mode
    ret

; Function to clear the screen
drawBG:
    push ax
    push es
    push di
    mov ax, 0xA000    ; Video memory segment for VGA
    mov es, ax
    mov di, 0        ; Start at the beginning of video memory
    mov cx, 320*200
	.l1:
        mov word [es:di], 0x0009 ; Clear to black (color index 0)
        add di, 1                ; Move to the next pixel (2 bytes per pixel)
        loop .l1             ; Decrease CX and loop until it's 0
    pop di
    pop es
    pop ax
    ret

drawRectangle:
	push bp
	mov bp, sp
	push ax
    push es
    push di
	push cx
	push dx
    mov ax, 0xA000    ; Video memory segment for VGA
    mov es, ax
    mov di, 0        ; Start at the beginning of video memory
    mov cx, [bp+4]	;x
	.l1:
		add di, 1
		sub cx, 1
		jnz .l1
	mov cx, [bp+6]	;y
	.l2:
		add di, 320
		sub cx, 1
		jnz .l2
	mov cx, [bp+8]	;h
	.l3:
		mov dx, [bp+10]	;w
		.l4:
			push ax
			mov ax, [bp+12]
			mov word [es:di], ax
			pop ax
			add di, 1
			sub dx, 1
			jnz .l4
		add di, 320
		sub di, [bp+10]
		sub cx, 1
		jnz .l3
	pop dx
	pop cx
    pop di
    pop es
    pop ax
	pop bp
    ret 10

drawBird:
	push word 0x0006	;brown
	push 6				;w
	push 7				;h
	add word [birdY], 17
	add word [birdX], 7
	push word [birdY]	;y
	push word [birdX]	;x
	sub word [birdY], 17
	sub word [birdX], 7
	call drawRectangle

	push word 0x000E	;yellow
	push 20			;w
	push 20			;h
	push word [birdY]	;y
	push word [birdX]	;x
	call drawRectangle
	
	push word 0x000C	;red
	push 15				;w
	push 5				;h
	add word [birdY], 10
	sub word [birdX], 10
	push word [birdY]	;y
	push word [birdX]	;x
	sub word [birdY], 10
	add word [birdX], 10
	call drawRectangle
	
	push word 0x0000	;black
	push 9				;w
	push 10				;h
	add word [birdY], 3
	add word [birdX], 11
	push word [birdY]	;y
	push word [birdX]	;x
	sub word [birdY], 3
	sub word [birdX], 11
	call drawRectangle
	
	push word 0x000F	;white
	push 8				;w
	push 8				;h
	add word [birdY], 4
	add word [birdX], 12
	push word [birdY]	;y
	push word [birdX]	;x
	sub word [birdY], 4
	sub word [birdX], 12
	call drawRectangle
	
	push word 0x0000	;black
	push 2				;w
	push 6				;h
	add word [birdY], 5
	add word [birdX], 16
	push word [birdY]	;y
	push word [birdX]	;x
	sub word [birdY], 5
	sub word [birdX], 16
	call drawRectangle

    ret
	
drawGround:

	push word 0x0006	;brown
	push 320			;w
	push 30				;h
	push word 170		;y
	push word 0			;x
	call drawRectangle
	
	push word 0x000A	;green
	push 320			;w
	push 6				;h
	push word 165		;y
	push word 0			;x
	call drawRectangle
	
	ret
	
drawPipe:

	push ax
	push word 0x000A	;green
	push 40				;w
	mov ax, 200
	sub ax, [pipeY]
	push ax	;h
	push word [pipeY]	;y
	push word [pipeX]	;x
	call drawRectangle
	pop ax
	
	
	push word 0x0002	;green
	push 60				;w
	push 20				;h
	push word [pipeY]	;y
	sub word [pipeX], 10
	push word [pipeX]	;x
	add word [pipeX], 10
	call drawRectangle
	ret
	
drawUPipe:

	push word 0x000A	;green
	push 40				;w
	push word [upipeY]	;h
	push word 0			;y
	push word [upipeX]	;x
	call drawRectangle
	
	
	push word 0x0002	;green
	push 60				;w
	push 20				;h
	push word [upipeY]	;y
	sub word [upipeX], 10
	push word [upipeX]	;x
	add word [upipeX], 10
	call drawRectangle
	ret

;main
start:

    call setVGA        ; Set 640x480 16-color VGA mode
    call drawBG        ; Clear the screen
	call drawBird
	call drawGround
	call drawPipe
	call drawUPipe
	
end:
    mov ax, 0x4C00     ; Terminate program
    int 0x21           ; DOS interrupt
