bios = {
	DRIVE = "{DRIVE}",
	PATH = "bootloader",
	VERSION = "1.1.0",
	LIBS = {
		json = {},
		storage = {}
	}
}

function bios.loadOS()
	local success, result = pcall(function()
	filesystem.initFileSystem("/dev")
	filesystem.mount("/dev/"..bios.DRIVE, "/")
	filesystem.doFile("boot/os.lua")
	filesystem.unmount("/")
	end)
	if(not success) then
		print("Error occurred while starting the operating system: " .. result) 
	end
end

function bios.autoUpdate()
	if(bios.LIBS.storage:has("update") and bios.LIBS.storage:has("update-url")) then
		if(bios.LIBS.storage:get("update") == true) then
			local updateUrl = bios.LIBS.storage:get("update-url")
			bios.LIBS.storage:remove("update")
			bios.LIBS.storage:saveConfig()
			bios.updateOS(updateUrl, false, false, true)
		end
	elseif bios.LIBS.storage:has("install-on-startup") then
		if(bios.LIBS.storage:get("install-on-startup") == true) then
			local updateUrl = bios.LIBS.storage:get("update-url")
			bios.LIBS.storage:remove("install-on-startup")
			bios.LIBS.storage:remove("update-url")
			bios.LIBS.storage:saveConfig()
			bios.updateOS(updateUrl, false, false, true)
		end
	end
end

function bios.mount(callback)
    filesystem.mount("/dev/" .. bios.DRIVE, "/")
    local returnVal = callback()
    filesystem.unmount("/")
    return returnVal
end

function bios.updateOnStartup(url)
	bios.LIBS.storage:set("update", true)
	bios.LIBS.storage:set("update-url", url)
	bios.LIBS.storage:set("install-on-startup", true)
	bios.LIBS.storage:saveConfig()
	print("restarting")
	computer.reset()
end

function bios.updateOS(url, setEEPROM, setBootLoader, restart)
	local success, result = pcall(function()
		local http = computer.getPCIDevices(classes["FINInternetCard"])[1]
		if(http == nil) then
			computer.panic("Internet card could not be found")
			return
		end
		filesystem.initFileSystem("/dev")    
		filesystem.makeFileSystem("tmpfs", "tmp")
		filesystem.mount("/dev/tmp", "/")
		local installerURL = url .. "installer.lua"
		local req = http:request(installerURL, "GET", "")
		local code, data = req:await()
		if(code ~= 200) then
			if(code == nil) then
				computer.panic("http request connection timeout")
			else
				computer.panic("http request "..installerURL.." failed: "..code)
			end
		end
		local file = filesystem.open("installer.lua", "w")
		file:write(data)
		file:close()
		local installer = filesystem.doFile("installer.lua")
		filesystem.unmount("/")
		if(installer ~= nil) then
			installer.install(url, bios.DRIVE, setEEPROM, false, restart)
		end
	end)
	if(not success) then
		print("Error occurred while executing updateOS: " .. result)
	end
end

filesystem.initFileSystem("/dev")
filesystem.mount("/dev/"..bios.DRIVE, "/")
bios.LIBS.json = filesystem.doFile("bootloader/json.lua")
bios.LIBS.storage = filesystem.doFile("bootloader/storage.lua")
bios.LIBS.storage:loadConfig()
filesystem.unmount("/")

print(string.format("BIOS ver %s loaded on drive [%s]", bios.VERSION, bios.DRIVE))

return bios