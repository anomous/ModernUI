;==============================================================================
;
; ModernUI Control - ModernUI_Animation
;
; Copyright (c) 2019 by fearless
;
; All Rights Reserved
;
; http://github.com/mrfearless/ModernUI
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
;
;==============================================================================

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none
include \masm32\macros\macros.asm

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

include ModernUI.inc
includelib ModernUI.lib

IFDEF MUI_USEGDIPLUS
ECHO MUI_USEGDIPLUS
include gdiplus.inc
include ole32.inc
includelib gdiplus.lib
includelib ole32.lib
ELSE
ECHO MUI_DONTUSEGDIPLUS
ENDIF

include ModernUI_Animation.inc


ANIMATION_USE_TIMERQUEUE      EQU 1 ; comment out to use WM_SETIMER instead of TimerQueue

IFDEF ANIMATION_USE_TIMERQUEUE
ECHO *** ModernUI_Animation - Using TimerQueue ***
ELSE
ECHO *** ModernUI_Animation - Using WM_TIMER ***
ENDIF

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_AnimationWndProc         PROTO :DWORD, :DWORD, :DWORD, :DWORD
_MUI_AnimationInit            PROTO :DWORD
_MUI_AnimationCleanup         PROTO :DWORD
_MUI_AnimationPaint           PROTO :DWORD
_MUI_AnimationPaintBackground PROTO :DWORD, :DWORD, :DWORD
_MUI_AnimationPaintImages     PROTO :DWORD, :DWORD, :DWORD, :DWORD
_MUI_AnimationNotify          PROTO :DWORD, :DWORD

_MUI_AnimationFrameData       PROTO :DWORD, :DWORD
_MUI_AnimationFrameIndex      PROTO :DWORD
_MUI_AnimationFrameType       PROTO :DWORD, :DWORD
_MUI_AnimationFrameImage      PROTO :DWORD, :DWORD
_MUI_AnimationFrameTime       PROTO :DWORD, :DWORD
_MUI_AnimationFrameParam      PROTO :DWORD, :DWORD

_MUI_AnimationNextFrame       PROTO :DWORD
_MUI_AnimationNextFrameIndex  PROTO :DWORD
_MUI_AnimationNextFrameTime   PROTO :DWORD

IFDEF MUI_USEGDIPLUS
_MUI_AnimationLoadPng         PROTO :DWORD, :DWORD
ENDIF
IFDEF ANIMATION_USE_TIMERQUEUE
_MUI_AnimationTimerProc       PROTO :DWORD, :DWORD
ENDIF
_MUI_AnimationTimerStart      PROTO :DWORD
_MUI_AnimationTimerStop       PROTO :DWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_ANIMATION_PROPERTIES      STRUCT
	dwBackColor			      DD ?  ; RGBCOLOR. Background color of animation
	dwAnimationLoop           DD ?  ; BOOL. Loop animation back to start. Default is TRUE
	dwAnimationNotifications  DD ?  ; BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
	dwAnimationNotifyCallback DD ?  ; DWORD. Address of custom notifications callback function
	dwAnimationDllInstance    DD ?  ; DWORD. Instance of DLL if using control in a DLL
    dwAnimationParam          DD ?  ; DWORD. Custom user specified value
MUI_ANIMATION_PROPERTIES      ENDS

; Internal properties
_MUI_ANIMATION_PROPERTIES     STRUCT
	dwMouseOver		          DD ?  ; BOOL. Mouse is over control
    dwTotalFrames             DD ?  ; DWORD. Total image frames in control
    dwFrameIndex              DD ?  ; DWORD. Current frame index
    dwFramesArray             DD ?  ; DWORD. Points to array of _MUI_ANIMATION_FRAME structures for each frame
    dwFramesImageType         DD ?  ; DWORD. BMP, ICO or PNG
    dwFrameTimeDefault        DD ?  ; DWORD. Default frame time for all frames that have frame time as 0
    dwFrameSpeed              DD ?  ; DWORD. Current frame's speed (frame time)
    dwNotifyData              DD ?  ; DWORD. Pointer to NM_ANIMATION notification structure data
    IFDEF SPINNER_USE_TIMERQUEUE
    bUseTimerQueue            DD ?  ; BOOL. Use timerqueue - if timerqueue api calls fail can fallback to WM_TIMER
    hQueue                    DD ?  ; DWORD. Handle to timerqueue
    hTimer                    DD ?  ; DWORD. Handle to timerqueue timer
    ENDIF
_MUI_ANIMATION_PROPERTIES     ENDS

IFNDEF _MUI_ANIMATION_FRAME
_MUI_ANIMATION_FRAME          STRUCT
    dwFrameType               DD ?  ; Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    dwFrameImage              DD ?  ; Handle to image: Bitmap, Icon or PNG
    dwFrameTime               DD ?  ; Frame time in milliseconds
    lParam                    DD ?  ; Custom user specified value
_MUI_ANIMATION_FRAME               ENDS
ENDIF

IFNDEF NM_ANIMATION_FRAME     ; ModernUI_Animation Notification Item
NM_ANIMATION_FRAME            STRUCT
    dwFrameIndex              DD ?  ; Frame index
    dwFrameType               DD ?  ; Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    dwFrameImage              DD ?  ; Handle or resource ID of image : Bitmap, Icon or PNG (RT_BITMAP, RT_ICON or RT_RCDATA resource)
    dwFrameTime               DD ?  ; Frame time in milliseconds
    lParam                    DD ?  ; Custom user specified value
NM_ANIMATION_FRAME            ENDS
ENDIF

IFNDEF NM_ANIMATION           ; Notification Message Structure for ModernUI_Animation
NM_ANIMATION                  STRUCT
    hdr                       NMHDR <>
    item                      NM_ANIMATION_FRAME <>
NM_ANIMATION                  ENDS
ENDIF

IFDEF MUI_USEGDIPLUS
IFNDEF UNKNOWN
UNKNOWN STRUCT
   QueryInterface   DWORD ?
   AddRef           DWORD ?
   Release          DWORD ?
UNKNOWN ENDS
ENDIF

IFNDEF IStream
IStream STRUCT
IUnknown            UNKNOWN <>
Read                DWORD ?
Write               DWORD ?
Seek                DWORD ?
SetSize             DWORD ?
CopyTo              DWORD ?
Commit              DWORD ?
Revert              DWORD ?
LockRegion          DWORD ?
UnlockRegion        DWORD ?
Stat                DWORD ?
Clone               DWORD ?
IStream ENDS
ENDIF
ENDIF


.CONST
ANIMATION_FRAME_TIME_MIN      EQU 10
ANIMATION_FRAME_TIME_DEFAULT  EQU 250 ; Milliseconds for timer firing

; Internal properties
; Internal properties
@AnimationMouseOver           EQU 0
@AnimationTotalFrames         EQU 4
@AnimationFrameIndex          EQU 8
@AnimationFramesArray         EQU 12
@AnimationImageType           EQU 16
@AnimationFrameTimeDefault    EQU 20
@AnimationFrameSpeed          EQU 24
@AnimationNotifyData          EQU 28
IFDEF ANIMATION_USE_TIMERQUEUE
@AnimationUseTimerQueue       EQU 32
@AnimationQueue               EQU 36
@AnimationTimer               EQU 40
ENDIF



.DATA
szMUIAnimationClass           DB 'ModernUI_Animation',0 	; Class name for creating our ModernUI_Animation control



.CODE

MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for Animation control
;------------------------------------------------------------------------------
MUIAnimationSetProperty PROC hControl:DWORD, dwProperty:DWORD, dwPropertyValue:DWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, dwProperty, dwPropertyValue
    ret
MUIAnimationSetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for Animation control
;------------------------------------------------------------------------------
MUIAnimationGetProperty PROC hControl:DWORD, dwProperty:DWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, dwProperty, NULL
    ret
MUIAnimationGetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationRegister - Registers the Animation control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as Animation
;------------------------------------------------------------------------------
MUIAnimationRegister PROC
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:DWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, eax

    invoke GetClassInfoEx,hinstance,addr szMUIAnimationClass, Addr wc 
    .IF eax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea eax, szMUIAnimationClass
    	mov wc.lpszClassName, eax
    	mov eax, hinstance
        mov wc.hInstance, eax
    	mov wc.lpfnWndProc, OFFSET _MUI_AnimationWndProc
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, eax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 8 ; cbWndExtra +0 = dword ptr to internal properties memory block, cbWndExtra +4 = dword ptr to external properties memory block
    	Invoke RegisterClassEx, addr wc
    .ENDIF  
    ret

MUIAnimationRegister ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationCreate - Returns handle in eax of newly created control
;------------------------------------------------------------------------------
MUIAnimationCreate PROC hWndParent:DWORD, xpos:DWORD, ypos:DWORD, controlwidth:DWORD, controlheight:DWORD, dwResourceID:DWORD, dwStyle:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:DWORD
	LOCAL hControl:DWORD
	LOCAL dwNewStyle:DWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, eax

	Invoke MUIAnimationRegister
	
    mov eax, dwStyle
    mov dwNewStyle, eax
    and eax, WS_CHILD or WS_CLIPCHILDREN
    .IF eax != WS_CHILD or WS_CLIPCHILDREN
        or dwNewStyle, WS_CHILD or WS_CLIPCHILDREN
    .ENDIF	
	
    Invoke CreateWindowEx, NULL, Addr szMUIAnimationClass, NULL, dwNewStyle, xpos, ypos, controlwidth, controlheight, hWndParent, dwResourceID, hinstance, NULL
	mov hControl, eax
	.IF eax != NULL
		
	.ENDIF
	mov eax, hControl
    ret
MUIAnimationCreate ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_AnimationWndProc PROC USES EBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov ebx, lParam
		; sets text of our control, delete if not required.
        ;Invoke SetWindowText, hWin, (CREATESTRUCT PTR [ebx]).lpszName	
        mov eax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, MUI_INTERNAL_PROPERTIES, SIZEOF _MUI_ANIMATION_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, MUI_EXTERNAL_PROPERTIES, SIZEOF MUI_ANIMATION_PROPERTIES ; external properties
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusStart ; for png resources if used
        ENDIF
		Invoke _MUI_AnimationInit, hWin
		mov eax, 0
		ret 

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_AnimationCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, MUI_INTERNAL_PROPERTIES
		Invoke MUIFreeMemProperties, hWin, MUI_EXTERNAL_PROPERTIES
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusFinish
        ENDIF
		mov eax, 0
		ret
        
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_AnimationPaint, hWin
        mov eax, 0
        ret

    .ELSEIF eax == WM_LBUTTONUP
		; simulates click on our control, delete if not required.
		Invoke GetDlgCtrlID, hWin
		mov ebx,eax
		Invoke GetParent, hWin
		Invoke PostMessage, eax, WM_COMMAND, ebx, hWin

   .ELSEIF eax == WM_MOUSEMOVE
		Invoke MUISetIntProperty, hWin, @AnimationMouseOver, TRUE
		.IF eax != TRUE
		    Invoke InvalidateRect, hWin, NULL, TRUE
		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
		    mov TE.dwFlags, TME_LEAVE
		    mov eax, hWin
		    mov TE.hwndTrack, eax
		    mov TE.dwHoverTime, NULL
		    Invoke TrackMouseEvent, Addr TE
		.ENDIF

    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @AnimationMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, eax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @AnimationMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, eax
    
	.ELSEIF eax == WM_TIMER
	    mov eax, wParam
	    .IF eax == hWin
	        Invoke _MUI_AnimationNextFrame, hWin
	    .ENDIF
    
	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		Invoke MUISetExtProperty, hWin, wParam, lParam
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_AnimationWndProc ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationInit - set initial default values
;------------------------------------------------------------------------------
_MUI_AnimationInit PROC hWin:DWORD
    LOCAL hParent:DWORD
    LOCAL dwStyle:DWORD
    
    Invoke GetParent, hWin
    mov hParent, eax
    
    ; get style and check it is our default at least
    Invoke GetWindowLong, hWin, GWL_STYLE
    mov dwStyle, eax
    and eax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF eax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov eax, dwStyle
        or eax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov dwStyle, eax
        Invoke SetWindowLong, hWin, GWL_STYLE, dwStyle
    .ENDIF
    ;PrintDec dwStyle
    
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hWin, @AnimationBackColor, MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hWin, @AnimationLoop, TRUE
    Invoke MUISetIntProperty, hWin, @AnimationFrameTimeDefault, ANIMATION_FRAME_TIME_DEFAULT

    IFDEF ANIMATION_USE_TIMERQUEUE
    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, TRUE
    ENDIF

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF NM_ANIMATION
    .IF eax != NULL
        Invoke MUISetIntProperty, hWin, @AnimationNotifyData, eax
        Invoke MUISetExtProperty, hWin, @AnimationNotifications, TRUE
    .ENDIF
    
    mov eax, TRUE
    ret
_MUI_AnimationInit ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationCleanup - cleanup
;------------------------------------------------------------------------------
_MUI_AnimationCleanup PROC USES EBX hWin:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL pCurrentFrame:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL ImageType:DWORD
    LOCAL hImage:DWORD
    
    Invoke _MUI_AnimationTimerStop, hWin
    
    Invoke MUIAnimationClear, hWin
    
;    Invoke MUIGetIntProperty, hWin, @AnimationImageType
;    mov ImageType, eax    
;    
;    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
;    .IF eax != NULL
;        mov pAnimationFramesArray, eax
;        mov pCurrentFrame, eax
;        
;        Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
;        mov TotalFrames, eax
;        
;        mov FrameIndex, 0
;        mov eax, 0
;        .WHILE eax < TotalFrames
;            mov ebx, pCurrentFrame
;            
;            mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage ; get bitmap handle and delete object if it exists
;            
;            .IF eax != NULL
;                mov hImage, eax
;                
;                mov eax, ImageType
;                .IF eax == MUIAIT_BMP
;                    ;PrintText 'Deleteing bitmap'
;                    Invoke DeleteObject, hImage
;                .ELSEIF eax == MUIAIT_ICO
;                    Invoke DestroyIcon, hImage
;                .ELSEIF eax == MUIAIT_PNG
;                    IFDEF MUI_USEGDIPLUS
;                    Invoke GdipDisposeImage, hImage
;                    ENDIF
;                .ENDIF
;            .ENDIF
;            
;            add pCurrentFrame, SIZEOF _MUI_ANIMATION_FRAME
;            inc FrameIndex
;            mov eax, FrameIndex
;        .ENDW
;    
;        Invoke GlobalFree, pAnimationFramesArray
;    
;    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationNotifyData
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF
    
    ret
_MUI_AnimationCleanup ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaint
;------------------------------------------------------------------------------
_MUI_AnimationPaint PROC hWin:DWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, eax

    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
    Invoke GetClientRect, hWin, Addr rect

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, eax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, eax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, eax

    ;----------------------------------------------------------
    ; Background
    ;----------------------------------------------------------
    Invoke _MUI_AnimationPaintBackground, hWin, hdcMem, Addr rect
    
    ;----------------------------------------------------------
    ; Images
    ;----------------------------------------------------------
    Invoke _MUI_AnimationPaintImages, hWin, hdc, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Border
    ;----------------------------------------------------------
    ;Invoke _MUI_AnimationPaintBorder, hWin, hdcMem, Addr rect
    
    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY
    
    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem
    
    Invoke EndPaint, hWin, Addr ps
    
    ret
_MUI_AnimationPaint ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaintBackground
;------------------------------------------------------------------------------
_MUI_AnimationPaintBackground PROC hWin:DWORD, hdc:DWORD, lpRect:DWORD
    LOCAL BackColor:DWORD
    LOCAL hBrush:DWORD
    LOCAL hOldBrush:DWORD
    LOCAL rect:RECT

    Invoke CopyRect, Addr rect, lpRect
    inc rect.bottom ; rect needs to be increased for FillRect call
    inc rect.right ; rect needs to be increased for FillRect call
    
    Invoke MUIGetExtProperty, hWin, @AnimationBackColor
    mov BackColor, eax
    
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, eax
    Invoke SelectObject, hdc, eax
    mov hOldBrush, eax
    Invoke SetDCBrushColor, hdc, BackColor
    Invoke FillRect, hdc, Addr rect, hBrush
    
    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    
    ret
_MUI_AnimationPaintBackground ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaintImages
;------------------------------------------------------------------------------
_MUI_AnimationPaintImages PROC USES EBX hWin:DWORD, hdcMain:DWORD, hdcDest:DWORD, lpRect:DWORD
    LOCAL hdcMem:HDC
    LOCAL hbmOld:DWORD
    LOCAL hImage:DWORD
    LOCAL ImageType:DWORD
    LOCAL pGraphics:DWORD
    LOCAL pGraphicsBuffer:DWORD
    LOCAL pBitmap:DWORD
    LOCAL ImageWidth:DWORD
    LOCAL ImageHeight:DWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    
    Invoke MUIGetIntProperty, hWin, @AnimationImageType
    .IF eax == 0
        ret
    .ENDIF
    mov ImageType, eax
    
    Invoke _MUI_AnimationFrameImage, hWin, -1 ; get current frame
    ;Invoke _MUI_AnimationCurrentFrameImage, hWin
    .IF eax == 0
        ret
    .ENDIF
    mov hImage, eax
    
    Invoke CopyRect, Addr rect, lpRect
    Invoke MUIGetImageSize, hImage, ImageType, Addr ImageWidth, Addr ImageHeight
    
    mov eax, rect.right
    shr eax, 1
    mov ebx, ImageWidth
    shr ebx, 1
    sub eax, ebx
    .IF sdword ptr eax < 0
        mov eax, 0
    .ENDIF
    mov pt.x, eax
    mov eax, rect.bottom
    shr eax, 1
    mov ebx, ImageHeight
    shr ebx, 1
    sub eax, ebx
    .IF sdword ptr eax < 0
        mov eax, 0
    .ENDIF
    mov pt.y, eax
    
    mov eax, ImageType
    .IF eax == MUIAIT_BMP ; bitmap
        
        Invoke CreateCompatibleDC, hdcMain
        mov hdcMem, eax
        Invoke SelectObject, hdcMem, hImage
        mov hbmOld, eax

        Invoke BitBlt, hdcDest, pt.x, pt.y, ImageWidth, ImageHeight, hdcMem, 0, 0, SRCCOPY

        Invoke SelectObject, hdcMem, hbmOld
        Invoke DeleteDC, hdcMem
        .IF hbmOld != 0
            Invoke DeleteObject, hbmOld
        .ENDIF
        
    .ELSEIF eax == MUIAIT_ICO ; icon
        Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, 0, 0, 0, 0, DI_NORMAL
    
    .ELSEIF eax == MUIAIT_PNG ; png
        IFDEF MUI_USEGDIPLUS
        Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
        Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
        Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer
        
        Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
        Invoke GdipSetPixelOffsetMode, pGraphicsBuffer, PixelOffsetModeHighQuality
        Invoke GdipSetPageUnit, pGraphics, UnitPixel
        Invoke GdipSetPageUnit, pGraphicsBuffer, UnitPixel
        Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
        Invoke GdipSetSmoothingMode, pGraphicsBuffer, SmoothingModeAntiAlias
        Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
        Invoke GdipSetInterpolationMode, pGraphicsBuffer, InterpolationModeHighQualityBicubic
        
        Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
        Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, ImageWidth, ImageHeight
        .IF pBitmap != NULL
            Invoke GdipDisposeImage, pBitmap
        .ENDIF
        .IF pGraphicsBuffer != NULL
            Invoke GdipDeleteGraphics, pGraphicsBuffer
        .ENDIF
        .IF pGraphics != NULL
            Invoke GdipDeleteGraphics, pGraphics
        .ENDIF
        ENDIF
    .ENDIF    

    ret
_MUI_AnimationPaintImages ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaintBorder
;------------------------------------------------------------------------------
_MUI_AnimationPaintBorder PROC hWin:DWORD, hdc:DWORD, lpRect:DWORD
;    LOCAL BorderColor:DWORD
;    LOCAL hBrush:DWORD
;    LOCAL hOldBrush:DWORD
;    
;    ;Invoke MUIGetExtProperty, hWin, @AnimationBorderColor
;    mov eax, -1
;    mov BorderColor, eax
;    
;    .IF BorderColor != -1
;        Invoke GetStockObject, DC_BRUSH
;        mov hBrush, eax
;        Invoke SelectObject, hdc, eax
;        mov hOldBrush, eax
;        Invoke SetDCBrushColor, hdc, BorderColor
;        Invoke FrameRect, hdc, lpRect, hBrush
;        
;        .IF hOldBrush != 0
;            Invoke SelectObject, hdc, hOldBrush
;            Invoke DeleteObject, hOldBrush
;        .ENDIF     
;        .IF hBrush != 0
;            Invoke DeleteObject, hBrush
;        .ENDIF                
;    .ENDIF
    ret
_MUI_AnimationPaintBorder ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNotify
;------------------------------------------------------------------------------
_MUI_AnimationNotify PROC USES EBX hWin:DWORD, dwCode:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL pFrameData:DWORD
    LOCAL NotifyData:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL FrameType:DWORD
    LOCAL FrameImage:DWORD
    LOCAL FrameTime:DWORD
    LOCAL lParam:DWORD
    LOCAL hParent:DWORD
    LOCAL idControl:DWORD
    LOCAL NotifyCallback:DWORD
    
    Invoke MUIGetExtProperty, hWin, @AnimationNotifications
    .IF eax == FALSE
        mov eax, TRUE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF eax == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pAnimationFramesArray, eax

    Invoke MUIGetIntProperty, hWin, @AnimationNotifyData
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov NotifyData, eax

    ; Get current frame index and then frame data
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    mov FrameIndex, eax
    mov eax, FrameIndex
    mov ebx, SIZEOF _MUI_ANIMATION_FRAME
    mul ebx
    add eax, pAnimationFramesArray
    mov pFrameData, eax
    
    ; Get current information about our frame
    mov ebx, pFrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameType
    mov FrameType, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage
    mov FrameImage, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameTime
    mov FrameTime, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.lParam
    mov lParam, eax
    
    ; Add frame info and other info to notify data
    mov ebx, NotifyData
    mov eax, hWin
    mov [ebx].NM_ANIMATION.hdr.hwndFrom, eax
    mov eax, dwCode
    mov [ebx].NM_ANIMATION.hdr.code, eax
    mov eax, FrameIndex
    mov [ebx].NM_ANIMATION.item.dwFrameIndex, eax
    mov eax, FrameType
    mov [ebx].NM_ANIMATION.item.dwFrameType, eax
    mov eax, FrameImage
    mov [ebx].NM_ANIMATION.item.dwFrameImage, eax
    mov eax, FrameTime
    mov [ebx].NM_ANIMATION.item.dwFrameTime, eax
    mov eax, lParam
    mov [ebx].NM_ANIMATION.item.lParam, eax
    
    Invoke MUIGetExtProperty, hWin, @AnimationNotifyCallback
    .IF eax == NULL
        ; PostMessage WM_NOTIFY
        Invoke GetParent, hWin
        mov hParent, eax
        Invoke GetDlgCtrlID, hWin
        mov idControl, eax

        .IF hParent != NULL
            Invoke PostMessage, hParent, WM_NOTIFY, idControl, NotifyData
            mov eax, TRUE
        .ELSE
            mov eax, FALSE
        .ENDIF
    .ELSE
        ; Custom user callback for notifications instead of WM_NOTIFY
        mov NotifyCallback, eax
        push NotifyData
        push hWin
        call NotifyCallback
    .ENDIF
    ret
_MUI_AnimationNotify endp

;------------------------------------------------------------------------------
; _MUI_AnimationFrameData - gets a pointer to a frame's data
; if dwFrameIndex == -1 then gets the current frame's data
; Returns in eax pointer to _MUI_ANIMATION_FRAME data
;------------------------------------------------------------------------------
_MUI_AnimationFrameData PROC USES EBX hWin:DWORD, dwFrameIndex:DWORD
    LOCAL pAnimationFramesArray:DWORD
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF
    .IF dwFrameIndex >= eax ; TotalFrames
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF
    mov pAnimationFramesArray, eax
    
    .IF dwFrameIndex == -1
        Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    .ELSE
        mov eax, dwFrameIndex
    .ENDIF
    mov ebx, SIZEOF _MUI_ANIMATION_FRAME
    mul ebx
    add eax, pAnimationFramesArray

    ret
_MUI_AnimationFrameData ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameIndex - Gets current frame index
;------------------------------------------------------------------------------
_MUI_AnimationFrameIndex PROC hWin:DWORD
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    ret
_MUI_AnimationFrameIndex ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameType - gets a frame's image type
; if dwFrameIndex == -1 then gets the current frame's image type
;------------------------------------------------------------------------------
_MUI_AnimationFrameType PROC hWin:DWORD, dwFrameIndex:DWORD
    Invoke _MUI_AnimationFrameData, hWin, dwFrameIndex
    .IF eax == NULL
        ret
    .ENDIF
    mov eax, [eax]._MUI_ANIMATION_FRAME.dwFrameType
    ret
_MUI_AnimationFrameType ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameImage - gets a frame's image handle
; if dwFrameIndex == -1 then gets the current frame's image handle
;------------------------------------------------------------------------------
_MUI_AnimationFrameImage PROC hWin:DWORD, dwFrameIndex:DWORD
    Invoke _MUI_AnimationFrameData, hWin, dwFrameIndex
    .IF eax == NULL
        ret
    .ENDIF
    mov eax, [eax]._MUI_ANIMATION_FRAME.dwFrameImage
    ret
_MUI_AnimationFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameIndex - Gets a frame's time
; if dwFrameIndex == -1 then gets the current frame's time
;------------------------------------------------------------------------------
_MUI_AnimationFrameTime PROC hWin:DWORD, dwFrameIndex:DWORD
    Invoke _MUI_AnimationFrameData, hWin, dwFrameIndex
    .IF eax == NULL
        ret
    .ENDIF
    mov eax, [eax]._MUI_ANIMATION_FRAME.dwFrameTime
    ret
_MUI_AnimationFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameParam - Gets a frame's lParam
; if dwFrameIndex == -1 then gets the current frame's lParam
;------------------------------------------------------------------------------
_MUI_AnimationFrameParam PROC hWin:DWORD, dwFrameIndex:DWORD
    Invoke _MUI_AnimationFrameData, hWin, dwFrameIndex
    .IF eax == NULL
        ret
    .ENDIF
    mov eax, [eax]._MUI_ANIMATION_FRAME.lParam
    ret
_MUI_AnimationFrameParam ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrameIndex - Sets the next frame index to use for painting
; Returns the next frame index or -1 if error or -2 if animation is at end.
;------------------------------------------------------------------------------
_MUI_AnimationNextFrameIndex PROC USES EBX hWin:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL NextFrame:DWORD
    LOCAL bLoop:DWORD

    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF eax == 0
        mov eax, -1 ; no frames
        ret
    .ENDIF
    mov TotalFrames, eax
    
    Invoke MUIGetExtProperty, hWin, @AnimationLoop
    mov bLoop, eax
    
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    inc eax
    .IF eax >= TotalFrames
        .IF bLoop == TRUE
            mov eax, 0
        .ELSE
            mov eax, -2 ; stop playing
            ret
        .ENDIF
    .ENDIF
    mov NextFrame, eax
    Invoke MUISetIntProperty, hWin, @AnimationFrameIndex, NextFrame
    mov eax, NextFrame
    ret
_MUI_AnimationNextFrameIndex ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrameTime - Sets the next frame time to use for timer
; Returns frame time or -1 if error
;------------------------------------------------------------------------------
_MUI_AnimationNextFrameTime PROC hWin:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL FrameTime:DWORD
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF eax == 0
        Invoke MUISetIntProperty, hWin, @AnimationFrameSpeed, 0
        mov eax, 0
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov pAnimationFramesArray, eax
    
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    mov ebx, SIZEOF _MUI_ANIMATION_FRAME
    mul ebx
    add eax, pAnimationFramesArray
    mov ebx, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameTime
    mov FrameTime, eax
    Invoke MUISetIntProperty, hWin, @AnimationFrameSpeed, FrameTime 
    mov eax, FrameTime
    ret
_MUI_AnimationNextFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStart - Starts animation playing
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationStart PROC hControl:DWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF eax == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameTime
    Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, eax
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, 0 ; set play to start at frame 0
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    Invoke _MUI_AnimationNotify, hControl, MUIAN_START
    Invoke _MUI_AnimationTimerStart, hControl
    ret
MUIAnimationStart ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStop - Stops animation
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationStop PROC hControl:DWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationTimerStop, hControl
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, 0 ; reset for play to start at frame 0
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    Invoke _MUI_AnimationNotify, hControl, MUIAN_STOP
    mov eax, TRUE
    ret
MUIAnimationStop ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationPause - Pauses animation
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationPause PROC hControl:DWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationTimerStop, hControl
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    Invoke _MUI_AnimationNotify, hControl, MUIAN_PAUSE
    mov eax, TRUE
    ret
MUIAnimationPause ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationResume - Resumes animation that was paused or stopped.
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationResume PROC hControl:DWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF eax == 0
        xor eax, eax
        ret
    .ENDIF    
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    Invoke _MUI_AnimationNotify, hControl, MUIAN_START
    Invoke _MUI_AnimationTimerStart, hControl
    ret
MUIAnimationResume ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStep
; Returns: next frame that is being shown, or -1 if no frames, or -2 if end of
; animation and @AnimationLoop is not set to TRUE to loop.
;------------------------------------------------------------------------------
MUIAnimationStep PROC hControl:DWORD, bReverse:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL NextFrame:DWORD
    LOCAL bLoop:DWORD
    
    .IF hControl == NULL
        mov eax, -1 ; no frames
        ret
    .ENDIF
    
    ;Invoke MUIAnimationPause, hControl
    Invoke _MUI_AnimationTimerStop, hControl
    
    ; inc or dec frame index
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF eax == 0
        mov eax, -1 ; no frames
        ret
    .ENDIF
    mov TotalFrames, eax
    
    Invoke MUIGetExtProperty, hControl, @AnimationLoop
    mov bLoop, eax
    
    Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .IF bReverse == FALSE
        inc eax
        .IF eax >= TotalFrames
            .IF bLoop == TRUE
                mov eax, 0
            .ELSE
                ; stop playing
                mov eax, -2
                ret
            .ENDIF
        .ENDIF
    .ELSE
        dec eax
        .IF sdword ptr eax < 0 
            .IF bLoop == TRUE
                mov eax, TotalFrames
                dec eax
            .ELSE
                ; stop playing
                mov eax, -2
                ret
            .ENDIF
        .ENDIF
    .ENDIF
    mov NextFrame, eax
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, NextFrame

    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    Invoke _MUI_AnimationNotify, hControl, MUIAN_STEP
    mov eax, NextFrame
    ret
MUIAnimationStep ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameInfo - Get MUI_ANIMATION_FRAME frame data
; Returns TRUE if successful or FALSE otherwise. On successful return the
; MUI_ANIMATION_FRAME structure pointed to by lpMuiAnimationFrameStruct will
; contain the frame data.
;------------------------------------------------------------------------------
MUIAnimationGetFrameInfo PROC USES EBX EDX hControl:DWORD, dwFrameIndex:DWORD, lpMuiAnimationFrameStruct:DWORD
    LOCAL FrameData:DWORD
    
    .IF lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, eax
    
    ; Get frame info
    mov edx, lpMuiAnimationFrameStruct
    mov ebx, FrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameType
    mov [edx].MUI_ANIMATION_FRAME.dwFrameType, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage
    mov [edx].MUI_ANIMATION_FRAME.dwFrameImage, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameTime
    mov [edx].MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.lParam
    mov [edx].MUI_ANIMATION_FRAME.lParam, eax
    
    mov eax, TRUE
    ret
MUIAnimationGetFrameInfo ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameImage
; Returns: in eax the handle of the image, and the dword pointed to by 
; lpdwFrameType will contain the image type: MUIAIT_PNG, MUIAIT_BMP, MUIAIT_ICO
;------------------------------------------------------------------------------
MUIAnimationGetFrameImage PROC USES EBX EDX hControl:DWORD, dwFrameIndex:DWORD, lpdwFrameType:DWORD
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov ebx, eax ; ebx is FrameData

    .IF lpdwFrameType != NULL
        mov edx, lpdwFrameType
        mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameType
        mov [edx], eax
    .ENDIF
    
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage
    ret
MUIAnimationGetFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameTime
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationGetFrameTime PROC USES EBX hControl:DWORD, dwFrameIndex:DWORD
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov ebx, eax ; ebx is FrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage
    ret
MUIAnimationGetFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameInfo - Get MUI_ANIMATION_FRAME frame data
; Returns TRUE if successful or FALSE otherwise. On successful return the
; MUI_ANIMATION_FRAME structure pointed to by lpMuiAnimationFrameStruct will
; contain the frame data.
;------------------------------------------------------------------------------
MUIAnimationSetFrameInfo PROC USES EBX EDX hControl:DWORD, dwFrameIndex:DWORD, lpMuiAnimationFrameStruct:DWORD
    LOCAL dwPrevFrameType:DWORD
    LOCAL dwPrevFrameImage:DWORD
    LOCAL FrameData:DWORD
    
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, eax
    
    ; Get previous frame image and type
    mov ebx, FrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameType
    mov dwPrevFrameType, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage    
    mov dwPrevFrameImage, eax
    
    ; Delete previous image
    mov eax, dwPrevFrameType
    .IF eax == MUIAIT_NONE
    .ELSEIF eax == MUIAIT_BMP
        ;PrintText 'Deleteing bitmap'
        Invoke DeleteObject, dwPrevFrameImage
    .ELSEIF eax == MUIAIT_ICO
        Invoke DestroyIcon, dwPrevFrameImage
    .ELSEIF eax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke GdipDisposeImage, dwPrevFrameImage
        ENDIF
    .ENDIF
    
    ; Set frame info
    mov ebx, lpMuiAnimationFrameStruct
    mov edx, FrameData
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameType
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameType, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameImage
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameTime
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.lParam
    mov [edx]._MUI_ANIMATION_FRAME.lParam, eax
        
    mov eax, TRUE
    ret
MUIAnimationSetFrameInfo ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameImage
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationSetFrameImage PROC USES EBX hControl:DWORD, dwFrameIndex:DWORD, dwFrameType:DWORD, hFrameImage:DWORD
    LOCAL dwPrevFrameType:DWORD
    LOCAL dwPrevFrameImage:DWORD
    LOCAL FrameData:DWORD
    
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, eax
    
    ; Get previous frame image and type
    mov ebx, FrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameType
    mov dwPrevFrameType, eax
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage    
    mov dwPrevFrameImage, eax
    
    ; Delete previous image
    mov eax, dwPrevFrameType
    .IF eax == MUIAIT_NONE
    .ELSEIF eax == MUIAIT_BMP
        ;PrintText 'Deleteing bitmap'
        Invoke DeleteObject, dwPrevFrameImage
    .ELSEIF eax == MUIAIT_ICO
        Invoke DestroyIcon, dwPrevFrameImage
    .ELSEIF eax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke GdipDisposeImage, dwPrevFrameImage
        ENDIF
    .ENDIF
    
    ; Set frame image and type
    mov ebx, FrameData
    mov eax, dwFrameType
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameType, eax
    mov eax, hFrameImage
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    
    mov eax, TRUE
    ret
MUIAnimationSetFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameTime
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationSetFrameTime PROC USES EBX hControl:DWORD, dwFrameIndex:DWORD, dwFrameTime:DWORD
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov ebx, eax
    mov eax, dwFrameTime
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov eax, TRUE
    ret
MUIAnimationSetFrameTime ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationCropFrame - Crops a specific frame image based on rectangle 
; passed via lpRect. Area inside the rect is kept. Original frame image is 
; destroyed and the new cropped frame replaces it.
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationCropFrame PROC USES EBX hControl:DWORD, dwFrameIndex:DWORD, lpRect:DWORD
    LOCAL hImage:DWORD
    LOCAL hImageOld:DWORD
    LOCAL hImageCropped:DWORD
    LOCAL hImageCroppedOld:DWORD
    LOCAL dwImageType:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD
    LOCAL FrameData:DWORD
    LOCAL hdc:DWORD
    LOCAL hdcOriginal:DWORD
    LOCAL hdcCropped:DWORD
    LOCAL pt:POINT
    LOCAL rect:RECT
    
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, eax
    
    Invoke _MUI_AnimationFrameImage, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov hImage, eax
    
    Invoke CopyRect, Addr rect, lpRect
    Invoke MUIGetImageSize, hImage, dwImageType, Addr dwImageWidth, Addr dwImageHeight
    
    Invoke GetDC, hControl
    mov hdc, eax
    
    ; get image type

    mov eax, dwImageType
    .IF eax == MUIAIT_NONE
        xor eax, eax
        ret
    
    .ELSEIF eax == MUIAIT_BMP ; bitmap
        Invoke CreateCompatibleDC, hdc
        mov hdcOriginal, eax
        Invoke SelectObject, hdcOriginal, hImage
        mov hImageOld, eax

        Invoke CreateCompatibleDC, hdc
        mov hdcCropped, eax
        Invoke CreateCompatibleBitmap, hdcCropped, rect.right, rect.bottom
        mov hImageCropped, eax
        Invoke SelectObject, hdcCropped, hImageCropped
        mov hImageCroppedOld, eax

        Invoke BitBlt, hdcCropped, 0, 0, rect.right, rect.bottom, hdcOriginal, rect.left, rect.top, SRCCOPY

        Invoke SelectObject, hdcCropped, hImageCroppedOld
        Invoke DeleteDC, hdcCropped
        .IF hImageCroppedOld != 0
            Invoke DeleteObject, hImageCroppedOld
        .ENDIF
        Invoke SelectObject, hdcOriginal, hImageOld
        Invoke DeleteDC, hdcOriginal
        .IF hImageOld != 0
            Invoke DeleteObject, hImageOld
        .ENDIF
        .IF hImage != 0
            Invoke DeleteObject, hImage
        .ENDIF
        
        ; Replace original image with new cropped image 
        mov ebx, FrameData
        mov eax, hImageCropped
        mov [ebx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    
    .ELSEIF eax == MUIAIT_ICO ; icon
    
    .ELSEIF eax == MUIAIT_PNG ; png
    
    .ENDIF
    
    mov eax, TRUE
    ret
MUIAnimationCropFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationCropFrames - Crops all frames based on rectangle passed via 
; lpRect. Area inside the rect is kept. Original frame images are destroyed and
; the new cropped frames replaces them.
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationCropFrames PROC hControl:DWORD, lpRect:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameIndex:DWORD
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF eax == 0
        xor eax, eax
        ret
    .ENDIF
    mov TotalFrames, eax
    
    mov eax, 0
    mov FrameIndex, 0
    .WHILE eax < TotalFrames
        
        Invoke MUIAnimationCropFrame, hControl, FrameIndex, lpRect
        .IF eax == FALSE
            xor eax, eax
            ret
        .ENDIF
        
        inc FrameIndex
        mov eax, FrameIndex
    .ENDW
    
    mov eax, TRUE
    ret
MUIAnimationCropFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationClear - deletes all frames
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationClear PROC hControl:DWORD
    Invoke MUIAnimationDeleteFrames, hControl
    ret
MUIAnimationClear ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationDeleteFrame
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationDeleteFrame PROC hControl:DWORD, dwFrameIndex:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameData:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL ImageType:DWORD
    LOCAL hImage:DWORD
    LOCAL dwSizeRemainingFrames:DWORD
    LOCAL pRemainingFrames:DWORD
    
    Invoke _MUI_AnimationFrameData, hControl, dwFrameIndex
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, eax
    
    ; Get frame image handle and delete it
    Invoke MUIGetIntProperty, hControl, @AnimationImageType
    mov ImageType, eax
    
    mov ebx, FrameData
    mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage
    mov hImage, eax
    
    mov eax, ImageType
    .IF eax == MUIAIT_NONE
    .ELSEIF eax == MUIAIT_BMP
        ;PrintText 'Deleteing bitmap'
        Invoke DeleteObject, hImage
    .ELSEIF eax == MUIAIT_ICO
        Invoke DestroyIcon, hImage
    .ELSEIF eax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke GdipDisposeImage, hImage
        ENDIF
    .ENDIF
    
    .IF dwFrameIndex == -1
        Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .ELSE
        mov eax, dwFrameIndex
    .ENDIF
    mov FrameIndex, eax
    
    ; Move remaining frames down over deleted frame
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, eax    
    sub eax, FrameIndex
    inc eax ; adjust for 0 based index
    mov ebx, SIZEOF _MUI_ANIMATION_FRAME
    mul ebx
    mov dwSizeRemainingFrames, eax
    
    mov eax, FrameData
    add eax, SIZEOF _MUI_ANIMATION_FRAME
    mov pRemainingFrames, eax
    Invoke RtlMoveMemory, FrameData, pRemainingFrames, dwSizeRemainingFrames
    
    ; null out end frame
    mov eax, FrameData
    add eax, dwSizeRemainingFrames
    sub eax, SIZEOF _MUI_ANIMATION_FRAME
    mov ebx, eax
    mov eax, NULL
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameType, eax
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    mov [ebx]._MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov [ebx]._MUI_ANIMATION_FRAME.lParam, eax
    
    ; Adjust total frames and free all memory if 0 total frames
    dec TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    .IF TotalFrames == 0
        Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        Invoke MUISetIntProperty, hControl, @AnimationFramesArray, NULL
    .ENDIF
    
    ; if deleting current frame, move to next one
    Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .IF eax == dwFrameIndex
        Invoke _MUI_AnimationNextFrameIndex, hControl
        .IF sdword ptr eax >= 0
            Invoke _MUI_AnimationNextFrameTime, hControl
        .ENDIF
    .ENDIF
    
    mov eax, TRUE
    ret
MUIAnimationDeleteFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationDeleteFrames - deletes all frames
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationDeleteFrames PROC hControl:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL pCurrentFrame:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL ImageType:DWORD
    LOCAL hImage:DWORD
    
    Invoke MUIGetIntProperty, hControl, @AnimationImageType
    mov ImageType, eax    
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF eax != NULL
        mov pAnimationFramesArray, eax
        mov pCurrentFrame, eax
        
        Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
        mov TotalFrames, eax
        
        mov FrameIndex, 0
        mov eax, 0
        .WHILE eax < TotalFrames
            mov ebx, pCurrentFrame
            
            mov eax, [ebx]._MUI_ANIMATION_FRAME.dwFrameImage ; get bitmap handle and delete object if it exists
            
            .IF eax != NULL
                mov hImage, eax
                
                mov eax, ImageType
                .IF eax == MUIAIT_BMP
                    ;PrintText 'Deleteing bitmap'
                    Invoke DeleteObject, hImage
                .ELSEIF eax == MUIAIT_ICO
                    Invoke DestroyIcon, hImage
                .ELSEIF eax == MUIAIT_PNG
                    IFDEF MUI_USEGDIPLUS
                    Invoke GdipDisposeImage, hImage
                    ENDIF
                .ENDIF
            .ENDIF
            
            add pCurrentFrame, SIZEOF _MUI_ANIMATION_FRAME
            inc FrameIndex
            mov eax, FrameIndex
        .ENDW
    
        Invoke GlobalFree, pAnimationFramesArray
        Invoke MUISetIntProperty, hControl, @AnimationFramesArray, NULL
    .ENDIF
    ret
MUIAnimationDeleteFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationAddFrame
;------------------------------------------------------------------------------
MUIAnimationAddFrame PROC USES EBX EDX hControl:DWORD, dwImageType:DWORD, lpMuiAnimationFrameStruct:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL FrameType:DWORD
    LOCAL FrameImage:DWORD
    LOCAL FrameTime:DWORD
    LOCAL FrameData:DWORD
    LOCAL dwSize:DWORD
    
    .IF hControl == NULL || dwImageType == NULL || lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, eax
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF eax == NULL
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF _MUI_ANIMATION_FRAME
        .IF eax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, eax
        mov FrameData, eax
    .ELSE
        mov pAnimationFramesArray, eax
        mov eax, TotalFrames
        inc eax
        mov ebx, SIZEOF _MUI_ANIMATION_FRAME
        mul ebx
        mov dwSize, eax
        Invoke GlobalReAlloc, pAnimationFramesArray, dwSize, GMEM_ZEROINIT or GMEM_MOVEABLE
        .IF eax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, eax
        add eax, dwSize
        sub eax, SIZEOF _MUI_ANIMATION_FRAME
        mov FrameData, eax
    .ENDIF
    
    Invoke MUISetIntProperty, hControl, @AnimationFramesArray, pAnimationFramesArray
    
    mov edx, FrameData
    mov ebx, lpMuiAnimationFrameStruct
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameType
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameType, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameImage
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameTime
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.lParam
    mov [edx]._MUI_ANIMATION_FRAME.lParam, eax
    
    inc TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, FrameTime
    
    mov eax, TRUE
    ret
MUIAnimationAddFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationAddFrames
;------------------------------------------------------------------------------
MUIAnimationAddFrames PROC hControl:DWORD, dwImageType:DWORD, lpArrayMuiAnimationFrameStructs:DWORD, dwCount:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL lpMuiAnimationFrameStruct:DWORD
    
    .IF hControl == NULL || dwImageType == NULL || lpArrayMuiAnimationFrameStructs == NULL || dwCount == NULL 
        xor eax, eax
        ret
    .ENDIF

    mov eax, lpArrayMuiAnimationFrameStructs
    mov lpMuiAnimationFrameStruct, eax
    mov FrameIndex, 0
    mov eax, 0
    .WHILE eax < dwCount
        Invoke MUIAnimationAddFrame, hControl, dwImageType, lpMuiAnimationFrameStruct
        .IF eax == FALSE
            xor eax, eax
            ret
        .ENDIF
        add lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
        inc FrameIndex
        mov eax, FrameIndex
    .ENDW
    mov eax, TRUE
    ret
MUIAnimationAddFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationLoadFrame - Loads a resource as an image frame to the Animation
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationLoadFrame PROC USES EBX hControl:DWORD, dwImageType:DWORD, lpMuiAnimationFrameStruct:DWORD
    LOCAL hinstance:DWORD
    LOCAL idResImage:DWORD
    LOCAL MAF:MUI_ANIMATION_FRAME
    
    IFDEF DEBUG32
    ;PrintText 'MUIAnimationLoadFrame'
    ENDIF
    
    .IF hControl == NULL || dwImageType == 0 || lpMuiAnimationFrameStruct == NULL  
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @AnimationDllInstance
    .IF eax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, eax    
    
    Invoke RtlMoveMemory, Addr MAF, lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
    
    lea ebx, MAF
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameImage
    .IF eax == NULL
        ret
    .ENDIF
    mov idResImage, eax
    
    mov eax, dwImageType
    .IF eax == MUIAIT_BMP
        Invoke LoadBitmap, hinstance, idResImage
    .ELSEIF eax == MUIAIT_ICO
        Invoke LoadImage, hinstance, idResImage, IMAGE_ICON, 0, 0, 0
    .ELSEIF eax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke _MUI_AnimationLoadPng, hinstance, idResImage
        ENDIF
    .ELSE
        xor eax, eax
        ret
    .ENDIF
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    ; eax contains image handle
    ; save image handle to copy of the animation frame
    lea ebx, MAF
    mov [ebx].MUI_ANIMATION_FRAME.dwFrameImage, eax
    
    Invoke MUIAnimationAddFrame, hControl, dwImageType, Addr MAF
    .IF eax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov eax, TRUE
    ret
MUIAnimationLoadFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationLoadFrames - Process an array of resource ids and load the resource
; and add them to the Animation control as image frames
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationLoadFrames PROC USES EBX EDX hControl:DWORD, dwImageType:DWORD, lpArrayMuiAnimationFrameStructs:DWORD, dwCount:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL lpMuiAnimationFrameStruct:DWORD
    
    .IF hControl == NULL || dwCount == NULL || dwImageType == NULL || lpArrayMuiAnimationFrameStructs == NULL
        xor eax, eax
        ret
    .ENDIF

    mov eax, lpArrayMuiAnimationFrameStructs
    mov lpMuiAnimationFrameStruct, eax
    mov FrameIndex, 0
    mov eax, 0
    .WHILE eax < dwCount
        Invoke MUIAnimationLoadFrame, hControl, dwImageType, lpMuiAnimationFrameStruct
        .IF eax == FALSE
            xor eax, eax
            ret
        .ENDIF
        add lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
        inc FrameIndex
        mov eax, FrameIndex
    .ENDW
    
    mov eax, TRUE
    ret
MUIAnimationLoadFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationInsertFrame
;------------------------------------------------------------------------------
MUIAnimationInsertFrame PROC USES EBX EDX hControl:DWORD, dwImageType:DWORD, lpMuiAnimationFrameStruct:DWORD, dwFrameIndex:DWORD, bInsertAfter:DWORD
    LOCAL pAnimationFramesArray:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL FrameIndex:DWORD
    LOCAL FrameType:DWORD
    LOCAL FrameImage:DWORD
    LOCAL FrameTime:DWORD
    LOCAL FrameData:DWORD
    LOCAL dwSize:DWORD
    LOCAL dwSizeRemainingFrames:DWORD
    LOCAL pRemainingFrames:DWORD
    
    .IF hControl == NULL || dwImageType == NULL || lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, eax
    .IF eax > 0
        .IF dwFrameIndex >= eax
            xor eax, eax
            ret
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF eax == NULL
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF _MUI_ANIMATION_FRAME
        .IF eax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, eax
        mov FrameData, eax
    .ELSE
        mov pAnimationFramesArray, eax
        mov eax, TotalFrames
        inc eax
        mov ebx, SIZEOF _MUI_ANIMATION_FRAME
        mul ebx
        mov dwSize, eax
        Invoke GlobalReAlloc, pAnimationFramesArray, dwSize, GMEM_ZEROINIT or GMEM_MOVEABLE
        .IF eax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, eax
        
        ; Calc frame data for specified index
        mov eax, dwFrameIndex
        mov ebx, SIZEOF _MUI_ANIMATION_FRAME
        mul ebx
        add eax, pAnimationFramesArray
        .IF bInsertAfter == TRUE
            add eax, SIZEOF _MUI_ANIMATION_FRAME
        .ENDIF
        mov FrameData, eax
        
        ; shift memory for inserting new frame
        mov eax, TotalFrames
        inc eax
        mov ebx, FrameIndex
        inc ebx
        .IF bInsertAfter == TRUE
            inc ebx
        .ENDIF
        sub eax, ebx
        .IF sdword ptr eax > 0
            mov ebx, SIZEOF _MUI_ANIMATION_FRAME
            mul ebx
            mov dwSizeRemainingFrames, eax
        
            mov eax, FrameData
            add eax, SIZEOF _MUI_ANIMATION_FRAME
            mov pRemainingFrames, eax
            Invoke RtlMoveMemory, FrameData, pRemainingFrames, dwSizeRemainingFrames
        .ENDIF
    .ENDIF
    
    Invoke MUISetIntProperty, hControl, @AnimationFramesArray, pAnimationFramesArray
    
    mov edx, FrameData
    mov ebx, lpMuiAnimationFrameStruct
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameType
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameType, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameImage
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameImage, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.dwFrameTime
    mov [edx]._MUI_ANIMATION_FRAME.dwFrameTime, eax
    mov eax, [ebx].MUI_ANIMATION_FRAME.lParam
    mov [edx]._MUI_ANIMATION_FRAME.lParam, eax
    
    inc TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, FrameTime    
    
    mov eax, TRUE
    ret
MUIAnimationInsertFrame ENDP

;------------------------------------------------------------------------------
; _MUI_AnimationTimerProc for TimerQueue
;------------------------------------------------------------------------------
IFDEF ANIMATION_USE_TIMERQUEUE
MUI_ALIGN
_MUI_AnimationTimerProc PROC USES EBX lpParam:DWORD, TimerOrWaitFired:DWORD
    ; lpParam is hControl
    Invoke _MUI_AnimationNextFrame, lpParam
    ret
_MUI_AnimationTimerProc ENDP
ENDIF

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrame - called by _MUI_AnimationTimerProc or WM_TIMER
; advances frame index to next frame and updates timer to new frame's time
;------------------------------------------------------------------------------
_MUI_AnimationNextFrame PROC hWin:DWORD
    
    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF
    
    ;Invoke MUIAnimationPause, hWin
    Invoke _MUI_AnimationTimerStop, hWin

    Invoke _MUI_AnimationNextFrameIndex, hWin
    .IF sdword ptr eax >= 0
        Invoke _MUI_AnimationNextFrameTime, hWin
    .ELSE 
        ; no frames or end of animation, so stop
        Invoke MUIAnimationStop, hWin
        ret
    .ENDIF
    
    Invoke InvalidateRect, hWin, NULL, TRUE
    Invoke UpdateWindow, hWin
    
    Invoke _MUI_AnimationTimerStart, hWin
    ;Invoke MUIAnimationResume, hWin ; timer is restarted with new frame time set in _MUI_AnimationNextFrameTime
     
    mov eax, TRUE
    ret
_MUI_AnimationNextFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationTimerStart
;------------------------------------------------------------------------------
_MUI_AnimationTimerStart PROC hWin:DWORD
    LOCAL dwTimeInterval:DWORD
    IFDEF ANIMATION_USE_TIMERQUEUE
    LOCAL hQueue:DWORD
    LOCAL hTimer:DWORD
    ENDIF

    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF eax == 0
        xor eax, eax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @AnimationFrameSpeed
    .IF eax == 0
        Invoke MUIGetIntProperty, hWin, @AnimationFrameTimeDefault
        .IF eax == 0
            mov eax, ANIMATION_FRAME_TIME_DEFAULT
        .ENDIF
    .ENDIF
    mov dwTimeInterval, eax    

    IFDEF ANIMATION_USE_TIMERQUEUE
        Invoke MUIGetIntProperty, hWin, @AnimationUseTimerQueue
        .IF eax == TRUE
            Invoke MUIGetIntProperty, hWin, @AnimationQueue
            mov hQueue, eax
            Invoke MUIGetIntProperty, hWin, @AnimationTimer
            mov hTimer, eax
            .IF hQueue != NULL ; re-use existing hQueue
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, dwTimeInterval, dwTimeInterval
                .IF eax == 0 ; failed 
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                    Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke SetTimer, hWin, hWin, dwTimeInterval, NULL
                .ENDIF
            .ELSE ; Try to create TimerQueue 
                Invoke CreateTimerQueue
                .IF eax != NULL
                    mov hQueue, eax
                    Invoke CreateTimerQueueTimer, Addr hTimer, hQueue, Addr _MUI_AnimationTimerProc, hWin, dwTimeInterval, dwTimeInterval, 0
                    .IF eax == 0 ; failed, so fall back to WM_TIMER usage
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                        Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                        Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                        Invoke SetTimer, hWin, hWin, dwTimeInterval, NULL
                    .ELSE ; Success! - so save TimerQueue handles for re-use
                        IFDEF DEBUG32
                        PrintText 'Using QueueTimer'
                        ENDIF
                        Invoke MUISetIntProperty, hWin, @AnimationQueue, hQueue
                        Invoke MUISetIntProperty, hWin, @AnimationTimer, hTimer
                    .ENDIF
                .ELSE ; failed, so fall back to WM_TIMER usage
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke SetTimer, hWin, hWin, dwTimeInterval, NULL
                .ENDIF
            .ENDIF
        .ELSE  ; Not using TimerQueue, previous failure?, so fall back to WM_TIMER usage
            Invoke SetTimer, hWin, hWin, dwTimeInterval, NULL
        .ENDIF
    ELSE ; compiled define says to use WM_TIMER instead
        Invoke SetTimer, hWin, hWin, dwTimeInterval, NULL
    ENDIF
    mov eax, TRUE
    ret
_MUI_AnimationTimerStart ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationTimerStop
;------------------------------------------------------------------------------
_MUI_AnimationTimerStop PROC hWin:DWORD
    IFDEF ANIMATION_USE_TIMERQUEUE
    LOCAL hQueue:DWORD
    LOCAL hTimer:DWORD
    ENDIF

    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF
    
    IFDEF ANIMATION_USE_TIMERQUEUE
        Invoke MUIGetIntProperty, hWin, @AnimationUseTimerQueue
        .IF eax == TRUE
            Invoke MUIGetIntProperty, hWin, @AnimationQueue
            mov hQueue, eax
            Invoke MUIGetIntProperty, hWin, @AnimationTimer
            mov hTimer, eax
            .IF hQueue != NULL
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, INFINITE, 0
                .IF eax == 0 ; failed, fall back to use KillTimer for WM_TIMER usage
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                    Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke KillTimer, hWin, hWin
                .ENDIF
            .ELSE ; fall back to use KillTimer for WM_TIMER usage
                Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                Invoke KillTimer, hWin, hWin
            .ENDIF
        .ELSE ; Not using TimerQueue, previous failure? back to use KillTimer for WM_TIMER usage
            Invoke KillTimer, hWin, hWin
        .ENDIF
    ELSE ; compiled define says to use WM_TIMER instead
        Invoke KillTimer, hWin, hWin
    ENDIF
    
    mov eax, TRUE
    ret
_MUI_AnimationTimerStop ENDP


;------------------------------------------------------------------------------
; Load JPG/PNG from resource using GDI+
;   Actually, this function can load any image format supported by GDI+
;
; by: Chris Vega
;
; Addendum KSR 2014 : Needs OLE32 include and lib for CreateStreamOnHGlobal and 
; GetHGlobalFromStream calls. Underlying stream needs to be left open for the 
; life of the bitmap or corruption of png occurs. store png as RCDATA in 
; resource file.
;------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUI_ALIGN
_MUI_AnimationLoadPng PROC hinstance:DWORD, idResPng:DWORD
    local rcRes:HRSRC
    local hResData:HRSRC
    local pResData:HANDLE
    local sizeOfRes:DWORD
    local hResBuffer:HANDLE
    local pResBuffer:DWORD
    local pIStream:DWORD
    local hIStream:DWORD
    LOCAL pImage:DWORD
    LOCAL pBitmapFromStream:DWORD
    LOCAL pGraphics:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD  

    ; ------------------------------------------------------------------
    ; STEP 1: Find the resource
    ; ------------------------------------------------------------------
    invoke  FindResource, hinstance, idResPng, RT_RCDATA
    or      eax, eax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     rcRes, eax
    
    ; ------------------------------------------------------------------
    ; STEP 2: Load the resource
    ; ------------------------------------------------------------------
    invoke  LoadResource, hinstance, rcRes
    or      eax, eax
    jnz     @f
    ret     ; Resource was not loaded
@@: mov     hResData, eax
    
    ; ------------------------------------------------------------------
    ; STEP 3: Create a stream to contain our loaded resource
    ; ------------------------------------------------------------------
    invoke  SizeofResource, hinstance, rcRes
    or      eax, eax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     sizeOfRes, eax
    
    invoke  LockResource, hResData
    or      eax, eax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     pResData, eax

    invoke  GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
    or      eax, eax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     hResBuffer, eax

    invoke  GlobalLock, hResBuffer
    mov     pResBuffer, eax
    
    invoke  RtlMoveMemory, pResBuffer, hResData, sizeOfRes
    invoke  CreateStreamOnHGlobal, pResBuffer, TRUE, Addr pIStream
    or      eax, eax
    jz      @f
    jmp     _MUIAnimationLoadPng@Close
@@: 

    ; ------------------------------------------------------------------
    ; STEP 4: Create an image object from stream
    ; ------------------------------------------------------------------
    invoke  GdipCreateBitmapFromStream, pIStream, Addr pBitmapFromStream
    invoke  GetHGlobalFromStream, pIStream, Addr hIStream
    
    ; ------------------------------------------------------------------
    ; STEP 5: Copy stream bitmap image to new ARGB 32bpp bitmap image
    ; ------------------------------------------------------------------
    mov pGraphics, 0
    Invoke GdipGetImageWidth, pBitmapFromStream, Addr dwImageWidth
    Invoke GdipGetImageHeight, pBitmapFromStream, Addr dwImageHeight    
    Invoke GdipCreateBitmapFromScan0, dwImageWidth, dwImageHeight, 0, PixelFormat32bppARGB, 0, Addr pImage
    Invoke GdipGetImageGraphicsContext, pImage, Addr pGraphics
    Invoke GdipDrawImage, pGraphics, pBitmapFromStream, 0, 0
    
    ; ------------------------------------------------------------------
    ; STEP 6: Free all used locks and resources
    ; ------------------------------------------------------------------
    .IF pGraphics != NULL
        Invoke GdipDeleteGraphics, pGraphics
    .ENDIF
    Invoke GlobalUnlock, hResBuffer
    Invoke GlobalFree, pResBuffer
    
    ; ------------------------------------------------------------------
    ; STEP 7: Set property and return pImage
    ; ------------------------------------------------------------------
    mov eax, pImage

_MUIAnimationLoadPng@Close:
    ret
_MUI_AnimationLoadPng endp
ENDIF




MODERNUI_LIBEND













