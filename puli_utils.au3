Func set_full_path($path)
   If StringInStr($path, ".\") == 1 Then
	  $path = @ScriptDir & StringMid($path,2)
   EndIf
   $path = $path
   return $path
EndFunc

Func set_full_path_quote($path)
   If StringInStr($path, ".\") == 1 Then
	  $path = @ScriptDir & StringMid($path,2)
   EndIf
   $path = '"' & $path & '"'
   return $path
EndFunc

Func trim($str)
   return StringStripWS($str, $STR_STRIPLEADING + $STR_STRIPTRAILING)
EndFunc