Button = {}
Button.__index = Button

function Button:new(panel, btn_x, btn_y, led_x, led_y)
	local instance = setmetatable({}, self)  -- Create the object and set its metatable
	instance.btn = panel:getModule(btn_x, btn_y)
	instance.led = panel:getModule(led_x, led_y)
	instance:update()
	return instance  -- Return the new object
end

function Button:isOn()
	return self.btn.state and self.btn.enabled
end

function Button:setEventListener(callback)
	self.callback = callback
end

function Button:update()
	if self.callback then
        local block = self.callback(self)
        if type(block) == "boolean" then
            self.btn.enabled = block
        end
    end
	
	if self:isOn() then
		self.led:setText("on")
		self.led:setColor(0,1,0,5)
	else
		self.led:setText("off")
		self.led:setColor(1,0,0,5)
	end
end