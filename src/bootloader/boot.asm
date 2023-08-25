org 0x7C00
bits 16


; A nasm macro to store both the line feed and carriage return characters for
; line ends:
%define ENDL 0x0D, 0x0A


start:
    jmp main


; Prints a string to the screen.
; Params:
;   -ds:si points to the string
puts:
    ; Save the registers' values before modifying them:
    push si
    push ax

.loop:
    lodsb               ; loads the next character into al.
    or al, al           ; if this caused the zero flag to be set, the next
                        ; character is null.
    jz .done            ; if so, jump to .done.

    ; Setting ah to 0x0E and calling the interrupt 0x10 will cause text to
    ; get printed to the screen in TTY mode:
    mov ah, 0x0E        ; call the BIOS interrupt
    mov bh, 0           ; setup page number
    int 0x10
    jmp .loop           ; move to the next character.

.done:
    ; Refetch the values of the modified registers:
    pop ax
    pop si
    ret

main:

    ; Setup data segments:
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; Setup the stack (The stack grows downwards, so setting it to where the program
    ; is loaded in memory would protect the program from getting overwritten):
    mov ss, ax
    mov sp, 0x7C00

    ; Print a message:
    mov si, hello_message
    call puts

    ; Just halt the execution:
    hlt


; In certain cases, the CPU might start executing again after halting. To prevent it
; from executing beyond the program, the following code will get the CPU stuck in an
; infinite loop:
.halt:
    jmp .halt

hello_message: db 'Snake OS!', ENDL, 0

; BIOS Signature: The BIOS expects that the last two bytes of the first sector are
; 0xAA55. The program is currently designed to be put on a standard 1.44MB Floppy
; disk, where a sector has 512 Bytes. NASM is asked here to emit bytes:
times 510-($-$$) db 0
dw 0AA55h
