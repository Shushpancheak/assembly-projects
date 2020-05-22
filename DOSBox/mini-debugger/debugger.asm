.186
.model tiny
locals @@

.data

;===============================================================================
; CONSTANTS

MACR			equ nop

video_memory_start	= 0b800h

; CHARACTERS

left_up_corner		= 0c9h	; Й
left_down_corner	= 0c8h	; И
right_up_corner		= 0bbh 	; »
right_down_corner	= 0bch	; ј
horizontal		= 0cdh	; Н
vertical		= 0bah	; є
space_char		= ' '	; space

; COLORS		  backfore
;			  brgbirgb
border_color		= 01011111b
inner_color		= 01011111b
shadow_mask		= 0000011111111111b

inner_symattr		= space_char 		or (inner_color  shl 8)
vertical_symattr	= vertical 		or (border_color shl 8)
horizontal_symattr	= horizontal 		or (border_color shl 8)
ru_symattr		= right_up_corner 	or (border_color shl 8)
rd_symattr		= right_down_corner 	or (border_color shl 8)
lu_symattr		= left_up_corner 	or (border_color shl 8)
ld_symattr		= left_down_corner 	or (border_color shl 8)

; DOS VARS
dos_width		= 80d
dos_height		= 25d

;===============================================================================
; MACROS

;-------------------------------------------------------------------------------
; DrawLine					
; Draws vert1_symattr, then inner_symattr x width, then vert2_symattr.
;
; bx += dow_width * 2
; 
; di <- bx
; ax <- symbols
; cx <- iterator
;-------------------------------------------------------------------------------

cur_symbol	equ ax

DrawLine macro vert1_symattr, inner_symattr, vert2_symattr, x1, x2
local x_loop
		MACR
		
		mov di, bx

		mov cx, x2 - x1
		
		mov cur_symbol, vert1_symattr
		stosw
		
		mov cur_symbol, inner_symattr
x_loop:		rep stosw

		mov cur_symbol, vert2_symattr
		stosw
		
		add bx, dos_width * 2

		MACR
endm

;-------------------------------------------------------------------------------
; DrawString					
; Draws string, start: bx -> di.
;
; Don't forget to set ah to attributes you want.
;
; bx += dos_width * 2
;
; si <- string iterator
; di <- bx
; ax <- symbols
; cx <- iterator
;-------------------------------------------------------------------------------

DrawString macro max_length
local x_loop, .end
		MACR
		
		mov di, bx
		mov si, dx
		
		mov cx, max_length

x_loop:		cmp byte ptr cs:[si], '$'
		je .end

		mov al, byte ptr cs:[si]
		mov byte ptr es:[di], al
		mov byte ptr es:[di + 1], ah
		
		add di, 2
		inc si
		
		loop x_loop
		
.end:		add bx, dos_width * 2

		MACR
endm

;-------------------------------------------------------------------------------
; ShadowVert
; Applies mask to vertical near window
; 
; di <- bx
; ax <- mask
; cx <- iterator
;-------------------------------------------------------------------------------

ShadowVert macro y1, y2
local sh_loop
		MACR
		mov cx, y2 - y1 + 2
		mov ax, shadow_mask
		mov di, bx
		
sh_loop:	and word ptr es:[di], ax
		add di, dos_width * 2
		loop sh_loop
		MACR
endm

;-------------------------------------------------------------------------------
; ShadowHor
; Applies mask to vertical near window
; 
; di <- bx
; ax <- max
; cx <- iterator
;-------------------------------------------------------------------------------

ShadowHor macro x1, x2
local sh_loop
		MACR
		mov cx, x2 - x1 + 3
		mov ax, shadow_mask
		mov di, bx
		
sh_loop:	and word ptr es:[di], ax
		add di, 2
		loop sh_loop
		MACR
endm

;-------------------------------------------------------------------------------
; DrawWindow
; Creates window
; 
; ax, bx, cx, di, es
;-------------------------------------------------------------------------------

DrawWindow macro x1, y1, x2, y2
local y_loop
		MACR
		; To draw, we will use video memory starting at 
		; video_memory_start. The instruction stosw will essentially
		; place a character and attributes to the es:[di] cell.
		; im the most geyskiy gay in 831 (max mumlad ze)

		mov ax, video_memory_start	; Tmp storage for video seg.
		mov es, ax			; And es now points to the start
						; of video segment.
		
		; Assume we know the exact number of bytes for DOS overlay
		; width and height. Use them to calculate the cell in video
		; memory ([y * width + x] * 2).

cur_y		equ dx				; current y.
cur_start_byte	equ bx				; start byte number for
						; current line

		mov cur_y, y1
		mov cur_start_byte, (y1 * dos_width + x1) * 2

		DrawLine lu_symattr, horizontal_symattr, ru_symattr, x1, x2

y_loop:		DrawLine vertical_symattr, inner_symattr, vertical_symattr, x1, x2
		
		inc cur_y
		cmp cur_y, y2
		jne y_loop

		DrawLine ld_symattr, horizontal_symattr, rd_symattr, x1, x2
		
		; Shadow.
		
		mov cur_start_byte, ((y1 + 1) * dos_width + x2 + 2) * 2
		ShadowVert y1, y2
		mov cur_start_byte, ((y1 + 1) * dos_width + x2 + 3) * 2
		ShadowVert y1, y2
		
		mov cur_start_byte, ((y2 + 2) * dos_width + x1 + 1) * 2
		ShadowHor x1, x2
		
		MACR
endm

;-------------------------------------------------------------------------------
; RegisterToString(reg: register, string: char*, num_start (offset in string): int)
; Stores register to given string, with leading zeros: 00000.
;
; ax, bx, cx, si, reg, dx, di
;-------------------------------------------------------------------------------

RegisterToString macro reg, string, num_start
local .loop
		MACR
		
		push reg
		
		mov ax, offset string
		add ax, num_start
		add ax, 4
		mov si, ax

		pop reg
		mov ax, reg
		xor dx, dx
		
		mov cx, 4
		
.loop:		mov dl, al
		and dl, 00001111b
		add dx, offset hex_str
		mov di, dx
		mov bl, byte ptr cs:[di]
		mov byte ptr cs:[si], bl
		dec si
		xor dx, dx
		
		shr ax, 4					; /= 16
		loop .loop
		
		MACR
endm

;-------------------------------------------------------------------------------
; GetRegisters
; Stores ax and bx to debug_XX_str's.
;
; ax, bx, cx, ds, si
;-------------------------------------------------------------------------------

GetRegisters macro
		MACR
		
		push cx 						; NEW
		push bx
		
		RegisterToString ax, debug_ax_str, debug_num_start
		
		pop bx
		RegisterToString bx, debug_bx_str, debug_num_start
		
		pop cx 							; NEW
		RegisterToString cx, debug_cx_str, debug_num_start 	; NEW
		
		MACR
endm


;-------------------------------------------------------------------------------
; DrawDebugWindow
; Creates window in certain position with ax and bx registers shown.
; 
; ax, bx, cx, di, es
;-------------------------------------------------------------------------------

debug_x0		= 65
debug_y0		= 3
debug_x1		= 75
debug_y1		= 6						; UPD

debug_ax_x0		= debug_x0 + 1
debug_ax_y0		= debug_y0 + 1
debug_bx_x0		= debug_x0 + 1
debug_bx_y0		= debug_y0 + 2
debug_cx_x0		= debug_x0 + 1					; NEW
debug_cx_y0		= debug_y0 + 3					; NEW

debug_color		= inner_color

debug_num_start		= 4 ; start of 00000 in str

DrawDebugString macro debug_reg_x0, debug_reg_y0, debug_reg_str
		MACR
		
		mov ah, debug_color
		mov bx, (debug_reg_x0 + debug_reg_y0 * dos_width) * 2
		mov dx, offset debug_reg_str
		DrawString debug_x1 - debug_x0 - 2
		
		MACR

endm

DrawDebugWindow macro
		MACR
		
		GetRegisters

		DrawWindow debug_x0, debug_y0, debug_x1, debug_y1

		DrawDebugString debug_ax_x0, debug_ax_y0, debug_ax_str
		DrawDebugString debug_bx_x0, debug_bx_y0, debug_bx_str
		DrawDebugString debug_cx_x0, debug_cx_y0, debug_cx_str 	; NEW
		
		MACR
endm

;-------------------------------------------------------------------------------
; SetHandler
; Ties handler to some interrupt
;
; int_num - interrupt number:
; 8 - timer
; 9 - keyboard
;
; old_offset, old_segment -- allocated variables in following
; form:
;
; jmp_far		db 0eah 	; Command jmpf
; old_offset		dw 0
; old_segment		dw 0
;
; that are used in handler just before iret, to execute previous
; handler.
; 
; ax, bx, es
;-------------------------------------------------------------------------------

SetHandler macro int_num, handler, old_offset, old_segment
		MACR

		; Getting old handler
		xor ax, ax
		mov es, ax
		mov bx, int_num * 4		; ith int handler info
		
		cli
		
		mov ax, es:[bx]
		mov old_offset, ax
		mov ax, es:[bx + 2]
		mov old_segment, ax
		
		mov es:[bx], offset handler
		mov es:[bx + 2], cs
		
		sti
		
		MACR
endm

;-------------------------------------------------------------------------------
; UnsetHandler
; Unties handler to some interrupt
;
; int_num - interrupt number:
; 8 - timer
; 9 - keyboard
;
; old_offset, old_segment -- allocated variables in following
; form:
;
; jmp_far		db 0eah 	; Command jmpf
; old_offset		dw 0
; old_segment		dw 0
;
; that are used in handler just before iret, to execute previous
; handler.
; 
; ax, bx, es
;-------------------------------------------------------------------------------

UnsetHandler macro int_num, old_offset, old_segment
		MACR

		xor ax, ax
		mov es, ax
		mov bx, int_num * 4
		
		cli
		
		mov ax, old_offset
		mov es:[bx], ax
		mov ax, old_segment
		mov es:[bx + 2], ax
		
		sti
		
		MACR
endm

;-------------------------------------------------------------------------------
; ResidentExit
;
; Exit without clearing the memory
; 
;-------------------------------------------------------------------------------

ResidentExit macro
		MACR

		mov al, 0
		mov ah, 31h
		mov dx, offset .CODE_END
		shr dx, 4
		inc dx
		int 21h
		
		MACR
endm

;===============================================================================
; CODE

.code
org 100h

start: 
		SetHandler 9, StartShowingDebug, ssd_old_off, ssd_old_seg
		SetHandler 8, DebugTimerHandler, dth_old_off, dth_old_seg
	
		ResidentExit

;===============================================================================
; PROCEDURES

StartShowingDebug proc
		push ax bx es
		
		in al, 60h
		
		cmp al, 41
		jne @@end

		cmp ssd_is_showing, 1
		je @@unset

		mov ssd_is_showing, 1
		;SetHandler 8, DebugTimerHandler, dth_old_off, dth_old_seg
		
		jmp @@end

@@unset:	;UnsetHandler 8, dth_old_off, dth_old_seg	
		mov ssd_is_showing, 0

@@end:		pop es bx ax
ssd_jmpf		db 0eah
ssd_old_off		dw 0
ssd_old_seg		dw 0

		iret
endp

DebugTimerHandler proc
		pusha
		push ds es
		
		mov dx, video_memory_start
		mov es, dx
		
		cmp ssd_is_showing, 1
		je @@draw
		jmp @@end

@@draw:		DrawDebugWindow

@@end:		pop es ds
		popa

dth_jmpf		db 0eah
dth_old_off		dw 0
dth_old_seg		dw 0
endp

.data
ssd_is_showing		db 0
debug_ax_str		db 'ax: 00000$'
debug_bx_str		db 'bx: 00000$'
debug_cx_str		db 'cx: 00000$' ; NEW

hex_str			db '0123456789abcdef'

.CODE_END:

end start