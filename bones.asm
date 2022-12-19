.686
.model	flat, stdcall
option	casemap :none

USE_BMP = 1

include	resID.inc
include BoxProc.asm
include algo.asm
include aboutbox.asm

AllowSingleInstance MACRO lpTitle
        invoke FindWindow,NULL,lpTitle
        cmp eax, 0
        je @F
          push eax
          invoke ShowWindow,eax,SW_RESTORE
          pop eax
          invoke SetForegroundWindow,eax
          mov eax, 0
          ret
        @@:
ENDM

patch MACRO offsetAdr,_bytes,_byteSize
 invoke SetFilePointer,hTarget,offsetAdr,NULL,FILE_BEGIN
   .if eax==0FFFFFFFFh
     invoke CloseHandle,hTarget
     invoke MessageBox,hDlg,addr Filebusy,addr Cpt1,MB_OK OR MB_ICONERROR
     ret
.endif
 invoke WriteFile,hTarget,addr _bytes,_byteSize,addr BytesWritten,FALSE
ENDM

.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	InitCommonControls
	invoke LoadBitmap,hInstance,400
	mov hIMG,eax
	invoke CreatePatternBrush,eax
	mov hBrush,eax
	AllowSingleInstance addr WindowTitle
	invoke	DialogBoxParam, hInstance, IDD_MAIN, 0, offset DlgProc, 0
	invoke	ExitProcess, eax

DlgProc proc hDlg:HWND,uMessg:UINT,wParams:WPARAM,lParam:LPARAM
LOCAL ps:PAINTSTRUCT
LOCAL ff32:WIN32_FIND_DATA
LOCAL pFileMem:DWORD

	.if [uMessg] == WM_INITDIALOG
 
 		push hDlg
 		pop xWnd               
		invoke GetSystemMetrics,0                
		sub eax, nHeight
		shr eax, 1
		mov PosX, eax
		invoke GetSystemMetrics,1               
		sub eax, nWidth
		shr eax, 1
		mov PosY, eax
		invoke SetWindowPos,xWnd,0,PosX,PosY,nHeight,nWidth,40h
            	
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, xWnd, WM_SETICON, 1, eax
		invoke  SetWindowText,xWnd,addr WindowTitle
		
		invoke  MAGICV2MENGINE_DllMain,hInstance,DLL_PROCESS_ATTACH,0
		invoke 	V2mPlayStream, addr v2m_Data,TRUE
		invoke  V2mSetAutoRepeat,1
		
		invoke  SkrBoxInit,xWnd
		invoke  GetUserName,offset Userbuff,offset usrsize
		invoke  SetDlgItemText,xWnd,IDC_NAME,offset Userbuff
		invoke 	SendDlgItemMessage, xWnd, IDC_NAME, EM_SETLIMITTEXT, 31, 0
		invoke CreateFontIndirect,addr TxtFont
		mov hFont,eax
		invoke GetDlgItem,xWnd,IDC_NAME
		mov hName,eax
		invoke SendMessage,eax,WM_SETFONT,hFont,1
		invoke GetDlgItem,xWnd,IDC_SERIAL
		mov hSerial,eax
		invoke SendMessage,eax,WM_SETFONT,hFont,1
		
		invoke ImageButton,xWnd,23,186,500,502,501,IDB_PATCH
		mov hPatch,eax
		invoke ImageButton,xWnd,164,186,600,602,601,IDB_ABOUT
		mov hAbout,eax
		invoke ImageButton,xWnd,305,186,700,702,701,IDB_EXIT
		mov hExit,eax
		
		invoke GenKey,xWnd
		
		call InitCRC32Table
		
	.elseif [uMessg] == WM_LBUTTONDOWN

		invoke SendMessage, xWnd, WM_NCLBUTTONDOWN, HTCAPTION, 0

	.elseif [uMessg] == WM_CTLCOLORDLG

		return hBrush

	.elseif [uMessg] == WM_PAINT
                
		invoke BeginPaint,xWnd,addr ps
		mov edi,eax
		lea ebx,r3kt
		assume ebx:ptr RECT
                
		invoke GetClientRect,xWnd,ebx
		invoke CreateSolidBrush,00FF00CCh
		invoke FrameRect,edi,ebx,eax
		invoke EndPaint,xWnd,addr ps                   
     
    .elseif [uMessg] == WM_CTLCOLOREDIT
    
		invoke SetBkMode,wParams,TRANSPARENT
		invoke SetTextColor,wParams,White
		invoke GetWindowRect,xWnd,addr WndRect
		invoke GetDlgItem,xWnd,IDC_NAME
		invoke GetWindowRect,eax,addr NameRect
		mov edi,WndRect.left
		mov esi,NameRect.left
		sub edi,esi
		mov ebx,WndRect.top
		mov edx,NameRect.top
		sub ebx,edx
		invoke SetBrushOrgEx,wParams,edi,ebx,0
		mov eax,hBrush
		ret        
	
	.elseif [uMessg] == WM_CTLCOLORSTATIC
	
		invoke SetBkMode,wParams,TRANSPARENT
		invoke SetTextColor,wParams,White
		invoke GetWindowRect,xWnd,addr XndRect
		invoke GetDlgItem,xWnd,IDC_SERIAL
		invoke GetWindowRect,eax,addr SerialRect
		mov edi,XndRect.left
		mov esi,SerialRect.left
		sub edi,esi
		mov ebx,XndRect.top
		mov edx,SerialRect.top
		sub ebx,edx
		invoke SetBrushOrgEx,wParams,edi,ebx,0
		mov eax,hBrush
		ret
	.elseif [uMessg] == WM_COMMAND
        
		mov eax,wParams
		mov edx,eax
		shr edx,16
		and eax,0ffffh
		.if edx == EN_CHANGE
			.if eax == IDC_NAME
				invoke GenKey,xWnd
			.endif
		.endif
		.if	eax==IDB_PATCH
			invoke FindFirstFile,ADDR TargetName,ADDR ff32
	        .if eax == INVALID_HANDLE_VALUE
	           invoke MessageBox,xWnd,addr Notfound,addr Cpt1,MB_OK OR MB_ICONERROR
	        .else
	        mov eax,TargetSize
	            ; File size is incorrect
	            .if ff32.nFileSizeLow != eax
	                invoke MessageBox,xWnd,addr Wrongsize,addr Cpt1,MB_OK OR MB_ICONERROR
	            ; Filesize is correct
	            .else
	            mov pFileMem,InputFile(ADDR TargetName)
	            invoke CRC32,pFileMem,ff32.nFileSizeLow
	            mov edx,TargetCRC32
	            ; Calculated CRC32 does not match
	            .if eax != edx
	               invoke MessageBox,xWnd,addr Badcrc,addr Cpt1,MB_OK OR MB_ICONERROR
	            .else
	            invoke GetFileAttributes,addr TargetName
	            ; The file is read-only, so let's try to set it to read/write
	                .if eax!=FILE_ATTRIBUTE_NORMAL
	                    invoke SetFileAttributes,addr TargetName,FILE_ATTRIBUTE_NORMAL
	                .endif
	              ; Everything's okay, so let's patch the file
	              invoke CreateFile,addr TargetName,GENERIC_READ+GENERIC_WRITE,FILE_SHARE_READ+FILE_SHARE_WRITE,\
	                                                NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	             .if eax!=INVALID_HANDLE_VALUE
	                    mov hTarget,eax
	            invoke CopyFile, addr TargetName, addr BackupName, TRUE
	     		   .endif
	        ; Start patches to the file
	        patch RawOffset1,WBuffer1,5
	        patch RawOffset2,WBuffer2,4
	        patch RawOffset3,WBuffer3,4
	        patch RawOffset4,WBuffer4,2
	        patch RawOffset5,WBuffer5,4
	        patch RawOffset6,WBuffer6,10
	        patch RawOffset7,WBuffer7,6
	        patch RawOffset8,WBuffer8,10
	        patch RawOffset9,WBuffer9,6
	        patch RawOffset10,WBuffer10,10
	        patch RawOffset11,WBuffer11,6
	        patch RawOffset12,WBuffer12,10
	        patch RawOffset13,WBuffer13,6
	        patch RawOffset14,WBuffer14,10
	        patch RawOffset15,WBuffer15,6
	        patch RawOffset16,WBuffer16,10
	        patch RawOffset17,WBuffer17,6
	        patch RawOffset18,WBuffer18,10
	        patch RawOffset19,WBuffer19,6
	        patch RawOffset20,WBuffer20,10
	        patch RawOffset21,WBuffer21,6
	        patch RawOffset22,WBuffer22,10
	        patch RawOffset23,WBuffer23,6
	        patch RawOffset24,WBuffer24,10
	        patch RawOffset25,WBuffer25,6
	        patch RawOffset26,WBuffer26,9
	        invoke CloseHandle,hTarget
	        invoke MessageBox,xWnd,addr Msg1,addr Cpt1,MB_OK OR MB_ICONINFORMATION
	        invoke GetDlgItem,xWnd,IDB_PATCH
	        invoke EnableWindow, eax, FALSE
	        .endif
	        .endif
	    .endif
		.elseif eax == IDB_ABOUT
			invoke SuspendThread,BoxThread
	    	invoke ShowWindow,xWnd,0
	    	invoke DialogBoxParam,0,IDD_ABOUT,0,offset AboutProc,0
		.elseif eax == IDB_EXIT
			invoke SendMessage,xWnd,WM_CLOSE,0,0
		.endif 
             
	.elseif [uMessg] == WM_CLOSE
		invoke V2mStop
  		invoke MAGICV2MENGINE_DllMain,hInstance,DLL_PROCESS_DETACH,0 
		call CleanEf
		invoke EndDialog,xWnd,0     
	.endif
         xor eax,eax
         ret
DlgProc endp

end start