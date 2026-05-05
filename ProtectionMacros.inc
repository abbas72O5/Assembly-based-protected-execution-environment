; ============================================================================
; PROTECTION MACROS LIBRARY
; ============================================================================
; Runtime-safe macros that reuse the existing protection providers.
; These macros are designed to be included by multiple ASM modules.
; ============================================================================

; ---- Core canary macros (use SecurityProvider procedures) ----

INIT_CANARY MACRO canaryVar, frameSlot
    call CreateDynamicCanary
    mov canaryVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

VERIFY_CANARY MACRO frameSlot, canaryVar, failLabel
    mov eax, DWORD PTR frameSlot
    mov ebx, canaryVar
    call ValidateCanary
    cmp eax, 1
    jne failLabel
ENDM

; ---- Input guard initialization macros ----

INIT_RET_GUARD MACRO canaryVar, retVar, frameSlot
    mov eax, canaryVar
    xor eax, 0C3C3C3C3h
    mov retVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

INIT_FP_GUARD MACRO fpVar, frameSlot
    call CreateFunctionPointerGuard
    mov fpVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

INIT_SWITCH_GUARD MACRO switchVar, frameSlot
    call CreateSwitchGuard
    mov switchVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

INIT_FRAME_SIG_GUARD MACRO sigVar, frameSlot
    call CreateFrameSignature
    mov sigVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

; ---- Partial-overwrite aware validation macro ----

VALIDATE_GUARD_PARTIAL MACRO frameSlot, trustedVar, nextLabel, partialLabel, failLabel
    mov eax, DWORD PTR frameSlot
    mov ebx, trustedVar
    call ValidatePartialOverwrite
    cmp eax, 1
    je nextLabel
    cmp eax, 2
    je partialLabel
    jmp failLabel
ENDM

; ============================================================================
; END PROTECTION MACROS
; ============================================================================
