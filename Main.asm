INCLUDE Irvine32.inc

CheckInputNoProtection PROTO, pInput:PTR BYTE
CheckInputProtected    PROTO, pInput:PTR BYTE
AsciiToInt             PROTO, pInput:PTR BYTE
AttackISR              PROTO, attackCode:DWORD
AddOperation           PROTO, a:SDWORD, b:SDWORD
SubOperation           PROTO, a:SDWORD, b:SDWORD
MulOperation           PROTO, a:SDWORD, b:SDWORD
DivOperation           PROTO, a:SDWORD, b:SDWORD
FactorialOperation     PROTO, a:SDWORD, b:SDWORD
FibonacciOperation     PROTO, a:SDWORD, b:SDWORD
ReverseNumberOperation PROTO, a:SDWORD, b:SDWORD
XorEncryptOperation    PROTO, a:SDWORD, b:SDWORD
XorDecryptOperation    PROTO, a:SDWORD, b:SDWORD
CaesarEncryptOperation PROTO, a:SDWORD, b:SDWORD
CaesarDecryptOperation PROTO, a:SDWORD, b:SDWORD
HashMixOperation       PROTO, a:SDWORD, b:SDWORD
ChecksumOperation      PROTO, a:SDWORD, b:SDWORD
SimulateReturnHijack   PROTO, pInput:PTR BYTE

ParseArgs              PROTO
ExtractLastToken       PROTO, pDest:PTR BYTE, maxLen:DWORD

.data
    title_msg         BYTE "--- Protected Function Execution Environment ---", 0
    usage_msg         BYTE "Usage: SecureProject.exe <mode> <op> <a> <b>", 0
    usage2_msg        BYTE "mode:1=normal,2=protected | op:1=add 2=sub 3=mul 4=div 5=xorE 6=xorD 7=caesarE 8=caesarD 9=hash 10=checksum 11=factorial 12=fibonacci 13=reverse 14=hijackDemo", 0
    invalid_mode_msg  BYTE "ERROR: invalid mode.", 0
    invalid_op_msg    BYTE "ERROR: invalid operation.", 0
    invalid_args_msg  BYTE "ERROR: missing or malformed arguments.", 0
    div0_msg          BYTE "Division by zero is not allowed.", 0
    blocked_msg       BYTE "[PROTECTED MODE] Canary mismatch detected. Execution BLOCKED.", 0
    hijack_msg        BYTE "[PROTECTED MODE] Control-hijack pattern detected (return marker mismatch). Execution BLOCKED.", 0
    fp_msg            BYTE "[PROTECTED MODE] Function-pointer integrity violation detected. Execution BLOCKED.", 0
    switch_msg        BYTE "[PROTECTED MODE] Switch/jump-target integrity violation detected. Execution BLOCKED.", 0
    frame_msg         BYTE "[PROTECTED MODE] Stack-frame corruption detected. Execution BLOCKED.", 0
    partial_msg       BYTE "[PROTECTED MODE] Partial overwrite attack pattern detected. Execution BLOCKED.", 0
    normal_warn_msg   BYTE "[NORMAL MODE] Overflow-like input detected, but execution continued.", 0
    result_msg        BYTE "Result = ", 0
    hijack_safe_msg   BYTE "[ATTACK SIM] No hijack triggered (payload stayed within local frame).", 0

    inputMode         BYTE 16 DUP(0)
    inputOp           BYTE 16 DUP(0)
    inputA            BYTE 128 DUP(0)
    inputB            BYTE 128 DUP(0)

    selected_mode     DWORD 0
    selected_op       DWORD 0
    valueA            SDWORD 0
    valueB            SDWORD 0
    overflow_flag     DWORD 0
    exit_code         DWORD 0

    parse_cursor      DWORD 0
    parse_end         DWORD 0
    parse_ok          DWORD 0

.code
main PROC
    mov exit_code, 0
    mov edx, OFFSET title_msg
    call WriteString
    call Crlf

    call ParseArgs
    cmp parse_ok, 1
    jne InvalidArgs

    invoke AsciiToInt, ADDR inputMode
    mov selected_mode, eax

    cmp eax, 1
    je ModeValid
    cmp eax, 2
    je ModeValid
    mov edx, OFFSET invalid_mode_msg
    call WriteString
    call Crlf
    jmp ShowUsage

ModeValid:
    invoke AsciiToInt, ADDR inputOp
    mov selected_op, eax

    cmp eax, 1
    jb InvalidOperation
    cmp eax, 14
    ja InvalidOperation

    mov overflow_flag, 0
    cmp selected_mode, 2
    jne NormalInputChecks

    invoke CheckInputProtected, ADDR inputA
    cmp eax, 1
    jne ProtectedBlockedByCode
    invoke CheckInputProtected, ADDR inputB
    cmp eax, 1
    jne ProtectedBlockedByCode
    jmp ConvertAndExecute

NormalInputChecks:
    invoke CheckInputNoProtection, ADDR inputA
    or overflow_flag, eax
    invoke CheckInputNoProtection, ADDR inputB
    or overflow_flag, eax

ConvertAndExecute:
    cmp selected_op, 14
    je DoHijackDemo

    invoke AsciiToInt, ADDR inputA
    mov valueA, eax
    invoke AsciiToInt, ADDR inputB
    mov valueB, eax

    mov eax, selected_op
    cmp eax, 1
    je DoAdd
    cmp eax, 2
    je DoSub
    cmp eax, 3
    je DoMul
    cmp eax, 4
    je DoDiv
    cmp eax, 5
    je DoXorEnc
    cmp eax, 6
    je DoXorDec
    cmp eax, 7
    je DoCaesarEnc
    cmp eax, 8
    je DoCaesarDec
    cmp eax, 9
    je DoHashMix
    cmp eax, 10
    je DoChecksum
    cmp eax, 11
    je DoFactorial
    cmp eax, 12
    je DoFibonacci
    cmp eax, 13
    je DoReverse
    jmp DoHijackDemo

DoAdd:
    invoke AddOperation, valueA, valueB
    jmp PrintResult

DoSub:
    invoke SubOperation, valueA, valueB
    jmp PrintResult

DoMul:
    invoke MulOperation, valueA, valueB
    jmp PrintResult

DoDiv:
    cmp valueB, 0
    je DivisionByZero
    invoke DivOperation, valueA, valueB
    jmp PrintResult

DoXorEnc:
    invoke XorEncryptOperation, valueA, valueB
    jmp PrintResult

DoXorDec:
    invoke XorDecryptOperation, valueA, valueB
    jmp PrintResult

DoCaesarEnc:
    invoke CaesarEncryptOperation, valueA, valueB
    jmp PrintResult

DoCaesarDec:
    invoke CaesarDecryptOperation, valueA, valueB
    jmp PrintResult

DoHashMix:
    invoke HashMixOperation, valueA, valueB
    jmp PrintResult

DoChecksum:
    invoke ChecksumOperation, valueA, valueB
    jmp PrintResult

DoFactorial:
    invoke FactorialOperation, valueA, valueB
    jmp PrintResult

DoFibonacci:
    invoke FibonacciOperation, valueA, valueB
    jmp PrintResult

DoReverse:
    invoke ReverseNumberOperation, valueA, valueB
    jmp PrintResult

DoHijackDemo:
    invoke SimulateReturnHijack, ADDR inputA
    cmp eax, 1
    je ProgramExit
    mov edx, OFFSET hijack_safe_msg
    call WriteString
    call Crlf
    jmp ProgramExit

DivisionByZero:
    mov edx, OFFSET div0_msg
    call WriteString
    call Crlf
    mov exit_code, 2
    jmp ProgramExit

PrintResult:
    mov edx, OFFSET result_msg
    call WriteString
    call WriteInt
    call Crlf

    cmp selected_mode, 1
    jne ProgramExit
    cmp overflow_flag, 1
    jne ProgramExit
    mov edx, OFFSET normal_warn_msg
    call WriteString
    call Crlf
    mov exit_code, 4
    jmp ProgramExit

ProtectedBlocked:
    invoke AttackISR, 10
    mov edx, OFFSET blocked_msg
    call WriteString
    call Crlf
    mov exit_code, 1
    jmp ProgramExit

ProtectedBlockedByCode:
    cmp eax, 11
    je ControlHijackBlocked
    cmp eax, 12
    je FunctionPointerBlocked
    cmp eax, 13
    je SwitchBlocked
    cmp eax, 14
    je FrameBlocked
    cmp eax, 15
    je PartialOverwriteBlocked
    jmp ProtectedBlocked

ControlHijackBlocked:
    invoke AttackISR, 11
    mov edx, OFFSET hijack_msg
    call WriteString
    call Crlf
    mov exit_code, 5
    jmp ProgramExit

FunctionPointerBlocked:
    invoke AttackISR, 12
    mov edx, OFFSET fp_msg
    call WriteString
    call Crlf
    mov exit_code, 6
    jmp ProgramExit

SwitchBlocked:
    invoke AttackISR, 13
    mov edx, OFFSET switch_msg
    call WriteString
    call Crlf
    mov exit_code, 7
    jmp ProgramExit

FrameBlocked:
    invoke AttackISR, 14
    mov edx, OFFSET frame_msg
    call WriteString
    call Crlf
    mov exit_code, 8
    jmp ProgramExit

PartialOverwriteBlocked:
    invoke AttackISR, 15
    mov edx, OFFSET partial_msg
    call WriteString
    call Crlf
    mov exit_code, 9
    jmp ProgramExit

InvalidOperation:
    mov edx, OFFSET invalid_op_msg
    call WriteString
    call Crlf
    mov exit_code, 3
    jmp ShowUsage

InvalidArgs:
    mov edx, OFFSET invalid_args_msg
    call WriteString
    call Crlf
    mov exit_code, 3

ShowUsage:
    mov edx, OFFSET usage_msg
    call WriteString
    call Crlf
    mov edx, OFFSET usage2_msg
    call WriteString
    call Crlf

ProgramExit:
    mov eax, exit_code
    invoke ExitProcess, eax
main ENDP

ParseArgs PROC USES eax edx esi
    mov parse_ok, 0

    call GetCommandTail
    mov parse_cursor, edx
    mov esi, edx

FindTailEnd:
    mov al, [esi]
    cmp al, 0
    je TailEndFound
    cmp al, 13
    je TailEndFound
    inc esi
    jmp FindTailEnd

TailEndFound:
    dec esi
    mov parse_end, esi

    invoke ExtractLastToken, ADDR inputB, LENGTHOF inputB
    cmp eax, 1
    jne ParseDone

    invoke ExtractLastToken, ADDR inputA, LENGTHOF inputA
    cmp eax, 1
    jne ParseDone

    invoke ExtractLastToken, ADDR inputOp, LENGTHOF inputOp
    cmp eax, 1
    jne ParseDone

    invoke ExtractLastToken, ADDR inputMode, LENGTHOF inputMode
    cmp eax, 1
    jne ParseDone

    mov parse_ok, 1

ParseDone:
    ret
ParseArgs ENDP

ExtractLastToken PROC USES ebx ecx edx esi edi, pDest:PTR BYTE, maxLen:DWORD
    mov eax, 0
    mov esi, parse_end

SkipRightSpaces:
    cmp esi, parse_cursor
    jb NoToken
    mov dl, [esi]
    cmp dl, ' '
    jne FoundTokenEnd
    dec esi
    jmp SkipRightSpaces

FoundTokenEnd:
    mov ebx, esi

FindTokenStart:
    cmp esi, parse_cursor
    jb TokenAtBegin
    mov dl, [esi]
    cmp dl, ' '
    je TokenStartFound
    dec esi
    jmp FindTokenStart

TokenAtBegin:
    mov esi, parse_cursor
    jmp CopyToken

TokenStartFound:
    inc esi

CopyToken:
    mov edx, esi
    mov edi, pDest
    mov ecx, maxLen
    dec ecx
    xor eax, eax

CopyLoop:
    cmp esi, ebx
    ja CopyDone
    mov al, [esi]
    cmp ecx, 0
    je SkipWrite
    mov [edi], al
    inc edi
    dec ecx
SkipWrite:
    inc esi
    jmp CopyLoop

CopyDone:
    mov BYTE PTR [edi], 0
    mov parse_end, edx
    dec parse_end
    mov eax, 1
    ret 8

NoToken:
    ret 8
ExtractLastToken ENDP

END main