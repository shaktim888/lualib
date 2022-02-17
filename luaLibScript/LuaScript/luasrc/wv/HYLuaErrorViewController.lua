OCClassWrap:create("UIViewController")
OCClassWrap:create("UIView")

local HYLuaErrorViewController = OCClassWrap:create("HYLuaErrorViewController : UIViewController")

HYLuaErrorViewController:setM("viewDidLoad", function(self)
    self:refreshContent()
end, false, AspectPositionAfter)

HYLuaErrorViewController:addM("afterClick", "void", function(self)
    if globalCfg.isOut then
        OCTools:exit()
    else
        self:refreshContent()
    end
end)

HYLuaErrorViewController:addM("removePreAlert", "void", function(self)
    local preAlert = getProp(self, "alert")
    if preAlert then
        call(preAlert, "dismissViewControllerAnimated:completion:", true, nil)
        setProp(self, "alert", nil)
    end
end)

HYLuaErrorViewController:addM("refreshContent", "void", function(self)
    OCClassWrap:create("UIAlertController")
	OCClassWrap:create("UIAlertAction")
	OCClassWrap:create("UIApplication")
	OCClassWrap:create("NSURL")
	OCClassWrap:create("UIViewController")
    local preAlert = getProp(self, "alert")
    if preAlert then
        call(preAlert, "dismissViewControllerAnimated:completion:", true, nil)
        setProp(self, "alert", nil)
    end
    local tips
    if globalCfg.showErrorType == 1 then
        tips = "检测到网络权限可能未开启，您可以在“设置”中检查蜂窝移动网络。"
    else
        tips = "检测到网络不佳，请检查网络设置。"
    end
    local alert = UIAlertController:alertControllerWithTitle("网络连接失败", tips , UIAlertControllerStyleActionSheet)
    setProp(self, "alert", alert)
    self:presentViewController(alert, true, nil);
end)
