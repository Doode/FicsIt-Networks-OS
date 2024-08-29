os = {
	thread = {},
	events = {},
	network = {},
	buttons = {},
	json = {},
	storage = {}
}

os.SETTINGS = {}
os.VERSION = "1.2.5"
os.NAME = "DevOS"
os.LOADED_MODULES = 0
os.DRIVE = "{DRIVE}"
os.PATH = "/boot"
os.MODULES = {
	THREAD = {bitmask = 1, file = "boot/bin/mod_thread.lua", id = "thread"},
	EVENTS = {bitmask = 2, file = "boot/bin/mod_events.lua", id = "events"},
	NETWORK = {bitmask = 4, file = "boot/bin/mod_network.lua", id = "network"},
	BUTTONS = {bitmask = 8, file = "boot/bin/mod_buttons.lua", id = "buttons"},
	JSON = {bitmask = 16, file = "boot/bin/mod_json.lua", id = "json"},
	STORAGE = {bitmask = 32, file = "boot/bin/mod_storage.lua", id = "storage"},
}

function os.isLoaded(module)
	return (os.LOADED_MODULES & module.bitmask) ~= 0
end

function os.mount(callback)
    filesystem.mount("/dev/" .. os.DRIVE, "/")
    local returnVal = callback()
    filesystem.unmount("/")
    return returnVal
end

function os.updateOS(url)
	bios.updateOnStartup(url)
end

function os.require(module)
	local success, result = pcall(function()
		if(type(module) == "string") then
			for _, mod in pairs(os.MODULES) do
				if(mod.id == module) then
					module = mod
					break
				end
			end
		end
		if(type(module) == "string") then
			print("module could not be found")
		elseif(not os.isLoaded(module)) then
			os.LOADED_MODULES = os.LOADED_MODULES | module.bitmask
			filesystem.mount("/dev/"..os.DRIVE, "/")
			if(filesystem.exists(module.file)) then
				os[module.id] = filesystem.doFile(module.file)
				if(os[module.id] == nil) then
					print("module "..module.id.." could not be loaded")
				end
				filesystem.unmount("/")
				print("loaded module ("..module.id..")")
			else
				print("module file " .. module.file .. " could not be found")
			end
		end
	end)
	if(not success) then
		print("could not load module: ", result)
	end
end

function os.start()
	print("<===> OS: ", os.NAME, ", Version: ", os.VERSION, "<===>")
end


print(string.format("%s ver %s loaded on drive [%s]", os.NAME, os.VERSION, os.DRIVE))
