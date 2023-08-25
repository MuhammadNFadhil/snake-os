org 0x7C00
bits 16


; A nasm macro to store both the line feed and carriage return characters for
; line ends:
%define ENDL 0x0D, 0x0A

;
; FAT12 header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'               ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                     ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                     ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                        ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads_count:            dw 2
bdb_hidden_sector_count:    dd 0
bdb_large_sector_count:     dd 0

; Extended boot record
ebr_drive_number:           db 0                        ; 0x00 floppy, 0x80 hdd
                            db 0                        ; reserved byte
ebr_signiture:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h       ; serial number, doesn't matter
ebr_volume_label:           db 'SNAKE OS '              ; 11 bytes string padded by spaces
ebr_system_id:              db 'FAT12   '               ; 8 bytes


;
; Starting point of the actual code
;

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


;
; Disk routines
;

; Converts an LBA addres to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylender
;   - dh: head
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; reset dx
    div word [bdb_sectors_per_track]    ; ax = LBA / bdb_sectors_per_track
                                        ; dx = LBA % bdb_sectors_per_track
    inc dx                              ; dx = (LBA % bdb_sectors_per_track + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bdb_heads_count]          ; ax = (LBA / bdb_sectors_per_track) / Heads = cylender
                                        ; dx = (LBA / bdb_sectors_per_track) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylender (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits og cylender in CL

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


hello_message: db 'Snake OS!', ENDL, 0

; BIOS Signature: The BIOS expects that the last two bytes of the first sector are
; 0xAA55. The program is currently designed to be put on a standard 1.44MB Floppy
; disk, where a sector has 512 Bytes. NASM is asked here to emit bytes:
times 510-($-$$) db 0
dw 0AA55h
