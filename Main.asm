INCLUDE Irvine32.inc

CheckInputNoProtection PROTO, pInput:PTR BYTE
CheckInputProtected    PROTO, pInput:PTR BYTE
AsciiToInt             PROTO, pInput:PTR BYTE
AddOperation           PROTO, a:SDWORD, b:SDWORD
SubOperation           PROTO, a:SDWORD, b:SDWORD
MulOperation           PROTO, a:SDWORD, b:SDWORD
DivOperation           PROTO, a:SDWORD, b:SDWORD

ParseArgs              PROTO
ExtractLastToken       PROTO, pDest:PTR BYTE, maxLen:DWORD

.data
    title_msg         BYTE "--- Protected Function Execution Environment ---", 0
    usage_msg         BYTE "Usage: SecureProject.exe <mode> <op> <a> <b>", 0
    usage2_msg        BYTE "mode: 1=normal, 2=protected | op: 1=add, 2=sub, 3=mul, 4=div", 0
    invalid_mode_msg  BYTE "ERROR: invalid mode.", 0
    invalid_op_msg    BYTE "ERROR: invalid operation.", 0
    invalid_args_msg  BYTE "ERROR: missing or malformed arguments.", 0
    div0_msg          BYTE "Division by zero is not allowed.", 0
    blocked_msg       BYTE "[PROTECTED MODE] Canary mismatch detected. Execution BLOCKED.", 0
    normal_warn_msg   BYTE "[NORMAL MODE] Overflow-like input detected, but execution continued.", 0
    result_msg        BYTE "Result = ", 0

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
    cmp eax, 4
    ja InvalidOperation

    mov overflow_flag, 0
    cmp selected_mode, 2
    jne NormalInputChecks

    invoke CheckInputProtected, ADDR inputA
    cmp eax, 1
    jne ProtectedBlocked
    invoke CheckInputProtected, ADDR inputB
    cmp eax, 1
    jne ProtectedBlocked
    jmp ConvertAndExecute

NormalInputChecks:
    invoke CheckInputNoProtection, ADDR inputA
    or overflow_flag, eax
    invoke CheckInputNoProtection, ADDR inputB
    or overflow_flag, eax

ConvertAndExecute:
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
    jmp DoDiv

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
    mov edx, OFFSET blocked_msg
    call WriteString
    call Crlf
    mov exit_code, 1
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