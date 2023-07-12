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
#include <String.au3>

testGetElement()

Func testGetElement()
	Local $sSession = SetupChrome()

	;~ _WD_Window($sSession,"MINIMIZE")

	Local $sFilePath = _WriteTestHtml()
	_WD_Navigate($sSession, $sFilePath)
	_WD_LoadWait($sSession, 1000)

	;~ $sElement = findElement($sSession, "//h4[contains(text(),'bevis')]")

	$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='card']/div[@class='card-body']/form[@action='/web/event/boss-item-bid.submit_bid.shtml']", Default, True)

	$aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//div[@class='col-sm-6 align-self-center']/div[@class='input-group']/span", $aElements[0], True)
        
	;~ ConsoleWrite("sElement: " & $aChildElements)

	;~ _ArrayDisplay($aChildElements)

	$sTimeFinish = getTextElement($sSession, $aChildElements[0])
	$currentCharAuction = getTextElement($sSession, $aChildElements[1])

	$timeFinish = _DateAdd('h', 0, $sTimeFinish)

	$timeCheck = _DateAdd('n', -10, $sTimeFinish)

	writeLog("$timeFinish: " & $timeFinish)

	writeLog("$timeCheck: " & $timeCheck)

	$sElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//span[@name='help-price']", Default, False)

	$sHelpPrice = getTextElement($sSession, $sElements)

	$minAuctionAllow = _StringBetween($sHelpPrice, "Tối thiểu ", " bạc")[0]

	writeLog("$minAuctionAllow: " & $minAuctionAllow)

	Local $sScript = "document.querySelector('input[name=price]').value = '"& $minAuctionAllow &"';"
	_WD_ExecuteScript($sSession, $sScript)

	secondWait(5)
	
	$sElement = findElement($sSession, "//button[@type='submit']") 
	clickElement($sSession, $sElement)

	secondWait(5)

	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()

EndFunc

Func _WriteTestHtml($sFilePath = $sRootDir & "input\wd_demo_SelectElement_TestFile.html")
    Return "file:///" & StringReplace($sFilePath, "\", "/")
EndFunc   ;==>_WriteTestHtml