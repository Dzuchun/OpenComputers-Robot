function tableLength(table)
	local res=0
	for a, b in pairs(table) do
		res = res+1
	end
	return res
end

function turnTo(facing)
	while (require("component").navigation.getFacing() ~= facing) do
		robot.turnRight()
	end
end

function moveToWaypoint2D (waypoint)
	local delta = 1
	print("Beginning move. Relative coords = (" .. waypoint.position[1] .. ";".. waypoint.position[2] .. ";".. waypoint.position[3] .. ")")
	while ((waypoint.position[1] ~= 0) or (waypoint.position[2] ~= 0) or (waypoint.position[3] ~= 0)) do

		print("Starting step. Relative coords = (" .. waypoint.position[1] .. ";".. waypoint.position[2] .. ";".. waypoint.position[3] .. ")")
		--moving along x axis		
		turnTo(sides.posx)
		if waypoint.position[1] < 0 then
			delta = 1
			robot.turnAround()
		else
			delta = -1
		end

		while (waypoint.position[1] ~= 0) do 
			if (robot.forward() ~= true) then
				print("Failed to move at x")
				break
			end
			waypoint.position[1] = waypoint.position[1] + delta
		end

		--moving along y axis
		if (waypoint.position[2] > 0) then
			while (waypoint.position[2] ~= 0) do
				if (robot.up() ~= true) then
				print("Failed to move at y")
					break
				end
				waypoint.position[2] = waypoint.position[2] - 1
			end
		else
			while (waypoint.position[2] ~= 0) do 
				if (robot.down() ~= true) then
				print("Failed to move at y")
					break
				end
				waypoint.position[2] = waypoint.position[2] + 1
			end
		end

		--moving along z axis
		turnTo(sides.posz)
		if waypoint.position[3] < 0 then
			delta = 1
			robot.turnAround()
		else
			delta = -1
		end

		while (waypoint.position[3] ~= 0) do 
			if (robot.forward() ~= true) then
				print("Failed to move at z")
				break
			end
			waypoint.position[3] = waypoint.position[3] + delta
		end
	end
end

function reachedWaypoint(waypoint)
	if (waypoint.position[1] == 0) and (waypoint.position[2] == 0) and (waypoint.position[3] == 0) then
		return true
	else
		return false
	end
end

function findWaypoint(name)
	local waypoints = require("component").navigation.findWaypoints(30) --parametrize
	for n, w in pairs(waypoints) do
		if ((n ~= "n") and (w.label == name)) then
			return w
		end
	end
	return nil, "Can't find waypoint"
end

function moveToWaypointName(name)
	local tmp = findWaypoint(name)
	if (tmp == nil) then 
		return false
	else
		moveToWaypoint2D(tmp)
	end
end

function getSideToMove(label) --returns side where to move to reach a waypoint
	local waypoint = findWaypoint(label)
	if (waypoint.position[1] ~= 0) then
		if (waypoint.position[1] > 0) then
			return sides.posx
		else
			return sides.negx
		end
	end
	if (waypoint.position[2] ~= 0) then
		if (waypoint.position[2] > 0) then
			return sides.posy
		else
			return sides.negy
		end
	end
	if (waypoint.position[3] ~= 0) then
		if (waypoint.position[3] > 0) then
			return sides.posz
		else
			return sides.negz
		end
	end
end

function takeItemStackFromInventory (side, label, amount)
	local inventory = require("component").inventory_controller
	local inventorySize = inventory.getInventorySize(side)
	local tmp
	if (inventorySize == nil) then
		return nil, "no inventory"
	end
	local sucked = 0
	for i=1, inventorySize do
		tmp = inventory.getStackInSlot(side, i)
		if (amount ~= sucked and tmp ~= nill and tmp.label == label) then
			sucked = sucked + inventory.suckFromSlot(side, i, amount-sucked)
		end
	end
	return sucked
end

function takeItemStackFromInput (label, amount, beginName, endName) 
	moveToWaypoint2D(findWaypoint(beginName))
	local sideToMove = getSideToMove(endName)
	local s = require("sides")
	local r = require("robot")
	local tmp
	turnTo(sideToMove)
	while (not((reachedWaypoint(endName)) or (getAmountInSelectedSlot() == amount))) do
		tmp = findWaypoint(endName).position
		--print("not reached end, dx="..tostring(tmp[1])..", dy="..tostring(tmp[2])..", dz="..tostring(tmp[3]))
		r.turnRight()
		repeat
			takeItemStackFromInventory(s.front, label, amount - getAmountInSelectedSlot())
		until ((getAmountInSelectedSlot() == amount) or (getAmountInInventory(s.front, label) == 0))
		turnTo(sideToMove)
		r.forward()
	end
	if (getAmountInSelectedSlot() < amount) then
		return false
	end
	return true
end

function flushItemsToLine(beginWaypointName, sideToMove)
	if (not moveToWaypointName(beginWaypointName)) then
		return false, "Can't find waypoint"
	end
	turnTo(sideToMove)
	local r = require("robot")
	local i = component.inventory_controller
	r.select(1)
	while (i.getStackInInternalSlot() ~= nil) do
		print("Dropping slot no " .. r.select())
		r.dropUp()
		r.select(r.select()+1)
		r.forward()
	end
	return true
end

function getFluidAmountInSelectedTank()
	local t = require("component").tank_controller
	local tmp = t.getFluidInInternalTank()
	if (tmp == nil) then
		return 0
	else
		return tmp.amount
	end
end

function getFluidAmountInTank(side, label)
	local t = require("component").tank_controller
	local tmp = t.getFluidInTank(side)
	print("tmp = " .. tostring(tmp))
	if ((tmp == nil) or (tmp.label ~= label)) then
		return 0
	else
		return tmp.amount
	end
end

function suckFluidFromTank (side, label, amount)
	local tank = require("component").tank_controller
	local tmp
	tmp = tank.getFluidInTank(side)

	if (tmp[1].label ~= nil) then 
		print("I see " .. tmp[1].label .. " in tank")
	end

	if (tmp[1].label == label) then
		return require("robot").drain(amount)
	else 
		return 0
	end
end

function suckFluidFromInput (label, amount, beginName, endName) 
	moveToWaypoint2D(findWaypoint(beginName))
	local sideToMove = getSideToMove(endName)
	local s = require("sides")
	local r = require("robot")
	local t = require("component").tank_controller
	local tmp
	turnTo(sideToMove)
	while not((reachedWaypoint(endName)) or (getFluidAmountInSelectedTank() == amount)) do
		--tmp = findWaypoint(endName).position
		--print("not reached end, dx="..tostring(tmp[1])..", dy="..tostring(tmp[2])..", dz="..tostring(tmp[3]))
		r.turnRight()
		repeat
			print(suckFluidFromTank(s.front, label, amount - getFluidAmountInSelectedTank()))
		until ((getFluidAmountInSelectedTank() == amount) or (getFluidAmountInTank(s.front, label) == 0))
		turnTo(sideToMove)
		r.forward()
	end
	if (getFluidAmountInSelectedTank() < amount) then
		return false
	end
	return true
end

function flushFluidsToLine(beginWaypointName, sideToMove)
	if (not moveToWaypointName(beginWaypointName)) then
		return nil, "Can't find waypoint"
	end
	turnTo(sideToMove)
	local r = require("robot")
	local t = component.tank_controller
	r.selectTank(1)
	while (t.getFluidInInternalTank() ~= nil) do
		print("Dropping slot no " .. r.select())
		r.fillUp(getFluidAmountInSelectedTank())
		r.selectTank(r.selectTank()+1)
		r.forward()
	end
	return true
end

function triggers(beginName, endName, triggerSide, craft, sleepTime)
	local event = require("event")
	local e
	local redstone = require("component").redstone
	local robot = require("robot")
	local c, f
	local flag = true
	repeat
		os.execute("sleep " .. sleepTime)
		moveToWaypointName(beginName)
		c=0
		f = false
		turnTo(getSideToMove(endName))
		repeat
			if (robot.forward()) then
				c = c+1
				if (redstone.getInput(triggerSide) > 0) then
					f = true
				end
			end
		until (f or reachedWaypoint(findWaypoint(endName)))
		flag = craft(c)
		if (not flag) then
			print("Crafting failed - " .. flag)
			break
		end
		--sleep(sleepTime)
		e = event.pull()
	until (e=="interrupted")
	if (not flag) then
		error()
	end
end

function readRecipe(fileName)
	local file = io.open(fileName, "r")
	if (file == nil) then 
		return nil, "Can't find file"
	end
	local res = {}
	io.input(file)
	res.name = io.read("*line")
	res.items = {}
	res.items.n = tonumber(io.read("*line"))
	for i=1, res.items.n do
		res.items[i] = {}
		res.items[i].name = io.read("*line")
		res.items[i].amount = tonumber(io.read("*line"))
		--print(res.items[i].name .. " " .. res.items[i].amount)
	end
	res.fluids = {}	
	res.fluids.n = tonumber(io.read("*line"))
	print(res.fluids.n)
	for i=1, res.fluids.n do
		res.fluids[i] = {}
		res.fluids[i].name = io.read("*line")
		res.fluids[i].amount = tonumber(io.read("*line"))
	end
	res.wait = io.read("*n")
	io.close(file)
	return res
end

function printRecipe(recipe) --debug
	print("Recipe of " .. recipe.name)
	print("All you need is:")
	for i=1, recipe.items.n do
		print(recipe.items[i].amount .. " " .. recipe.items[i].name .. " in " .. i .. "th input bus,")
	end
	for i=1, recipe.fluids.n do
		print(recipe.fluids[i].amount .. "mb " .. recipe.fluids[i].name .. " in " .. i .. "th input hatch,")
	end
	print("And wait for " .. recipe.wait .. " seconds")
end

function error()
	print("Erroring!!!")
	moveToWaypointName("al.err")
	for i=0, 5 do
		require("component").redstone.setOutput(i, 15)
	end
	os.execute("sleep 5")
	print("Senpai, im tired, may I sleep?")
	print(io.stdin:read("*line"))
	for i=0, 5 do
		require("component").redstone.setOutput(i, 0)
	end
	print("Zzz")
end

function takeResult()
	moveToWaypointName("al.res.in")
	if (not robot.suckUp()) then
		return false
	end
	moveToWaypointName("al.res.out")
	turnTo(sides.east)
	robot.drop()
	return true
end

function craft(no)
	local currentRecipe = recipes[no]
	local flag = true
	print("Crafting " .. currentRecipe.name)
	print("Waiting a bit for system to load all the components")
	os.execute("sleep 5")

	print("Taking items")
	for i=1, currentRecipe.items.n do
		robot.select(i)
		print("Taking " .. currentRecipe.items[i].amount .. " of " .. currentRecipe.items[i].name .. "...")
		flag = takeItemStackFromInput(currentRecipe.items[i].name, currentRecipe.items[i].amount, "al.item.in.b", "al.item.in.e")
		if flag then
			print("Taken!")
		else
			print("Failed, erroring")
			return false, "NEI"
		end
	end
	print("Taken all items")

	print("Taking fluids")
	for i=1, currentRecipe.fluids.n do
		robot.selectTank(i)
		print("Taking " .. currentRecipe.fluids[i].amount .. "mb of " .. currentRecipe.fluids[i].name .. "...")
		flag = suckFluidFromInput(currentRecipe.fluids[i].name, currentRecipe.fluids[i].amount, "al.fluid.in.b", "al.fluid.in.e")
		if flag then
			print("Taken!")
		else
			print("Failed, erroring")
			return false, "NEF"
		end
	end
	print("Taken all fluids")

	print("Hurray, now I may start crafting!")
	print("Flushing items...")
	flag = flushItemsToLine("al.item.out", sides.north)
	if (not flag) then
		print("Failed - " .. flag)
		return flag
	end
	print("Flushed!")

	print("Flushing fluids...")
	flag = flushFluidsToLine("al.fluid.out", sides.north)
	if (not flag) then
		print("Failed - " .. flag)
		return flag
	end
	print("Flushed!")
	
	print("So, now I may wait for " .. currentRecipe.wait .. "s")
	os.execute("sleep " .. currentRecipe.wait)
	print("Waited long enough, hope recipe suceed!")
	if (takeResult()) then
		print("Hurray! Have your " .. currentRecipe.name)
	else
		print("Something went wrong... erroring")
		return false, "No result"
	end
end

sides = require("sides")
filesystem = require("filesystem")
robot = require("robot")
recipes = {}
local iter = filesystem.list("/home/al/recipes/")
if (iter == null) then
	return nil, "No directory"
end
local c=0
local tmp = iter()
while(tmp ~= nil) do
	c = c+1
	tmp = iter()
end
print("Detected " .. c .. " recipes")
for i=1, c do
	recipes[i] = readRecipe("/home/al/recipes/" .. i .. ".recipe")
	if (recipes[i] == nil) then
		print("Wrong recipe format")
	else
		print("Succesfully read recipe:")
		printRecipe(recipes[i])
	end
end
print("Readed all recipes")
print("TODO Please tech me move to energy at first")
triggers("al.trig.b", "al.trig.e", sides.east, craft, 10)
