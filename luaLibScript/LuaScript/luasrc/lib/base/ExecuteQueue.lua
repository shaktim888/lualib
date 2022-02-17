local ExecuteQueue = class("ExecuteQueue")

function ExecuteQueue:ctor()
    self.queue = {}
    self.index = 0
end

function ExecuteQueue:addStep(func)
    self.queue[#self.queue + 1] = func
end

function ExecuteQueue:next()
    if self.index < #self.queue then
        self.index = self.index + 1
        local func = self.queue[self.index]
        if func then func() end
    end
end

return ExecuteQueue