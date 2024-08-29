local function downloadInstaller(url)
    local http = computer.getPCIDevices(classes["FINInternetCard"])[1]
    if(http == nil) then
    	computer.panic("Internet card could not be found")
        return
    end
	filesystem.initFileSystem("/dev")    
	filesystem.makeFileSystem("tmpfs", "tmp")
    filesystem.mount("/dev/tmp", "/")
    local req = http:request(url, "GET", "")
	local code, data = req:await()
    if(code ~= 200) then
    	if(code == nil) then
        	computer.panic("could not connect to the internet")
        else
        	computer.panic("could not download the installer with return code "..code)
        end
    end
    local file = filesystem.open("installer.lua", "w")
    file:write(data)
    file:close()
    local installer = filesystem.doFile("installer.lua")
    filesystem.unmount("/")
    return installer
end

local installer = downloadInstaller("http://localhost/devos/latest/installer.lua")
if(installer ~= nil) then
    installer.install("http://localhost/devos/latest/")
end