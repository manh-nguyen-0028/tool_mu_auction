#include-once
#include <Array.au3>
#include <Excel.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include "../au3WebDriver-0.12.0/wd_helper.au3"
#include "../au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../au3WebDriver-0.12.0/wd_core.au3"
#include "../au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../utils/common_utils.au3"
#include <Constants.au3>

start()

Func test()

	Local $sSession = SetupChrome()

	Local $sURL = "https://www.facebook.com/groups/406692874523853/community_roles/Admin"
	Local $aParentElements = ["x9f619 x1n2onr6 x1ja2u2z x78zum5 xdt5ytf x2lah0s x193iq5w x1xmf6yo x1e56ztr xzboxd6 x14l7nz5"]
	Local $sChildClassName = "x9f619 x1n2onr6 x1ja2u2z x78zum5 xdt5ytf x1iyjqo2 x2lwn1j"


	; Mở trang web
	_WD_Navigate( $sSession,$sURL)

	Local $sClassName = "x1n2onr6 x1ja2u2z x9f619 x78zum5 xdt5ytf x2lah0s x193iq5w xjkvuk6 x1cnzs8"
	Local $sText = "Thành viên đảm nhận vai trò này"

	; Tìm phần tử theo class và chứa văn bản
	Local $sXPath = "//span[contains(text(), 'Thành viên đảm nhận vai trò này')]/ancestor::div[contains(@class, 'x1n2onr6 x1ja2u2z x9f619 x78zum5 xdt5ytf x2lah0s x193iq5w xjkvuk6 x1cnzs8')]"

	Local $aElements = findElement($sSession, $sXPath) 

	Local $sParentXPath = "./parent::div"
    Local $aParentElement = _WD_FindElement($sSession, $sParentXPath, $aElements)
	
	If @error Then
		ConsoleWrite("Không tìm thấy phần tử" & @CRLF)
	Else
		; In ra tên class của phần tử cha
		Local $sClass = _WD_ElementAction($sSession, $aParentElement, "Attribute", "class")
		ConsoleWrite("Tên class cha: " & $sClass & @CRLF)
	EndIf

	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
	
	Return True
EndFunc

Func start()
	;~ MsgBox($MB_ICONINFORMATION, "Thông báo", "Khi chương trình chạy sẽ đóng tất cả các trình duyệt chrome. Hãy chắc chắn rằng bạn đã lưu và đóng tất cả các tab và công việc quan trọng trước khi thực hiện chạy auto")
	checkThenCloseChrome()
	deleteFileInFolder()
	checkAdminGroup()
	Return True
EndFunc

Func checkAdminGroup()
	Local $sSession = SetupChrome()

	Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
	Local $sFilePath = $sRootDir & "output\\File_" & $sDateTime & ".txt"

	Local $sAdminsIdFilePath = $sRootDir & "input\\admins_id.txt"

	; Đọc nội dung của file .txt vào mảng
	Local $adminIDs
	If FileExists($sAdminsIdFilePath) Then
		$adminIDs = FileReadToArray($sAdminsIdFilePath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file.")
			Exit
		EndIf
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf

	Local $hFile = FileOpen($sFilePath, $FO_OVERWRITE)

	Local $sURLs = readExcel()

	$textIntro = "Tool check admin group - Ekago" & @CRLF 

	$textIntro = $textIntro & "Thời gian quét: " & @HOUR & ":"& @MIN & ":"& @SEC & " " & @MDAY & "-"& @MON & "-"& @YEAR & @CRLF

	$textIntro = $textIntro & "Số nhóm quét: " &  UBound($sURLs) & @CRLF

	$issueGroup = 0

	$idIssueGroup = ""

	$sTextOut = ""

	;~ FileWriteLine($hFile, $textIntro)

	For $i = 0 To UBound($sURLs) - 1

		$sTextOut = $sTextOut & ($i + 1) & "--> "

		ConsoleWrite("$sURLs " & $i & $sURLs[$i] & @CRLF)

		_WD_Navigate($sSession, $sURLs[$i])

		secondWait(2)

		$sElement = findElement($sSession, "//span[contains(text(), 'Quản trị viên & người kiểm duyệt')]") 

		If @error Then
			$sTextOut = $sTextOut & "$sURL: " & $sURLs[$i] & " -- Check:  isAdmin = False"
			$issueGroup = $issueGroup + 1
			$idIssueGroup = $idIssueGroup & $sURLs[$i] & ";"
			writeLog("Fail:" & $sTextOut)
		Else
			Local $sScript = 'return document.title;'
			Local $sTitle = _WD_ExecuteScript($sSession, $sScript)
			$sTextOut = $sTextOut & "$sURL: " & $sURLs[$i] & " -- Title: " & $sTitle &" -- Check:  isAdmin = True " & @CRLF 
			; Chi check khi lam admin
			$aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//span[contains(@class, 'xt0psk2')]/a[contains(@class, 'x1i10hfl xjbqb8w x6umtig x1b1mbwd xaqea5y xav7gou x9f619 x1ypdohk xt0psk2 xe8uvvx xdj266r x11i5rnm xat24cr x1mh8g0r xexx8yu x4uap5 x18d9i69 xkhd6sd x16tdsg8 x1hl2dhg xggy1nq x1a2a7pz xt0b8zv xzsf02u x1s688f')]", Default, True)
			If @error Then
				ConsoleWrite("Không tìm thấy phần tử con trong phần tử thứ " & $i & @CRLF)
				_ArrayDisplay($aChildElements)
			Else
				$checkIssueGroup = True
				For $j = 0 To UBound($aChildElements) - 1
					$bFound = False
					$sHref = _WD_ElementAction($sSession, $aChildElements[$j], "Attribute", "href")
					$sCurrentUid = StringRegExpReplace($sHref, "^.*\/(\d+)\/$", "$1")
					writeLog("href: " & $sHref & "--- sCurrentUid: " & $sCurrentUid)
					;~ _ArrayDisplay($adminIDs)
					For $z = 0 To UBound($adminIDs) - 1
						writeLog("$adminIDs[$z]: " & $adminIDs[$z])
						If $adminIDs[$z] == $sCurrentUid Then
							$bFound = True
							ExitLoop
						EndIf
					Next
					$sText = getTextElement($sSession, $aChildElements[$j])
					$sTextOut = $sTextOut & "UID:" & $sCurrentUid & "-- Name: " & $sText 
					If $bFound == False Then 
						$checkIssueGroup = False
						$sTextOut = $sTextOut & "-- CANH BAO: USER ID KHONG THUOC DANH SACH ADMIN DINH SAN"
					EndIf
					$sTextOut = $sTextOut & @CRLF
				Next
				If ($checkIssueGroup == False) Then
					$issueGroup = $issueGroup + 1
					$idIssueGroup = $idIssueGroup & $sURLs[$i] & ";"
				EndIf
			EndIf
		EndIf

		$sTextOut = $sTextOut & @CRLF
	Next

	$textIntro = $textIntro & "Số nhóm lỗi: " &  $issueGroup & @CRLF
	$textIntro = $textIntro & "ID nhóm lỗi: " &  $idIssueGroup & @CRLF
	$textIntro = $textIntro & @CRLF
	$textIntro = $textIntro & "SAU ĐÂY LÀ TỔNG KẾT " & @CRLF
	$textIntro = $textIntro & @CRLF

	FileWriteLine($hFile, $textIntro)

	FileWriteLine($hFile, $sTextOut)

	FileClose($hFile)

	; Hiển thị MsgBox
	MsgBox($MB_OK, "Thông báo", "Đã thực hiện xong. Mở file kết quả ?")

	; Kiểm tra nút OK được nhấn
	If @error == 0 Then
		; Đường dẫn của file txt
		;~ Local $sFilePath = "path/to/your/file.txt"

		writeLog("$sFilePath: " & $sFilePath)
		; Kiểm tra xem file có tồn tại không
		If FileExists($sFilePath) Then
			; Mở file văn bản trong notepad
			Run("notepad.exe " & $sFilePath)
		Else
			MsgBox($MB_OK, "Thông báo", "File kết quả không tồn tại. Kiểm tra lại trong đường dẫn output")
		EndIf
	EndIf

	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
	
	Return True
EndFunc

Func checkAdminGroupTest()
	Local $sSession = SetupChrome()

	Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
	Local $sFilePath = $sRootDir & "output\\File_" & $sDateTime & ".txt"

	Local $sAdminsIdFilePath = $sRootDir & "input\\admins_id.txt"

	; Đọc nội dung của file .txt vào mảng
	Local $adminIDs
	If FileExists($sAdminsIdFilePath) Then
		$adminIDs = FileReadToArray($sAdminsIdFilePath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file.")
			Exit
		EndIf
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf

	Local $hFile = FileOpen($sFilePath, $FO_OVERWRITE)

	Local $sURLs = readExcel()

	For $i = 0 To UBound($sURLs) - 1

		$sTextOut = ($i + 1) & "--> "

		ConsoleWrite("$sURLs " & $i & $sURLs[$i] & @CRLF)

		;~ MsgBox(16, "Info", $sURLs[$i])

		_WD_Navigate($sSession, $sURLs[$i])

		$sElement = findElement($sSession, "//h2[@class='x1heor9g x1qlqyl8 x1pd3egz x1a2a7pz']") 

		$sText = getTextElement($sSession, $sElement)
		writeLog("$sText: " & $sText)

		Local $sScript = 'return document.title;'
		Local $sTitle = _WD_ExecuteScript($sSession, $sScript)

		If $sText == 'Quản trị viên' Then
			$sTextOut = $sTextOut & "$sURL: " & $sURLs[$i] & " -- Title: " & $sTitle &" -- Check:  isAdmin = True " & @CRLF 
			; Chi check khi lam admin
			$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='x9f619 x1n2onr6 x1ja2u2z x78zum5 xdt5ytf x2lah0s x193iq5w x1xmf6yo x1e56ztr xzboxd6 x14l7nz5']", Default, True)
			
			$sPosition = 999

			For $k = 0 To UBound($aElements) - 1
				Local $aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//span[@class='x1lliihq x6ikm8r x10wlt62 x1n2onr6 x1120s5i']", $aElements[$k], True)
				
				If @error Then
					; _ArrayDisplay($aElements)

					ConsoleWrite("Không tìm thấy phần tử con trong phần tử thứ " & $k & @CRLF)
				Else
					$sText = getTextElement($sSession, $aChildElements[0])
					If $sText == 'Thành viên đảm nhận vai trò này' Then
						$sPosition = $k
						ExitLoop
					EndIf
				EndIf
			Next

			$sTextOut = $sTextOut & "Danh sach Admin: " & @CRLF
			If ($sPosition <> 999) Then
				$sPositionReal = $sPosition + 2
				writeLog("Vi tri lay dc: " & $sPositionReal)
				$aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//span[contains(@class, 'xt0psk2')]/a[contains(@class, 'x1i10hfl xjbqb8w x6umtig x1b1mbwd xaqea5y xav7gou x9f619 x1ypdohk xt0psk2 xe8uvvx xdj266r x11i5rnm xat24cr x1mh8g0r xexx8yu x4uap5 x18d9i69 xkhd6sd x16tdsg8 x1hl2dhg xggy1nq x1a2a7pz xt0b8zv xzsf02u x1s688f')]", $aElements[$sPositionReal], True)
				If @error Then
					ConsoleWrite("Không tìm thấy phần tử con trong phần tử thứ " & $i & @CRLF)
					_ArrayDisplay($aChildElements)
				Else
					For $j = 0 To UBound($aChildElements) - 1
						$bFound = False
						$sHref = _WD_ElementAction($sSession, $aChildElements[$j], "Attribute", "href")
						$sCurrentUid = StringRegExpReplace($sHref, "^.*\/(\d+)\/$", "$1")
						;~ _ArrayDisplay($adminIDs)
						For $z = 0 To UBound($aChildElements) - 1
							If $adminIDs[$z] == $sCurrentUid Then
								$bFound = True
								ExitLoop
							EndIf
						Next
						;~ ConsoleWrite("Tên HREF của phần tử con : " & _WD_ElementAction($sSession, $aChildElements[$j], "Attribute", "href") & @CRLF)
						$sText = getTextElement($sSession, $aChildElements[$j])
						$sTextOut = $sTextOut & "UID:" & $sCurrentUid & "-- Name: " & $sText 
						If $bFound == False Then 
							$sTextOut = $sTextOut & "-- CANH BAO: USER ID KHONG THUOC DANH SACH ADMIN DINH SAN"
						EndIf
						$sTextOut = $sTextOut & @CRLF
					Next
				EndIf
			EndIf
		Else
			$sTextOut = $sTextOut & "$sURL: " & $sURLs[$i] & " -- Check:  isAdmin = False"
			writeLog("Fail:" & $sTextOut)
		EndIf

		writeLog($sTextOut)

		FileWriteLine($hFile, $sTextOut)
	Next

	FileClose($hFile)

	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
	
	Return True
EndFunc

Func deleteFileInFolder()
	Local $sFolderPath = $sRootDir & "output" ; Đường dẫn thư mục output

	Local $aFileList = _FileListToArray($sFolderPath) ; Lấy danh sách các file trong thư mục

	If @error Then
		writeLog("Không thể đọc danh sách file trong thư mục")
	Else
		For $i = 1 To $aFileList[0] ; Duyệt qua từng file
			If StringInStr($aFileList[$i], "File_") Then ; Kiểm tra nếu tên file chứa "File_"
				Local $sFilePath = $sFolderPath & "\" & $aFileList[$i] ; Đường dẫn đầy đủ của file
				FileDelete($sFilePath) ; Xoá file
			EndIf
		Next
		;~ MsgBox(64, "Thông báo", "Xoá các file thành công")
	EndIf

	Return True
EndFunc

Func readExcel()
	Local $sFilePath = $sRootDir & "input\\groups.xlsx" ; Đường dẫn đến file Excel

	Local $oExcel = _Excel_Open()
	If @error Then
		MsgBox(16, "Lỗi", "Không thể mở ứng dụng Excel")
		Exit
	EndIf

	Local $oWorkbook = _Excel_BookOpen($oExcel, $sFilePath)
	If @error Then
		MsgBox(16, "Lỗi", "Không thể mở file Excel")
		_Excel_Close($oExcel)
		Exit
	EndIf

	Local $aArray = _Excel_RangeRead($oWorkbook) ; Đọc dữ liệu từ toàn bộ range trong file Excel

	If @error Then
		MsgBox(16, "Lỗi", "Không thể đọc dữ liệu từ file Excel")
		_Excel_BookClose($oWorkbook)
		_Excel_Close($oExcel)
		Exit
	EndIf

	For $i = 0 To UBound($aArray) - 1 ; Duyệt qua từng dòng trong mảng
		$aArray[$i] = $aArray[$i] & "members/admins"
		writeLog($aArray[$i])
	Next

	_Excel_BookClose($oWorkbook)
	_Excel_Close($oExcel)
	Return $aArray
EndFunc