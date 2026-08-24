Unicode true
SetCompressor lzma
RequestExecutionLevel user

!include "MUI2.nsh"

Name "OpenPNGStudio"
InstallDir "$LOCALAPPDATA\OpenPNGStudio"
OutFile "installer.exe"

!define MUI_ABORTWARNING
!define MUI_ICON "logo.ico"

!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define FINAL_PAGE_BITMAP "finish.bmp"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\COPYING"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!include "FinishPage.nsh"
!insertmacro INSERT_FINAL_PAGE "finish.bmp"

!insertmacro MUI_LANGUAGE "English"

!ifndef IDIR
  !define IDIR "build\_install"
!endif

Function .onInit
  SetRegView 64
FunctionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

Section "C3 Compiler"
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "..\..\COPYING"
  File "..\..\README.md"

  SetOutPath "$INSTDIR\bin"
  File /nonfatal /r "..\..\${IDIR}\bin\*"

  SetOutPath "$INSTDIR\share"
  File /nonfatal /r "..\..\${IDIR}\share\*"

  WriteUninstaller "$INSTDIR\uninstall.exe"

  CreateShortcut "$DESKTOP\OpenPNGStudio.lnk" "$INSTDIR\bin\OpenPNGStudio.exe"

  CreateDirectory "$SMPROGRAMS\OpenPNGStudio"
  CreateShortcut "$SMPROGRAMS\OpenPNGStudio\OpenPNGStudio.lnk" "$INSTDIR\bin\OpenPNGStudio.exe"

  WriteRegStr HKCU "Software\Classes\.opng" "" "OpenPNGStudio.Project"

  WriteRegStr HKCU "Software\Classes\OpenPNGStudio.Project" "" "OpenPNGStudio Model"
  WriteRegStr HKCU "Software\Classes\OpenPNGStudio.Project\DefaultIcon" "" "$INSTDIR\bin\OpenPNGStudio.exe,0"
  WriteRegStr HKCU "Software\Classes\OpenPNGStudio.Project\shell\open\command" "" '"$INSTDIR\bin\OpenPNGStudio.exe" "%1"'

  System::Call 'Shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\COPYING"
  Delete "$INSTDIR\uninstall.exe"
  Delete "$INSTDIR\README.md"
  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\share"

  Delete "$DESKTOP\OpenPNGStudio.lnk"
  Delete "$SMPROGRAMS\OpenPNGStudio\OpenPNGStudio.lnk"
  RMDir "$SMPROGRAMS\OpenPNGStudio"

  DeleteRegKey HKCU "Software\Classes\.opng"
  DeleteRegKey HKCU "Software\Classes\OpenPNGStudio.Project"

  System::Call 'Shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'

  RMDir "$INSTDIR"
SectionEnd