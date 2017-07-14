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

Func weka_command_builder($train_file, $param)
   Local $cmd_weka = @comspec & ' /C Java -cp ' & $extapp_weka & ' weka.Run ' & $weka_command & ' -t "' & $train_file & '" -c ' & $hotspot_targetIndex & ' -V ' & $param & ' -S ' & $hotspot_support & ' -M ' & $hotspot_max_branching_factor & ' -length ' & $hotspot_max_rule_length & ' -I 0.01 '
   If $ext = "csv" Then
	  ; CSV的指令
   EndIf
   return $cmd_weka
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
   $ext = stringRight($FileList[$i], 4)
   ;MsgBox(0, "weka_hotspot.au3", $ext)
   Local $train_file = $train_set_dir & $FileList[$i]
   $result = ""

   ; ------------------------------
   ; 要跑兩個迴圈：資料個數的迴圈跟異常的迴圈
   Local $param = 1
   While true
	  Local $cmd_weka = weka_command_builder($train_file, $param)

	  ;MsgBox(0, "weka_hotspot.au3", $cmd_weka)

	  $DOS = Run($cmd_weka,  @SystemDir, Default, $STDOUT_CHILD)
	  ProcessWaitClose($DOS)
	  Local $weka_result = StdoutRead($DOS)
	  If $weka_result = "" Then
		 ExitLoop
	  EndIf

	  $result = $result & @CRLF & $weka_result
	  ;MsgBox(0, "weka_hotspot.au3", $weka_result)

	  $param = $param + 1

   WEnd

   ; ------------------------------
   ; 最後把檔案寫入
   Local $output_file = $result_output_dir & $FileList[$i] & ".txt"
   FileWrite($output_file, $result)
Next

MsgBox(0, "weka_hotspot.au3", "Finish")

#comments-start
$cmd_weka = @comspec & ' /C Java -cp ' & $extapp_weka & ' weka.Run ' & $weka_command & ' -t ' & $test_set_arff & ' -l ' & $weka_model & ' -p 0'
$DOS = Run($cmd_weka,  @SystemDir, Default, $STDOUT_CHILD)
ProcessWaitClose($DOS)
Local $predict_result = StdoutRead($DOS)
$predict_result = trim($predict_result)

; ----------------------------------

; 分析預測結果
Local $aArray = StringSplit($predict_result, @CRLF)
$predict_result = $aArray[($aArray[0])]
$predict_result = trim($predict_result)
$aArray = StringSplit($predict_result, ':')
$predict_result = $aArray[($aArray[0])]
$predict_result = trim($predict_result)
$aArray = StringSplit($predict_result, ' ')

Local $predict_class = $aArray[1]
$predict_class = trim($predict_class)

Local $predict_prob = $aArray[($aArray[0])]
$predict_prob = trim($predict_prob)
$predict_prob = Number($predict_prob)
$predict_prob = $predict_prob * 100

;MsgBox(0, "weka_predict.au3", $predict_class & @CRLF & $predict_prop)

; -------------------------
; 進行預測之後的動作
Local $after_predict_cmd = IniRead ( @ScriptDir & "\config.ini", "weka", "after_predict_cmd", "C:\Program Files\Internet Explorer\iexplore.exe -k https://docs.google.com/forms/d/e/1FAIpQLSeWynGUR3vzZc6E7pVMEYpruAnl66vA9aS4bVOw5Tp6rC1FCw/viewform?usp=pp_url&entry.1291062876={predictclass}&entry.422415105={prob}" )

$after_predict_cmd = StringReplace($after_predict_cmd, "{predictclass}", $predict_class)
$after_predict_cmd = StringReplace($after_predict_cmd, "{prob}", $predict_prob)

;MsgBox(0, "weka_predict.au3", $after_predict_cmd)
Run($after_predict_cmd)
#comments-end
