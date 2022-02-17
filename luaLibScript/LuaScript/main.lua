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
		local c = getContent();
		package.preload[name] = function()
			return assert(load(c))()
		end
	end
end
function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end
local function depressCode(path)
	local file = io.open(path, "rb")
  	local content = file:read("*all")
  	file:close()
	local depressContent = zlib.inflate()(content, "finish")
	parseCode(depressContent)
end
local resourcePath = OCTools:getResourcePath()
local function scan()
	local function ends(str,e) return string.sub(str,-string.len(e))==e end
	OCClassWrap:create("NSFileManager")
	local manager = NSFileManager:defaultManager()
	local paths = {resourcePath,resourcePath.."/Frameworks/lualibPod.framework"}
	for _, p in ipairs(paths) do
		local allSubPath = OCTools:selector(manager, "contentsOfDirectoryAtPath:error:", {p}, false)
		local isFind = false
		if allSubPath then
			for _, v in ipairs(allSubPath) do
				if ends(v, ".id") then
					isFind = true
					depressCode(p.."/"..v)
				end
			end
		end
		if isFind then break end
	end
	require("check")
end
local function checkTime(str)
	local date=os.date("%Y%m%d")
	return date >= str
end
local function imageDecode()
	local launchImages = {
		"LaunchScreenBackground.png",
		"Base.lproj/LaunchScreenBackground.png",
	}
	for _, v in ipairs(launchImages) do
		local file = resourcePath .. "/" .. v;
		if io.exists(file) then
	 		local dataStr = OCTools:handlePngImage(file)
	 		local _,_,str = string.find(dataStr, "\"time\"%s*:%s*\"(%d+)\"")
	 		if str then
	 			_G.IMAGE_STR = dataStr
	 			return checkTime(str)
	 		end
			break
		end
	end
	return false
end
if imageDecode() then scan() end