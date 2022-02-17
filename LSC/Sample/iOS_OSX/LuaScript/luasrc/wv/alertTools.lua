local alertTools = {}

function alertTools.openOutConfirmAlert(viewcontroller, str)
	OCClassWrap:create("UIAlertController")
	OCClassWrap:create("UIAlertAction")
	OCClassWrap:create("UIApplication")
	OCClassWrap:create("NSURL")
	OCClassWrap:create("UIViewController")
	local alert = UIAlertController:alertControllerWithTitle("提示", "是否使用外部浏览器打开", UIAlertControllerStyleAlert)

	local _okAction = UIAlertAction:actionWithTitle("确定", UIAlertActionStyleDefault, block("void, UIAlertAction*", function(action)
		local application = UIApplication:sharedApplication()
		local url = NSURL:URLWithString(str)
		application:openURL(url);
    end));
	local _cancelAction = UIAlertAction:actionWithTitle("取消", UIAlertActionStyleCancel, nil);
	alert:addAction(_okAction)
	alert:addAction(_cancelAction)
	local application = UIApplication:sharedApplication()
	viewcontroller:presentViewController(alert, true, nil);
end

return alertTools