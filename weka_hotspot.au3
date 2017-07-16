#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <AutoItConstants.au3>
#include <puli_utils.au3>
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

$weka_command = "weka.associations.HotSpot"

; -----------------------------

Func weka_command_builder($train_file, $param)
   $ext = stringRight($train_file, 4)
   Local $cmd_weka = @comspec & ' /C Java -cp ' & $extapp_weka & ' weka.Run ' & $weka_command & ' -t "' & $train_file & '" -c ' & $hotspot_targetIndex & ' -V ' & $param & ' -S ' & $hotspot_support & ' -M ' & $hotspot_max_branching_factor & ' -length ' & $hotspot_max_rule_length & ' -I 0.01 '
   Local $cmd_weka2 = $cmd_weka & " -R"
   If $ext = "csv" Then
	  ; CSV的指令
   EndIf
   Local $commands[2] = [$cmd_weka, $cmd_weka2]
   return $commands
EndFunc

; -----------------------------

Global $target_array[0] = []
Global $rule_target_array[0] = []

Func weka_result_format_builder($weka_result)
   ; ------------------------------------------
   ; 找出需要的程式碼

   Local $parts = string_split($weka_result, @LF & @LF)
   Local $result = $parts[2]
   $result = trim($result)
   ;MsgBox(0, "weka_hotspot.au3", $result)
   $weka_result = $result

   If StringInStr($weka_result, "  <conf:(") = 0 Then
	  $weka_result = weka_result_format_builder_tree($weka_result)
	  array_push($target_array, $weka_result)
   Else
	  weka_result_format_builder_rule($weka_result)
   EndIf
EndFunc

; ------------------------------------------

Func weka_result_format_builder_tree($weka_result)
   ; 找出需要的變數
   Local $lines = StringSplit($weka_result, @LF & " ", 1)

   Local $rhs = StringSplit($lines[1], ' (', 1)
   Local $rhs_item = trim($rhs[1])
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
   return $a
EndFunc

; -----------------------------
Func weka_result_format_builder_rule($weka_result)
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
   Local $result = '<table border="1">'
   string_append($result, '<thead><tr>')
   string_append($result, '<td>RHS item</td><td>RHS index</td><td>LHS itemset</th>')
   string_append($result, '<td>all</td><td>match</td><td>conf</td><td>lift</td><td>lev</td><td>conv</td>')
   string_append($result, '</tr></thead>')
   string_append($result, '<tbody>')
   For $t = 0 to array_count($target_array) -1
	  Local $target_item = $target_array[$t]
	  ;_ArrayDisplay($target_item)
	  Local $rhs_item = $target_item[0]
	  Local $rhs_index = $target_item[1]
	  Local $lhs_item = $target_item[2]
	  Local $lhs_index = $target_item[3]
	  Local $lhs_last_item = $target_item[4]

	  For $i = 0 to array_count($lhs_item)-1
		 string_append($result, "<tr>")


		 If $i = 0 Then
			string_append($result, '<td rowspan="' & array_count($lhs_item) & '" valign="top">')
			string_append($result, $rhs_item)
			string_append($result, "</td>")

			string_append($result, '<td rowspan="' & array_count($lhs_item) & '" valign="top">')
			string_append($result, $rhs_index)
			string_append($result, "</td>")
		 EndIf

		 ;MsgBox(0, $i, $lhs_item[$i])
		 string_append($result, "<td>" & $lhs_item[$i] & "</td>")
		 Local $index_array = $lhs_index[$i]
		 string_append($result, "<td>" & $index_array[2] & "</td>")
		 string_append($result, "<td>" & $index_array[1] & "</td>")
		 string_append($result, "<td>" & $index_array[0] & "</td>")

		 ; 找尋其他index
		 Local $last_item = $lhs_last_item[$i]
		 console_log($last_item)
		 Local $match = $index_array[1]
		 Local $all = $index_array[2]
		 For $j = 0 to array_count($rule_target_array) -1
			$rule = $rule_target_array[$j]
			If $rule[0] = $rhs_item And $rule[1] = $last_item And $rule[2] = $match And $rule[3] = $all Then
			   string_append($result, "<td>" & $rule[4] & "</td>")
			   string_append($result, "<td>" & $rule[5] & "</td>")
			   string_append($result, "<td>" & $rule[6] & "</td>")
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
; 訊息


$weka_run_title = IniRead ( @ScriptDir & "\config.ini", "weka", "weka_run_title", "Weka" )
$weka_run_message = IniRead ( @ScriptDir & "\config.ini", "weka", "weka_run_message", "Please wait. Predicting..." )
;SplashTextOn($weka_run_title, $weka_run_message, 300, 40) ; https://www.autoitscript.com/autoit3/docs/functions/SplashTextOn.htm

; -----------------------------
; 開始進行預測
Local $FileList = _FileListToArray($train_set_dir, "*")
If @error = 1 Then
	MsgBox(0, "weka_hotspot.au3", "No Folders Found.")
	Exit
EndIf
If @error = 4 Then
	MsgBox(0, "weka_hotspot.au3", "No Files Found.")
	Exit
 EndIf

;MsgBox(0, "weka_hotspot.au3", $FileList[1])

For $i = 1 To $FileList[0]
   $file_name = $FileList[$i]
   $ext = stringRight($file_name, 9)
   ;MsgBox(0, "weka_hotspot.au3", $ext)
   If $ext = "gitignore" Then
	  ContinueLoop
   EndIf
   ;MsgBox(0, "weka_hotspot.au3", $ext)
   Local $train_file = $train_set_dir & $file_name
   Local $full_result[0] = []

   ; ------------------------------
   ; 要跑兩個迴圈：資料個數的迴圈跟異常的迴圈
   Local $param = 1
   While true
	  Local $cmd_weka = weka_command_builder($train_file, $param)
	  If isArray($cmd_weka) = False Then
		 Local $a[1] = [$cmd_weka]
		 $cmd_weka = $a
	  EndIf
	  ;MsgBox(0, "weka_hotspot.au3", $cmd_weka)

	  Local $weka_result = ""
	  For $i = 0 to array_count($cmd_weka) - 1
		 $DOS = Run($cmd_weka[$i],  @SystemDir, Default, $STDOUT_CHILD)
		 ProcessWaitClose($DOS)
		 Local $weka_result = StdoutRead($DOS)
		 $weka_result = trim($weka_result)
		 If $weka_result = "" Then
			ExitLoop
		 EndIf
		 array_push($full_result, $weka_result)
	  Next
	  If $weka_result = "" Then
		 ExitLoop
	  EndIf

	  $param = $param + 1
   WEnd
   ; ------------------------------

   For $i = 0 to array_count($full_result) -1
	  weka_result_format_builder($full_result[$i])
   Next
   $format_result = hotspot_result_table_builder()
   $full_result = '<pre>' & array_join($full_result, '</pre><hr /><pre>') & '</pre>'

   ; ------------------------------
   ; 最後把檔案寫入
   Local $output_file = $result_output_dir & $file_name & ".html"
   $format_result = trim($format_result)
   $full_result = trim($full_result)
   Local $result = "<h1>Format Result</h1>" & @CRLF & $format_result & @CRLF & "<hr /> <h1>Original Result</h1>" & @CRLF & $full_result
   $result = '<link rel=stylesheet type="text/css" href="../style.css">' & $result
   FileOpen ($output_file, 2)
   FileWrite($output_file, $result)
Next

MsgBox(0, "weka_hotspot.au3", "Finish")