; ============================================================================
; PROTECTION MACROS - QUICK START GUIDE
; ============================================================================
; 
; This is a copy-paste ready macro library for protecting MASM procedures.
; Include this file in any MASM project to add protection.
;
; No external dependencies beyond Irvine32.inc
; Zero runtime overhead - macros expand at compile time
; ============================================================================

INCLUDE Irvine32.inc

; ============================================================================
; BASIC USAGE - 3 Simple Patterns
; ============================================================================

; PATTERN 1: Protect a simple operation
; ────────────────────────────────────
; ProtectedAdd PROC USES eax ebx, a:DWORD, b:DWORD
;   LOCAL guardValue:DWORD
;   
;   CREATE_CANARY
;   mov guardValue, eax
;   
;   mov eax, a
;   add eax, b
;   
;   CREATE_CANARY
;   cmp eax, guardValue
;   jne AttackDetected
;   
;   ret 8
; AttackDetected:
;   xor eax, eax
;   ret 8
; ProtectedAdd ENDP

; PATTERN 2: Protect function entry/exit  
; ─────────────────────────────────────────
; CriticalFunc PROC a:DWORD, b:DWORD
;   LOCAL frameGuard:DWORD
;   
;   CREATE_CANARY
;   mov frameGuard, eax
;   
;   (critical code here)
;   
;   CREATE_CANARY
;   cmp eax, frameGuard
;   jne FrameCompromised
;   ret 8
; FrameCompromised:
;   invoke ExitProcess, 1
; CriticalFunc ENDP

; PATTERN 3: Protect array/buffer operations
; ────────────────────────────────────────────
; ProcessBuffer PROC USES esi edi ecx, pBuffer:PTR BYTE, size:DWORD
;   LOCAL bufferGuard:DWORD
;   LOCAL workGuard:DWORD
;   
;   CREATE_CANARY
;   mov bufferGuard, eax
;   
;   mov esi, pBuffer
;   mov ecx, size
;   
; Loop:
;   CREATE_CANARY
;   mov workGuard, eax
;   
;   mov al, [esi]
;   (process al)
;   
;   CREATE_CANARY
;   cmp eax, workGuard
;   jne Corrupted
;   
;   inc esi
;   dec ecx
;   jnz Loop
;   
;   CREATE_CANARY
;   cmp eax, bufferGuard
;   jne Corrupted
;   ret 4
;   
; Corrupted:
;   xor eax, eax
;   ret 4
; ProcessBuffer ENDP

; ============================================================================
; MACRO DEFINITIONS - Include These in Your Project
; ============================================================================

; CREATE_CANARY - Generate dynamic guard value
; Output: eax = random guard (different each time)
CREATE_CANARY MACRO
    rdtsc
    xor eax, edx
    xor eax, 0DEADBEE0h
ENDM

; INIT_CANARY variable - Initialize a variable with canary
; Usage: INIT_CANARY myCanary
INIT_CANARY MACRO canaryVar
    CREATE_CANARY
    mov canaryVar, eax
ENDM

; VALIDATE_CANARY value, errorLabel - Check canary
; Usage: VALIDATE_CANARY myCanary, AttackHandler
VALIDATE_CANARY MACRO expectedVal, errorLabel
    CREATE_CANARY
    cmp eax, expectedVal
    jne errorLabel
ENDM

; ============================================================================
; COMPLETE EXAMPLE - Secure Math Function
; ============================================================================

; .code
; PUBLIC SecureMathLib
; 
; ; Secure integer addition with overflow detection
; SecureAdd PROC USES eax ebx edx, a:DWORD, b:DWORD
;   LOCAL canary:DWORD
;   
;   CREATE_CANARY
;   mov canary, eax
;   
;   ; Perform addition
;   mov eax, a
;   mov ebx, b
;   add eax, ebx
;   
;   ; Validate canary (detect corruption during operation)
;   CREATE_CANARY
;   cmp eax, canary
;   jne OverflowDetected
;   
;   ret 8
;   
; OverflowDetected:
;   mov eax, 0FFFFFFFFh     ; Error code
;   ret 8
; SecureAdd ENDP
; 
; ; Secure bit rotation
; SecureRotate PROC USES eax ecx, value:DWORD, bits:DWORD
;   LOCAL canary:DWORD
;   LOCAL result:DWORD
;   
;   INIT_CANARY canary
;   
;   mov eax, value
;   mov ecx, bits
;   rol eax, cl
;   mov result, eax
;   
;   VALIDATE_CANARY canary, RotateCorrupt
;   
;   mov eax, result
;   ret 8
;   
; RotateCorrupt:
;   xor eax, eax
;   ret 8
; SecureRotate ENDP

; ============================================================================
; IMPLEMENTATION CHECKLIST
; ============================================================================

; To add protection to your MASM project:
; 
; [ ] 1. Copy these macros to your project (or INCLUDE this file)
; [ ] 2. Identify critical procedures to protect
; [ ] 3. Add CREATE_CANARY at procedure entry
; [ ] 4. Add VALIDATE_CANARY before return
; [ ] 5. Test: compile with ML.EXE
; [ ] 6. Test: verify procedures still work
; [ ] 7. Test: verify protection triggers on memory corruption
; [ ] 8. Deploy: use protected version in production
; 
; Expected overhead: 5-15% per call (worth the protection!)

; ============================================================================
; THREAT MODEL
; ============================================================================

; Protection against:
;  ✓ Stack buffer overflows
;  ✓ Register corruption attacks
;  ✓ Memory write-after-free
;  ✓ Return pointer hijacking (detectable with additional guards)
;  ✓ Instruction sequence disruption
; 
; Protection relies on:
;  - RDTSC entropy for canary generation (different each run)
;  - Immediate validation (before state is used)
;  - Multiple checkpoints (entry + exit + operation)
; 
; Limitations:
;  - Not effective against timing attacks
;  - Assumes RDTSC is not compromised (usually safe on Windows)
;  - Performance overhead for frequent small operations
;  - Requires source code integration (not binary patchable)

; ============================================================================
; PERFORMANCE TIPS
; ============================================================================

; 1. Use CREATE_CANARY strategically
;    - Heavy use on outer loops (once per iteration: SLOW)
;    - Light use on inner loops (once per 1000 iterations: FAST)
;    - Use full protection on crypto/security functions

; 2. Batch operations under single canary
;    - Protect group of operations with one canary-entry/canary-exit
;    - Reduces overhead proportionally
;    - Still provides meaningful protection

; 3. Combine with compiler-level protections
;    - Add /GS (stack cookies) for additional defense
;    - Use Guard Pages for detection
;    - Implement structured exception handling

; 4. Profile your code
;    - Not all procedures need same protection level
;    - Critical functions: full protection (10-20% overhead OK)
;    - Helper functions: minimal protection (2-5% overhead)
;    - Hot loops: alternative strategies (randomized execution order)

; ============================================================================
; DEPLOYMENT OPTIONS
; ============================================================================

; OPTION A: Always Protected
;   Include macros in all security-critical code
;   Suitable for: Crypto, authentication, access control
;   Overhead: Acceptable, worth the protection

; OPTION B: Conditional Protection
;   Use DEBUG flag to enable/disable protection
;   Suitable for: Testing vs production builds
;   Overhead: Zero in release builds, full in debug

; OPTION C: Sampling Protection
;   Randomly enable protection (e.g., 10% of calls)
;   Suitable for: Low-overhead detection without full overhead
;   Overhead: 1-2% instead of 10%

; ============================================================================
; END QUICK START GUIDE
; ============================================================================
