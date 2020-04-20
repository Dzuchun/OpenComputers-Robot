local c = require("component")
local e = require("event")

local redstoneList = c.list("redstone")
print("Printing redstone devices")
local a=0
local redstoneTable = {}
for address, type in redstoneList do
	print(a .. ") " .. address)
	redstoneTable[a] = address
	a=a+1
end

local IOTable = 
{
	["energy"] = {address = nil, side = nil},
	["fluid"] = {address = nil, side = nil},
	["ring1"] = {address = nil, side = nil},
	["ring2"] = {address = nil, side = nil}
}

local input = nil
for name, properties in pairs(IOTable) do
	print("Define IO for " .. name)
	input = io.read("*n")
	print("Setting to " .. redstoneTable[input])
	properties.address = redstoneTable[input]
	print("Define side for " .. name .. "")
	input = io.read("*n")
	properties.side = input
	IOTable[name] = properties
end

print("test")
for name, properties in pairs(IOTable) do
	print("For " .. name .. " address= " .. properties.address .. ", side=" .. properties.side)
end

local f = false
repeat
	print("executing logic")

	if c.proxy(IOTable["fluid"].address).getInput(IOTable["fluid"].side) < 2 or c.proxy(IOTable["energy"].address).getInput(IOTable["energy"].side) < 2 then
		if f == false then
			print("ACTIVATE!!!")
			f = true
		end
	elseif c.proxy(IOTable["fluid"].address).getInput(IOTable["fluid"].side) > 13 and c.proxy(IOTable["energy"].address).getInput(IOTable["energy"].side) > 13 then
		if f == true then
			print("DEACTIVATE!!!")
			f = false
		end
	end

	if f then
		--c.proxy(IOTable["ring1"].address).setOutput(IOTable["ring1"].side, 15)
		--c.proxy(IOTable["ring2"].address).setOutput(IOTable["ring2"].side, 15)
	else
		--c.proxy(IOTable["ring1"].address).setOutput(IOTable["ring1"].side, 0)
		--c.proxy(IOTable["ring2"].address).setOutput(IOTable["ring2"].side, 0)
	end

	local event = e.pull()
until event == "interrupted"
