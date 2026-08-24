!ifndef FINAL_PAGE_NSH_INCLUDED
!define FINAL_PAGE_NSH_INCLUDED

Function SwapFinishBitmap
  InitPluginsDir
  File /oname=$PLUGINSDIR\modern-wizard.bmp "${FINAL_PAGE_BITMAP}"
FunctionEnd

!macro INSERT_FINAL_PAGE BITMAP_PATH
  !define MUI_PAGE_CUSTOMFUNCTION_PRE SwapFinishBitmap
  !insertmacro MUI_PAGE_FINISH
!macroend

!endif