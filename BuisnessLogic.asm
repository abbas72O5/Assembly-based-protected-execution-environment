INCLUDE Irvine32.inc

; External Prototypes
CreateDynamicCanary PROTO
ValidateCanary      PROTO

.code
PUBLIC CheckInputNoProtection
PUBLIC CheckInputProtected
PUBLIC AsciiToInt
PUBLIC AddOperation
PUBLIC SubOperation
PUBLIC MulOperation
PUBLIC DivOperation
; Also list the external functions this file needs
EXTERN CreateDynamicCanary:PROTO
EXTERN ValidateCanary:PROTO

MAX_SAFE_INPUT EQU 16

;---------------------------------------------------------
; CheckInputNoProtection:
; Returns EAX=1 if input length exceeds 16 (overflow-like), else 0.
;---------------------------------------------------------
CheckInputNoProtection PROC, pInput:PTR BYTE
    invoke Str_length, pInput
    cmp eax, MAX_SAFE_INPUT
    jbe NoOverflow
    mov eax, 1
    ret 4

NoOverflow:
    xor eax, eax
    ret 4
CheckInputNoProtection ENDP

;---------------------------------------------------------
; CheckInputProtected:
; Copies user input into a 16-byte local buffer with adjacent canary.
; Returns EAX=1 if canary intact, 0 if corrupted.
;---------------------------------------------------------
CheckInputProtected PROC USES ebx ecx esi edi, pInput:PTR BYTE
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD

    call CreateDynamicCanary
    mov trustedCanary, eax
    mov DWORD PTR frame[16], eax

    invoke Str_length, pInput
    mov ecx, eax
    inc ecx
    cmp ecx, 24
    jbe CopyProtected
    mov ecx, 24

CopyProtected:
    mov esi, pInput
    lea edi, frame
    rep movsb

    mov eax, DWORD PTR frame[16]
    mov ebx, trustedCanary
    call ValidateCanary
    ret 4
CheckInputProtected ENDP

;---------------------------------------------------------
; AsciiToInt:
; Converts optional-sign decimal string to signed integer.
;---------------------------------------------------------
AsciiToInt PROC USES ebx ecx edx esi, pInput:PTR BYTE
    mov esi, pInput
    xor eax, eax
    mov ebx, 1

    mov dl, [esi]
    cmp dl, '-'
    jne ParseDigits
    mov ebx, -1
    inc esi

ParseDigits:
    mov dl, [esi]
    cmp dl, 0
    je ApplySign
    cmp dl, '0'
    jb ApplySign
    cmp dl, '9'
    ja ApplySign

    imul eax, 10
    movzx ecx, dl
    sub ecx, '0'
    add eax, ecx
    inc esi
    jmp ParseDigits

ApplySign:
    cmp ebx, 1
    je DoneParse
    neg eax

DoneParse:
    ret 4
AsciiToInt ENDP

AddOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    add eax, b
    ret 8
AddOperation ENDP

SubOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    sub eax, b
    ret 8
SubOperation ENDP

MulOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    imul eax, b
    ret 8
MulOperation ENDP

DivOperation PROC USES ebx edx, a:SDWORD, b:SDWORD
    mov eax, a
    cdq
    mov ebx, b
    idiv ebx
    ret 8
DivOperation ENDP

END