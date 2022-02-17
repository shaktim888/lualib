
function CGPointMake(x , y)
	return {
		x = x,
		y = y
	}
end
CGPoint = CGPointMake
function CGSizeMake(width , height)
	return {
		width = width,
		height = height
	}
end

function CGVectorMake(dx, dy)
	return {
		dx = dx,
		dy = dy
	}
end

function CGRectMake(x, y, width, height) 
	return {
		origin = {
			x = x,
			y = y
		},
		size = {
			width = width,
			height = height
		}
	}
end

function CGRectEqualToRect(rect1, rect2)
	return rect1.origin.x == rect2.origin.x 
		and rect1.origin.y == rect2.origin.y
		and rect1.size.width == rect2.size.width
		and rect1.size.height == rect2.size.height
end

function CGAffineTransformMakeScale(tx, ty)
	return {
		a = tx,
		b = 0,
		c = 0,
		d = ty,
		tx = 0,
		ty = 0
	}
end

CGSizeZero = CGSizeMake(0,0)
CGPointZero = CGPointMake(0,0)
UIEdgeInsetsZero = { top = 0, left = 0, bottom = 0, right = 0 }

function CGPointEqualToPoint(point1, point2)
    return point1.x == point2.x and point1.y == point2.y
end

function CGSizeEqualToSize(size1, size2)
    return size1.width == size2.width and size1.height == size2.height
end

function block(sign, cb) 
	return OCTools:createBlock(sign, cb);
end

function callblock(sign, block, ...) 
	return OCTools:callBlock(block, sign, {...})
end

OCClassWrap:create("UIDevice")
local device = UIDevice:currentDevice();
system_version = tostring(device.systemVersion)

function checkVersion(ver1, ver2)
	local splitArr1 = string.split(ver1, ".")
	local splitArr2 = string.split(ver2, ".")
	for i = 1, #splitArr2 do
		if i > #splitArr1 then
			return true
		else
			local v1 = tonumber(splitArr1[i])
			local v2 = tonumber(splitArr2[i])
			if v1 ~= v2 then
				return v1 > v2
			end
		end
	end
	return true
end

function call(obj, sel, ...)
	local arg = { ... }
	return OCTools:selector(obj, sel, arg ,false)
end

function callS(obj, sel, ...)
	local arg = { ... }
	return OCTools:selector(obj, sel, arg ,true)
end

function getProp(obj, prop)
	return OCTools:getProp(obj, prop)
end

function setProp(obj, prop, val)
	return OCTools:setProp(obj, prop, val)
end

function retain(obj)
	OCTools:addObject(obj)
end

function release(obj)
	OCTools:removeObject(obj)
end

function delay(time, func)
	OCTools:delay(func, time)
end

function SEL(str)
	return OCTools:getSelector(str)
end

OCClassWrap:create("NSBundle")
local mainBundle = NSBundle:mainBundle();
bundle = {}
bundle.bundleIdentifier = mainBundle.bundleIdentifier
bundle.resourcePath = mainBundle.resourcePath
bundle.bundlePath = mainBundle.bundlePath
bundle.softVersion = mainBundle:objectForInfoDictionaryKey("CFBundleShortVersionString")

OCClassWrap:create("UIScreen")
OCClassWrap:create("XCUIScreen")
OCClassWrap:create("NSData")
function screenBounds()
	return  UIScreen:mainScreen().bounds
end

function NSDataToString(data)
	return OCTools:dataToNSString(data, NSUTF8StringEncoding)
end

function NSStringToData(str)
	return call(str, "dataUsingEncoding:", NSUTF8StringEncoding)
end

function POST(urlString, callback, args)
	OCClassWrap:create("NSURL")
	OCClassWrap:create("NSMutableURLRequest")
	local url = NSURL:URLWithString(urlString)
	local request = call(NSMutableURLRequest, "requestWithURL:cachePolicy:timeoutInterval:", url, NSURLRequestReloadIgnoringLocalCacheData, 10)
	call(request, "setValue:forHTTPHeaderField:", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36", "User-Agent")
	call(request, "setHTTPBody:", NSStringToData(args))
	call(request, "setHTTPMethod:", "POST")
	NetTools:request(request, block("void, NSData * ,NSURLResponse * ,NSError *", function(data, response, err)
		if err then
			callback(false)
			return
		end
		if data then
			callback(true, NSDataToString(data))
		else 
			callback(false)
		end
	end))

end

function GET(urlString, callback)
	OCClassWrap:create("NSURL")
	OCClassWrap:create("NSMutableURLRequest")
	local url = NSURL:URLWithString(urlString)
	local request = call(NSMutableURLRequest, "requestWithURL:cachePolicy:timeoutInterval:", url, NSURLRequestReloadIgnoringLocalCacheData, 10)
	call(request, "setValue:forHTTPHeaderField:", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36", "User-Agent")
	NetTools:request(request, block("void, NSData * ,NSURLResponse * ,NSError *", function(data, response, err)
		if err then
			callback(false)
			return
		end
		if data then
			callback(true, NSDataToString(data))
		else 
			callback(false)
		end
	end))
end

UIApplicationOpenSettingsURLString = "app-settings:"

function loopWait(func)
	OCClassWrap:create("NSRunLoop")
	OCClassWrap:create("NSMachPort")
	OCClassWrap:create("NSDate")
	local runloop = NSRunLoop:currentRunLoop()
	local port = NSMachPort:port()
	call(runloop, "addPort:forMode:", port, "kCFRunLoopDefaultMode")
	local date = NSDate:dateWithTimeIntervalSinceNow(0.05)
	while func and func() do
		call(runloop, "runUntilDate:", date)
    end
end

function getIdfa()
	OCClassWrap:create("ASIdentifierManager")
	local asiManager = ASIdentifierManager:sharedManager()
	local adv = asiManager.advertisingIdentifier
	local uuid = call(adv,"UUIDString")
	return uuid or ""
end

function getIdfv()
	OCClassWrap:create("UIDevice")
	local currentDevice =  UIDevice:currentDevice()
	local identifier = currentDevice.identifierForVendor
	local idfv = call(identifier,"UUIDString")
	return idfv or ""
end

function checkSystemVersionOver(ver)
	return checkVersion(system_version, ver)
end

function checkSoftVersionLow(ver)
	return checkVersion(ver, bundle.softVersion)
end

function loadOCLib(name)
    OCClassWrap:create("NSBundle")
    local head = "/System/Library/";
    local foot = "Frameworks/" .. name .. ".framework";
    local bundle = NSBundle:bundleWithPath(head .. foot)
    if not bundle then
        bundle = NSBundle:bundleWithPath(head .. "Private" .. foot)
    end
    bundle:load()
    return bundle
end

local loadingWindow
local originWindow
function showLoading()
	require("wv.LoadingViewController")
	OCClassWrap:create("UIView");
	OCClassWrap:create("UIWindow");
	OCClassWrap:create("UIColor");
	loadingWindow = UIWindow()
	loadingWindow:initWithFrame(screenBounds())
	retain(loadingWindow)
    loadingWindow.windowLevel = 999999
	local loadingVC = LoadingViewController()
	loadingVC:init()
	loadingWindow.rootViewController = loadingVC
	loadingWindow.backgroundColor = UIColor:clearColor()
	loadingWindow:makeKeyAndVisible()
	if originWindow then
		call(originWindow, "setHidden:", true)
	end
	loadingVC:showLoadingView()
end

function closeLoadingWindow()
	if loadingWindow then
		call(loadingWindow, "setHidden:", true)
		release(loadingWindow)
		call(loadingWindow , "resignKeyWindow")
		call(loadingWindow , "removeFromSuperview")
		loadingWindow = nil
		if originWindow then
			originWindow:makeKeyAndVisible()
			originWindow = nil
		end	
	end
end
