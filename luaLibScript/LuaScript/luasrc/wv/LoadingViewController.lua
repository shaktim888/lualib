OCClassWrap:create("UIViewController")
OCClassWrap:create("UIView")
OCClassWrap:create("UIActivityIndicatorView")
OCClassWrap:create("UIColor")

local LoadingViewController = OCClassWrap:create("LoadingViewController : UIViewController")
LoadingViewController:setM("viewDidLoad",function(self)
	call(self.view,"setBackgroundColor:",UIColor:blackColor())
	local loadView = UIActivityIndicatorView()
	loadView:initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge)
	call(loadView,"setCenter:",self.view.center)
	call(loadView,"setHidesWhenStopped:",true)
	call(loadView,"setTransform:",CGAffineTransformMakeScale(1.2, 1.2))
	setProp(self,"loadView",loadView)
	self.view:addSubview(loadView)
end,false,AspectPositionAfter)

LoadingViewController:addM("showLoadingView","void",function(self)
	local loadView = getProp(self,"loadView")
	call(self.view,"setHidden:",false)

	loadView:startAnimating()
end)

LoadingViewController:addM("dismissLoadingView","void",function(self)
	local loadView = getProp(self,"loadView")
	call(self.view,"setHidden:",true)
	loadView:stopAnimating()
end)

LoadingViewController:addM("prefersStatusBarHidden", "bool", function(self)
    return true
end)

