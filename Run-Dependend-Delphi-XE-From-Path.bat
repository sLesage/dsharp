@echo off
  call :do cd %~dp0
  call :do call Dependencies Set
  :: Rad Studio:  "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\bds.exe"
  :: Delphi:      "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\bds.exe" -pDelphi
  :: C++ Builder  "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\bds.exe" -pCBuilder
  :: call :do start bds.exe -pDelphi
  :: XE: "C:\Program Files (x86)\Embarcadero\RAD Studio\8.0\bin\bds.exe"
  call :do start "Delphi XE" "C:\Program Files (x86)\Embarcadero\RAD Studio\8.0\bin\bds.exe" -pDelphi
  pause
  goto :eof
:do
  echo %*
  %*
  goto :eof
