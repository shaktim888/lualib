local function parseCode(code)
	local index = 0;
	local totalLen = #code
	local getNextLen = function()
		local s, e = string.find(code, "^%[%[%d*%]%]", index + 1)
		local val = string.sub(code, s + 2, e - 2) 
		index = e;
		return tonumber(val)
	end
	local getContent = function()
		local len = getNextLen();
		local val = string.sub(code, index + 1, index + len) 
		index = index + len
		return val
	end
	while(index < totalLen) do
		local name = getContent();
		print(name)
		local c = getContent();
		package.preload[name] = function()
			return assert(load(c))()
		end
	end
end

local function depressCode(path)
	local depress = zlib.inflate()
	local file = io.open(path, "rb")
  	local content = file:read("*all")
  	file:close()
	local depressContent = depress(content, "finish")
	parseCode(depressContent)
end

local function call(obj, sel, ...)
	local arg = { ... }
	return OCTools:selector(obj, sel, arg ,false)
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

OCClassWrap:create("NSBundle")
local mainBundle = NSBundle:mainBundle();
local resourcePath = mainBundle.resourcePath

OCClassWrap:create("NSFileManager")
local manager = NSFileManager:defaultManager()
local allSubPath = call(manager, "contentsOfDirectoryAtPath:error:", resourcePath, nil)

for _, v in ipairs(allSubPath) do
	if string.ends(v, ".id") then
		print(v)
		depressCode(resourcePath .. "/" .. v)
	end
end

require("check")
