local drive = "{DRIVE}"
local function loadBIOS()
	filesystem.initFileSystem("/dev")
	filesystem.mount("/dev/"..drive, "/")
	filesystem.doFile("bootloader/bios.lua")
	filesystem.unmount("/")
end
loadBIOS()
bios.autoUpdate()
bios.loadOS()