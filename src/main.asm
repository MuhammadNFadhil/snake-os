org 0x7C00
bits 16


main:
    ; Just halt the execution:
    hlt

; In certain cases, the CPU might start executing again after halting. To prevent it
; from executing beyond the program, the following code will get the CPU stuck in an
; infinite loop:
.halt:
    jmp .halt

; BIOS Signature: The BIOS expects that the last two bytes of the first sector are
; 0xAA55. The program is currently designed to be put on a standard 1.44MB Floppy
; disk, where a sector has 512 Bytes. NASM is asked here to emit bytes:
times 510-($-$$) db 0
dw 0AA55h
