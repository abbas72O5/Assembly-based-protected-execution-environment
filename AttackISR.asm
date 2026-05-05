INCLUDE Irvine32.inc
INCLUDE ProtectionMacros.inc

GENERIC_WRITE        EQU 40000000h
FILE_SHARE_READ      EQU 00000001h
OPEN_ALWAYS          EQU 4
CREATE_ALWAYS        EQU 2
FILE_ATTRIBUTE_NORMAL EQU 80h
FILE_END             EQU 2
INVALID_HANDLE_VALUE EQU 0FFFFFFFFh

.data
    attackLogFileName BYTE "attack_log.txt", 0
    attackPatternFileName BYTE "attack_pattern_stats.bin", 0
    logTemplate BYTE "[ATTACK] code=00 type=UNKNOWN                  date=0000-00-00 time=00:00:00", 13, 10, 0
    logBuffer  BYTE LENGTHOF logTemplate DUP(0)
    patternSnapshot DWORD 4 DUP(0) ; [0]=lastCode [1]=frequency [2]=consecutive [3]=cycleDetected

    typeUnknown BYTE "UNKNOWN", 0
    typeCanary BYTE "CANARY_MISMATCH", 0
    typeReturn BYTE "RETURN_MARKER_HIJACK", 0
    typeFunctionPointer BYTE "FUNCTION_POINTER_HIJACK", 0
    typeSwitchTarget BYTE "SWITCH_TARGET_HIJACK", 0
    typeFrame BYTE "STACK_FRAME_CORRUPTION", 0
    typePartial BYTE "PARTIAL_OVERWRITE", 0

.code
PUBLIC AttackISR
PUBLIC AttackISR

RecordAttackPattern PROTO, attackCode:DWORD
IsCycleDetected PROTO
GetAttackCounter PROTO, attackCode:DWORD
GetConsecutiveCount PROTO

TYPE_SLOT_OFFSET EQU 22
TYPE_SLOT_LENGTH EQU 24
CODE_OFFSET      EQU 14
YEAR_OFFSET      EQU 52
MONTH_OFFSET     EQU 57
DAY_OFFSET       EQU 60
HOUR_OFFSET      EQU 69
MINUTE_OFFSET    EQU 72
SECOND_OFFSET    EQU 75

Write2Digits PROC USES eax ebx edx, pDest:PTR BYTE, value:DWORD
    mov eax, value
    xor edx, edx
    mov ebx, 10
    div ebx
    add al, '0'
    add dl, '0'

    mov ebx, pDest
    mov [ebx], al
    mov [ebx+1], dl
    ret 8
Write2Digits ENDP

Write4Digits PROC USES eax ebx ecx edx edi, pDest:PTR BYTE, value:DWORD
    mov eax, value
    mov edi, pDest

    mov ebx, 1000
    xor edx, edx
    div ebx
    add al, '0'
    mov [edi], al

    mov eax, edx
    mov ebx, 100
    xor edx, edx
    div ebx
    add al, '0'
    mov [edi+1], al

    mov eax, edx
    mov ebx, 10
    xor edx, edx
    div ebx
    add al, '0'
    add dl, '0'
    mov [edi+2], al
    mov [edi+3], dl
    ret 8
Write4Digits ENDP

CopyTypeToSlot PROC USES eax ecx edx edi esi, pDest:PTR BYTE, slotLen:DWORD, pType:PTR BYTE
    mov edi, pDest
    mov ecx, slotLen
    mov al, ' '

FillSpaces:
    cmp ecx, 0
    je CopyType
    mov [edi], al
    inc edi
    dec ecx
    jmp FillSpaces

CopyType:
    mov edi, pDest
    mov esi, pType
    mov ecx, slotLen

CopyTypeLoop:
    cmp ecx, 0
    je CopyTypeDone
    mov dl, [esi]
    cmp dl, 0
    je CopyTypeDone
    mov [edi], dl
    inc edi
    inc esi
    dec ecx
    jmp CopyTypeLoop

CopyTypeDone:
    ret 12
CopyTypeToSlot ENDP

GetAttackType PROC USES edx, attackCode:DWORD
    mov eax, OFFSET typeUnknown

    mov edx, attackCode
    cmp edx, 10
    je IsCanary
    cmp edx, 11
    je IsReturn
    cmp edx, 12
    je IsFunctionPointer
    cmp edx, 13
    je IsSwitch
    cmp edx, 14
    je IsFrame
    cmp edx, 15
    je IsPartial
    ret 4

IsCanary:
    mov eax, OFFSET typeCanary
    ret 4

IsReturn:
    mov eax, OFFSET typeReturn
    ret 4

IsFunctionPointer:
    mov eax, OFFSET typeFunctionPointer
    ret 4

IsSwitch:
    mov eax, OFFSET typeSwitchTarget
    ret 4

IsFrame:
    mov eax, OFFSET typeFrame
    ret 4

IsPartial:
    mov eax, OFFSET typePartial
    ret 4
GetAttackType ENDP

AttackISR PROC USES eax ebx ecx edx esi edi, attackCode:DWORD
    LOCAL now:SYSTEMTIME
    LOCAL hFile:DWORD
    LOCAL bytesWritten:DWORD
    LOCAL patternCount:DWORD
    LOCAL patternConsecutive:DWORD
    LOCAL patternCycle:DWORD

    invoke GetLocalTime, ADDR now

    lea esi, logTemplate
    lea edi, logBuffer
    mov ecx, LENGTHOF logTemplate
    rep movsb

    invoke Write2Digits, ADDR logBuffer + CODE_OFFSET, attackCode
    invoke GetAttackType, attackCode
    invoke CopyTypeToSlot, ADDR logBuffer + TYPE_SLOT_OFFSET, TYPE_SLOT_LENGTH, eax

    movzx eax, now.wYear
    invoke Write4Digits, ADDR logBuffer + YEAR_OFFSET, eax
    movzx eax, now.wMonth
    invoke Write2Digits, ADDR logBuffer + MONTH_OFFSET, eax
    movzx eax, now.wDay
    invoke Write2Digits, ADDR logBuffer + DAY_OFFSET, eax
    movzx eax, now.wHour
    invoke Write2Digits, ADDR logBuffer + HOUR_OFFSET, eax
    movzx eax, now.wMinute
    invoke Write2Digits, ADDR logBuffer + MINUTE_OFFSET, eax
    movzx eax, now.wSecond
    invoke Write2Digits, ADDR logBuffer + SECOND_OFFSET, eax

    invoke CreateFileA,
        ADDR attackLogFileName,
        GENERIC_WRITE,
        FILE_SHARE_READ,
        0,
        OPEN_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
    mov hFile, eax
    cmp eax, INVALID_HANDLE_VALUE
    je AttackRecordedToTelemetry

    invoke SetFilePointer, hFile, 0, 0, FILE_END
    invoke WriteFile, hFile, ADDR logBuffer, LENGTHOF logTemplate-1, ADDR bytesWritten, 0
    invoke CloseHandle, hFile

AttackRecordedToTelemetry:
    ; Record attack in pattern engine and snapshot metrics for GUI.
    invoke RecordAttackPattern, attackCode

    invoke GetAttackCounter, attackCode
    mov patternCount, eax

    invoke GetConsecutiveCount
    mov patternConsecutive, eax

    invoke IsCycleDetected
    mov patternCycle, eax

    mov eax, attackCode
    mov DWORD PTR patternSnapshot[0], eax
    mov eax, patternCount
    mov DWORD PTR patternSnapshot[4], eax
    mov eax, patternConsecutive
    mov DWORD PTR patternSnapshot[8], eax
    mov eax, patternCycle
    mov DWORD PTR patternSnapshot[12], eax

    invoke CreateFileA,
        ADDR attackPatternFileName,
        GENERIC_WRITE,
        FILE_SHARE_READ,
        0,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
    mov hFile, eax
    cmp eax, INVALID_HANDLE_VALUE
    je AttackISREnd

    invoke WriteFile, hFile, ADDR patternSnapshot, 16, ADDR bytesWritten, 0
    invoke CloseHandle, hFile
    
AttackISREnd:
    ret 4
AttackISR ENDP

END
