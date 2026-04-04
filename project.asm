INCLUDE Irvine32.inc
.586
.model flat, stdcall
.stack 4096
.data
    prompt      BYTE "Enter a string (max 16 chars to be safe): ", 0
    safe_msg    BYTE "Function returned safely. No corruption.", 0
    attack_msg  BYTE "CRITICAL ERROR: Stack corruption detected!", 0
    
    ; Input buffer for the user
    input_data  BYTE 100 DUP(0)
    input_count DWORD ?

.code
main PROC
    ; 1. Print Prompt
    mov edx, OFFSET prompt
    call WriteString

    ; 2. Read string from user
    mov edx, OFFSET input_data
    mov ecx, SIZEOF input_data
    call ReadString
    mov input_count, eax   ; Save number of chars read

    ; 3. Call the protected function
    push OFFSET input_data
    call ProtectedFunction
    ; Clean up stack (1 parameter = 4 bytes)
    add esp, 4

    ; 4. If we reached here, it was safe
    mov edx, OFFSET safe_msg
    call WriteString
    call Crlf

    exit
main ENDP

; =========================================================
; PROTECTED FUNCTION
; =========================================================
ProtectedFunction PROC
    push ebp
    mov ebp, esp
    push ebx              ; SAVE EBX

    ; Create Local Space:
    ; [ebp-4]  -> The Canary (4 bytes)
    ; [ebp-20] -> Local Buffer (16 bytes)
    sub esp, 20

    ; --- SETUP DYNAMIC CANARY ---
    ; Generate a runtime canary using time + register mixing

    rdtsc                  ; EDX:EAX = timestamp counter
    xor eax, edx           ; mix high + low bits
    xor eax, ebp           ; mix with stack base pointer
    xor eax, 0A5A5A5A5h    ; add constant for more randomness

    mov ebx, eax           ; save original canary in EBX (trusted copy)
    mov dword ptr [ebp-4], eax   ; store canary on stack

    ; --- VULNERABLE COPY ---
    ; We copy user input into the 16-byte local buffer.
    ; If user input > 16 bytes, it will overwrite the canary.
    mov esi, [ebp+8]        ; Source: address of input_data
    lea edi, [ebp-20]       ; Destination: local buffer

CopyLoop:
    mov al, [esi]
    mov [edi], al
    cmp al, 0               ; Stop at null terminator
    je EndCopy
    inc esi
    inc edi
    jmp CopyLoop

EndCopy:
    ; --- CANARY CHECK ---
    ; Check if our secret value is still 0ABCDEF0h
    mov eax, [ebp-4]   ; read canary from stack
    cmp eax, ebx           ; compare with original
    jne Corrupted           ; If it changed, someone overflowed!

    ; --- NORMAL EXIT ---
    pop ebx               ; RESTORE EBX
    mov esp, ebp
    pop ebp
    ret

Corrupted:
    pop ebx               ; RESTORE EBX before exit
    mov edx, OFFSET attack_msg
    call WriteString
    call Crlf
    exit                   ; Terminate program immediately
ProtectedFunction ENDP

END main