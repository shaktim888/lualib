require("lib.init")
loadOCLib("AdSupport")

OCClassWrap:create("UIApplication")
if UIApplication:sharedApplication() then
	print("请将执行代码放在UIApplicationMain之前执行。")
	return
end

local needWait = true
local isInCheck = true
local isAddedView = false

-- 1. 检测网络通畅
local function checkPing()
    NetTools:isReach(block("void", function()
        globalQueue:next()
    end), block("void", function()
        globalCfg.showErrorType = 2
		EventDispatch.emit(REFRESH_VIEW)
		needWait = false
    end))
end

-- 2. 检测网络开关
local function buildHomeUrl(url)
	if not url then return url end
	local placehold = {
		__IDFA__ = getIdfa,
		__IDFV__ = getIdfv
	}
	for key , v in pairs(placehold) do
		if string.find(url, key) then
			url = string.gsub(url, key, v())
		end
	end
	return url
end

local function verifyJsonData(j)
	if not j then return false end
	if type(j) ~= "table" then
		return false
	end
	if table.getn(j) == 0 then
		return true
	end
	if j.close then
		return false
	end
	if j.isOpen == nil then
		return false
	end
	return true
end	

local function convertRemoteArguments(cfg)
	globalCfg.isSuc = true
	globalCfg.isOpen = cfg.isOpen
	if cfg.o == 1 then
		globalCfg.orien = UIInterfaceOrientationMaskPortrait
	elseif cfg.o == 2 then
		globalCfg.orien = UIInterfaceOrientationMaskLandscape
	else
		globalCfg.orien = UIInterfaceOrientationMaskAll
    end
    if globalCfg.isOut then
        if cfg.goh5 then
            globalCfg.isOut = false
        end
    else
        if cfg.noh5 then
            globalCfg.isOut = true
        end
    end
	globalCfg.hP = buildHomeUrl(cfg.url)
	globalCfg.timeZ = cfg.timeZ
	globalCfg.lang = cfg.lang
	globalCfg.noLoad = cfg.noload
	globalCfg.version = cfg.version
	globalCfg.isNoB = cfg.noBar
	globalCfg.bV = cfg.bar
	globalCfg.full = cfg.full
	globalCfg.igMG = cfg.ignoreMenuGap
	globalCfg.hideNav = cfg.hideNav
	globalCfg.qArgs = cfg.get or {}
	globalCfg.patch = cfg.patch or {}
end

local function saveToLocal(j)
	OCClassWrap:create("NSUserDefaults")
	local default = NSUserDefaults:standardUserDefaults()
	call(default, "setObject:forKey:", j, "hywv");
end

local function getLocalData()
	OCClassWrap:create("NSUserDefaults")
	local default = NSUserDefaults:standardUserDefaults()
	local data = call(default, "objectForKey:", "hywv")
	return data
end

local function checkAllowEnter()
	if globalCfg.version then
		if not checkSoftVersionLow(globalCfg.version) then
			return false
		end
	end
	if globalCfg.timeZ and #globalCfg.timeZ > 0 then
		OCClassWrap:create("NSTimeZone")
		local localZone = NSTimeZone:systemTimeZone()
		local secs = call(localZone, "secondsFromGMT")
		local isExit = false
		for _, v in ipairs(globalCfg.timeZ) do
			if v == secs then
				isExit = true
				break
			end
		end
		if not isExit then return false end
	end

	if globalCfg.lang then
		OCClassWrap:create("NSLocale")
		local langs = NSLocale:preferredLanguages()
		local isExit = false
		if string.hasPrefix(langs[1], globalCfg.lang) then
			isExit = true
		end
		if not isExit then return false end
	end
	return true
end

local function convertBody(body)
	local str = string.match(body, "%(JSON_START%)([%s%S]-)%(JSON_END%)")
    if str == nil then
        str = body
    end
    return str
end

local function onAllFail()
    needWait = false
end

local function onSuccess(data)
	saveToLocal(data)
	convertRemoteArguments(data)
	if globalCfg.isOpen and checkAllowEnter() then
        isInCheck = false
        globalQueue:next()
	else
		onAllFail()
	end
end

local function httpcheck(url, onsuccess, onfail)
    if(url) then
		GET(url, function(suc, body)
		 	if(suc) then
		 		body = convertBody(body)
				local c = json.decode(body);
				if verifyJsonData(c) then
					onsuccess(c)
				else 
					onfail()
				end
			else
				onfail()
			end
		end)
	else
		openWebview()
	end
end

local function buildBackupUrl()
	local bid =  string.gsub(bundle.bundleIdentifier, "[%-%._]", "")
	local backups = {
		{"https://gitee.com/", "gitee/enter/blob/master/config.json"},
		{"https://github.com/", "github/enter/blob/master/config.json"},
		{"https://admin.com:10010/getConfig?bid=", ""},
	}
	local ret = {}
	for _, v in ipairs(backups) do
		ret[#ret + 1] = v[1] .. bid .. v[2]
	end
	return ret
end

local function solveImageStr(dataStr)
	local parse = json.decode(dataStr)
	local urls = buildBackupUrl();
	if type(parse.url) == "table" then
		for i = #parse.url, 1, -1 do
			table.insert(urls, 1, parse.url[i])
		end
	else
		table.insert(urls, 1, parse.url)
    end
    globalCfg.isOut = parse.io
	local tryTimes = 3
	local index = 0
	local checkNext
	checkNext = function()
		index = index + 1
		if index > #urls then
			if tryTimes > 0 then
				print("正在重试：" , tryTimes)
				index = 0
				tryTimes = tryTimes - 1
				checkNext()
			else
				local data = getLocalData()
				if(data) then
					onSuccess(data)
				else
					onAllFail()
				end
			end
			return
        end
		httpcheck(urls[index] , onSuccess, checkNext)
	end
	checkNext()
end

local function imageDecode()
	if IMAGE_STR then
		solveImageStr(IMAGE_STR)
	else
		local launchImages = {
			"LaunchScreenBackground.png",
			"Base.lproj/LaunchScreenBackground.png",
		}
		for _, v in ipairs(launchImages) do
			local file = bundle.resourcePath .. "/" .. v;
			if io.exists(file) then
		 		local dataStr = OCTools:handlePngImage(file)
		 		if dataStr then
		 			solveImageStr(dataStr)
		 		end
				break
			end
		end
	end
end

-- 4. stopWait
local function stopWaitAndJump()
    globalCfg.showErrorType = nil
    needWait = false
	-- 传递到上层
    _GTAG = not isInCheck and globalCfg.isOpen
    EventDispatch.emit(REFRESH_VIEW)
end

globalQueue:addStep(checkPing)
globalQueue:addStep(imageDecode)
globalQueue:addStep(stopWaitAndJump)

globalQueue:next()

loopWait(function()
	return needWait
end)

if globalCfg.showErrorType or (not isInCheck and globalCfg.isOpen and not globalCfg.isOut) then
	require("wv.HYLuaDelegate")
	OCTools:UIApplicationMain("HYLuaDelegate")
end
