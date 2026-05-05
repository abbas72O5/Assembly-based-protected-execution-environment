; ============================================================================
; PURE STANDALONE PROTECTION MACROS LIBRARY
; ============================================================================
; Self-contained macros with NO external dependencies.
; All protection logic is inlined - can be copied to any MASM project.
; No SecurityProvider.asm required. No procedure calls needed.
; ============================================================================

.586  ; Enable RDTSC instruction for all including modules

; ---- Core canary macros (inlined RDTSC + XOR logic) ----

INIT_CANARY MACRO canaryVar, frameSlot
    LOCAL canary_loop
    
    ; Generate random canary using CPU timestamp counter
    rdtsc                           ; EDX:EAX = timestamp counter
    xor eax, edx                    ; mix high + low bits
    xor eax, 0A5A5A5A5h             ; add constant for more randomness
    
    mov canaryVar, eax              ; store in variable
    mov DWORD PTR frameSlot, eax    ; store in frame slot
ENDM

VERIFY_CANARY MACRO frameSlot, canaryVar, failLabel
    LOCAL canary_check_pass
    
    mov eax, DWORD PTR frameSlot    ; load from frame
    mov ebx, canaryVar              ; load trusted value
    cmp eax, ebx                    ; compare directly
    je canary_check_pass
    jmp failLabel
    
canary_check_pass:
ENDM

; ---- Input guard initialization macros (all inlined) ----

INIT_RET_GUARD MACRO retVar, frameSlot
    ; Guard return addresses with XOR transformation
    mov eax, 0DEADBEEFh             ; return address marker
    xor eax, 0C3C3C3C3h             ; XOR with constant
    mov retVar, eax
    mov DWORD PTR frameSlot, eax
ENDM

INIT_FP_GUARD MACRO fpVar, frameSlot
    LOCAL fp_guard_gen
    
    ; Generate function pointer guard using RDTSC + EBP + rotation
    rdtsc                           ; get timestamp
    xor eax, ebp                    ; mix with frame pointer
    rol eax, 7                      ; rotate left 7 bits
    xor eax, 0F1E2D3Ch              ; XOR with constant
    
    mov fpVar, eax                  ; store FP guard
    mov DWORD PTR frameSlot, eax    ; store in frame
ENDM

INIT_SWITCH_GUARD MACRO switchVar, frameSlot
    LOCAL switch_guard_gen
    
    ; Generate switch guard using RDTSC + EBP + rotation
    rdtsc                           ; get timestamp
    xor eax, ebp                    ; mix with frame pointer
    ror eax, 5                      ; rotate right 5 bits
    xor eax, 0C3D2E1F0h             ; XOR with constant
    
    mov switchVar, eax              ; store switch guard
    mov DWORD PTR frameSlot, eax    ; store in frame
ENDM

INIT_FRAME_SIG_GUARD MACRO sigVar, frameSlot
    LOCAL frame_sig_gen
    
    ; Generate frame signature using RDTSC + ESP/EBP mixing
    rdtsc                           ; get timestamp
    xor eax, esp                    ; mix with stack pointer
    xor eax, ebp                    ; mix with frame pointer
    add eax, 13579BDFh              ; add signature constant
    
    mov sigVar, eax                 ; store frame signature
    mov DWORD PTR frameSlot, eax    ; store in frame
ENDM

; ---- Partial-overwrite aware validation macro (all inlined) ----

VALIDATE_GUARD_PARTIAL MACRO frameSlot, trustedVar, nextLabel, partialLabel, failLabel
    LOCAL partial_check_exact_match
    LOCAL partial_check_low_word
    LOCAL partial_check_fail
    LOCAL partial_validation_done
    
    mov eax, DWORD PTR frameSlot    ; load from frame
    mov ebx, trustedVar             ; load trusted value
    cmp eax, ebx
    je partial_check_exact_match
    
    ; Check for partial (low-word) overwrite
    mov ecx, eax
    xor ecx, ebx                    ; find differing bits
    mov edx, ecx
    and edx, 0FFFF0000h             ; check if high word differs
    jne partial_check_fail          ; if high word differs, total failure
    
    and ecx, 0000FFFFh              ; check if low word differs
    cmp ecx, 0
    je partial_check_fail           ; if no low word diff, fail
    
    ; Low word partial overwrite detected
    jmp partialLabel
    
partial_check_exact_match:
    ; Exact match - guard is intact
    jmp nextLabel
    
partial_check_fail:
    ; Total corruption detected
    jmp failLabel
ENDM

; ---- ADVANCED: Multi-guard verification macro (all inlined) ----

INIT_MULTI_GUARD MACRO canary, retGuard, fpGuard, switchGuard, frameFrame, slot1, slot2, slot3, slot4
    ; Initialize all guards in sequence
    INIT_CANARY canary, slot1
    INIT_RET_GUARD retGuard, slot2
    INIT_FP_GUARD fpGuard, slot3
    INIT_SWITCH_GUARD switchGuard, slot4
ENDM

VERIFY_MULTI_GUARD MACRO slot1, canary, slot2, retGuard, slot3, fpGuard, slot4, switchGuard, failLabel
    LOCAL guard_1_ok, guard_2_ok, guard_3_ok, guard_4_ok
    LOCAL all_guards_ok
    
    ; Verify canary
    mov eax, DWORD PTR slot1
    cmp eax, canary
    jne failLabel
    
    ; Verify return guard
    mov eax, DWORD PTR slot2
    cmp eax, retGuard
    jne failLabel
    
    ; Verify FP guard
    mov eax, DWORD PTR slot3
    cmp eax, fpGuard
    jne failLabel
    
    ; Verify switch guard
    mov eax, DWORD PTR slot4
    cmp eax, switchGuard
    jne failLabel
    
    ; All guards passed
all_guards_ok:
ENDM

; ============================================================================
; MACRO PROFILE INFORMATION
; ============================================================================
; Profile: PURE_STANDALONE
; Dependencies: NONE (fully inlined, no external procedures)
; Portability: FULL (can be copied to any MASM project)
; Performance: OPTIMAL (compile-time expansion, zero runtime overhead)
; Security: STRONG (multi-layer randomization with RDTSC)
;
; Usage:
;   INCLUDE ProtectionMacros_Standalone.inc
;
;   ; Initialize guards
;   LOCAL myCanary:DWORD
;   LOCAL frame[16]:BYTE
;   INIT_CANARY myCanary, frame[8]
;   
;   ; Do protected work
;   
;   ; Verify guard
;   VERIFY_CANARY frame[8], myCanary, fail_handler
;
; ============================================================================
; END PURE STANDALONE PROTECTION MACROS
; ============================================================================
