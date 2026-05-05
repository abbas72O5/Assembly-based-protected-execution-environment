INCLUDE Irvine32.inc
.586

.data
    attack_msg BYTE "!!! SECURITY ALERT: DYNAMIC CANARY MISMATCH !!!", 0
    ret_msg    BYTE "!!! SECURITY ALERT: RETURN ADDRESS MODIFIED !!!", 0

.code
PUBLIC CreateDynamicCanary
PUBLIC ValidateCanary
PUBLIC ValidateReturnAddress
PUBLIC CreateFunctionPointerGuard
PUBLIC CreateSwitchGuard
PUBLIC CreateFrameSignature
PUBLIC ValidatePartialOverwrite
;---------------------------------------------------------
; CreateDynamicCanary:
; Generates a unique value using CPU timestamp and EBP.
; Returns: EAX (the new canary)
;---------------------------------------------------------
CreateDynamicCanary PROC
    rdtsc                  ; EDX:EAX = timestamp counter
    xor eax, edx           ; mix high + low bits
    xor eax, 0A5A5A5A5h    ; add constant for more randomness
    ; We return the canary in EAX
    ret
CreateDynamicCanary ENDP

;---------------------------------------------------------
; ValidateCanary:
; Receives: EAX = Canary from the stack (potentially corrupted)
;           EBX = The original "Trusted" Canary
; Returns:  EAX = 1 if intact, 0 if corrupted
;---------------------------------------------------------
ValidateCanary PROC
    cmp eax, ebx
    jne CanaryMismatch
    mov eax, 1
    ret

CanaryMismatch:
    mov eax, 0
    ret
ValidateCanary ENDP

;---------------------------------------------------------
; ValidateReturnAddress:
; Receives: EAX = observed return marker from frame
;           EBX = expected safe return marker
; Returns:  EAX = 1 if unchanged, 0 if modified
;---------------------------------------------------------
ValidateReturnAddress PROC
    cmp eax, ebx
    jne ReturnMismatch
    mov eax, 1
    ret

ReturnMismatch:
    mov eax, 0
    ret
ValidateReturnAddress ENDP

;---------------------------------------------------------
; CreateFunctionPointerGuard:
; Produces a guard value for indirect-call / function-pointer integrity checks.
;---------------------------------------------------------
CreateFunctionPointerGuard PROC
    rdtsc
    xor eax, ebp
    rol eax, 7
    xor eax, 0F1E2D3Ch
    ret
CreateFunctionPointerGuard ENDP

;---------------------------------------------------------
; CreateSwitchGuard:
; Produces a guard value for switch-table / jump-target integrity checks.
;---------------------------------------------------------
CreateSwitchGuard PROC
    rdtsc
    xor eax, ebp
    ror eax, 5
    xor eax, 0C3D2E1F0h
    ret
CreateSwitchGuard ENDP

;---------------------------------------------------------
; CreateFrameSignature:
; Produces a stack-frame signature for local frame corruption detection.
;---------------------------------------------------------
CreateFrameSignature PROC
    rdtsc
    xor eax, esp
    xor eax, ebp
    add eax, 13579BDFh
    ret
CreateFrameSignature ENDP

;---------------------------------------------------------
; ValidatePartialOverwrite:
; Returns 1 if exact match, 2 if low-word partial overwrite is suspected, 0 otherwise.
;---------------------------------------------------------
ValidatePartialOverwrite PROC
    cmp eax, ebx
    je PartialOk

    mov ecx, eax
    xor ecx, ebx
    mov edx, ecx
    and edx, 0FFFF0000h
    jne PartialFail
    and ecx, 0000FFFFh
    cmp ecx, 0
    je PartialFail
    mov eax, 2
    ret

PartialFail:
    mov eax, 0
    ret

PartialOk:
    mov eax, 1
    ret
ValidatePartialOverwrite ENDP

END