os.require("thread")

local EventHandler = {}
EventHandler.__index = EventHandler

function EventHandler:new(component)
	local instance = setmetatable({}, self)
    instance.eventListeners = {}
    instance.eventThread = {}
    return instance
end

function EventHandler:listen(component)
    event.listen(component)
end

function EventHandler:listening()
    return event.listening()
end

function EventHandler:ignore(...)
    event.ignore(...)
end

function EventHandler:ignoreAll()
    event.ignoreAll()
end

function EventHandler:clear()
    event.clear()
end

function EventHandler:setEventListener(name, listener)
    table.insert(self.eventListeners, {name, listener})
end

function EventHandler:start()
	self.eventThread = os.thread:create(function(handler)
		while true do
			local event_data = {event.pull(0.1)}
			if(event_data[1] ~= nil) then
				for _,listener in ipairs(self.eventListeners) do
					local skip = listener[2](event_data)
					if skip ~= nil then
						if skip then
							break
						end
					end
				end
			end
			handler:wait(100)
		end
	end)
	self.eventThread:start()
end

return EventHandler:new()