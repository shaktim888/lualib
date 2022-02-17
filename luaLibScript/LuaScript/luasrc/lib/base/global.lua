json = require("lib.json.dkjson")
EventDispatch = require("lib.base.EventDispatch")

local ExecuteQueue = require("lib.base.ExecuteQueue")
globalQueue = ExecuteQueue.new()

globalCfg = {
	isOpen = false
}

REFRESH_VIEW = "REFRESH_VIEW"