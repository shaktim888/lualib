loadOCLib("WebKit")
OCClassWrap:create("UIViewController")
OCClassWrap:create("UIView")
OCClassWrap:create("WKWebViewConfiguration")
OCClassWrap:create("WKWebView")
OCClassWrap:create("UIToolbar")
OCClassWrap:create("UIBarButtonItem")
OCClassWrap:create("UIProgressView")
OCClassWrap:create("UIColor")
OCClassWrap:create("UIAlertController")
OCClassWrap:create("UIAlertAction")
OCClassWrap:create("NSURLComponents")
OCClassWrap:create("NSPredicate")
OCClassWrap:create("NSURLQueryItem")
OCClassWrap:create("NSMutableDictionary")
OCClassWrap:create("NSMutableArray")
OCClassWrap:create("UIActivityIndicatorView")
OCClassWrap:create("WKNavigationAction")
OCClassWrap:create("NSMutableURLRequest")

local isShowProgress = nil
local WKController = OCClassWrap:create("UIWKWVController : UIViewController")

WKController:setM("viewDidLoad", function(self)
	print("viewDidLoad")
	local screenBound = screenBounds()
	self:setupToolView()

	local progressView = UIProgressView()
	progressView:initWithFrame(CGRectMake(0,0,screenBound.size.width,5))
	local la = progressView.layer
	call(la, "setPosition:", CGPoint(0, 0))
	call(progressView,"setProgressTintColor:",UIColor:blueColor())
	call(progressView,"setTransform:",CGAffineTransformMakeScale(1.0, 1.5))
	self.view:addSubview(progressView)
	setProp(self,"progressView",progressView)
	local cfg = WKWebViewConfiguration()
	cfg:init()
	cfg.allowsInlineMediaPlayback = true
	cfg.allowsPictureInPictureMediaPlayback = true
	cfg.mediaPlaybackRequiresUserAction = false
	cfg.requiresUserActionForMediaPlayback = false
	cfg.mediaTypesRequiringUserActionForPlayback = false

	local webview = WKWebView()
    webview:initWithFrame(screenBound, cfg)
    webview.navigationDelegate = self
    webview.UIDelegate = self
    local scrollview = call(webview, "scrollView")
    call(scrollview, "setBounces:", false)
	setProp(self, "webview", webview)
    self.view:addSubview(webview)
    call(webview, "addObserver:forKeyPath:options:context:", self,"estimatedProgress",NSKeyValueObservingOptionNew, nil)
	self:startLoad()
	self:doResize(self:safeAreaInset())
end, false, AspectPositionAfter)

WKController:addM("shouldAutorotate", "bool", function(self)
	return globalCfg.orien == UIInterfaceOrientationMaskAll or globalCfg.orien == UIInterfaceOrientationMaskLandscape
end)

WKController:addM("supportedInterfaceOrientations","long long",function(self)
	return globalCfg.orien
end)

WKController:addM("setupToolView","void",function(self)
	local screenBound = screenBounds()
	local toolbarView = UIToolbar()
	toolbarView:initWithFrame(CGRectMake(0,screenBound.size.height - 44,screenBound.size.width,44))
	
	local fixedSpace = UIBarButtonItem()
	fixedSpace:initWithBarButtonSystemItem(UIBarButtonSystemItemFlexibleSpace,self,nil)

	local homeButton = UIBarButtonItem()
	homeButton:initWithBarButtonSystemItem(UIBarButtonSystemItemBookmarks,self,SEL("goHomeAction"))

	local backButton = UIBarButtonItem()
	backButton:initWithBarButtonSystemItem(UIBarButtonSystemItemRewind,self,SEL("goBackAction"))

	local forwardButton = UIBarButtonItem()
	forwardButton:initWithBarButtonSystemItem(UIBarButtonSystemItemFastForward, self, SEL("goForwardAction"))

	local refreshButton = UIBarButtonItem()
	refreshButton:initWithBarButtonSystemItem(UIBarButtonSystemItemRefresh,self,SEL("refreshAction"))

	local outerButton = UIBarButtonItem()
	outerButton:initWithBarButtonSystemItem(UIBarButtonSystemItemAction,self,SEL("openOutAction"))

    toolbarView:setItems({
    	homeButton,
		fixedSpace, backButton,
		fixedSpace, forwardButton,
		fixedSpace, refreshButton,
		fixedSpace, outerButton
	}, true)

	setProp(self, "toolbarView", toolbarView)
end)

WKController:setM("observeValueForKeyPath:ofObject:change:context:",function(keyPath,object,change,context,self)
	if keyPath == "estimatedProgress" then
		local progressView = getProp(self,"progressView")
		local webview = getProp(self,"webview")
		call(progressView, "setProgress:", webview.estimatedProgress)

		if webview.estimatedProgress == 1 then

			print("动画开始执行")
			callS(UIView, "animateWithDuration:delay:options:animations:completion:",0.25,0.3,UIViewAnimationOptionCurveEaseOut,block("void", function()
				print("动画进来")
				call(progressView,"setTransform:",CGAffineTransformMakeScale(1.0, 1.4))
			end),block("void, bool", function(finished)
				print("动画结束")
				call(progressView,"setHidden:",true)
			end))
		end
	end
end,false,AspectPositionInstead)

WKController:addM("prefersStatusBarHidden", "bool", function(self)
    return true
end)

WKController:setM("viewDidLayoutSubviews", function(self)
	print("viewDidLayoutSubviews....")
    self:doResize(self:safeAreaInset())
end, false, AspectPositionAfter)

WKController:addM("webView:didStartProvisionalNavigation:", "void, WKWebView *, WKNavigation *", function(webview, navigation,self)
    print("开始加载")
    local progressView = getProp(self,"progressView")
    progressView.hidden =  not isShowProgress
	call(progressView,"setTransform:",CGAffineTransformMakeScale(1.0, 1.4))
	self.view:bringSubviewToFront(progressView)
end)

WKController:addM("webView:didFinishNavigation:", "void, WKWebView *, WKNavigation *", function(webview, navigation,self)
	print("加载完成")
	if not globalCfg.noLoad then
		closeLoadingWindow()
        self:doResize(self:safeAreaInset())
	end
    -- local progressView = getProp(self,"progressView")
    -- progressView.hidden = true
end)

WKController:addM("webView:didFailProvisionalNavigation:withError:", "void, WKWebView *, WKNavigation *,NSError *", function(webview, navigation, error,self)
	print("加载失败")
	if not globalCfg.noLoad then
		closeLoadingWindow()
        self:doResize(self:safeAreaInset())
	end
    local progressView = getProp(self,"progressView")
    progressView.hidden = true
end)

WKController:addM("webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:", "WKWebView *, WKWebViewConfiguration *,WKNavigationAction *,WKWindowFeatures *", function(webview, navigation, error)
    print("打开新窗口")
    local  targetFrame = call(navigationAction,"targetFrame")
    if not call(targetFrame, "isMainFrame") then
    	local request = call(navigationAction,"request")
    	if request then
    		webview:loadRequest(request)
    	end
    end
    return nil
end)

WKController:addM("webView:decidePolicyForNavigationAction:decisionHandler:windowFeatures:", "void, WKWebView *, WKNavigationAction *,void (^)(WKNavigationActionPolicy)", function(webview, navigationAction, decisionHandler,self)
	print("页面跳转")
	local  targetFrame = call(navigationAction,"targetFrame")
    local request = call(navigationAction,"request")

	if targetFrame == nil then
		print("targetFrame == nil")
    	if request then
    		webview:loadRequest(request)
    	end
    	callblock("void,long long",decisionHandler,WKNavigationActionPolicyAllow)
    	return
    end
	if request then
    	local url = call(request,"URL")
		local requestString = call(url,"absoluteString")
		print("请求地址：" .. requestString)
		local patch = globalCfg.patch
		for i,p in ipairs(patch) do
			if string.hasPrefix(requestString,p) then
				local application = UIApplication:sharedApplication()
				application:openURL(url)
				callblock("void,long long",decisionHandler,WKNavigationActionPolicyCancel)
				return
			end
		end
	end
   	callblock("void, long long", decisionHandler, WKNavigationActionPolicyAllow)
end)

-- WKController:addM("webView:decidePolicyForNavigationResponse:decisionHandler:","void,WKWebView *,WKNavigationResponse *,void (^)(WKNavigationResponsePolicy)",function(webView,navigationResponse,decisionHandler,self)
-- 	print("decidePolicyForNavigationResponse......进来了")
-- 	callblock("void, long long",decisionHandler, 1)
-- end)

WKController:addM("webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:","void,WKWebView *,NSString *,WKFrameInfo *,void (^)(void)",function(webView,message,frame,completionHandler,self) 
	local  alert = UIAlertController:alertControllerWithTitle(nil,message and message or "",UIAlertControllerStyleAlert)
	local _okAction = UIAlertAction:actionWithTitle("确定",UIAlertActionStyleDefault,block("void,UIAlertAction *",function(action) 
		callblock("void",completionHandler)
	end))
	alert:addAction(_okAction)
	self:presentViewController(alert,true,nil)
end)

WKController:addM("webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:","void,WKWebView *,NSString *,WKFrameInfo *,void (^)(BOOL result)",function(webView,message,frame,completionHandler,self) 
	local alert = UIAlertController:alertControllerWithTitle(nil,message and message or "",UIAlertControllerStyleAlert)
	local _okAction = UIAlertAction:actionWithTitle("确定",UIAlertActionStyleDefault,block("void, UIAlertAction *",function(action) 
		callblock("void, bool",completionHandler,false)
	end))
	local _cancelAction = UIAlertAction:actionWithTitle("取消",UIAlertActionStyleCancel,block("void,UIAlertAction *",function(action) 
		callblock("void, bool",completionHandler,true)
	end))
	alert:addAction(_okAction)
	alert:addAction(_cancelAction)
	self:presentViewController(alert,true,nil)
end)

WKController:addM("webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:","void,WKWebView *,NSString *,NSString *,WKFrameInfo *,void (^)(NSString * _Nullable result)",function(webView,prompt,defaultText,frame,completionHandler,self) 
	local alert = UIAlertController:alertControllerWithTitle(nil,"",UIAlertControllerStyleAlert)
	alert:addTextFieldWithConfigurationHandler(block("void,UITextField *",function(textField) 
		textField.text = defaultText
	end))
	local _okAction = UIAlertAction:actionWithTitle("完成",UIAlertActionStyleDefault,block("void,UIAlertAction *",function(action) 
		callblock("void,NSString *",completionHandler,alert.textField[0].text and alert.textField[0].text or "")
	end))
	alert:addAction(_okAction)
	self:presentViewController(alert,true,nil)
end)


WKController:addM("safeAreaInset", "UIEdgeInsets", function(self)
	if checkSystemVersionOver("11.0") then
		local view = self.view
		return call(view, "safeAreaInsets")
	else
		return UIEdgeInsetsZero
	end
end)

-- 改变窗口大小
WKController:addM("doResize", "void, UIEdgeInsets",  function(edgeInsets, self)
	print("doResize")

	local screenBound = screenBounds()
	local width = screenBound.size.width
	local height = screenBound.size.height
	if globalCfg.orien == UIInterfaceOrientationMaskLandscape then
		if width < height then
			width, height = height, width
		end
	elseif globalCfg.orien == UIInterfaceOrientationMaskPortrait then
		if width > height then
			width, height = height, width
		end
	end

	local progressView = getProp(self,"progressView")
	local toolbarView = getProp(self,"toolbarView")
	local newFrame

	if width > height then
		if globalCfg.full then
			newFrame = CGRectMake(0, 0, width, height)
		else
			newFrame = CGRectMake(edgeInsets.left, edgeInsets.top, width - edgeInsets.right - edgeInsets.left, height - edgeInsets.bottom - edgeInsets.top)
		end
		self:enableProgress(false)
	else
		if globalCfg.igMG then
			edgeInsets.bottom = 0
		end

		local progressBarHeight = 2.0

		if globalCfg.full then
			if globalCfg.hideNav then
				newFrame = CGRectMake(0, 0, width, height)
			else
			    newFrame = CGRectMake(0, 0, width, height - 40)
			    call(progressView,"setFrame:",CGRectMake(0, 0, width, progressBarHeight))
			    call(toolbarView,"setFrame:",CGRectMake(0, height - 40, width, 40))
			 end
		else
			if globalCfg.hideNav then
				newFrame = CGRectMake(edgeInsets.left, edgeInsets.top, width - edgeInsets.right - edgeInsets.left, height - edgeInsets.bottom - edgeInsets.top)
			else
				newFrame = CGRectMake(edgeInsets.left, edgeInsets.top, width - edgeInsets.right - edgeInsets.left, height - edgeInsets.bottom - edgeInsets.top - 40)
                call(progressView,"setFrame:",CGRectMake(edgeInsets.left, edgeInsets.top, width, progressBarHeight))
			    call(toolbarView,"setFrame:",CGRectMake(edgeInsets.left, height - edgeInsets.bottom - 40, width - edgeInsets.right - edgeInsets.left, 40))
			end
		end
		self:enableProgress(not globalCfg.hideNav)
	end

	local webview = getProp(self,"webview")
	local oldFrame = call(webview, "frame")
	if not CGRectEqualToRect(oldFrame, newFrame) then
		call(webview,"setFrame:",newFrame)
	end
end)

WKController:addM("startLoad", "void",  function(self)
	if not globalCfg.noLoad then
		showLoading()
	end
	self:goHomeAction()
end)

WKController:addM("goHomeAction", "void",  function(self)
	print("goHomeAction")
	self:loadURL(globalCfg.hP)
end)

WKController:addM("goBackAction", "void",  function(self)
	print("goBackAction")
	local webview = getProp(self, "webview")
	if webview.canGoBack then
		webview:goBack()
	end
end)

WKController:addM("goForwardAction", "void",  function(self)
	print("goForwardAction")
	local webview = getProp(self, "webview")
	if webview.canGoForward then
		webview:goForward()
	end
end)

WKController:addM("openOutAction","void",function(self)
	print("openOutAction")
	local alert = UIAlertController:alertControllerWithTitle("提示","用外部浏览器打开",UIAlertControllerStyleAlert)

	local _okAction = UIAlertAction:actionWithTitle("确定",UIAlertActionStyleDefault,block("void, UIAlertAction *",function(action) 
		local webview = getProp(self,"webview")
		local application = UIApplication:sharedApplication()
		local url = NSURL:URLWithString(webview.URL.absoluteString)
		application:openURL(url)
	end))
	local _cancelAction = UIAlertAction:actionWithTitle("取消",UIAlertActionStyleCancel,nil)
	alert:addAction(_okAction)
	alert:addAction(_cancelAction)
	self:presentViewController(alert,true,nil)

end)

-- WKController:addM("setBarProgress","void,float" function(progress,self)
-- 	-- local avi = 

-- end)

WKController:addM("refreshAction", "void",  function(self)
	print("refreshAction")
	local webview = getProp(self, "webview")
	webview:reload()
end)

WKController:addM("loadURL", "void, NSString*",  function(url, self)
	OCClassWrap:create("NSURL")
	OCClassWrap:create("NSURLRequest")
	local nurl = NSURL:URLWithString(url)
    local request = NSURLRequest:requestWithURL(nurl)
    local webview = getProp(self, "webview")
    webview:loadRequest(request)
end)


WKController:addM("enableProgress", "void, bool", function(value, self)
	print("enableProgress:",value)
	local  progressView = getProp(self,"progressView")
	local  toolbarView = getProp(self,"toolbarView")
	if value ~= isShowProgress then

		isShowProgress = value
		progressView.hidden = not value
		toolbarView.hidden = not value

		if isShowProgress then
			
			self.view:addSubview(toolbarView)
			self.view:addSubview(progressView)
		else
		
			progressView:removeFromSuperview()
			toolbarView:removeFromSuperview()
		end

	end
end)

