.model tiny

;===============================================================================
; CONSTANTS

MACRO_START		equ	nop
MACRO_END		equ	nop


;===============================================================================
; MACROS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MEMORY AND STRING MACROS
; Remembor to set df to that value you want it to be!
; Strings are terminated by '$' character.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FIXED SIZE ARRAYS

;-------------------------------------------------------------------------------
; memset(arr, val, n) -> void
;
; arr		- address of the array,			W
; val		- value to replace with,		Byte
; n		- length of the array,			W
;
; Sets memory in cells [arr, arr + n - 1] to val.
;
; Used registers and flags:
; es <- arr
; di <- n
; al <- val
; cx <- 0
;-------------------------------------------------------------------------------

memset macro arr, val, n
		MACRO_START
		
		mov es, arr
		mov di, 0
		mov al, val
		mov cx, n
		
		rep stosb

		MACRO_END
endm

;-------------------------------------------------------------------------------
; memcpy(arr_1, arr_2, n) -> void
;
; arr_1		- address of the source array,		W
; arr_2		- address of the destination array,	W
; n		- how many cells to copy,		W
;
; Sets memory in cells [arr_2, arr_2 + n - 1] to corresponding memory at
; [arr_1, arr_1 + n - 1].
;
; Used registers and flags:
; es <- arr_1
; di <- n
; ds <- arr_2
; si <- n
; cx <- 0
;-------------------------------------------------------------------------------

memcpy macro arr_1, arr_2, n
		MACRO_START
		
		mov ds, arr_1
		mov si, 0
		mov es, arr_2
		mov di, 0
		mov cx, n
		
		rep movsb

		MACRO_END
endm

;-------------------------------------------------------------------------------
; memchr(arr, char, n) -> es + di
;
; arr		- address of the array,			W
; char		- byte to find,				Byte
; n		- length of the array,			W
;
; Returns address of the first occurence in es + di.
;
; Finds first occurence of char in the array.
;
; Used registers and flags:
; es <- arr
; di <- index of found element or n
; cx <- [0, n]
;
; of, sf, zf, af, pf, cf
;-------------------------------------------------------------------------------

memchr macro arr, char, n
		MACRO_START
		
		mov es, arr
		mov di, 0
		mov al, char
		mov cx, n
		
		repne scasb

		MACRO_END
endm

;-------------------------------------------------------------------------------
; memcmp(arr_1, arr_2, n) -> zf, sf
;
; arr_1		- address of the first array,		W
; arr_2		- address of the second array,		W
; n		- how many cells to compare,		W
;
; Compares two arrays by lexicographical order.
;
; Used registers and flags:
; es <- arr_2
; di <- n
; ds <- arr_1
; si <- n
; cx <- 0
;
; zf <- 1 if arrays are identical, else 0
; sf <- 1 if arr_1 < arr_2, else 0
; of, sf, af, pf
;-------------------------------------------------------------------------------

memcmp macro arr_1, arr_2, n
		MACRO_START

		mov ds, arr_1
		mov si, 0
		mov es, arr_2
		mov di, 0
		mov cx, n
		
		repe cmpsb

		MACRO_END
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; STRINGS

;-------------------------------------------------------------------------------
; strlen(arr) -> di
;
; str		- address of the string,		W
;
; Finds the length of a string.
;
; Used registers and flags:
; es <- str
; di <- length
; al <- '$'
; ah <- '$'
;
; zf <- 1
; of, sf, af, pf, cf
;-------------------------------------------------------------------------------

strlen macro arr
local .loop
		MACRO_START

		mov ah, '$'
		mov ds, arr
		mov si, 0
		
.loop:		lodsb
		cmp al, ah
		je .loop

		MACRO_END
endm

;-------------------------------------------------------------------------------
; strcpy(arr_1, arr_2) -> void
;
; arr_1		- address of the source string,		W
; arr_2		- address of the destination string,	W
;
; Copies n characters of source string to destination string, including '$',
; where n = min {strlen(str_1), strlen(str_2)}.
;
; Used registers and flags:
; es <- arr_2
; di <- n
; ds <- arr_1
; si <- n
; ah <- '$'
;
; zf <- 1
; of, sf, af, pf, cf
;-------------------------------------------------------------------------------

strcpy macro arr_1, arr_2
local .loop, .end
		MACRO_START

		mov ah, '$'
		mov ds, arr_1
		mov si, 0
		mov es, arr_2
		mov di, 0
		
.loop:	cmp ah, byte ptr ds:[si]		; '$' == str_2[i]?
		movsb
		jne .loop

.end:		MACRO_END
endm

;-------------------------------------------------------------------------------
; strchr(arr, char) -> es + di
;
; arr		- address of the string,		W
; char		- byte to find,				Byte
;
; Returns address of the first occurence of char.
;
; Used registers and flags:
; es <- arr
; di <- index of found element or n
;
; of, sf, zf, af, pf, cf
;-------------------------------------------------------------------------------

strchr macro arr, char
local .loop, .end
		MACRO_START

		mov ah, '$'
		mov es, arr
		mov di, 0
		mov al, char
		
.loop:		cmp ah, byte ptr ds:[si]
		je .end
		scasb
		jne .loop

.end:		MACRO_END
endm

;-------------------------------------------------------------------------------
; strrchr(arr, char) -> es + si
;
; arr		- address of the string,		W
; char		- byte to find,				Byte
;
; Returns address of the last occurence of char.
;
; Used registers and flags:
; es <- arr
; si <- index of found element or 0
; di <- length
;
; of, sf, zf, af, pf, cf
;-------------------------------------------------------------------------------

strrchr macro arr, char
local .loop, .end, .loop_end
		MACRO_START

		mov ah, '$'
		mov es, arr
		mov di, 0
		mov si, 0
		mov al, char
		
.loop:		cmp ah, byte ptr ds:[si]
		je .end
		scasb
		jne .loop_end
		mov si, di
.loop_end:	jmp .loop

.end:		MACRO_END
endm

;-------------------------------------------------------------------------------
; strcmp(arr_1, arr_2) -> zf, sf
;
; arr_1		- address of the first array,		W
; arr_2		- address of the second array,		W
;
; Compares two strings by lexicographical order.
; n = min {strlen(arr_1), strlen(arr_2)}.
;
; Used registers and flags:
; es <- arr_2
; di <- <=n
; ds <- arr_1
; si <- <=n
;
; zf <- 1 if strings are identical, else 0
; sf <- 1 if arr_1 < arr_2, else 0
; of, sf, af, pf
;
; Uses one word in stack.
;-------------------------------------------------------------------------------

strcmp macro arr_1, arr_2
local .loop, .end, .first, .second, .first_is_less, .second_is_less
		MACRO_START

		mov ah, '$'
		mov ds, arr_1
		mov si, 0
		mov es, arr_2
		mov di, 0
		
.loop:		cmpsb

		pushf
		
.first:		cmp byte ptr ds:[si], ah	; if (str_1[i] == '$')
		jne .second			; (else check str_2[i])
		cmp byte ptr es:[di], ah	; 	if (str_2[i] == '$'
		jne .first_is_less		;	(else first is less)
		
		cmp 0, 0
		je .end				; 	Equal
		
		
.second:	cmp byte ptr es:[di], ah	; if (str_2[i] == '$')
		je .second_is_less		; second is less
		
		popf

		je .loop
		jmp .end

.first_is_less:	cmp 0, 1
		jmp .end
		
.second_is_less:cmp 1, 0
		jmp .end

.end:		MACRO_END
endm


;===============================================================================
; CODE

.code
org 100h

start:		
		

		ret
end start
