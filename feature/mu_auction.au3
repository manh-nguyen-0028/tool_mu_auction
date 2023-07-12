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
#include <String.au3>

; Valiable
Local $sSession,$adminIDs,$auctionsConfig
Local $sTitleLoginSuccess = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - Thông báo"
Local $sDateToday = @YEAR & @MON & @MDAY
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $logFile, $auctionArray[0]
Local $recordExample = "5153|100"

start()
;~ test()

;~ deleteFileInFolder()

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

	Local $sFilePath = $sRootDir & "output\\File_" & $sDateTime & ".txt"

	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	
	checkThenCloseChrome()

	deleteFileInFolder()

	; Set up chrome
	$sSession = SetupChrome()

	; thuc hien di vao trang dau gia
	While @HOUR >= 19 And @HOUR < 23 
		login()

		; Check IP
		$isHaveIP = checkIp()
		If $isHaveIP == False Then ExitLoop

		getConfigAuction()
		
		; Truong hop co 1 phan tu va phan tu do bang phan tu example thi dong chuong trinh
		If UBound($auctionsConfig) == 1 And $auctionsConfig[0] == $recordExample Then ExitLoop

		ReDim $auctionArray[0]
		For $i = 0 To UBound($auctionsConfig) - 1
			writeLogFile($logFile, "Thông tin account đấu giá: " & $auctionsConfig[$i])
			$idUrl = StringSplit($auctionsConfig[$i], "|")[1]
			$maxPrice = StringSplit($auctionsConfig[$i], "|")[2]
			auction($idUrl, $maxPrice, $adminIDs)
		Next

		reWriteAuctionFile($auctionArray)

		minuteWait(4)
	WEnd
	
	FileClose($logFile)
	
	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()

	Return True
EndFunc

Func auction($idUrl, $maxPrice, $adminIDs)
	writeLogFile($logFile, "Bắt đầu đấu giá cho id : " & $idUrl &  ". Giá tối đa: " & $maxPrice)
	_WD_Navigate($sSession, getUrlAuction($idUrl))
	secondWait(5)
	; Check title xem dung chua, neu dung thi moi tiep tuc
	$sTitle = getTitleWebsite($sSession)
	If $sTitle == 'MU Hà Nội 2003 | GamethuVN.net - Season 15 - Đấu giá vật phẩm BOSS' Then
		$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='card']/div[@class='card-body']/form[@action='/web/event/boss-item-bid.submit_bid.shtml']", Default, True)

		$aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//div[@class='col-sm-6 align-self-center']/div[@class='input-group']/span", $aElements[0], True)
      
		$sTimeFinish = getTextElement($sSession, $aChildElements[0])

		
		$sCurrentChar = getTextElement($sSession, $aChildElements[1])

		; Boc tach du lieu va trim du lieu
		$currentCharAuction = ''
		
		If 'Chưa có' == $sCurrentChar Then
			$currentCharAuction = $sCurrentChar
		Else
			$currentCharAuction = StringSplit($sCurrentChar, " (")[1]
			writeLogFile($logFile, "Nhân vật đang đấu giá hiện tại: " & $currentCharAuction)
		EndIf
		
		$timeFinish = _DateAdd('h', 0, $sTimeFinish)

		$timeMatch = _DateAdd('n', -7, $sTimeFinish)

		$currentTime = _NowCalc()

		$isCheckTimeOk = True 

		If $currentTime < $timeMatch Or $currentTime > $timeFinish Then
			$isCheckTimeOk = False
			If $currentTime > $timeFinish Then 
				writeLogFile($logFile, "Đấu giá đã kết thúc ! Đã kết thúc đấu giá lúc: " & $timeFinish)
			Else
				Redim $auctionArray[UBound($auctionArray) + 1]
				$auctionArray[UBound($auctionArray) - 1] = $idUrl & "|" & $maxPrice & "|" & $timeFinish 
			EndIf
			If $currentTime < $timeMatch Then writeLogFile($logFile, "Chưa tới thời gian đấu giá ! Thời gian có thể vào đấu giá lúc: " & $timeMatch)
		EndIf

		; check gia dang duoc goi y
		$sElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//span[@name='help-price']", Default, False)

		$sHelpPrice = getTextElement($sSession, $sElements)

		$minAuctionAllow = _StringBetween($sHelpPrice, "Tối thiểu ", " bạc")[0]

		writeLogFile($logFile, "Giá tối thiểu được lấy từ website: " & $minAuctionAllow)

		; Check nhan vat dang dau gia co phai la nhan vat cua minh hay khong
		$bFound = False
		; Neu nhan vat dang dau gia khac cua minh thi moi thuc hien dau gia 
		For $z = 0 To UBound($adminIDs) - 1
			If $adminIDs[$z] == $currentCharAuction Then
				$bFound = True
				ExitLoop
			EndIf
		Next

		If $bFound == False Then
			writeLogFile($logFile, "Nhân vật đang đấu giá khác với ID được cấu hình. Có thể vào đấu giá. Nhân vật đang đấu giá là: " & $currentCharAuction)
		EndIf

		$checkMatchMaxPrice = True

		If $minAuctionAllow > $maxPrice Then $checkMatchMaxPrice = False

		If $isCheckTimeOk == True And $bFound == False And $checkMatchMaxPrice == True Then
			$numPriceAuctionAllow = Number(StringReplace($minAuctionAllow, ",", ""))
			Local $sScript = "document.querySelector('input[name=price]').value = '"& ($numPriceAuctionAllow + 1) &"';"
			_WD_ExecuteScript($sSession, $sScript)
			secondWait(1)
		
			$sElement = findElement($sSession, "//button[@type='submit']") 
			clickElement($sSession, $sElement)
			secondWait(2)
			$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
			If @error Then
				writeLogFile($logFile, "Không tìm thấy message confirm !")
			Else
				clickElement($sSession, $checkConfirmBox)
			EndIf
			writeLogFile($logFile, "Đấu giá thành công !")
		Else
			writeLogFile($logFile, "Không đủ điều kiện đấu giá !")
			If $isCheckTimeOk == False Then writeLogFile($logFile, "Thời gian chưa đủ để đấu giá ! Thời gian kết thúc: " & $timeFinish)
			If $bFound == True Then writeLogFile($logFile, "Nhân vật đang đấu giá là chính bạn. Nhân vật đang đấu giá: " & $currentCharAuction)
			If $checkMatchMaxPrice == True Then writeLogFile($logFile, "Giá cho phép đã vượt qua ngưỡng tối đa. Max giá: " & $maxPrice)
		EndIf	
		secondWait(2)
	EndIf
	Return True
EndFunc

Func login()
	; vao website
	_WD_Navigate($sSession, $baseMuUrl)
	secondWait(5)
	; get title
	$sTitle = getTitleWebsite($sSession)

	While $sTitle <> $sTitleLoginSuccess
		$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
		If @error Then
			writeLogFile($logFile, "Không tìm thấy diaglog lỗi !")
		Else
			clickElement($sSession, $checkConfirmBox)
		EndIf
		loginWebsite($sSession, Default)
		$sTitle = getTitleWebsite($sSession)
	WEnd

	writeLogFile($logFile, "Đăng nhập thành công !")
	Return True
EndFunc

Func getConfigAuction()
	Local $sAdminsIdFilePath = $sRootDir & "input\\admins_id.txt"
	Local $auctionConfigPath = $sRootDir & "input\\auctions.txt"

	; Đọc nội dung của file .txt vào mảng
	If FileExists($sAdminsIdFilePath) And FileExists($auctionConfigPath) Then
		; char auction list
		$adminIDs = FileReadToArray($sAdminsIdFilePath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file.")
			Exit
		EndIf

		; auction config list
		$auctionsConfig = FileReadToArray($auctionConfigPath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file.")
			Exit
		EndIf
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf
	Return True
EndFunc

Func loginWebsite($sSession, $accountInfo)

	$username = "mala"
	$password = "manhva02"
	$charName = "CoGaiVang"

	writeLogFile($logFile, "UserName: " & $username & ", Password: " & $password & ", Char Name: " & $charName)

	_WD_Navigate($sSession, $baseMuUrl)
	secondWait(5)

	; _WD_Window($sSession,"MINIMIZE")

	_Demo_NavigateCheckBanner($sSession, $baseUrl)
    _WD_LoadWait($sSession, 1000)

	; Fill user name
	$sElement = _WD_GetElementByName($sSession,"username")
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	secondWait(2)
	_WD_ElementAction($sSession, $sElement, 'value',$username)
	
	; Fill password
	$sElement = _WD_GetElementByName($sSession,"password") 
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	secondWait(2)
	_WD_ElementAction($sSession, $sElement, 'value',$password)

	; Save captcha
	$captchaImgPath = @ScriptDir & "\captcha_img.png";
	; Find image captcha
	$sElement = findElement($sSession, "//img[@class='captcha_img']")
	_WD_DownloadImgFromElement($sSession, $sElement, $captchaImgPath)

	If @error = $_WD_ERROR_Success Then 
		$idCaptchaFinal = ''
		; Get captcha buoc 2 => call server captcha 
		While $idCaptchaFinal == '' Or StringLen($idCaptchaFinal) > 4
			$sFilePath = "file:///" & $sRootDir & "input/get_captcha.html"

			; Get captcha buoc 1
			createNewTab($sSession,optimizeUrl($sFilePath))
			; select captcha
			_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='file']", $captchaImgPath)
			; Submit get id from azcaptcha
			$sElement = findElement($sSession, "//input[@type='submit']")
			clickElement($sSession, $sElement)
			; get text
			$sElement = findElement($sSession, "//body")
			$idCaptcha = getTextElement($sSession, $sElement)
			$idCaptcha = StringReplace($idCaptcha, "OK|", "")
			secondWait(2)

			; Get captcha buoc 2
			$serverCaptcha = "http://azcaptcha.com/res.php?key=ai0xvvkw3hcoyzbgwdu5tmqdaqyjlkjs&action=get&id=" & $idCaptcha
			_Demo_NavigateCheckBanner($sSession, $serverCaptcha)
			; _WD_Window($sSession,"MINIMIZE")
			; get text
			$sElement = findElement($sSession, "//body")
			$idCaptchaFinal = getTextElement($sSession, $sElement)
			$idCaptchaFinal = StringReplace($idCaptchaFinal, "OK|", "")
			writeLogFile($logFile, "Captcha Value: " & $idCaptchaFinal)
			secondWait(1)
		WEnd
		
		; Chuyen lai tab ve gamethuvn.net
		_WD_Attach($sSession, "gamethuvn.net", "URL")
		
		; _WD_Window($sSession,"MINIMIZE")

		writeLogFile($logFile, "mu_auction.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)
		; set input captcha
		$sElement = findElement($sSession, "//input[@name='captcha']") 
		_WD_ElementAction($sSession, $sElement, 'value',$idCaptchaFinal)
		secondWait(1)
		; Submit to login
		$sElement = findElement($sSession, "//button[@type='submit']") 
		clickElement($sSession, $sElement)
		secondWait(5)
	EndIf

	Return True
EndFunc

Func checkIp()
	$isHaveIP = True
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='alert alert-success']/i[@class='c-icon c-icon-xl cil-shield-alt t-pull-left']", Default, False)
	If @error Then
		writeLogFile($logFile, "IP KHONG CHINH CHU")
		$isHaveIP = False
	EndIf
	Return $isHaveIP
EndFunc

Func deleteFileInFolder()

	Local $sFolderPath = $sRootDir & "output" ; Đường dẫn thư mục output

	Local $aFileList = _FileListToArray($sFolderPath) ; Lấy danh sách các file trong thư mục

	If @error Then
		writeLogFile($logFile, "Không thể đọc danh sách file trong thư mục")
	Else
		For $i = 1 To $aFileList[0] ; Duyệt qua từng file
			If StringInStr($aFileList[$i], "File_" & $sDateToday) == 0 Then ; Kiểm tra nếu tên file chứa "File_"
				Local $sFilePath = $sFolderPath & "\" & $aFileList[$i] ; Đường dẫn đầy đủ của file
				FileDelete($sFilePath) ; Xoá file
			EndIf
		Next
		;~ MsgBox(64, "Thông báo", "Xoá các file thành công")
	EndIf

	Return True
EndFunc

Func reWriteAuctionFile($auctionArray)
	
	Local $auctionPath = $sRootDir & "input\\auctions.txt"

	$autionFile = FileOpen($auctionPath, $FO_OVERWRITE)

	For $i = 0 To UBound($auctionArray) - 1
		FileWriteLine($autionFile, $auctionArray[$i])
	Next

	If UBound($auctionArray) == 0 Then FileWriteLine($autionFile, $recordExample)

	FileClose($autionFile)

EndFunc