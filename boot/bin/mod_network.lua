os.require("events")
os.require("thread")

local NetworkServer = {}
NetworkServer.__index = NetworkServer

local NetworkManager = {}
NetworkManager.__index = NetworkManager

NetworkManager.COMMAND = {
	PING = 0,
	PING_UPDATE = 1,
	UPDATE_OS = 2,
	POWER = 3
}

NetworkManager.EVENT = {
	CONNECT = 0,
	DISCONNECT = 1,
	UPDATE = 2
}
function NetworkServer:new(id, name, port, osName, osVersion, biosVersion)
	local instance = setmetatable({}, self)
	instance.id = id
	instance.name = name
   	instance.port = port
	instance.osName = osName
	instance.osVersion = osVersion
	instance.biosVersion = biosVersion
	instance.pingTimeout = 10 * 1000
	instance.lastPing = computer.millis()
	return instance
end

function NetworkServer:refresh()
	self.lastPing = computer.millis()
end

function NetworkServer:isAlive()
	return computer.millis() < self.lastPing + self.pingTimeout
end

function NetworkManager:new(network, id, name, port)
	local instance = setmetatable({}, self)
	instance.network = network
	instance.id = id
	instance.name = name
    instance.port = port
    instance.broadcastPort = 99
	instance.pingInterval = 5 * 1000
	instance.servers = {}
	instance.eventListeners = {}
	return instance
end

function NetworkManager:registerEventListener(id, func)
	self.eventListeners[id] = func
end

function NetworkManager:unregisterEventListener(id)
	self.eventListeners[id] = nil
end

function NetworkManager:fireEvent(type, server)
	for _,listener in pairs(self.eventListeners) do
		local success, response = pcall(listener, type, server)
		if(not success) then
			print("could not fire event due to invalid listener")
		end
	end
end

function NetworkManager:startPingThread()
	self.pingThread = os.thread:create(function(handler)
		self:broadcast(self.COMMAND.PING_UPDATE, self.id, self.name, self.port, os.NAME, os.VERSION, bios.VERSION)
		while true do
			self:broadcast(self.COMMAND.PING, self.id, self.name, self.port, os.NAME, os.VERSION, bios.VERSION)
			for id, server in pairs(self.servers) do
				if not server:isAlive() then
					self:fireEvent(self.EVENT.DISCONNECT, self.servers[id])
					self.servers[id] = nil
				end
			end
			handler:wait(self.pingInterval)
		end
	end)
	self.pingThread:start()
end

function NetworkManager:startListenerThread()
	os.events:listen(self.network)
	os.events:setEventListener("NetworkManager", function (event_data)
		if(event_data[1] == "NetworkMessage") then
			if(event_data[3] ~= self.network.id) then
				if(event_data[5] == self.COMMAND.PING or event_data[5] == self.COMMAND.PING_UPDATE) then
					local port = event_data[6]
					local id = event_data[7]
					local name = event_data[8]
					local osName = event_data[9]
					local osVersion = event_data[10]
					local biosVersion = event_data[11]
					local server = self.servers[tostring(id)]
					if(server == nil or self.COMMAND.PING_UPDATE) then
						local newServer = NetworkServer:new(id, name, port, osName, osVersion, biosVersion)
						self.servers[tostring(id)] = newServer
						if(server == nil) then
							self:fireEvent(self.EVENT.CONNECT, newServer)
						elseif(event_data[5] == self.COMMAND.PING_UPDATE) then
							--Made change so that PING_UPDATE sends can send a message to another computer
							self:fireEvent(self.EVENT.UPDATE, event_data[6])
						end
					else
						server:refresh()
					end
				elseif(event_data[5] == self.COMMAND.UPDATE_OS) then
					local url = event_data[6]
					os.updateOS(url)
				end
				return true
			end
		end
	end)
end

function NetworkManager:broadcast(command, ...)
	self.network:broadcast(self.broadcastPort, command, ...)
end
 

function NetworkManager:sendMessage(port, command, ...)
	self.network:broadcast(port, command, ...)
end

function NetworkManager:start()
	self.network:open(self.broadcastPort)
	self.network:open(self.port)
	self:startPingThread()
	self:startListenerThread()
end

if(os.SETTINGS.NETWORK.PORT == nil) then
	print("missing `SETTINGS.NETWORK.PORT` in settings")
	return nil
elseif(os.SETTINGS.NETWORK.ID == nil) then
	print("missing `SETTINGS.NETWORK.ID` in settings")
	return nil
elseif(os.SETTINGS.NETWORK.NAME == nil) then
	print("missing `SETTINGS.NETWORK.NAME` in settings")
	return nil
elseif(os.SETTINGS.NETWORK.DRIVER == nil) then
	print("missing `SETTINGS.NETWORK.DRIVER` in settings")
	return nil
end

return NetworkManager:new(os.SETTINGS.NETWORK.DRIVER, os.SETTINGS.NETWORK.PORT, os.SETTINGS.NETWORK.ID, os.SETTINGS.NETWORK.NAME)
