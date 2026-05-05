INCLUDE Irvine32.inc
INCLUDE ProtectionMacros_Standalone.inc
.586

.code
PUBLIC CheckInputNoProtection
PUBLIC CheckInputProtected
PUBLIC AsciiToInt

MAX_SAFE_INPUT EQU 16
MAX_PROTECTED_COPY EQU 40

; Returns EAX=1 if input length exceeds 16, else 0.
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

; Returns EAX=1 when protected frame is intact.
; Returns EAX=10 on canary mismatch.
; Returns EAX=11 on return-marker mismatch.
; Returns EAX=12 on function-pointer guard mismatch.
; Returns EAX=13 on switch-target guard mismatch.
; Returns EAX=14 on frame-signature mismatch.
; Returns EAX=15 on partial-overwrite pattern.
CheckInputProtected PROC USES ebx ecx esi edi, pInput:PTR BYTE
    LOCAL frame[40]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL trustedRetMarker:DWORD
    LOCAL trustedFpGuard:DWORD
    LOCAL trustedSwitchGuard:DWORD
    LOCAL trustedFrameSig:DWORD

    INIT_CANARY trustedCanary, frame[16]
    INIT_RET_GUARD trustedRetMarker, frame[20]
    INIT_FP_GUARD trustedFpGuard, frame[24]
    INIT_SWITCH_GUARD trustedSwitchGuard, frame[28]
    INIT_FRAME_SIG_GUARD trustedFrameSig, frame[32]

    invoke Str_length, pInput
    mov ecx, eax
    inc ecx
    cmp ecx, MAX_PROTECTED_COPY
    jbe CopyProtected
    mov ecx, MAX_PROTECTED_COPY

CopyProtected:
    mov esi, pInput
    lea edi, frame
    rep movsb

    VALIDATE_GUARD_PARTIAL frame[16], trustedCanary, ReturnMarkerCheck, PartialOverwriteCompromised, CanaryCompromised

ReturnMarkerCheck:
    VALIDATE_GUARD_PARTIAL frame[20], trustedRetMarker, FunctionPointerCheck, PartialOverwriteCompromised, ReturnMarkerCompromised

FunctionPointerCheck:
    VALIDATE_GUARD_PARTIAL frame[24], trustedFpGuard, SwitchTargetCheck, PartialOverwriteCompromised, FunctionPointerCompromised

SwitchTargetCheck:
    VALIDATE_GUARD_PARTIAL frame[28], trustedSwitchGuard, FrameSignatureCheck, PartialOverwriteCompromised, SwitchTargetCompromised

FrameSignatureCheck:
    VALIDATE_GUARD_PARTIAL frame[32], trustedFrameSig, FrameIntact, PartialOverwriteCompromised, FrameSignatureCompromised

FrameIntact:
    mov eax, 1
    ret 4

CanaryCompromised:
    mov eax, 10
    ret 4

PartialOverwriteCompromised:
    mov eax, 15
    ret 4

ReturnMarkerCompromised:
    mov eax, 11
    ret 4

FunctionPointerCompromised:
    mov eax, 12
    ret 4

SwitchTargetCompromised:
    mov eax, 13
    ret 4

FrameSignatureCompromised:
    mov eax, 14
    ret 4

CheckInputProtected ENDP

; Converts optional-sign decimal string to signed integer.
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

END
