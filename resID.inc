include		windows.inc 
include		kernel32.inc 
include		user32.inc 
include     gdi32.inc  
include 	shell32.inc
include		winmm.inc
include		masm32.inc
include		msvcrt.inc
include		comctl32.inc
include		oleaut32.inc
include		ole32.inc
include		advapi32.inc
include		comdlg32.inc
include		msimg32.inc
include     /masm32/macros/macros.asm

includelib	kernel32.lib
includelib	user32.lib 
includelib 	gdi32.lib
includelib 	shell32.lib
includelib	winmm.lib
includelib 	masm32.lib
includelib	msvcrt.lib
includelib	comctl32.lib
includelib  oleaut32.lib
includelib  ole32.lib
includelib	advapi32.lib
includelib	comdlg32.lib
includelib 	msimg32.lib

include btnt.inc
include crc32.inc

include MagicV2mEngine.inc
includelib MagicV2mEngine.lib

DlgProc			PROTO	:DWORD,:DWORD,:DWORD,:DWORD

.const
IDD_MAIN	equ	1000
IDD_ABOUT	equ	2000
IDB_EXIT	equ	1001
IDB_ABOUT	equ	1002
IDC_NAME	equ	1003
IDC_SERIAL	equ	1004
IDB_PATCH	equ	1005

nHeight		equ	448
nWidth		equ	222

.data
include timeindex.inc
WindowTitle	db	"-=: PRF oWNZ dA wORLD ! :=-",0
r3kt			RECT	<>
TxtFont		LOGFONT <0FFFFFFF5h,0,0,0,2BCh,0,0,0,1,0,0,0,0,'verdana'>
;<12,8,0,0,FW_DONTCARE,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,0,'terminal'>
DELAY_VALUE			equ		6
Transparency		dd		?
TRANSPARENT_VALUE	equ 254
usrsize		dd  100h
Userbuff	db	100h dup(0)

Cpt1		db	"PERYFERiAH tEAM",0
Msg1		db	"Patch succeeded!",0
Wrongsize	db	"Wrong size.",0
Badcrc		db 	"Wrong crc checksum.",0
Filebusy	db	"You need to run this keygen as admin to patch PDM.",13
			db  "Or if the app is running in background, pls close it.",0
Notfound	db	"pdownloadmanager.exe not found.",0

TargetName	db "pdownloadmanager.exe",0
BackupName	db "pdownloadmanager.exe.BAK",0
TargetCRC32	dd 0FBD72481h
TargetSize	dd 2057304

WBuffer1	db 0E9h,00Bh,002h,000h,000h
RawOffset1	dd 001D83C0h
WBuffer2	db 0BEh,0C0h,010h,0ACh
RawOffset2	dd 001D85D0h
WBuffer3	db 0BFh,00Ch,07Ch,07Dh
RawOffset3	dd 001D85D5h
WBuffer4	db 0B9h,0A9h
RawOffset4	dd 001D85DAh
WBuffer5	db 026h,0F3h,0A4h,0C3h
RawOffset5	dd 001D85DFh
WBuffer6	db 035h,030h,038h,037h,036h,032h,033h,037h,038h,033h
RawOffset6	dd 001DD0C0h
WBuffer7	db 039h,038h,030h,030h,037h,034h
RawOffset7	dd 001DD0CAh
WBuffer8	db 038h,038h,039h,030h,038h,030h,032h,039h,039h,039h
RawOffset8	dd 001DD0D0h
WBuffer9	db 039h,034h,032h,033h,037h,030h
RawOffset9	dd 001DD0DAh
WBuffer10	db 031h,031h,038h,039h,036h,030h,037h,039h,038h,030h
RawOffset10	dd 001DD0E0h
WBuffer11	db 038h,035h,038h,035h,032h,035h
RawOffset11	dd 001DD0EAh
WBuffer12	db 034h,030h,038h,030h,039h,036h,036h,031h,032h,036h
RawOffset12	dd 001DD0F0h
WBuffer13	db 035h,034h,039h,030h,037h,038h
RawOffset13	dd 001DD0FAh
WBuffer14	db 034h,033h,034h,031h,034h,035h,030h,033h,036h,033h
RawOffset14	dd 001DD100h
WBuffer15	db 039h,036h,030h,032h,031h,031h
RawOffset15	dd 001DD10Ah
WBuffer16	db 039h,036h,036h,033h,039h,039h,030h,034h,034h,032h
RawOffset16	dd 001DD110h
WBuffer17	db 030h,034h,039h,036h,038h,034h
RawOffset17	dd 001DD11Ah
WBuffer18	db 039h,035h,036h,032h,035h,038h,031h,034h,032h,035h
RawOffset18	dd 001DD120h
WBuffer19	db 034h,033h,036h,036h,034h,034h
RawOffset19	dd 001DD12Ah
WBuffer20	db 031h,039h,038h,033h,038h,038h,032h,031h,039h,034h
RawOffset20	dd 001DD130h
WBuffer21	db 037h,039h,038h,032h,038h,034h
RawOffset21	dd 001DD13Ah
WBuffer22	db 035h,037h,037h,033h,038h,037h,034h,037h,037h,036h
RawOffset22	dd 001DD140h
WBuffer23	db 031h,038h,030h,033h,035h,038h
RawOffset23	dd 001DD14Ah
WBuffer24	db 034h,033h,039h,031h,038h,031h,038h,032h,030h,037h
RawOffset24	dd 001DD150h
WBuffer25	db 038h,038h,030h,030h,038h,030h
RawOffset25	dd 001DD15Ah
WBuffer26	db 030h,032h,034h,039h,031h,030h,038h,030h,031h
RawOffset26	dd 001DD160h

.data?
hInstance	dd	?
hFont			dd	?
hName			dd	?
hSerial			dd	?
hIMG			dd  ?
WndRect		RECT	<>
XndRect		RECT	<>
NameRect	RECT	<>
SerialRect	RECT	<>
hBrush		dd	?
PosX		dd  ?
PosY		dd  ?
xWnd		dd  ?
hTarget      HINSTANCE ?
BytesWritten db  ?