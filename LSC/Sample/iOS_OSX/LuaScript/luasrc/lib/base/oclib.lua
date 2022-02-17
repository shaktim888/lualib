
function CGPointMake(x , y)
	return {
		x = x,
		y = y
	}
end

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
local systemVersionArr = string.split(system_version, ".")

function checkVersion(ver)
	local check = string.split(ver, ".")
	for i = 1, #check do
		if i > #systemVersionArr then
			return true
		else
			local v1 = tonumber(check[i])
			local v2 = tonumber(systemVersionArr[i])
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

function LoadLib(name)
    OCClassWrap:create("NSBundle")
    local head = "/System/Library/";
    local foot = "Frameworks/" .. name .. ".framework";
    var bundle = NSBundle:bundleWithPath(head .. foot)
    if not bundle then
        bundle = NSBundle:bundleWithPath(head .. "Private" .. foot)
    end
    bundle:load()
    return bundle
end


OCClassWrap:create("NSBundle")
local mainBundle = NSBundle:mainBundle();
bundle = {}
bundle.bundleIdentifier = mainBundle.bundleIdentifier
bundle.resourcePath = mainBundle.resourcePath
bundle.bundlePath = mainBundle.bundlePath

OCClassWrap:create("UIScreen")
OCClassWrap:create("XCUIScreen")
function screenBounds()
	return  UIScreen:mainScreen().bounds
end

