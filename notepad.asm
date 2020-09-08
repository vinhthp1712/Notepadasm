
extern GetModuleHandleA
extern GetCommandLineA
extern ExitProcess
extern MessageBoxA
extern LoadIconA
extern LoadCursorA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern UpdateWindow
extern GetMessageA
extern TranslateMessage
extern DispatchMessageA
extern PostQuitMessage
extern DefWindowProcA
extern GetClientRect
extern SetWindowPos
extern GetStockObject
extern SendMessageA
extern SetMenu
extern AppendMenuA
extern CreateMenu
extern GetDlgItem
extern SendMessageA
extern GetOpenFileNameA
extern CreateFileA
extern GetFileSize
extern GlobalAlloc
extern GlobalFree
extern ReadFile
extern SetWindowTextA
extern CloseHandle
extern GetOpenFileNameA
extern RtlZeroMemory
extern SetDlgItemTextA
extern CommDlgExtendedError
extern GetWindowTextLengthA
extern GetWindowTextA 
extern WriteFile
extern GetSaveFileNameA

;; Import the Win32 API functions.
import GetModuleHandleA kernel32.dll
import GetCommandLineA kernel32.dll
import ExitProcess kernel32.dll
import MessageBoxA user32.dll
import LoadIconA user32.dll
import LoadCursorA user32.dll
import RegisterClassExA user32.dll
import CreateWindowExA user32.dll
import ShowWindow user32.dll
import UpdateWindow user32.dll
import GetMessageA user32.dll
import TranslateMessage user32.dll
import DispatchMessageA user32.dll
import PostQuitMessage user32.dll
import DefWindowProcA user32.dll
import GetClientRect user32.dll
import SetWindowPos user32.dll
import GetStockObject gdi32.dll
import SendMessageA user32.dll
import AppendMenuA user32.dll
import SetMenu user32.dll
import CreateMenu user32.dll
import GetDlgItem user32.dll
import SendMessageA user32.dll
import GetOpenFileNameA comdlg32.dll
import CreateFileA kernel32.dll
import GetFileSize kernel32.dll
import GlobalAlloc kernel32.dll
import GlobalFree kernel32.dll
import ReadFile kernel32.dll
import SetWindowTextA user32.dll
import CloseHandle kernel32.dll
import GetOpenFileNameA comdlg32.dll
import RtlZeroMemory kernel32.dll
import SetDlgItemTextA user32.dll
import CommDlgExtendedError comdlg32.dll
import GetWindowTextLengthA user32.dll
import GetWindowTextA  user32.dll
import WriteFile kernel32.dll
import GetSaveFileNameA comdlg32.dll


section .text use32

..start:

push dword 0
call [GetModuleHandleA]
mov dword [hInstance], eax
call [GetCommandLineA]
mov dword [CommandLine], eax
;; Now we call our WindowMain() function.
;; The parameters to pass are:  hInstance, 0, CommandLine, SW_SHOWDEFAULT
;; SW_<something> is a Windows constant for how to show a window.
;; If we look into windows.h or windows.inc, we'll find that
;; SW_SHOWDEFAULT is defined as 10, so we'll pass that as the last argument.
push dword 10
;; Now the CommandLine variable.
push dword [CommandLine]          ;; The brackets tell NASM to use a memory access, and not a memory address.
;; And a NULL (NULL is equal to 0).
push dword 0
;; Then the hInstance variable.
push dword [hInstance]            ;; Once again, we don't want the pointer to hInstance, we want the actual value.
;; And we make a call to WindowMain().
call WindowMain

;; Then we exit the program, returning EAX, which is what WindowMain() will return.
push eax
call [ExitProcess]

;; This is now the WindowMain() function.
;; We will want to reserve enough stack space for a WNDCLASSEX structure so
;; we can make a class for our window, a MSG structure so we can receive messages
;; from our window when some event happens, and an HWND, which is just a
;; double-word that's used for storing the handle to our window.
WindowMain:

    ;;WNDClASSEX [ebp-48]
    ;;MSG[ebp-48-24]
    ;;HWND [ebp-48-24-4]
    ;;enter 76, 0
    push ebp
    mov ebp,esp
    sub esp,76
    ;;WNDCLASSEX
    lea ebx, [ebp-48]        
    mov dword [ebx+00], 48 ;StructSize      .
    mov dword [ebx+04], 3     ;;Window Style
    mov dword [ebx+08], WindowProcedure      
    mov dword [ebx+12], 0       ;cbClsExtra
    mov dword [ebx+16], 0       ;cbWndExtra

    mov eax, dword [ebp+8]      ;;1st parameter in winmain hInstance
    mov dword [ebx+20], eax     ;hInstance

    mov dword [ebx+32], 5 + 1 ;;Background burhs Color_Window+1
    mov dword [ebx+36], 0  ;;Menu Name
    mov dword [ebx+40], ClassName        

    push dword 32512 ;;IDI_APPLICATION
    push dword 0
    call [LoadIconA]

    mov dword [ebx+24], eax    ;;handle icon window
    mov dword [ebx+44], eax    ;;handle small icon

    push dword 32512 ;;IDC_ARROW 
    push dword 0
    call [LoadCursorA]

    mov dword [ebx+28], eax    ;;handle cursor

    push ebx
    call [RegisterClassExA]

    ;; CreateWindowEx(0, ClassName, window title, WS_OVERLAPPEDWINDOW, x, y, width, height, handle to parent window, handle to menu, hInstance, NULL);
    push dword 0 ;;lParam
    push dword [ebp+8] ;;hInstance
    push dword 0 ;;hMenu
    push dword 0 ;;hwndParent
    push dword 700              ;; 400 pixels high.
    push dword 1000             ;; 500 pixels wide.
    push dword 0x80000000       ;; CW_USEDEFAULT Y
    push dword 0x80000000       ;; CW_USEDEFAULT X
    push dword 0x00 | 0xC00000 | 0x80000 | 0x40000 | 0x20000 | 0x10000    ;; WS_OVERLAPPEDWINDOW //dwStyle
                                ;; WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
    push dword ApplicationName
    push dword ClassName
    push dword 0 ;;dwExStyle
    call [CreateWindowExA]

    mov dword [ebp-76], eax


    sub eax, 0                  
    jz .new_window_failed

    ;; ShowWindow([ebp-76], [ebp+20])
    push dword [ebp+20]
    push dword [ebp-76]
    call [ShowWindow]

    .MessageLoop:
        ;; GetMessage(the MSG structure, 0, 0, 0)
        push dword 0 ;wMsgFilterMax
        push dword 0 ;wMsgFilterMin
        push dword 0;hwnd
        lea ebx, [ebp-72] ;MSG struct
        push ebx
        call [GetMessageA]
        ;; If GetMessage() returns 0, it's time to exit.
        cmp eax, 0
        jz .MessageLoopExit

        ;; TranslateMessage(the MSG)
        lea ebx, [ebp-72]
        push ebx
        call [TranslateMessage]

        ;; DispatchMessage(the MSG)
        lea ebx, [ebp-72]
        push ebx
        call [DispatchMessageA]

        ;; And start the loop over again.
        jmp .MessageLoop
    .MessageLoopExit:

    jmp .finish

    .new_window_failed:
        push dword 0
        push dword 0
        push dword err_msg
        push dword 0
        call [MessageBoxA]

        ;; Exit, returning 1.
        mov eax, 1
        mov esp,ebp
	pop ebp
        ret 16
    .finish:

    ;; return the MSG.wParam value.
    lea ebx, [ebp-72]
    mov eax, dword [ebx+08]

    ;; It's time to leave.
    mov esp,ebp
    pop ebp

ret 16

;;    hWnd             The handle to the window that sent us that event.
;;                     This would be the handle to the window that uses
;;                     our window class.
;;    uMsg             This is the message that the window sent us. It
;;                     describes the event that has happened.
;;    wParam           This is a parameter that goes along with the
;;                     event message.
;;    lParam           This is an additional parameter for the message.

WindowProcedure:
    ;;Rect [ebp-16]
    ;;enter 16, 0
    push ebp
    mov ebp,esp
    sub esp,16
    ;; We need to retrieve the uMsg value.
    mov eax, dword [ebp+12]           ;; We get the value of the second argument.

    ;; Now here comes the new instruction. We need to compare the value we just
    ;; retrieved to WM_DESTROY to see if the message is a WM_DESTROY message.
    ;; If so, we'll jump to the .window_destroy label.
    cmp eax, 2                      ;; Compare EAX to WM_DESTROY, which is equal to 2.
    jz .window_destroy               ;; If it's equal to what we compared it to, jump to
                                    ;; the .window_destroy label.
    ;; If the processor doesn't jump to the .window_destroy label, it means that
    ;; the result of the comparison is not equal. In that case, the message
    ;; must be something else.
    ;; In cases like this we can either take care of the message right now, or
    ;; we can jump to another location in the code that would take care of the
    ;; message.
    ;; We'll just jump to the window_default label.
    
    cmp eax,1 ;;Compare MSG with WM_CREATE
    jz .window_create
    cmp eax,5 ;;Compare MSG with WM_SIZE
    jz .window_size
    cmp eax, 273 ;;Compare MSG with WM_COMMAND
    jz .window_command
    jmp .window_default

    .window_destroy:

        push dword 0
        call [PostQuitMessage]
        jmp .window_finish
	
    .window_create:
        ;; CreateWindowEx(0, ClassName, window title, WS_OVERLAPPEDWINDOW, x, y, width, height, handle to parent window, handle to menu, hInstance, NULL);
        push dword 0 ;;lParam
        push dword 0 ;;hInstance
        push dword 101 ;;IDC_MAIN_EDIT edit control ID
        push dword [ebp+08] ;;hwnd Parent
        push dword 400 
        push dword 120
        push dword 100
        push dword 100
        push dword 0x40000000 | 0x10000000 | 0x200000 | 0x00000000 | 0x00000004 | 0x00000040 ;;WS_OVERLAPPEDWINDOW
        push dword 0
        push dword ClassNameEdit 
        push dword 0
        call [CreateWindowExA]
        mov [hEdit],eax
	
	;;GetClientRect
	;;RECt(left,top,right,bottom)
	xor ebx,ebx
	lea ebx,[ebp-16]
	mov dword [ebx+00], 0
	mov dword [ebx+04], 0
	mov dword [ebx+08], 0
	mov dword [ebx+12], 0
	
	push ebx
	push dword [ebp+08]
	call [GetClientRect]
	
	;;SetWindowPos(hwnd,hwndInsertAfter,X,Y,cx,cy,uFlags)
	push dword 0x0004 ;;SWP_NOZORDER
	push dword [ebx+12] ;;rect bottom
	push dword [ebx+08] ;;rect right
	push dword 0
	push dword 0
	push dword 0
	push dword [hEdit]
	call [SetWindowPos]
	
	;;Add menus
	
	
	call [CreateMenu]
	mov dword [hMenu],eax
	
	call [CreateMenu]
	mov dword [hFileMenu],eax
	
	;;AppendMenuA(hMenu,uFlags,uIDNewItem,lpNewItem)
	push dword MenuNewFile
	push dword 1 ;;menu new file ID
	push dword 0x00000000 ;;MF_STRING
	push dword [hFileMenu]
	call [AppendMenuA]
	
		
	push dword MenuOpenFile
	push dword 2 ;; menu open file ID
	push dword 0x00000000 ;;MF_STRING
	push dword [hFileMenu]
	call [AppendMenuA]
		
	push dword MenuSaveFile
	push dword 3 ;;menu save file ID
	push dword 0x00000000 ;;MF_STRING
	push dword [hFileMenu]
	call [AppendMenuA]
	
	push dword MenuExitFile
	push dword 4 ;;menu exit file ID
	push dword 0x00000000 ;;MF_STRING
	push dword [hFileMenu]
	call [AppendMenuA]
		
	push dword MenuFile
	push dword [hFileMenu]
	push dword 0x00000010 ;;MF_POPUP
	push dword [hMenu]
	call [AppendMenuA]
	
	push dword [hMenu]
	push dword [ebp+08] ;;hwnd
	call [SetMenu]
	
	jmp .window_finish
    .window_size:
	;;RECt(left,top,right,bottom)
	xor ebx,ebx
	lea ebx,[ebp-16]
	
	mov dword [ebx+00], 0
	mov dword [ebx+04], 0
	mov dword [ebx+08], 0
	mov dword [ebx+12], 0
	
	push ebx
	push dword [ebp+08]
	call [GetClientRect]
	
	;;getdlgitem(hDlg,nIDDlgItem)
	;;retrieves handle hEdit
	push dword 101 ;;hEdit ID //IDC_MAIN_EDIT
	push dword [ebp+08]
	call [GetDlgItem]
	mov dword [hEdit],eax
	
	;;Set edit control
	;;SetWindowPos(hwnd,hwndInsertAfter,X,Y,cx,cy,uFlags)
	push dword 0x0004 ;;SWP_NOZORDER Retains the current Z order (ignores the hWndInsertAfter parameter).
	push dword [ebx+12] ;;rect bottom
	push dword [ebx+08] ;;rect right
	push dword 0
	push dword 0
	push dword 0
	push dword [hEdit]
	call [SetWindowPos]
	jmp .window_finish
	
    .window_command:
	;;wParam
	mov eax, dword [ebp+16]
	;;Compare with MenuID
	cmp eax,1 ;;new file ID
	jz .new_file
	cmp eax,2 ;; open file ID
	jz .window_open_file 
	cmp eax,3 ;; save file ID
	jz .window_save_file 
	jmp .window_finish
    .new_file:	
	;;Set edit control to new
	push dword DelText
	push dword 101
	push dword [ebp+08]
	call [SetDlgItemTextA]
	jmp .window_finish
	; cmp eax, 2
	; jz .window_open_file
	
    .window_open_file:
	;;Clear OpenFileName struct
	;;RtlZeroMemory(&struct,sizeof(struct))
	push dword 88
	push ofn
	call [RtlZeroMemory]
	;;clear the filename
	mov [filename],dword 0
	;;OpenFileNameStruct(lStructSize,hwndOwner,hInstance,lpstrFilter)
	;;Open file dialog
	mov [ofn.lStructSize],dword 88
	mov eax,[ebp+08]
	mov [ofn.hwndOwner],eax
	mov [ofn.hInstance],dword 0
	mov [ofn.lpstrFilter],dword filterString
	mov [ofn.lpstrCustomFilter],dword 0
	mov [ofn.nMaxCustFilter],dword 0
	mov [ofn.nFilterIndex],dword 0
	mov [ofn.lpstrFile],dword filename
	mov [ofn.nMaxFile],dword 260
	mov [ofn.lpstrFileTitle],dword 0
	mov [ofn.nMaxFileTitle],dword 0
	mov [ofn.lpstrInitialDir],dword 0
	mov [ofn.lpstrTitle],dword 0
	mov [ofn.nFileOffset],dword 0
	mov [ofn.nFileExtension],dword 0
	mov [ofn.lpstrDefExt],dword DefExt
	mov [ofn.lCustData],dword 0
	mov [ofn.lpfnHook],dword 0
	mov [ofn.lpTemplateName],dword 0
	mov [ofn.lpReserved],dword 0
	mov [ofn.dwReserved],dword 0
	mov [ofn.FlagsEx],dword 0
	mov eax,524288 | 4096 | 4 ;;OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
	mov [ofn.Flags],eax
	push ofn
	call [GetOpenFileNameA]
	;;retrieves handle hEdit
	push dword 101
	push dword [ebp+08]
	call [GetDlgItem]
	mov dword [hEdit],eax
	
	;;CreateFile(lpFileName,dwDesiredAccess,dwShareMode,lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile)

	push dword 0
	push dword 0
	push dword 3 ;;OPEN_EXISTING
	push dword 0
	push dword 0x00000001 ;;FILE_SHARE_READ
	push dword 0x80000000 ;;GENERIC_READ
	push dword filename
	call [CreateFileA]
	mov dword [hFile],eax
	
	;;GetFileSize
	push dword 0
	push dword [hFile]
	call [GetFileSize]
	mov dword [dwFileSize],eax

	add dword [dwFileSize],1

	;;Allocate memory for filetext
	push dword [dwFileSize]
	push dword 0x0040 ;;GPTR  Initializes memory contents to zero and Allocates fixed memory. The return value is a pointer.
	call [GlobalAlloc]
	mov dword [pszFileText],eax
	
	;;ReadFile(hFile,lpBuffer,nNumberOfBytesToRead,lpNumberOfBytesRead,lpOverlapped)
	
	push dword 0
	push dword dwRead
	push dword [dwFileSize]
	push dword [pszFileText]
	push dword [hFile]
	call [ReadFile]
	
	
	;Set WindowText
	push dword [pszFileText]
	push dword [hEdit]
	call [SetWindowTextA]
	push dword [pszFileText]
	call [GlobalFree]
	
	push dword [hFile]
	call [CloseHandle]
	
	jmp .window_finish
	
    .new_shit_failed:
        ;;;Display a message box with the error message.
	call [CommDlgExtendedError]
	push dword 0
	push dword 0
	push dword err_msg_shit
	push dword 0
	call [MessageBoxA]
	
	jmp .window_finish
	
	;push dword [ebp+08]
	;call [DoFileOpen]
    .new_shit_ok:
        ;Display a message box with the error message.
	
	push dword 0
	push dword 0
	push dword shit_ok
	push dword 0
	call [MessageBoxA]
	
	jmp .window_finish
    .window_save_file:
	;;Clear the openfilename struct
	push dword 88 ;;struct size
	push ofn
	call [RtlZeroMemory]
	mov [filename],dword 0
	;;OpenFileNameStruct(lStructSize,hwndOwner,hInstance,lpstrFilter)
	mov [ofn.lStructSize],dword 88
	mov eax,[ebp+08]
	mov [ofn.hwndOwner],eax
	mov [ofn.hInstance],dword 0
	mov [ofn.lpstrFilter],dword filterString
	mov [ofn.lpstrCustomFilter],dword 0
	mov [ofn.nMaxCustFilter],dword 0
	mov [ofn.nFilterIndex],dword 0
	mov [ofn.lpstrFile],dword filename
	mov [ofn.nMaxFile],dword 260
	mov [ofn.lpstrFileTitle],dword 0
	mov [ofn.nMaxFileTitle],dword 0
	mov [ofn.lpstrInitialDir],dword 0
	mov [ofn.lpstrTitle],dword 0
	mov [ofn.nFileOffset],dword 0
	mov [ofn.nFileExtension],dword 0
	mov [ofn.lpstrDefExt],dword DefExt
	mov [ofn.lCustData],dword 0
	mov [ofn.lpfnHook],dword 0
	mov [ofn.lpTemplateName],dword 0
	mov [ofn.lpReserved],dword 0
	mov [ofn.dwReserved],dword 0
	mov [ofn.FlagsEx],dword 0
	mov eax,524288 |2048|4|2
	mov [ofn.Flags],eax
	push ofn
	call [GetSaveFileNameA]
	;cmp eax,0
	;jz .new_shit_failed
	push dword 101
	push dword [ebp+08]
	call [GetDlgItem]
	mov dword [hEdit],eax
	;;CreateFile(lpFileName,dwDesiredAccess,dwShareMode,lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile)
	push dword 0
	push dword 128 ;;FILE_ATTRIBUTE_NORMAL
	push dword 2 ;;CREATE_ALWAYS
	push dword 0
	push dword 0
	push dword 1073741824 ;;	GENERIC_WRITE

	push dword filename
	call [CreateFileA]
	mov dword [hFile],eax
	
	;;Get Text length
	;;
	push dword [hEdit]
	call [GetWindowTextLengthA]
	mov dword [dwTextLength ],eax
	cmp eax,0
	jz .new_shit_ok
	
	add dword [dwTextLength],1
	mov eax,dword [dwTextLength]
	mov dword [dwBufferSize ],eax
	
	push dword [dwBufferSize]
	push dword 0x0040
	call [GlobalAlloc]
	mov dword [pszText],eax

	;;Get Text in edit control
	push dword [dwBufferSize]
	push dword [pszText]
	push dword [hEdit]
	call [GetWindowTextA ]
	
	;;Write to file with content pszText length dwTextLength 
	push dword 0
	push dword dwWritten
	push dword [dwTextLength]
	push dword [pszText]
	push dword [hFile]
	call [WriteFile]
	mov dword [dWriteFile],eax

	
	push dword [pszText]
	call [GlobalFree]
	push dword [hFile]
	
	call [CloseHandle]
	
	jmp .window_finish
	
	
     ;;if no uMsg we will jump in window_default
    .window_default:
	;;push the parameter of winproc
        push dword [ebp+20]
        push dword [ebp+16]
        push dword [ebp+12]
        push dword [ebp+08]
        ;; And we call the DefWindowProc() function.
        call [DefWindowProcA]

        mov esp,ebp
	pop ebp
        ret 16

        jmp .window_finish

    .window_finish:
    xor eax, eax                  
    mov esp,ebp
    pop ebp
    
ret 16

;;initialized value in .data
section .data
ClassName                           db "NotepPad", 0
ClassNameEdit                       db "Edit",0
ApplicationName                     db "NotePad", 0
MenuNewFile				db"New",0
MenuOpenFile				db"Open",0
MenuSaveFile				db"Save",0
MenuExitFile				db"Exit",0
MenuFile				db"File",0
FilterString			db"Text Files (*.txt)\0*.txt\0All Files (*.*)\0*.*\0"
DefExt					db"txt",0
DelText					db"",0

shit_ok			db"Shit OK",0
err_msg                             db "An error occurred while making the new window. ", 0
err_msg_shit 			db"Shit happend",0
filterString db "Text files (*.txt)",0,"*.txt",0
		db "All files (*.*)",0,"*.*",0,0

ofn:
    .lStructSize       dd 88
    .hwndOwner         dd 0
    .hInstance         dd 0
    .lpstrFilter       dd filterString
    .lpstrCustomFilter dd 0
    .nMaxCustFilter    dd 0
    .nFilterIndex      dd 1
    .lpstrFile         dd filename
    .nMaxFile          dd 255
    .lpstrFileTitle    dd 0
    .nMaxFileTitle     dd 0
    .lpstrInitialDir   dd 0
    .lpstrTitle        dd 0
    .Flags             dd 0
    .nFileOffset       dw 0
    .nFileExtension    dw 0
    .lpstrDefExt       dd DefExt
    .lCustData         dd 0
    .lpfnHook          dd 0
    .lpTemplateName    dd 0
    .lpReserved        dd 0
    .dwReserved        dd 0
    .FlagsEx           dd 0


;;uninitialized value in .bss
section .bss

hInstance                           resd 1
CommandLine                         resd 1
hEdit                        resd 1
hFont  			resd 1
hMenu			resd 1
hFileMenu			resd 1
filename 			resd 1
hFile				resd 1
dwFileSize			resd 1
pszFileText			resd 1
dwRead			resd 1
testHwnd			resd 1
dwTextLength 		resd 1
pszText 			resd 1
dwBufferSize 		resd 1
dwWritten			resd 1
dWriteFile			resd 1