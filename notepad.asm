;; Define the externs for the functions that we'll use in this program.
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

;; Tell NASM that we're about to type things for the code section.
section .text use32
;; We specify that here is the place where the program should start
;; executing.
..start:

;; We pass 0 as a parameter.
push dword 0
;; Then we call the GetModuleHandle() function.
call [GetModuleHandleA]
;; And we store the result (which is in EAX) in the hInstance global variable.
mov dword [hInstance], eax

;; Then we call the function to get the command line for our program.
call [GetCommandLineA]
;; And we store the result in the CommandLine global variable.
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
    ;; WNDCLASSEX is 48 bytes in size. Let's use [ebp-48] for the start of our
    ;; window class structure. MSG is 28 bytes in size; let's use [ebp-48-24]
    ;; = [ebp-72] for that. Then there's HWND, which is 4 bytes in size.
    ;; We'll use [ebp-76] to store that value.
    ;; So we'll have to reserve 76 bytes on the stack.
    enter 76, 0

    ;; We need to fill out the WNDCLASSEX structure, now.
    lea ebx, [ebp-48]           ;; We load EBX with the address of our WNDCLASSEX structure.

    ;; The structure of WNDCLASSEX can be found at this page:
    ;; http://msdn.microsoft.com/en-us/library/ms633577(v=vs.85).aspx

    mov dword [ebx+00], 48      ;; Offset 00 is the size of the structure.
    mov dword [ebx+04], 3       ;; Offset 04 is the style for the window. 3 is equal to CS_HREDRAW | CS_VREDRAW
    mov dword [ebx+08], WindowProcedure        ;; Offset 08 is the address of our window procedure.
    mov dword [ebx+12], 0       ;; I'm not sure what offset 12 and offset 16 are for.
    mov dword [ebx+16], 0       ;; But I do know that they're supposed to be NULL, at least for now.

    mov eax, dword [ebp+8]      ;; We load the hInstance value.
    mov dword [ebx+20], eax     ;; Offset 20 is the hInstance value.

    mov dword [ebx+32], 5 + 1   ;; Offset 32 is the handle to the background brush. We set that to COLOR_WINDOW + 1.
    mov dword [ebx+36], 0       ;; Offset 36 is the menu name, what we set to NULL, because we don't have a menu.
    mov dword [ebx+40], ClassName              ;; Offset 40 is the class name for our window class.
    ;; Note that when we're trying to pass a string, we pass the memory address of the string, and the
    ;; function to which we pass that address takes care of the rest.

    ;; LoadIcon(0, IDI_APPLICATION) where IDI_APPLICATION is equal to 32512.
    push dword 32512
    push dword 0
    call [LoadIconA]

    ;; All Win32 API functions preserve the EBP, EBX, ESI, and EDI registers, so it's
    ;; okay if we use EBX to store the address of the WNDCLASSEX structure, for now.

    mov dword [ebx+24], eax     ;; Offset 24 is the handle to the icon for our window.
    mov dword [ebx+44], eax     ;; Offset 44 is the handle to the small icon for our window.

    ;; LoadCursor(0, IDC_ARROW) where IDC_ARROW is equal to 32512.
    push dword 32512
    push dword 0
    call [LoadCursorA]

    mov dword [ebx+28], eax     ;; Offset 28 is the handle to the cursor for our window.

    ;; Now we register our window class with Windows, so that we can use the class name
    ;; for our window, when we make that.
    ;; Since EBX already has the address of our WNDCLASSEX structure, we can just pussh
    ;; EBX, so we don't have to reload the address of that structure.
    push ebx
    call [RegisterClassExA]

    ;; CreateWindowEx(0, ClassName, window title, WS_OVERLAPPEDWINDOW, x, y, width, height, handle to parent window, handle to menu, hInstance, NULL);
    push dword 0
    push dword [ebp+8]
    push dword 0
    push dword 0
    push dword 400              ;; 400 pixels high.
    push dword 500              ;; 500 pixels wide.
    push dword 0x80000000       ;; CW_USEDEFAULT
    push dword 0x80000000       ;; CW_USEDEFAULT
    push dword 0x00 | 0xC00000 | 0x80000 | 0x40000 | 0x20000 | 0x10000    ;; WS_OVERLAPPEDWINDOW
                                ;; WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
    push dword ApplicationName
    push dword ClassName
    push dword 0
    call [CreateWindowExA]
    ;; Store the result (which should be a handle to our window) in [ebp-76].
    mov dword [ebp-76], eax

    ;; Check if EAX is zero. If so, jump to the error-handling routine.
    sub eax, 0                  ;; The only difference between SUB and CMP is that CMP doesn't store the result in the first operand.
                                ;; Here we're subtracting 0 from EAX, which won't change EAX, so it doesn't matter if we use SUB.
    jz .new_window_failed

    ;; Now we need to show the window and update the window.

    ;; ShowWindow([ebp-76], [ebp+20])
    push dword [ebp+20]
    push dword [ebp-76]
    call [ShowWindow]

    ;; UpdateWindow([ebp-76])
    push dword [ebp-76]
    call [UpdateWindow]

    .MessageLoop:
        ;; GetMessage(the MSG structure, 0, 0, 0)
        push dword 0
        push dword 0
        push dword 0
            lea ebx, [ebp-72]
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

    ;; We'll need to jump over the error-handling routing, so we can continue.
    jmp .finish

    .new_window_failed:
        ;; Display a message box with the error message.
        push dword 0
        push dword 0
        push dword err_msg
        push dword 0
        call [MessageBoxA]

        ;; Exit, returning 1.
        mov eax, 1
        leave
        ret 16
    .finish:

    ;; We return the MSG.wParam value.
    lea ebx, [ebp-72]
    mov eax, dword [ebx+08]

    ;; It's time to leave.
    leave
;; And, since WindowMain() has 4 arguments, we free 4 * 4 = 16 bytes from
;; the stack, after we return.
ret 16

;; We also need a procedure to handle the events that our window sends us.
;; We call that procedure WindowProcedure().
;; It also has to take 4 arguments, which are as follows:
;;    hWnd             The handle to the window that sent us that event.
;;                     This would be the handle to the window that uses
;;                     our window class.
;;    uMsg             This is the message that the window sent us. It
;;                     describes the event that has happened.
;;    wParam           This is a parameter that goes along with the
;;                     event message.
;;    lParam           This is an additional parameter for the message.
;; If we process the message, we have to return 0.
;; Otherwise, we have to return whatever the DefWindowProc() function
;; returns. DefWindowProc() is kind of like the "default window procedure"
;; function. It takes the default action, based on the message.
;; For now, we only care about the WM_DESTROY message, which tells us
;; that the window has been closed. If we don't take care of the
;; WM_DESTROY message, who knows what will happen.
;; Later on, of course, we can expand our window to process other
;; messages too.
WindowProcedure:
    ;; We don't really need any local variables, for now, besides the function arguments.
    enter 0, 0

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
    jmp .window_default

    ;; We need to define the .window_destroy label, now.
    .window_destroy:
        ;; If uMsg is equal to WM_DESTROY (2), then the processor will execute this
        ;; code next.

        ;; We pass 0 as an argument to the PostQuitMessage() function, to tell it
        ;; to pass 0 as the value of wParam for the next message. At that point,
        ;; GetMessage() will return 0, and the message loop will terminate.
        push dword 0
        ;; Now we call the PostQuitMessage() function.
        call [PostQuitMessage]

        ;; When we're done doing what we need to upon the WM_DESTROY condition,
        ;; we need to jump over to the end of this area, or else we'd end up
        ;; in the .window_default code, which won't be very good.
        jmp .window_finish
    ;; And we define the .window_default label.
    .window_default:
        ;; Right now we don't care about what uMsg is; we just use the default
        ;; window procedure.

        ;; In order for use to call the DefWindowProc() function, we need to
        ;; pass the arguments to it.
        ;; It's arguments are the same as WindowProcedure()'s arguments.
        ;; We push the arguments to the stack, in backwards order.
        push dword [ebp+20]
        push dword [ebp+16]
        push dword [ebp+12]
        push dword [ebp+08]
        ;; And we call the DefWindowProc() function.
        call [DefWindowProcA]

        ;; At this point, we need to return. The return value must
        ;; be equal to whatever DefWindowProc() returned, so we
        ;; can't change EAX.

        ;; But we need to leave before we return.
        leave

        ;; Then, we can return. WindowProcedure() has 4 arguments, 4 bytes each,
        ;; so we free 4 * 4 = 16 bytes from the stack, after returning.
        ret 16

        ;; Any code after the RET instruction will not be executed.
        ;; But we'll put code there anyway, just for consistency.
        jmp .window_finish
    ;; This is where the we want to jump to after doing everything we need to.
    .window_finish:

    ;; Unless we use the DefWindowProc() function, we need to return 0.
    xor eax, eax                  ;; XOR EAX, EAX is a way to clear EAX.
                                  ;; Same applies for any other register.
    ;; Then we need to leave.
    leave
;; And, as said earlier, we free 16 bytes, after returning.
ret 16

;; We're about to define variables for the data section.
section .data
;; We define the class name for our window class.
ClassName                           db "SimpleWindowClass", 0
;; Then we define the application name, for our window's title.
ApplicationName                     db "Simple Window Example", 0

;; The error message.
err_msg                             db "An error occurred while making the new window. ", 0

;; We're about to define variables for the bss section.
section .bss
;; And we reserve a double-word for hInstance and a double-word for CommandLine.
hInstance                           resd 1
CommandLine                         resd 1
