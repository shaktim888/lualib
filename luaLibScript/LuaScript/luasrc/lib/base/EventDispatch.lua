local EventDispatch = class("EventDispatch")

local All_Listener = {} --添加监听的回调集合

-- 添加一个事件监听
function EventDispatch.on(eventName,callback,tag)
	All_Listener[eventName] = All_Listener[eventName] or {}
	local l = {}
	l.callback = callback
	l.tag = tag
	table.insert(All_Listener[eventName], l)
end

-- 移除这个函数对应的所有监听
function EventDispatch.offByFunc(callback)
	for k,listener in pairs(All_Listener) do
		for i=#listener,1,-1 do
			if listener[i].callback == callback then
				table.remove(listener,i)
			end
		end
	end
end

-- 移除所有对应事件名的所有回调,注意会移除其他人注册的哦!!
function EventDispatch.offByName(eventName)
	All_Listener[eventName] = nil
end

-- 移除所有对应事件名绑定的对象的所有回调
function EventDispatch.offByTag(eventName,tag)
	local listener = All_Listener[eventName] or {}
	for i=#listener,1,-1 do
		if listener[i].tag == tag then
			table.remove(listener,i)
		end
	end
end

-- 分发一个对应事件名的数据
function EventDispatch.emit(eventName, data, target)
	-- data should be nil
	local listeners = All_Listener[eventName] or {}
	for i=#listeners,1,-1 do
		local flag = nil
		xpcall(function ()
			flag = listeners[i].callback(data,eventName)
		end, __catchExcepitonHandler)
		if type(flag) == "boolean" and flag == true then
			return
		end
	end
end

return EventDispatch