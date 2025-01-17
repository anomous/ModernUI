;==============================================================================
;
; ModernUI Library v0.0.0.6
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



;------------------------------------------------------------------------------
; ModernUI Prototypes
;------------------------------------------------------------------------------
; ModernUI Base Functions:
MUIGetExtProperty               PROTO :DWORD,:DWORD                             ; hControl, dwProperty
MUISetExtProperty               PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwProperty, dwPropertyValue
MUIGetIntProperty               PROTO :DWORD,:DWORD                             ; hControl, dwProperty
MUISetIntProperty               PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwProperty, dwPropertyValue

MUIGetExtPropertyEx             PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwParentProperty, dwChildProperty
MUISetExtPropertyEx             PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hControl, dwParentProperty, dwChildProperty, dwPropertyValue
MUIGetIntPropertyEx             PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwParentProperty, dwChildProperty
MUISetIntPropertyEx             PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hControl, dwParentProperty, dwChildProperty, dwPropertyValue

MUIGetExtPropertyExtra          PROTO :DWORD,:DWORD                             ; hControl, dwProperty
MUISetExtPropertyExtra          PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwProperty, dwPropertyValue
MUIGetIntPropertyExtra          PROTO :DWORD,:DWORD                             ; hControl, dwProperty
MUISetIntPropertyExtra          PROTO :DWORD,:DWORD,:DWORD                      ; hControl, dwProperty, dwPropertyValue

; ModernUI Memory Functions:
MUIAllocMemProperties           PROTO :DWORD,:DWORD,:DWORD                      ; hControl, cbWndExtraOffset, dwSizeToAllocate
MUIFreeMemProperties            PROTO :DWORD,:DWORD                             ; hControl, cbWndExtraOffset
MUIAllocStructureMemory         PROTO :DWORD,:DWORD,:DWORD                      ; dwPtrStructMem, TotalItems, ItemSize

; ModernUI GDI Functions:
MUIGDIDoubleBufferStart         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD        ; hWin, hdcSource, lpHDCBuffer, lpClientRect, lphBufferBitmap
MUIGDIDoubleBufferFinish        PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD ; hdcBuffer, hBufferBitmap, hBitmapUsed, hFontUsed, hBrushUsed, hPenUsed
MUIGDIBlend                     PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, hdc, dwColor, dwBlendLevel
MUIGDIBlendBitmaps              PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hBitmap1, hBitmap2, dwColorBitmap2, dwTransparency
MUIGDIStretchBitmap             PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD ; hBitmap, lpBoundsRect, lpdwBitmapWidth, lpdwBitmapHeight, lpdwX, lpdwY
MUIGDIStretchImage              PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD ; hImage, dwImageType, lpBoundsRect, lpdwImageWidth, lpdwImageHeight, lpdwImageX, lpdwImageY
MUIGDIRotateCenterBitmap        PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, hBitmap, dwAngle, dwBackColor
MUIGDIPaintFill                 PROTO :DWORD,:DWORD,:DWORD                      ; hdc, lpFillRect, dwFillColor
MUIGDIPaintFrame                PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hdc, lpFrameRect, dwFrameColor, dwFrameStyle

; ModernUI GDIPlus Functions:
MUIGDIPlusStart                 PROTO                                           ; Wrapper for GDIPlus startup
MUIGDIPlusFinish                PROTO                                           ; Wrapper for GDIPlus shutdown
MUIGDIPlusDoubleBufferStart     PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, pGraphics, lpBitmapHandle, lpGraphicsBuffer
MUIGDIPlusDoubleBufferFinish    PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, pGraphics, hBitmap, pGraphicsBuffer
MUIGDIPlusRotateCenterImage     PROTO :DWORD,:REAL4                             ; hImage, fAngle
MUIGDIPlusPaintFill             PROTO :DWORD,:DWORD,:DWORD                      ; pGraphics, lpFillGdipRect, dwFillColor
MUIGDIPlusPaintFillI            PROTO :DWORD,:DWORD,:DWORD                      ; pGraphics, lpFillRectI, dwFillColor
MUIGDIPlusPaintFrame            PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; pGraphics, lpFrameGdipRect, dwFrameColor, dwFrameStyle
MUIGDIPlusPaintFrameI           PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; pGraphics, lpFrameRectI, dwFrameColor, dwFrameStyle
MUILoadPngFromResource          PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, dwInstanceProperty, dwProperty, idPngRes
MUIGDIPlusRectToGdipRect        PROTO :DWORD,:DWORD                             ; lpRect, lpGdipRect

; GDIPlus aliases:
MUIGDIPStart                    TEXTEQU <MUIGDIPlusStart>                       ; Wrapper for GDIPlus startup
MUIGDIPFinish                   TEXTEQU <MUIGDIPlusFinish>                      ; Wrapper for GDIPlus shutdown
MUIGDIPDoubleBufferStart        TEXTEQU <MUIGDIPlusDoubleBufferStart>           ; hWin, pGraphics, lpBitmapHandle, lpGraphicsBuffer
MUIGDIPDoubleBufferFinish       TEXTEQU <MUIGDIPlusDoubleBufferFinish>          ; hWin, pGraphics, hBitmap, pGraphicsBuffer
MUIGDIPRotateCenterImage        TEXTEQU <MUIGDIPlusRotateCenterImage>           ; hImage, fAngle, dwBackColor
MUIGDIPPaintFill                TEXTEQU <MUIGDIPlusPaintFill>                   ; pGraphics, lpFillGdipRect, dwFillColor
MUIGDIPPaintFillI               TEXTEQU <MUIGDIPlusPaintFillI>                  ; pGraphics, lpFillRectI, dwFillColor
MUIGDIPPaintFrame               TEXTEQU <MUIGDIPlusPaintFrame>                  ; pGraphics, lpFrameGdipRect, dwFrameColor, dwFrameStyle
MUIGDIPPaintFrameI              TEXTEQU <MUIGDIPlusPaintFrameI>                 ; pGraphics, lpFrameRectI, dwFrameColor, dwFrameStyle
MUILoadJpgFromResource          TEXTEQU <MUILoadPngFromResource>                ; hWin, dwInstanceProperty, dwProperty, idJpgRes
MUIGDIPRectToGdipRect           TEXTEQU <MUIGDIPlusRectToGdipRect>              ; lpRect, lpGdipRect

; ModernUI Painting & Color Functions:
MUIPaintBackground              PROTO :DWORD,:DWORD,:DWORD                      ; hDialogWindow, dwBackColor, dwBorderColor
MUIPaintBackgroundImage         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD ; hDialogWindow, dwBackColor, dwBorderColor, hImage, dwImageType, dwImageLocation
MUIGetParentBackgroundColor     PROTO :DWORD                                    ; hControl
MUIGetParentBackgroundBitmap    PROTO :DWORD                                    ; hControl

; ModernUI Window/Dialog Functions:
MUIApplyToDialog                PROTO :DWORD,:DWORD,:DWORD                      ; hDialogWindow, dwDropShadow (true to set drop shadow), dwClipping (true to set clipping on)
MUICenterWindow                 PROTO :DWORD,:DWORD                             ; hWndChild, hWndParent
MUIGetParentRelativeWindowRect  PROTO :DWORD,:DWORD                             ; hControl, lpRectControl

; ModernUI Region Functions:
MUILoadRegionFromResource       PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hInstance, idRgnRes, lpRegion, lpdwSizeRegion
MUISetRegionFromResource        PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, idRgnRes, lpdwCopyRgn, bRedraw

; ModernUI Font Functions:
MUIPointSizeToLogicalUnit       PROTO :DWORD,:DWORD                             ; hControl, dwPointSize

; ModernUI Image Functions:
MUIGetImageSize                 PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hImage, dwImageType, lpdwImageWidth, lpdwImageHeight
MUIGetImageSizeEx               PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD ; hWin, hImage, dwImageType, lpdwImageWidth, lpdwImageHeight, lpdwImageXPos, lpdwImageYPos
MUICreateIconFromMemory         PROTO :DWORD,:DWORD                             ; pIconData, iIcon
MUICreateCursorFromMemory       PROTO :DWORD                                    ; pCursorData
MUICreateBitmapFromMemory       PROTO :DWORD                                    ; pBitmapData
MUILoadBitmapFromResource       PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, dwInstanceProperty, dwProperty, idBmpRes
MUILoadIconFromResource         PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; hWin, dwInstanceProperty, dwProperty, idIcoRes
MUILoadImageFromResource        PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD        ; hWin, dwInstanceProperty, dwProperty, dwImageType, dwImageResId

; ModernUI DPI & Scaling Functions:
MUIDPI                          PROTO :DWORD,:DWORD                             ; lpdwDPIX, lpdwDPIY
MUIDPIScaleX                    PROTO :DWORD                                    ; dwValueX
MUIDPIScaleY                    PROTO :DWORD                                    ; dwValueY
MUIDPIScaleRect                 PROTO :DWORD                                    ; lpRect
MUIDPIScaleControl              PROTO :DWORD,:DWORD,:DWORD,:DWORD               ; lpdwLeft, lpdwTop, lpdwWidth, lpdwHeight
MUIDPIScaleFontSize             PROTO :DWORD                                    ; dwPointSize
MUIDPIScaleFont                 PROTO :DWORD                                    ; hFont
MUIDPIScaledScreen              PROTO :DWORD,:DWORD                             ; lpdwScreenWidth, lpdwScreenHeight
MUIDPISetDPIAware               PROTO

.CONST
IFDEF MODERNUI_DLL
    MODERNUI_LIBEND TEXTEQU <>
ELSE
    MODERNUI_LIBEND TEXTEQU <END>
ENDIF

;------------------------------------------
; Define MUI_USEGDIPLUS to compile
; gdiplus support into ModernUI library 
; Other controls can force this off by
; defining MUI_DONTUSEGDIPLUS if they
; wish to exclude gdiplus support
;------------------------------------------
IFNDEF MUI_DONTUSEGDIPLUS
MUI_USEGDIPLUS                  EQU 1               ; Use GDI+ or not
ENDIF

;------------------------------------------
; Global constants used by all ModernUI
; controls. 
;------------------------------------------
MUI_INTERNAL_PROPERTIES         EQU 0               ; cbWndExtra offset for internal properties pointer
MUI_EXTERNAL_PROPERTIES         EQU 4               ; cbWndExtra offset for external properties pointer
MUI_INTERNAL_PROPERTIES_EXTRA   EQU 8               ; cbWndExtra offset for extra internal properties pointer
MUI_EXTERNAL_PROPERTIES_EXTRA   EQU 12              ; cbWndExtra offset for extra external properties pointer
MUI_PROPERTY_ADDRESS            EQU 80000000h       ; OR with dwProperty in MUIGetIntProperty/MUIGetExtProperty to return address of property 

MUI_ALIGN                       TEXTEQU <ALIGN 16>

;------------------------------------------
; ModernUI Custom Messages - each control 
; should handle these
;------------------------------------------
MUI_GETPROPERTY                 EQU WM_USER + 1800  ; wParam = dwProperty, lParam = NULL
MUI_SETPROPERTY                 EQU WM_USER + 1799  ; wParam = dwProperty, lParam = dwPropertyValue
;MUI_GETTHEME                   EQU WM_USER + 1798  ; wParam = NULL, lParam = NULL. Returns in eax lpMUITHEMEStructure
;MUI_SETTHEME                   EQU WM_USER + 1797  ; wParam = lpMUITHEMEStructure, lParam = NULL

;------------------------------------------
; Image Types
;------------------------------------------
MUIIT_NONE                      EQU 0
MUIIT_BMP                       EQU 1
MUIIT_ICO                       EQU 2
MUIIT_PNG                       EQU 3

;------------------------------------------
; Image Locations
;------------------------------------------
MUIIL_CENTER                    EQU 0
MUIIL_BOTTOMLEFT                EQU 1
MUIIL_BOTTOMRIGHT               EQU 2
MUIIL_TOPLEFT                   EQU 3
MUIIL_TOPRIGHT                  EQU 4
MUIIL_TOPCENTER                 EQU 5
MUIIL_BOTTOMCENTER              EQU 6

;------------------------------------------
; MUIGDIPaintFrame Frame Style
;------------------------------------------
MUIPFS_NONE                     EQU 0
MUIPFS_LEFT                     EQU 1
MUIPFS_TOP                      EQU 2
MUIPFS_BOTTOM                   EQU 4
MUIPFS_RIGHT                    EQU 8
MUIPFS_ALL                      EQU MUIPFS_LEFT + MUIPFS_TOP + MUIPFS_BOTTOM + MUIPFS_RIGHT

;------------------------------------------
; ModernUI Macros
;------------------------------------------
MUI_ARGBCOLOR MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

AlphaRGB MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

MUI_RGBCOLOR MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

RGB MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

;------------------------------------------
; ModernUI Structures
;------------------------------------------
IFNDEF GDIPRECT
GDIPRECT     STRUCT
    left     REAL4 ?
    top	     REAL4 ?
    right	 REAL4 ?
    bottom	 REAL4 ?
GDIPRECT     ENDS
ENDIF


;------------------------------------------
; Notes
;------------------------------------------
; Custom controls: dwStyle parameter of 
; CreateWindowEx.
;
; The low 16 bits of the dwStyle parameter 
; are defined by the implementor of the 
; window class (by the person who calls 
; RegisterClass) - Raymond Chen
;
; 0x0h - 0xFFFFh reserved for user creating
; the control to define styles
;------------------------------------------


;------------------------------------------
; Remove comment to include debug32 macros
;------------------------------------------
;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF
;------------------------------------------


;------------------------------------------
; Remove comment to include unicode support
;------------------------------------------
;MUI_UNICODE TEXTEQU <__UNICODE__>
;IFDEF MUI_UNICODE
;__UNICODE__ EQU 1
;ECHO MUI_UNICODE BUILD
;ENDIF
;------------------------------------------








