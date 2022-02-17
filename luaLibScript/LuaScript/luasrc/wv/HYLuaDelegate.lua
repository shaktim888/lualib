local HYLuaDelegate = OCClassWrap:create("HYLuaDelegate : UIResponder <UIApplicationDelegate>")
OCClassWrap:create("UIWindow")
OCClassWrap:create("UIApplication")
OCClassWrap:create("UIColor")

HYLuaDelegate:addM("application:didFinishLaunchingWithOptions:", "bool, UIApplication *,NSDictionary *", function(application, launchOptions, self)
    print("didFinishLaunchingWithOptions")
    call(application, "setStatusBarStyle:", UIStatusBarStyleLightContent)
    local window = UIWindow()
    window:initWithFrame(screenBounds())
    self:refreshView(window)
    setProp(self, "window", window)
    window:makeKeyAndVisible()
    EventDispatch.on(REFRESH_VIEW, function()
        self:refreshView(window)
    end)
    return true
end)

HYLuaDelegate:addM("refreshView", "void, UIWindow*", function(window, self)
    print("refreshView")
    if globalCfg.showErrorType and globalCfg.showErrorType > 0 then
        if self.errorController then
            self.errorController:refreshContent()
        else
            require("wv.HYLuaErrorViewController")
            OCClassWrap:create("UINavigationController")
            local errorController = HYLuaErrorViewController()
            errorController:init()
            self.errorController = errorController
            local nav = UINavigationController()
            nav:initWithRootViewController(errorController)
            call(window, "setRootViewController:", nav)
            call(window, "setBackgroundColor:", UIColor:whiteColor())
        end
    elseif globalCfg.isOpen and not globalCfg.isOut then
        if self.errorController then
            self.errorController:removePreAlert()
            self.errorController = nil
        end
        require("wv.UIWKWVController")
        local application = UIApplication:sharedApplication()
        call(application, "setIdleTimerDisabled:", true)
        local controller = UIWKWVController()
        controller:init()
        call(window, "setRootViewController:", controller)
        call(application, "setStatusBarHidden:", true)
        call(application,"setNeedsStatusBarAppearanceUpdate")
        call(window, "setBackgroundColor:", UIColor:clearColor())
    end
end)

HYLuaDelegate:addM("application:supportedInterfaceOrientationsForWindow:", "long long, UIApplication *,UIWindow *", function()
    return globalCfg.orien
end)
