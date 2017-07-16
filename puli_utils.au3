Func set_full_path($path)
   If StringInStr($path, ".\") == 1 Then
	  $path = @ScriptDir & StringMid($path,2)
   EndIf
   $path = $path
   return $path
EndFunc

; -----------------

Func set_full_path_quote($path)
   If StringInStr($path, ".\") == 1 Then
	  $path = @ScriptDir & StringMid($path,2)
   EndIf
   $path = '"' & $path & '"'
   return $path
EndFunc

; -----------------

Func trim($str)
   return StringStripWS($str, $STR_STRIPLEADING + $STR_STRIPTRAILING)
EndFunc

; -----------------

Func array_push(ByRef $array, $item)
   If IsArray($item) Then
	  Local $a[1] = [$item]
	  $item = $a
   EndIf
   return _ArrayAdd($array, $item, 0, False)
EndFunc

; ---------------------
Func array_last(ByRef $array)
   $count = array_count($array);
   return $array[$count -1]
EndFunc

; -----------------

Func array_join($array, $delimiter)
   return _ArrayToString($array, $delimiter)
EndFunc

; -----------------

Func array_count(ByRef $array)
   return UBound($array)
EndFunc

; -----------------

Func console_log($message)
   ConsoleWrite($message & @CRLF)
EndFunc

; -----------------

Func string_split($string, $delimiter)
   return StringSplit($string, $delimiter, 1)
EndFunc

; -----------------

Func string_append(ByRef $string, $message)
   $string = $string & $message
EndFunc