INCLUDE Irvine32.inc
.586

.data
    attack_msg BYTE "!!! SECURITY ALERT: DYNAMIC CANARY MISMATCH !!!", 0
    ret_msg    BYTE "!!! SECURITY ALERT: RETURN ADDRESS MODIFIED !!!", 0

.code
PUBLIC CreateDynamicCanary
PUBLIC ValidateCanary
PUBLIC ValidateReturnAddress
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

END