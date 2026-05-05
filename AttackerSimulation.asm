INCLUDE Irvine32.inc

AttackISR PROTO, attackCode:DWORD

.code
PUBLIC SimulateReturnHijack
PUBLIC HijackedControlTransfer

; SimulateReturnHijack
; Educational demo: a long payload represents a return-address overwrite in
; an unprotected frame and transfers control to attacker code.
; Input: pInput -> payload string
; Output: eax = 1 if hijack path executed, 0 otherwise
SimulateReturnHijack PROC USES ebx ecx edx esi edi, pInput:PTR BYTE
    LOCAL localFrame[16]:BYTE
    LOCAL inputLen:DWORD

    invoke Str_length, pInput
    mov inputLen, eax

    ; Simulate a vulnerable copy into a small local frame (bounded copy to keep
    ; the demo stable while still modeling overflow conditions).
    mov ecx, inputLen
    inc ecx
    cmp ecx, SIZEOF localFrame
    jbe CopyPayload
    mov ecx, SIZEOF localFrame

CopyPayload:
    mov esi, pInput
    lea edi, localFrame
    rep movsb

    ; Payloads longer than the local frame are treated as return-address
    ; corruption and redirect execution to attacker code.
    mov eax, inputLen
    cmp eax, SIZEOF localFrame
    jbe NoHijack
    jmp HijackedControlTransfer

NoHijack:
    xor eax, eax
    ret 4
SimulateReturnHijack ENDP

; This function stands in for attacker-controlled execution.
HijackedControlTransfer PROC
    invoke AttackISR, 11
    mov edx, OFFSET hijack_exec_msg
    call WriteString
    call Crlf
    mov eax, 1
    ret
HijackedControlTransfer ENDP

.data
    hijack_exec_msg BYTE "[ATTACK SIM] Return address hijacked: control transferred to attacker module.", 0

END