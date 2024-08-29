local ThreadManager = {}
ThreadManager.__index = ThreadManager

local Thread = {}
Thread.__index = Thread

local ThreadController = {}
ThreadController.__index = ThreadController

function ThreadManager:new()
    local instance = setmetatable({}, self)
    instance.running = false
    instance.threads = {}
    return instance
end

function ThreadManager:create(func)
    return Thread:new(func)
end

function ThreadManager:listen(thread)
    table.insert(self.threads, thread)
end

function ThreadManager:stop()
    self.running = false
end

function ThreadManager:start()
    self.running = true
    while self.running do
        for i = #self.threads, 1, -1 do
            local thread = self.threads[i]
            if thread.isSuspended then
                table.remove(self.threads, i)
            else
                if thread.nextrun < computer.millis() then
                    local success, time = coroutine.resume(thread.routine, thread.threadcontroller)
                    if not success then
                        thread:terminate()
                    else
                        thread.nextrun = computer.millis() + (time or 0)
                    end
                end
            end
        end
    end
end

function ThreadController:new(thread)
    local instance = setmetatable({}, self)
    instance.thread = thread
    return instance
end

function ThreadController:stop()
    self.thread:terminate()
    coroutine.yield(0)
end

function ThreadController:next()
    self:wait(0)
end

function ThreadController:wait(time)
    coroutine.yield(time or 0)
end

function Thread:new(func)
    local instance = setmetatable({}, self)
    instance.isSuspended = false
    instance.nextrun = 0
    instance.routine = coroutine.create(func)
    instance.threadcontroller = ThreadController:new(instance)
    return instance
end

function Thread:terminate()
    self.isSuspended = true
end

function Thread:start()
    os.thread:listen(self)
end

return ThreadManager:new()