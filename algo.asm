include biglib.inc
includelib biglib.lib

include base64.asm

GenKey		PROTO	:DWORD
CheckName   PROTO   :DWORD,:DWORD,:DWORD

.data
ExpD db "1591C208F52FF24EE937A5D88B40B066FA835AFE99B7D7355E64535B8D098CCFA"
		db "7E494D7E05C1E28890C8DE8DDA7794B6893A4CA294A3405C960B933A226B56AE2"
		db "461F9ABBBD1",0
ExpN db "7797E6B4A44764CE046F7830626C1BABDFF7D2E13A900BC2EDCC782476AD2D037"
		db "57602C54E99A699EEED21AAD71B8133837BE2B941578135A5874522C66AF20A6B"
		db "46A923682D",0

ProgLabel	db "MD13",0
OneByte		db 01h,0 ; if i put 1 directly in this variable, then in OEE it'll show the license type behind the name buffer.
					 ; i just did what ev1l^4 [tPORt] did with these variables. :p
LicType		db "10000",0
StartKey	db "dqma",0
EndKey		db "amqd",0
CustomStr	db "PinkPajamasPenguinsOnTheBottom",0 ; can be any custom string after the strings shows in GenKey procedure,
								 ; doesn't have to be the expiration date as ev1l^4 did on the old OEE
NoName		db "insert ur name.",0
TooLong		db "name too long.",0
Blacklisted db "CANNOT GENERATE SERiAL :: NAME BLACKLiSTED",0
FinalBuffer db 256 dup(0)
NameBuffer	db 256 dup(0)
BlklistBuffer db 256 dup(0)

include blacklist.inc ; the blacklisted names were so many in this app O_o

.data?
_D			dd ?
_N			dd ?
Chipertxt	dd ?
Chipertxt2  dd ?
RSAEnk		db 256 dup(?)
Base64Bfr	db 256 dup(?)

.code
GenKey proc hWin:DWORD

	; get the whole name string.
	invoke GetDlgItemText,hWin,IDC_NAME,offset NameBuffer,sizeof NameBuffer
	or eax,eax
	jz no_name
	cmp eax,30
	jg name_too_long
	
	invoke lstrcpy,offset BlklistBuffer,offset NameBuffer
	invoke CheckName,offset BlklistBuffer,offset blk1,4500
	test eax,eax
	jz name_blacklisted

	; initialize the string for RSA-570 decryption
	mov byte ptr [RSAEnk],7
	invoke lstrcat,offset RSAEnk,offset ProgLabel	; MD13
	invoke lstrcat,offset RSAEnk,offset OneByte		; 01h
	invoke lstrcat,offset RSAEnk,offset NameBuffer	; ur name
	invoke lstrcat,offset RSAEnk,offset OneByte		; 01h
	invoke lstrcat,offset RSAEnk,offset LicType		; 10000 (Unlimited site license)
	invoke lstrcat,offset RSAEnk,offset OneByte		; 01h
	invoke lstrcat,offset RSAEnk,offset CustomStr	; any string :p
	invoke _BigCreate,0
	mov _D,eax
	invoke _BigCreate,0
	mov _N,eax
	invoke _BigCreate,0
	mov Chipertxt,eax
	invoke _BigCreate,0
	mov Chipertxt2,eax
	
	; decrypting string to 570 bits of RSA
	invoke _BigIn,offset ExpD,16,_D
	invoke _BigIn,offset ExpN,16,_N
	invoke lstrlen,offset RSAEnk
	invoke _BigInBytes,offset RSAEnk,eax,256,Chipertxt2
	invoke _BigPowMod,Chipertxt2,_N,_D,Chipertxt
	invoke _BigOutBytes,Chipertxt,256,offset RSAEnk
	
	; then encode them with base64
	push offset Base64Bfr
	push eax
	push offset RSAEnk
	call Base64Enk
	
	; "dqma" + final string made of RSA-570 & Base64 + "amqd"
	invoke lstrcat,offset FinalBuffer,offset StartKey
	invoke lstrcat,offset FinalBuffer,offset Base64Bfr
	invoke lstrcat,offset FinalBuffer,offset EndKey
	
	; final result in the textbox :p
	invoke SetDlgItemText,hWin,IDC_SERIAL,offset FinalBuffer
	
	; clear RSA buffers.
	call Clean
	ret
	
no_name:
    invoke SetDlgItemText,hWin,IDC_SERIAL,addr NoName
    ret
    
name_too_long:
    invoke SetDlgItemText,hWin,IDC_SERIAL,addr TooLong
    ret
    
name_blacklisted:
    invoke SetDlgItemText,hWin,IDC_SERIAL,addr Blacklisted
    ret 
	
GenKey endp

Clean proc

	invoke RtlZeroMemory,offset FinalBuffer,sizeof FinalBuffer
	invoke RtlZeroMemory,offset RSAEnk,sizeof RSAEnk
	invoke RtlZeroMemory,offset Base64Bfr,sizeof Base64Bfr
	invoke RtlZeroMemory,offset NameBuffer,sizeof NameBuffer
	invoke _BigDestroy,_D
	invoke _BigDestroy,_N
	invoke _BigDestroy,Chipertxt
	invoke _BigDestroy,Chipertxt2
	ret
	
Clean endp

CheckName proc str_1:LPCSTR,str_2:LPCSTR,bfrSize:DWORD

    push esi
    push edi
    push ebx
    mov edi, [str_1]
    mov esi, [str_2]
    mov ebx, [bfrSize]
    add ebx, esi

name_verif:             
    invoke lstrcmp,edi,esi
    test eax, eax
    jz final
    invoke lstrlen,esi
    inc eax
    add esi, eax
    cmp esi, ebx
    jl name_verif

final:
    pop ebx
    pop edi
    pop esi
    ret
    
CheckName endp