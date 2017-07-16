

Func _ConvertAnsiToUtf8($sText)
    Local $tUnicode = _WBD_WinAPI_MultiByteToWideChar($sText)
    If @error Then Return SetError(@error, 0, "")
    Local $sUtf8 = _WBD_WinAPI_WideCharToMultiByte(DllStructGetPtr($tUnicode), 65001)
    If @error Then Return SetError(@error, 0, "")
    Return SetError(0, 0, $sUtf8)
EndFunc   ;==>_ConvertAnsiToUtf8

Func _WBD_WinAPI_MultiByteToWideChar($sText, $iCodePage = 0, $iFlags = 0)
    Local $iText, $pText, $tText

    $iText = StringLen($sText) + 1
    $tText = DllStructCreate("wchar[" & $iText & "]")
    $pText = DllStructGetPtr($tText)
    DllCall("Kernel32.dll", "int", "MultiByteToWideChar", "int", $iCodePage, "int", $iFlags, "str", $sText, "int", $iText, "ptr", $pText, "int", $iText)
    If @error Then Return SetError(@error, 0, $tText)
    Return $tText
EndFunc   ;==>_WBD_WinAPI_MultiByteToWideChar

Func _WBD_WinAPI_WideCharToMultiByte($pUnicode, $iCodePage = 0)
    Local $aResult, $tText, $pText

    $aResult = DllCall("Kernel32.dll", "int", "WideCharToMultiByte", "int", $iCodePage, "int", 0, "ptr", $pUnicode, "int", -1, "ptr", 0, "int", 0, "int", 0, "int", 0)
    If @error Then Return SetError(@error, 0, "")
    $tText = DllStructCreate("char[" & $aResult[0] + 1 & "]")
    $pText = DllStructGetPtr($tText)
    $aResult = DllCall("Kernel32.dll", "int", "WideCharToMultiByte", "int", $iCodePage, "int", 0, "ptr", $pUnicode, "int", -1, "ptr", $pText, "int", $aResult[0], "int", 0, "int", 0)
    If @error Then Return SetError(@error, 0, "")
    Return DllStructGetData($tText, 1)
EndFunc   ;==>_WBD_WinAPI_WideCharToMultiByte