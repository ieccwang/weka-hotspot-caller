#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <AutoItConstants.au3>
#include <puli_utils.au3>
#include <WinAPI.au3>
#include <utf16.au3>
#pragma compile(Icon, 'weka-icon.ico')

; -----------------------------
; 取得資料

$extapp_weka = IniRead ( @ScriptDir & "\config.ini", "weka", "extapp_weka", "C:\Program Files\Weka-3-8\weka.jar" )
$extapp_weka = set_full_path_quote($extapp_weka)

$train_set_dir = IniRead ( @ScriptDir & "\config.ini", "weka", "train_set_dir", ".\input" )
$train_set_dir = set_full_path($train_set_dir) & "\"

;MsgBox(0, "weka_hotspot.au3", $train_set_dir & "\")

$result_output_dir = IniRead ( @ScriptDir & "\config.ini", "weka", "result_output_dir", ".\output" )
$result_output_dir = set_full_path($result_output_dir) & "\"

$hotspot_targetIndex = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_targetIndex", "last" )
$hotspot_support = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_support", "0.33" )
$hotspot_max_branching_factor = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_max_branching_factor", "2" )
$hotspot_max_rule_length = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_max_rule_length", "-1" )

$hotspot_rhs_item_full = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_rhs_item_full", "false" )
If $hotspot_rhs_item_full = "false" Then
   $hotspot_rhs_item_full = False
Else
   $hotspot_rhs_item_full = True
EndIf

$hotspot_analyze_min = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_analyze_min", "true" )
If $hotspot_analyze_min = "false" Then
   $hotspot_analyze_min = False
Else
   $hotspot_analyze_min = True
EndIf

$hotspot_target_analyze_all = IniRead ( @ScriptDir & "\config.ini", "weka", "hotspot_target_analyze_all", "true" )
If $hotspot_target_analyze_all = "false" Then
   $hotspot_target_analyze_all = False
Else
   $hotspot_target_analyze_all = True
EndIf

$weka_command = "weka.associations.HotSpot"

Local $sTempFile = _TempFile(@ScriptDir & "\tmp", "weak_hotspot_", ".csv")

; -----------------------------

Func weka_command_builder($train_file, $param, $minimize_target)
   $ext = stringRight($train_file, 4)
   Local $cmd_weka = @comspec & ' /C Java -Dfile.encoding=utf-8 -cp ' & $extapp_weka & ' weka.Run ' & $weka_command & ' -t "' & $train_file & '" -c ' & $hotspot_targetIndex & ' -V ' & $param & ' -S ' & $hotspot_support & ' -M ' & $hotspot_max_branching_factor & ' -length ' & $hotspot_max_rule_length & ' -I 0.01 '

   If $minimize_target = True Then
	  $cmd_weka = $cmd_weka & " -L "
   EndIf

   ;console_log($cmd_weka)
   Local $cmd_weka2 = $cmd_weka & " -R"
   ;If $ext = "csv" Then
	  ; CSV的指令
   ;EndIf
   Local $commands[2] = [$cmd_weka, $cmd_weka2]
   return $commands
EndFunc

; -----------------------------

Func weka_result_format_builder($weka_result)
   ; ------------------------------------------
   ; 找出需要的程式碼

   Local $parts = string_split($weka_result, @LF & @LF)
   Local $result = $parts[2]
   $result = trim($result)
   ;MsgBox(0, "weka_hotspot.au3", $result)
   $weka_result = $result

   If $weka_result = "" Then
	  Return
   EndIf

   If StringInStr($weka_result, "  <conf:(") = 0 Then
	  weka_result_format_builder_tree($weka_result)
   Else
	  weka_result_format_builder_rule($weka_result)
   EndIf
EndFunc

; ------------------------------------------

Func weka_result_format_builder_tree($weka_result)
   If $weka_result = "" Then
	  Return
   EndIf

   ;console_log($weka_result)

   ; 找出需要的變數
   Local $lines = StringSplit($weka_result, @LF & " ", 1)

   ;console_log($lines[1])
   Local $rhs = string_split($lines[1], ' (')
   ;console_log($rhs[0])
   Local $rhs_item = trim($rhs[1])

   If $hotspot_rhs_item_full = False And StringInStr($rhs_item, "=") Then
	  $rhs_item = string_split($rhs_item, '=')[2]
   EndIf

   Local $rhs_index = trim(StringTrimRight($rhs[2],1))
   ;MsgBox(0, "weka_hotspot.au3", $rhs_index)
   ;Exit

   ; 然後是LHS
   Local $lhs_item[0] = []
   Local $lhs_last_item[0] = []
   Local $lhs_index[0] = []
   For $i = 2 to $lines[0]
	  Local $line = $lines[$i]
	  Local $lhs = StringSplit($line, ' (', 1)
	  ;Local $lhs = string_split($line, ' (')
	  console_log($lhs);
	  Local $item = trim($lhs[1])

	  Local $last_item = string_split($item, "| ")
	  $last_item = array_last($last_item)
	  $last_item = StringReplace($last_item, " = ", "=")
	  $last_item = trim($last_item)

	  Local $index = trim(StringTrimRight($lhs[2],1))

	  ; 把index再處理的複雜一點
	  Local $conf_percent = string_split($index, " [")[1]
	  Local $match = string_split($index, " [")[2]
	  $match = string_split($match, "/")[1]
	  Local $all = string_split($index, "/")[2]
	  $all = string_split($all, "]")[1]

	  If $item <> "" Then
		 array_push($lhs_item, $item)
		 array_push($lhs_last_item, $last_item)
		 Local $index_array[3] = [$conf_percent, $match, $all]
		 array_push($lhs_index, $index_array)
	  EndIf
   Next

   ; --------------------------------
   Local $a[5] = [$rhs_item, $rhs_index, $lhs_item, $lhs_index, $lhs_last_item]

   array_push($target_array, $a)
EndFunc

; -----------------------------
Func weka_result_format_builder_rule($weka_result)
   If $weka_result = "" Then
	  Return
   EndIf

   Local $lines = string_split($weka_result, @LF)
   For $i = 1 to $lines[0]
	  Local $line = $lines[$i]
	  Local $lhs_items = string_split($line, " ==> ")
	  $lhs_items = $lhs_items[1]
	  $lhs_items = string_split($lhs_items, "]: ")
	  $lhs_items = $lhs_items[1]
	  $lhs_items = string_split($lhs_items, "[")
	  $lhs_items = $lhs_items[2]
	  ;console_log($lhs_items)

	  ; RHS
	  Local $rhs_item = string_split($line, " ==> [")[2]
	  $rhs_item = string_split($rhs_item, "]: ")[1]

	  If $hotspot_rhs_item_full = False Then
		 $rhs_item = string_split($rhs_item, '=')[2]
	  EndIf

	  ; 最後一條規則
	  Local $last_item = string_split($lhs_items, ", ")
	  $last_item = array_last($last_item)
	  ;console_log($last_item)

	  ; ---------------------------------------
	  Local $all = string_split($line, "]: ")[2]
	  $all = string_split($all, " ==> [")[1]
	  ;console_log($all)

	  Local $match = string_split($line, "]: ")[3]
	  $match = string_split($match, "   <conf:(")[1]
	  ;console_log($match)

	  ; ---------------------------------------

	  Local $needle = " lift:("
	  Local $lhs_indexes = string_split($lines[$i], $needle)
	  $lhs_indexes = $lhs_indexes[2]
	  $lhs_indexes = $needle & $lhs_indexes
	  $lhs_indexes = trim($lhs_indexes)

	  ; 切割吧
	  Local $lift = string_split($lhs_indexes, ") lev:(")[1]
	  $lift = string_split($lift, "lift:(")[2]
	  Local $lev = string_split($lhs_indexes, ") conv:(")[1]
	  $lev = string_split($lev, ") lev:(")[2]
	  Local $conv = string_split($lhs_indexes, ") conv:(")[2]
	  $conv = string_split($conv, ")")[1]

	  ;console_log($lift)
	  ;console_log($lev)
	  ;console_log($conv)

	  Local $a[7] = [$rhs_item, $last_item, $match, $all, $lift, $lev, $conv]
	  array_push($rule_target_array, $a)
   Next
EndFunc

; -----------------------------
Func hotspot_result_table_builder()
   ;_ArrayDisplay($target_array)
   Local $result = '<table border="1" width="100%">'
   string_append($result, '<thead><tr>')
   If $hotspot_rhs_item_full = True Then
	  string_append($result, '<td>RHS item</td><td>RHS index</td><td>LHS itemset</th>')
   Else
	  string_append($result, '<td>RHS</td><td>LHS itemset</th>')
   EndIf

   If $hotspot_rhs_item_full = True Then
	  string_append($result, '<td>all</td><td>match</td>')
   Else
	  string_append($result, '<td>cover</td>')
   EndIf
   string_append($result, '<td>conf</td><td>lift</td><td>lev</td><td>conv</td>')
   string_append($result, '</tr></thead>')
   string_append($result, '<tbody>')
   For $t = 0 to array_count($target_array) -1
	  Local $target_item = $target_array[$t]
	  If IsArray($target_item) = False Then
		 ContinueLoop
	  EndIf

	  ;_ArrayDisplay($target_item)
	  Local $rhs_item = $target_item[0]
	  Local $rhs_index = $target_item[1]
	  Local $lhs_item = $target_item[2]
	  Local $lhs_index = $target_item[3]
	  Local $lhs_last_item = $target_item[4]

	  For $i = 0 to array_count($lhs_item)-1
		 string_append($result, "<tr>")


		 If $i = 0 Then
			If $hotspot_rhs_item_full = True Then
			   string_append($result, '<td rowspan="' & array_count($lhs_item) & '" valign="top">')
			   string_append($result, $rhs_item)
			   string_append($result, "</td>")

			   string_append($result, '<td rowspan="' & array_count($lhs_item) & '" valign="top">')
			   string_append($result, $rhs_index)
			   string_append($result, "</td>")
			Else
			   string_append($result, '<td rowspan="' & array_count($lhs_item) & '" valign="top">')
			   string_append($result, $rhs_item & ": " & $rhs_index)
			   string_append($result, "</td>")
			EndIf
		 EndIf

		 ;MsgBox(0, $i, $lhs_item[$i])
		 Local $lhs_item_display = $lhs_item[$i]
		 $lhs_item_display = StringReplace($lhs_item_display, " = ", "=")
		 string_append($result, "<td>" & $lhs_item_display & "</td>")
		 Local $index_array = $lhs_index[$i]

		 If $hotspot_rhs_item_full = True Then
			string_append($result, "<td>" & $index_array[2] & "</td>")
			string_append($result, "<td>" & $index_array[1] & "</td>")
		 Else
			string_append($result, '<td nowrap>' & $index_array[1] & "/" & $index_array[2] & "</td>")
		 EndIf
		 string_append($result, "<td>" & $index_array[0] & "</td>")

		 ; 找尋其他index
		 Local $last_item = $lhs_last_item[$i]
		 ;console_log($last_item)
		 Local $match = $index_array[1]
		 Local $all = $index_array[2]
		 For $j = 0 to array_count($rule_target_array) -1
			$rule = $rule_target_array[$j]
			If $rule[0] = $rhs_item And $rule[1] = $last_item And $rule[2] = $match And $rule[3] = $all Then
			   string_append($result, '<td nowrap>' & $rule[4] & "</td>")
			   string_append($result, '<td nowrap>' & $rule[5] & "</td>")
			   string_append($result, '<td nowrap>' & $rule[6] & "</td>")
			   ExitLoop
			EndIf
		 Next

		 string_append($result, "</tr>")
	  Next
   Next

   $result = $result & "</tbody></table>"
   return $result
EndFunc

; -----------------------------

Func run_weka_command($filename, $minimize_target)

   Local $target_class = "max"
   If $minimize_target = True Then
	  $target_class = "min"
	  If $hotspot_analyze_min = False Then
		 Return
	  EndIf
   EndIf

   Global $target_array[0] = []
   Global $rule_target_array[0] = []

   ; 不處理.gitignore
   Local $ext = stringRight($file_name, 9)
   ;MsgBox(0, "weka_hotspot.au3", $ext)
   If $ext = "gitignore" Then
	  Return
   EndIf
   $ext = stringRight($file_name, 4)
   ;MsgBox(0, "weka_hotspot.au3", $ext)
   If $ext = "csv#" Then
	  Return
   EndIf
   ;MsgBox(0, "weka_hotspot.au3", $ext)

   Local $train_file = $train_set_dir & $file_name

   ; 把檔案取出來，另外建一個編碼後的，然後再來處理
   Local $hFileOpen = FileOpen($train_file, $FO_READ)
   Local $sFileRead = FileRead($hFileOpen)
   $sFileRead = string_encode_utf16($sFileRead )


   $hFileOpen = FileOpen($sTempFile, 2)
   FileWrite($sTempFile, $sFileRead)

   $train_file = $sTempFile


   Local $full_result[0] = []
   ;console_log($train_file)

   ; ------------------------------
   ; 要跑兩個迴圈：資料個數的迴圈跟異常的迴圈
   Local $param = 1
   While true
	  Local $cmd_weka = weka_command_builder($train_file, $param, $minimize_target)
	  ;console_log(array_count($cmd_weka))

	  If isArray($cmd_weka) = False Then
		 Local $a[1] = [$cmd_weka]
		 $cmd_weka = $a
	  EndIf
	  ;MsgBox(0, "weka_hotspot.au3", $cmd_weka)

	  Local $weka_result = ""

	  For $i = 0 to array_count($cmd_weka) - 1
		 $weka_result = ""

		 console_log($cmd_weka[$i])
		 ;ContinueLoop

		 $DOS = Run($cmd_weka[$i],  @SystemDir, @SW_HIDE, $STDOUT_CHILD)
		 ProcessWaitClose($DOS)
		 Local $weka_result = StdoutRead($DOS)
		 ; FileWrite($result_output_dir & $file_name & $param & ".txt", $weka_result)
		 ; $weka_result = _ConvertAnsiToUtf8($weka_result)
		 $weka_result = trim($weka_result)
		 $weka_result = string_decode_utf16($weka_result)

		 If $weka_result = "" Then
			ExitLoop
		 EndIf
		 array_push($full_result, $weka_result)
	  Next

	  $param = $param + 1
	  ;console_log($weka_result)
	  ;console_log($param)
	  ;Sleep(1000)
	  If $weka_result = "" Or $hotspot_target_analyze_all = False Then
		 ExitLoop
	  EndIf
   WEnd
   ; ------------------------------

   For $i = 0 to array_count($full_result) -1
	  weka_result_format_builder($full_result[$i])
   Next
   $format_result = hotspot_result_table_builder()
   $all_format_result = $all_format_result & @CRLF & @CRLF & "<h1>" & $file_name & " (" & $target_class & ")" & "</h1>" & @CRLF & @CRLF  & $format_result

   $full_result = '<pre>' & array_join($full_result, '</pre><hr /><pre>') & '</pre>'

   ; ------------------------------
   ; 最後把檔案寫入
   Local $output_file = $result_output_dir & $file_name & " (" & $target_class & ").html"
   $format_result = trim($format_result)
   $full_result = trim($full_result)
   Local $result = "<h1>Format Result</h1>" & @CRLF & $format_result & @CRLF & "<hr /> <h1>Original Result</h1>" & @CRLF & $full_result
   $result = '<link rel=stylesheet type="text/css" href="style.css">' & $result
   FileOpen ($output_file, 2)
   FileWrite($output_file, $result)
EndFunc

; -----------------------------
; 訊息


$weka_run_title = IniRead ( @ScriptDir & "\config.ini", "weka", "weka_run_title", "Weka" )
$weka_run_message = IniRead ( @ScriptDir & "\config.ini", "weka", "weka_run_message", "Please wait. Predicting..." )
SplashTextOn($weka_run_title, $weka_run_message, 300, 40) ; https://www.autoitscript.com/autoit3/docs/functions/SplashTextOn.htm

; -----------------------------
; 開始進行預測
Local $FileList = _FileListToArray($train_set_dir, "*", 1)
If @error = 1 Then
	MsgBox(0, "weka_hotspot.au3", "No Folders Found.")
	Exit
EndIf
If @error = 4 Then
	MsgBox(0, "weka_hotspot.au3", "No Files Found.")
	Exit
 EndIf

;MsgBox(0, "weka_hotspot.au3", $FileList[1])

Local $all_format_result = ""

;console_log($FileList[0])
For $f = 1 To $FileList[0]

   $file_name = $FileList[$f]


   run_weka_command($file_name, False)
   run_weka_command($file_name, True)

Next

$all_format_result = '<link rel=stylesheet type="text/css" href="style.css">' & $all_format_result
Local $output_file = $result_output_dir & "all_result.html"
FileOpen ($output_file, 2)
FileWrite($output_file, $all_format_result)

FileDelete($sTempFile)

;MsgBox(0, "weka_hotspot.au3", "Finish")