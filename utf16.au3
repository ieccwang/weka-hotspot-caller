Func string_encode_utf16($string)
   ;$string = StringToASCIIArray($string )
   ;$string = "[\u" & _ArrayToString($string, "][\u") & "]"

   Local $parts = StringToASCIIArray($string )
   $string = ""
   For $i = 0 to UBound($parts) -1
	  Local $part = $parts[$i]
	  If $part < 128 Then
		 Local $a[1] = [$part]
		 $part = StringFromASCIIArray($a)
	  Else
		 $part = "|\u" & $part & "|"
	  EndIf
	  $string = $string & $part
   Next

   ; 將逗點跟問號取代
   ;$string = StringReplace($string, "[\u44]", ",")
   ;$string = StringReplace($string, "[\u63]", "?")
   ;$string = StringReplace($string, "[\u10]", @LF)

   return $string
EndFunc

Func string_decode_utf16($string)
   Local $parts = StringSplit($string, "|\u", 1)
   ;_ArrayDisplay($parts)
   $string = $parts[1]
   For $i = 2 to $parts[0]
	  ;ConsoleWrite($parts[$i] & @CRLF)
	  Local $line = StringSplit($parts[$i], "|", 1)
	  ;_ArrayDisplay($line)
	  Local $part[1] = [$line[1]]
	  $part = StringFromASCIIArray($part)
	  $string = $string & $part & $line[2]
   Next
   return $string
EndFunc