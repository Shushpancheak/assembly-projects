.model tiny

;===============================================================================
; CONSTANTS

video_memory_start	= 0b800h

; CHARACTERS

left_up_corner		= '&'	;0c9h	; 
left_down_corner	= '&'	;0c8h	; 
right_up_corner		= '&'	;0bbh 	; 
right_down_corner	= '&'	;0bch	; 
horizontal		= '#'	;0cdh	; 
vertical		= '@'	;0bah	; 
space_char		= ':'	;177	; space

; COLORS		  backfore
;			  brgbirgb
border_color		= 00011111b
inner_color		= 00011111b
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
; di <- bx
; ax <- symbols
; cx <- iterator
;-------------------------------------------------------------------------------

cur_symbol	equ ax

DrawLine macro vert1_symattr, inner_symattr, vert2_symattr, x1, x2
local x_loop
		nop
		
		mov di, bx

		mov cx, x2 - x1
		
		mov cur_symbol, vert1_symattr
		stosw
		
		mov cur_symbol, inner_symattr
x_loop:		rep stosw

		mov cur_symbol, vert2_symattr
		stosw
		
		add bx, dos_width * 2

		nop
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
		mov cx, y2 - y1 + 2
		mov ax, shadow_mask
		mov di, bx
		
sh_loop:	and word ptr es:[di], ax
		add di, dos_width * 2
		loop sh_loop
endm

ShadowHor macro x1, x2
local sh_loop
		mov cx, x2 - x1 + 3
		mov ax, shadow_mask
		mov di, bx
		
sh_loop:	and word ptr es:[di], ax
		add di, 2
		loop sh_loop
endm

;-------------------------------------------------------------------------------
; DrawWindow
; Creates window
; 
; ax, bx, cx, di, es
;-------------------------------------------------------------------------------

DrawWindow macro x1, y1, x2, y2
local y_loop
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
endm

;===============================================================================
; CODE

.code
org 100h

start:		
		DrawWindow 5, 5, 70, 21
		DrawWindow 6, 6, 60, 15
		DrawWindow 50, 10, 65, 17

		ret

end start