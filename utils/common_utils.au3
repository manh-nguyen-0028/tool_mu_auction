#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <Array.au3>
#include "../au3WebDriver-0.12.0/wd_core.au3"

Local $sScriptDir = @ScriptDir ; Đường dẫn thư mục hiện tại của script
Global $sRootDir = StringRegExpReplace($sScriptDir, "^(.+\\)[^\\]+\\?$", "$1") ; Lấy đường dẫn thư mục gốc

Local $sAppDataPath = @AppDataDir ; Lấy đường dẫn tới thư mục "AppData"

Global $sAppDataLocalPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local") ; Lấy đường dẫn thư mục gốc

Global $sChromeUserDataPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local\\Google\\Chrome\\User Data\") ; Lấy đường dẫn thư mục gốc

;~ Global $baseMuUrl = "https://hn.gamethuvn.net/"
Global $baseMuUrl = "https://hn.mugamethuvn.info/"

;~ MsgBox($MB_OK, "Thông báo", "Đường dẫn tới thư mục AppData: " & $sAppDataLocalPath & "---" & $sChromeUserDataPath)

Func writeLog($textLog)
	ConsoleWrite(@HOUR & "-" &@MIN & "-" &@SEC & " : " & $textLog & @CRLF)
EndFunc

Func createTimeToTicks($gio,$phut,$giay)
	Return _TimeToTicks($gio, $phut, $giay)
EndFunc

Func diffTime($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour*60*60*1000 +  $sMinute*60*1000 + $sSecond*1000;
EndFunc

Func timeLeft($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour & ": " & $sMinute & ": " & $sSecond;
EndFunc

Func timeToText($time)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time, $sHour, $sMinute, $sSecond)
	Return $sHour & " h: " & $sMinute & " m: " & $sSecond & " s ";
EndFunc

Func getCurrentTime()
	Return createTimeToTicks(@HOUR, @MIN, @SEC)
EndFunc

Func minuteWait($minuteWait)
	writeLog("Sleep in: " & $minuteWait & " minute !")
	Sleep($minuteWait*60*1000)
EndFunc

Func secondWait($secondWait)
	;~ writeLog("Sleep in: " & $secondWait & " second !")
	Sleep($secondWait*1000)
EndFunc

Func _MU_MouseClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	Sleep(1000)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_LEFT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func _MU_MouseClick($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
EndFunc

Func _MU_Mouse_RightClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	Sleep(1000)
	MouseDown($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func sendKeyDelay($keyPress)
	Opt("SendKeyDownDelay", 1000)  ;5 second delay
	Send($keyPress)
	Opt("SendKeyDownDelay", 5)  ;reset to default when done
EndFunc

Func minisizeMain($mainNo)
	writeLog("SW_MINIMIZE main: " & $mainNo)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func activeAndMoveWin($main_i)
	writeLog("activeAndMoveWin. Main no: " & $main_i )
	$isActive = False;
	If WinActivate($main_i) Then
		$winActive = WinActivate($main_i)
		WinMove($winActive,"",0,0)
		$isActive = True
	Else
		writeLog("Window not activated : " & $main_i)
	EndIf
	Return $isActive
EndFunc

Func getPathImage($imagePath)
	$path =  @ScriptDir & "\image\" & $imagePath
	writeLog("execute method getPathIgetPathImage($imagePath). Response: " & $path)
	Return $path
EndFunc

Func getPathImageBanDo()
	Return getPathImage("ban_do")
EndFunc

Func waitToNextHour($hourPlus = 1)
	$nextHour = @HOUR + $hourPlus
	writeLog("Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, 0 , "05")
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	Sleep($diffTime)
EndFunc

Func readFileText($filePath)
	writeLog("Read file : " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	;~ writeLog("Text read from file: " &$convtext)
	FileClose($rtfhandle)
	Return $convtext
EndFunc

Func checkPixelColor($toaDoX, $toaDoY, $color)
	writeLog("checkPixelColor($toaDoX, $toaDoY, $color) : " & $toaDoX & $toaDoY & $color)
	$resultCompare = False
	MouseMove($toaDoX, $toaDoY)
	secondWait(1)
	$colorGetPosition = PixelGetColor($toaDoX, $toaDoY)
	writeLog("checkPixelColor -> colorGetPosition : " & $toaDoX & "-" & $toaDoY & "-" & Hex($colorGetPosition,6))
	If $colorGetPosition = $color Then $resultCompare = True
	Return $resultCompare
EndFunc

Func mouseMainClick($toaDoX, $toaDoY) 
	MouseClick("main",$toaDoX, $toaDoY,1)
	secondWait(1)
EndFunc

Func checkThenCloseChrome()
	Local $chromeProcessName = "chrome.exe"

	; Kiểm tra xem có trình duyệt Chrome đang chạy không
	If ProcessExists($chromeProcessName) Then
		; Đóng tất cả các tiến trình trình duyệt Chrome
		ProcessClose($chromeProcessName)
		;~ MsgBox($MB_ICONINFORMATION, "Thông báo", "Đã đóng tất cả các trình duyệt Chrome.")
		writeLog("Đã đóng tất cả các trình duyệt Chrome.")
	Else
		;~ MsgBox($MB_ICONINFORMATION, "Thông báo", "Không tìm thấy trình duyệt Chrome đang chạy.")
		writeLog("Không tìm thấy trình duyệt Chrome đang chạy.")
	EndIf
	
	Return True
EndFunc

Func getTitleWebsite($sSession)
	Local $sScript = 'return document.title;'
	Local $jsonString = _WD_ExecuteScript($sSession, $sScript)
	; Tìm vị trí của ký tự đầu tiên và ký tự cuối cùng trong chuỗi giá trị
	Local $startIndex = StringInStr($jsonString, ':"') + 2
	Local $endIndex = StringInStr($jsonString, '"', 0, -1)

	; Trích xuất giá trị từ chuỗi JSON
	Local $value = StringMid($jsonString, $startIndex, $endIndex - $startIndex)
	Return $value
EndFunc

Func msgBoxInfo($sText)
	writeLog("MsgBox value:" & $sText)
	MsgBox($MB_OK, "Thông báo", $sText)
	Return True
EndFunc

Func getUrlAuction($sId)
	Return $baseMuUrl&"web/event/boss-item-bid.item.shtml?id="&$sId
EndFunc

Func writeLogFile($logFile, $sText)
	writeLog($sText)
	FileWriteLine($logFile, @HOUR & "-" &@MIN & "-" &@SEC & " : " & $sText)
EndFunc