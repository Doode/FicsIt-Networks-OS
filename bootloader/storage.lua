local BiosStorageManager = {}
BiosStorageManager.__index = BiosStorageManager

function BiosStorageManager:new(drive, path)
	local instance = setmetatable({}, self)
    instance.config = {}
    instance.drive = drive
    instance.file = path .. "/storage.json"
    bios.mount(function()
        if(not filesystem.exists(path)) then
            filesystem.createDir(path)
        end
    end)
	return instance
end

function BiosStorageManager:get(key, default)
    local keys = {}
    for part in string.gmatch(key, "[^%.]+") do
        table.insert(keys, part)
    end
    local current = self.config
    for i = 1, #keys do
        local part = keys[i]
        if current[part] == nil then
            return default
        end
        current = current[part]
    end
    return current
end

function BiosStorageManager:set(key, val)
    local keys = {}
    for part in string.gmatch(key, "[^%.]+") do
        table.insert(keys, part)
    end
    local current = self.config
    for i = 1, #keys - 1 do
        local part = keys[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    local lastKey = keys[#keys]
    current[lastKey] = val
end

function BiosStorageManager:has(key)
    local keys = {}
    for part in string.gmatch(key, "[^%.]+") do
        table.insert(keys, part)
    end

    local current = self.config
    for i = 1, #keys do
        local part = keys[i]
        if current[part] == nil then
            return false
        end
        current = current[part]
    end

    return true
end

function BiosStorageManager:remove(key)
    local keys = {}
    for part in string.gmatch(key, "[^%.]+") do
        table.insert(keys, part)
    end

    local current = self.config
    for i = 1, #keys - 1 do
        local part = keys[i]
        if type(current[part]) ~= "table" then
            return false
        end
        current = current[part]
    end

    local lastKey = keys[#keys]
    if current[lastKey] ~= nil then
        current[lastKey] = nil
        return true
    else
        return false
    end
end


function BiosStorageManager:reset()
    self.config = {}
    self:saveConfig()
end

function BiosStorageManager:saveConfig()
    bios.mount(function()
        local file = filesystem.open(self.file, "w")
        file:write(bios.LIBS.json.encode(self.config))
        file:close()
    end)
end

function BiosStorageManager:loadConfig()
    bios.mount(function()
        if(filesystem.exists(self.file)) then
            local file = filesystem.open(self.file, "r")
            local data = ""
            while true do
             local r = file:read(256)
             if not r then break end
             data = data .. r
            end
            self.config = bios.LIBS.json.decode(data)
            file:close()
        end
    end)
end

return BiosStorageManager:new(bios.DRIVE, bios.PATH .. "/storage")