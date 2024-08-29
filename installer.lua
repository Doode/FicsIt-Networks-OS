local function mountDrive(drive, path, callback)
    filesystem.mount(drive,path)
    print("mounting to drive: ", drive, ", path: ", path)
    local returnVal = callback()
    filesystem.unmount(path)
    print("unmounted from drive: ", drive, ", path: ", path)
    return returnVal
end

local function httpGet(http, path)
    print("http request: ", path)
    local req = http:request(path, "GET", "")
	local code, file = req:await()
    if(code ~= 200) then
        computer.panic("http request "..path.." failed: "..code)
    end
    return file
end

local function downloadJSONLib(http, path)
    filesystem.makeFileSystem("tmpfs", "tmp")
    return mountDrive("/dev/tmp","/", function()
        print("downloading json library")
        local jsonFile = httpGet(http, path .. "lib/json.lua")
        local file = filesystem.open("json.lua", "w")
        print("extracting json library")
        file:write(jsonFile)
        file:close()
        local json = filesystem.doFile("json.lua")
        return json
    end)
end

local function getOSPackage(http, path, json)
    print("downloading os package.json")
	local packageFile = httpGet(http, path .. "package.json")
	return json.decode(packageFile)
end

local function printDrives()
    for _, drive in pairs(filesystem.childs("/dev")) do
        print("- " .. drive)
    end
end

local function sleep(milliseconds)
    local start_time = computer.millis()
    while (computer.millis() - start_time) < milliseconds do
    end
end

local function deleteBootloaderFolder(drive)
    mountDrive("/dev/"..drive, "/", function()
        if(filesystem.exists("/bootloader")) then
            print("removing existing bootloader folder")
            filesystem.remove("/bootloader", true)
            filesystem.unmount("/")
            print("restarting computer to continue instalation")
            computer.reset()
            return
        end
    end)
end

local function deleteBootFolder(drive)
    mountDrive("/dev/"..drive, "/", function()
        if(filesystem.exists("/boot")) then
            print("removing existing boot folder")
            filesystem.remove("/boot", true)
            filesystem.unmount("/")
            print("restarting computer to continue instalation")
            computer.reset()
            return
        end
    end)
end

local function downloadBinaries(http, url, files, drive, setBootLoader)
    for _, fileObj in pairs(files) do
        if not fileObj.bootloader or setBootLoader then
            if(not filesystem.exists("/"..fileObj.path)) then
                filesystem.createDir("/"..fileObj.path)
            end
            print("downloading file: ", fileObj.file)
            local binary = httpGet(http, url..fileObj.path..fileObj.file)
            print(fileObj.path .. fileObj.file)
            local extractPath = fileObj.path .. fileObj.file
            local extractFile = filesystem.open(extractPath, "w")
            print("extracting ".. fileObj.file)
            local compiled,_ = string.gsub(binary, "{DRIVE}", drive)
            extractFile:write(compiled)
            extractFile:close()
            print("successfully downloaded file: ", fileObj.file) 
        end
    end
end

local installer = {}

function installer.install(path, drive, setEEPROM, setBootLoader, restart)
    local http = computer.getPCIDevices(classes["FINInternetCard"])[1]
    filesystem.initFileSystem("/dev")
    if(http == nil) then
        print("cannot find an intercard card")
        computer.stop()
    elseif(drive == nil) then
        print("select a drive first to install the os on:")
        printDrives()
        computer.stop()
    else
        deleteBootFolder(drive)
        if(setBootLoader) then
            deleteBootloaderFolder(drive)
        end
        print("starting installation of operating system")
        local json = downloadJSONLib(http, path)
        local package = nil
        mountDrive("/dev/"..drive, "/", function()
            print("creating boot directory")
            filesystem.createDir("/boot")
            package = getOSPackage(http, path, json)
            print("Operating system ["..package.name.." "..package.version.."] found")
            downloadBinaries(http, path, package.files, drive, setBootLoader)
            if(setEEPROM) then
                local file = filesystem.open("/boot/eeprom.lua", "r")
                print("settings eeprom")
                local eeprom = file:read("10000")
                file:close()
                computer.setEEPROM(eeprom)
            end
        end)

        if(package == nil) then
            computer.panic("failure during install")
        else
            print("--------------------------------------------------------------------------------------------")
            print("SUCCESFULLY INSTALLED OPERATING SYSTEM ["..package.name.." "..package.version.."]")
            print("--------------------------------------------------------------------------------------------")
            computer.beep(0.9)
            sleep(200)
            computer.beep(1)
            sleep(200)
            computer.beep(1.1)
            sleep(200)
            if restart then
                computer.reset()
            else
                computer.stop()
            end
        end
    end
end

return installer