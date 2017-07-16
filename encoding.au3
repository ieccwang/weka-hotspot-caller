Func Asc2Unicode($AscString)
    Local $BufferSize = StringLen($AscString) * 2
    Local $Buffer = DllStructCreate("byte[" & $BufferSize & "]")
    Local $Return = DllCall("Kernel32.dll", "int", "MultiByteToWideChar", _
        "int", 0, _
        "int", 0, _
        "str", $AscString, _
        "int", StringLen($AscString), _
        "ptr", DllStructGetPtr($Buffer), _
        "int", $BufferSize)
    Local $UnicodeString = StringLeft(DllStructGetData($Buffer, 1), $Return[0] * 2)
    $Buffer = 0
    Return $UnicodeString
EndFunc

Func Unicode2Asc($UniString)
    If Not IsBinary($UniString) Then
        SetError(1)
        Return $UniString
    EndIf

    Local $BufferLen = StringLen($UniString)
    Local $Input = DllStructCreate("byte[" & $BufferLen & "]")
    Local $Output = DllStructCreate("char[" & $BufferLen & "]")
    DllStructSetData($Input, 1, $UniString)
    Local $Return = DllCall("kernel32.dll", "int", "WideCharToMultiByte", _
        "int", 0, _
        "int", 0, _
        "ptr", DllStructGetPtr($Input), _
        "int", $BufferLen / 2, _
        "ptr", DllStructGetPtr($Output), _
        "int", $BufferLen, _
        "int", 0, _
        "int", 0)
    Local $AscString = DllStructGetData($Output, 1)
    $Output = 0
    $Input = 0
    Return $AscString
EndFunc

Func Unicode2Utf8($UniString)
    If Not IsBinary($UniString) Then
        SetError(1)
        Return $UniString
    EndIf

    Local $UniStringLen = StringLen($UniString)
    Local $BufferLen = $UniStringLen * 2
    Local $Input = DllStructCreate("byte[" & $BufferLen & "]")
    Local $Output = DllStructCreate("char[" & $BufferLen & "]")
    DllStructSetData($Input, 1, $UniString)
    Local $Return = DllCall("kernel32.dll", "int", "WideCharToMultiByte", _
        "int", 65001, _
        "int", 0, _
        "ptr", DllStructGetPtr($Input), _
        "int", $UniStringLen / 2, _
        "ptr", DllStructGetPtr($Output), _
        "int", $BufferLen, _
        "int", 0, _
        "int", 0)
    Local $Utf8String = DllStructGetData($Output, 1)
    $Output = 0
    $Input = 0
    Return $Utf8String
EndFunc

Func Utf82Unicode($Utf8String)
    Local $BufferSize = StringLen($Utf8String) * 2
    Local $Buffer = DllStructCreate("byte[" & $BufferSize & "]")
    Local $Return = DllCall("Kernel32.dll", "int", "MultiByteToWideChar", _
        "int", 65001, _
        "int", 0, _
        "str", $Utf8String, _
        "int", StringLen($Utf8String), _
        "ptr", DllStructGetPtr($Buffer), _
        "int", $BufferSize)
    Local $UnicodeString = StringLeft(DllStructGetData($Buffer, 1), $Return[0] * 2)
    $Buffer = 0
    Return $UnicodeString
EndFunc