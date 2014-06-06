-- Put your global variables here

-- variable for chain task
part_of_chain = 0
stigma_chain = 0.5
p_bpoc = 0 -- prob. to become part of chain
stigma_chain_delta = 0.3
stigma_chain_alpha = 0.1

search_prev_chain_member = 5

tMax = 100
rID = 0
lastSeenID = 0


-- Variables for sync
alphaSync = 2
betaSync = 10
counterSyncBeat = 0


x_Velo = 30
y_Velo = 30


-- pattern
dTarget = 20
epsilon = 20
maxLength = dTarget / 5


--[[
-- cool clustering in small rectangles
dTarget = 60
epsilon = 50
maxLength = dTarget / 8
--]]
--


local collision = 0
local collisionLeft = 0
local collisionRight = 0


--- com overview
comData={
1, -- sync signal 	- 1 or 0 		-	1
1, -- pattern		- 1 := neighb.	-	2
1, -- part of chain	- 1 := true		-	3
0.1, -- right		4
0.0, --			5
0.0,	--			6
0.0,	--			7
0.0,	--			8
0.0,	--			9
0.0	--			10
}




--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
   -- put your code here

	-- initialize counterSyncBeat with a random value < tMax
	counterSyncBeat = robot.random.uniform(tMax)
	-- log("counterSyncBeat init : " .. counterSyncBeat)
	


	robot.in_chain = 0
	part_of_chain = 0
	stigma_chain = 0.5
	p_bpoc = 0 -- prob. to become part of chain

	-- id used to recognize an element in the chain
	-- if we see this rID we save it and use it for
	-- orientation
	rID = robot.random.uniform(1,1000)

	
end



function setSpeed(speed, turnSpeed)

	local leftSpeed = speed
	local rightSpeed = speed

	 --  curve
	leftSpeed = leftSpeed - turnSpeed
	rightSpeed = rightSpeed + turnSpeed

	

	robot.wheels.set_velocity(leftSpeed, rightSpeed)


end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	myprox = table.copy(robot.proximity)   

	groundIsWhite = robot.motor_ground[1].value + robot.motor_ground[2].value + robot.motor_ground[3].value + robot.motor_ground[4].value

	groundIsWhite = groundIsWhite / 4

	-- Synchronizing
	-- synchronization()
	-- Pattern formation
	-- pattern()

	if (part_of_chain == 0) then
		collisionHandling()

		collisionDetection()
	
	end

	-- beomming part of chain decision
	--if(groundIsWhite == 1) then
		engage_in_chain_decision()

	--end

	if (part_of_chain == 0) and (collision == 0)then
		
		exploration_along_chain()

	else
		
	end
	

	if (groundIsWhite == 0) and (count_message_recieved() <= 1) or (count_message_recieved_in(3) >= 1) and (groundIsWhite == 0) then
		-- we want only one robot on each black spot
		local t = robot.range_and_bearing
	
		for key,tab in pairs(t) do
			
			if(type(tab) == "table") then
				--log("Key : " .. key)
				--log("Table : " .. tab)
				--log("Type : " .. type(tab))
				--log("Range: ")
				--log(tab.range)
				
				--	log ("HB : " .. tab.horizontal_bearing)
				--	log ("Range : " .. tab.range)
					
				
				if (tab.range >= 10) then
					x_Velo = 0
					y_Velo= 0
				else
					x_Velo = 30
					y_Velo = 30
				end
				
			end
		end
		
	end

end


function exploration_along_chain()
	-- body

	local t = robot.range_and_bearing
	local x = 0
	local y = 0

	if (count_message_recieved_in(3) >= 1) then
	
		for key,tab in pairs(t) do
			
			if(type(tab) == "table") then
				--log("Key : " .. key)
				--log("Table : " .. tab)
				--log("Type : " .. type(tab))
				--log("Range: ")
				--log(tab.range)
				if (tab.data[3] == 1) then
				--	log ("HB : " .. tab.horizontal_bearing)
				--	log ("Range : " .. tab.range)
					lastSeenID = tab.data[4]
					--log("Lastseen " .. lastSeenID)
					local hb = tab.horizontal_bearing
					range = tab.range
					local lennardJones =  lennard_jones(range)
					--log("leanrd" .. lennardJones)
					local temp_x = math.cos(hb)
					local temp_y = math.sin(hb)

					local temp_angle = math.atan2(temp_y,temp_x)

					--log("temp_angle " .. temp_angle)

					if (temp_angle <= math.pi/4) and (temp_angle >= -math.pi/4) then
						--temp_x = lennardJones * math.cos(hb)
						--temp_y = lennardJones * math.sin(hb)
						
						--log("Range " .. range)
						if (range >= 40) then

							x = x + temp_x
							y = y + temp_y
			
							log("YESSSSSS")
						end
					else
						log("NOOOOOO")
					end

					
					--log("x : " .. temp_x)
					--log("y : " .. temp_y)
					
					
				end
				--[[
				for k,val in pairs(tab.data) do
					log("Data Key : " .. k)
					log("Data Val : " .. val)
					
				end
				--]]
			end

	   	end
		-- log("Count : " .. count)
		--log("Total x : " .. x)
		--log("Total y : " .. y)
		
		angle = math.atan2(y,x)
		--log("Angle : " .. angle)


		if (angle >= math.pi) then
			turnSpeed = (math.pi*2 - angle) * -1
		else
			turnSpeed = angle	
		end
		turnSpeed = (turnSpeed * 8) / math.pi

		local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))
		--log("Length : " .. length)
		local normLength = length / maxLength

		if (normLength > 1) then
			normLength = 1
		end
		
		setSpeed(x_Velo, turnSpeed)
	
	else
		setSpeed(x_Velo, 0)
	end
end


function leave_chain_decision()
	-- body
		-- leave chain ?

		r_leave_chain = robot.random.bernoulli(0.05) + math.max((count_message_recieved_in(3) / 2), 1)

		--log("r_leave_chain " .. r_leave_chain)

		if (r_leave_chain >= 1) then

			--leave
			robot.in_chain = 0
			part_of_chain = 0
			
			robot.range_and_bearing.set_data(3, 0)
			robot.leds.set_all_colors("black")
		
		end
	
end

function engage_in_chain_decision()
	-- body
	calculate_stigma_chain()
	--log("stigma_chain " .. stigma_chain)

	p_bpoc =  math.pow(stigma_chain,2) / (  math.pow(stigma_chain,2)  + 0.5 )


	--log("p_bpoc " .. p_bpoc)
	if (p_bpoc >= 0.7) then
		
		-- set chain signal in third byte
		robot.in_chain = 1
		part_of_chain = 1
		setSpeed(0,0);


		robot.range_and_bearing.set_data(3, 1)
		robot.range_and_bearing.set_data(4, rID)
		robot.leds.set_all_colors("green")
	else
		robot.in_chain = 0
		part_of_chain = 0
		
		robot.range_and_bearing.set_data(3, 0)
		robot.range_and_bearing.set_data(4, 0)
		robot.leds.set_all_colors("black")

	end



end

function calculate_stigma_chain()
	-- body
	groundIsWhite = robot.motor_ground[1].value + robot.motor_ground[2].value + robot.motor_ground[3].value + robot.motor_ground[4].value

	groundIsWhite = groundIsWhite / 4
	
	
	temp2 = count_message_recieved_in(3) / 2

	--log("rec val " .. temp2)
	
	tempa = stigma_chain + stigma_chain_alpha
	tempb = stigma_chain_delta * ( temp2 )
	tempc = tempa - tempb

	stigma_chain = stigma_chain + stigma_chain_alpha - stigma_chain_delta * ( temp2 )
	

	stigma_chain = math.max(stigma_chain,0)
	--log("stigma_chain " .. stigma_chain)
	
end




--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
   -- put your code here
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end


function collisionHandling()


if (collision == 1) then
k = findMaxKey(myprox)
r = robot.random.bernoulli(0.8)

if (collisionLeft == 1) then
	--robot.wheels.set_velocity(x_Velo,-y_Velo)
	

	--log("r : " .. r)
	if (r == 1) then
		k = 10
	end
	if (k == 10) or ( k == 11) or (k == 12)then
		--log("k : " .. k)
		collisionLeft = 0
		collision = 0;
	end

	-- perhaps the other way arround - right
	r = robot.random.bernoulli(0.05)
	if (r == 1) then
		--log("perhaps right")
		robot.wheels.set_velocity(-x_Velo/4,y_Velo)
		--robot.leds.set_all_colors("red")
		
	end
end

if (collisionRight == 1) then
	--robot.wheels.set_velocity(-x_Velo,y_Velo)
	
	--log("r : " .. r)
	if (r == 1) then
		k = 15
	end
	if (k == 15) or ( k == 14) or (k == 13)then
		--log("k : " ..k)
		collisionRight = 0
		collision = 0;
	end

	-- perhaps the other way arround - left
	r = robot.random.bernoulli(0.05)
	if (r == 1) then
		--log("perhaps left")
		robot.wheels.set_velocity(x_Velo,-y_Velo/4)
		--robot.leds.set_all_colors("yellow")
	end
end

if (nobodyThere(myprox) == 1) then
		collisionLeft = 0
		collisionRight = 0
		collision = 0
end



end


function collisionDetection()
-- DETECT



if(collision == 0) then
	robot.wheels.set_velocity(0,0)

	closeValueRight =  myprox[24].value +  myprox[23].value  +  myprox[22].value + myprox[21].value + myprox[20].value 
	closeValueLeft =   myprox[1].value + myprox[2].value + myprox[3].value + myprox[4].value + myprox[5].value 

	maxValue = closeValueLeft + closeValueRight
	--log("Max Value : " .. maxValue)
	if (maxValue > 0.02) then 
		if (closeValueLeft >= closeValueRight) then -- left
			collisionLeft = 1
			collisionRight = 0
			collision = 1
			robot.wheels.set_velocity(x_Velo/2,-y_Velo/4)
			--robot.leds.set_all_colors("yellow")
		
		else -- right
			collisionRight = 1
			collisionLeft = 0
			collision = 1
			robot.wheels.set_velocity(-x_Velo/4,y_Velo/2)
			--robot.leds.set_all_colors("red")
		end

	else
		collisionLeft = 0
		collisionRight = 0
		collision = 0
		robot.wheels.set_velocity(x_Velo, y_Velo)
		curve = robot.random.uniform()
		direct = robot.random.bernoulli(0.5)
		doIt = robot.random.bernoulli(0.3)
		if (doIt == 1) then
			if(direct == 1) then
				robot.wheels.set_velocity(curve * x_Velo, y_Velo)
			else
				robot.wheels.set_velocity(x_Velo, curve * y_Velo)
			end
		
			--robot.leds.set_all_colors("white")
		end
		
	end
	end

end

end


function table.copy(t)
   local t2 = {}
   for key,value in pairs(t) do
      t2[key] = value
   end
return t2 end


function findMaxKey(t)
	local k = 1
	for key,val in pairs(t) do
		if val.value >= t[k].value then
			k = key
		end
	end
return k end


function nobodyThere(t)
	for key,value in pairs(t) do
      if (value.value ~= 0) then
			return 0
		end
   	end
return 1 end
		

function countNearSides(t)
	local count = 0
	for key,value in pairs(t) do
      if (value.value >= 0.5) then
			count = count + 1
		end
   	end
return count end



-----------------------------------
-----------------------------------
---------- pattern & sync ---------


function signal()
	-- set signal in first byte
	robot.range_and_bearing.set_data(1, 1)
	-- reset counterSyncBeat
	counterSyncBeat = 0
	
end

function count_message_recieved_in(i)
	local t = robot.range_and_bearing
	local count = 0
	
	for key,tab in pairs(t) do
		
		if(type(tab) == "table") then
--			log("Key : " .. key)
			--log("Table : " .. tab)
--			log("Type : " .. type(tab))
			--log("Range: ")
			--log(tab.range)
			count = count + tab.data[i]
			--[[
			for k,val in pairs(tab.data) do
				log("Data Key : " .. k)
				log("Data Val : " .. val)
				
			end
			--]]
		end

   	end
	-- log("Count : " .. count)
return count end

function count_message_recieved()
	local t = robot.range_and_bearing
	local count = 0
	
	for key,tab in pairs(t) do
		
		if(type(tab) == "table") then
--			log("Key : " .. key)
			--log("Table : " .. tab)
--			log("Type : " .. type(tab))
			--log("Range: ")
			--log(tab.range)
			count = count + 1
			--[[
			for k,val in pairs(tab.data) do
				log("Data Key : " .. k)
				log("Data Val : " .. val)
				
			end
			--]]
		end

   	end
	-- log("Count : " .. count)
return count end


function synchronization()
	-- Synchronizing using range and bearing

	-- first reset signal
	robot.range_and_bearing.set_data(1, 0)
	if(counterSyncBeat > 5) then
		robot.leds.set_all_colors("white")
	end
	-- increase counterSyncBeat 
	counterSyncBeat = counterSyncBeat + 1
	log("C. : " .. counterSyncBeat )
	-- signal part
	if (counterSyncBeat > tMax) then
		signal()
		robot.leds.set_all_colors("red")
	end

	-- synchronizing part
	if (count_message_recieved_in(1) >= 1) and (counterSyncBeat > 2) then
		local r = robot.random.bernoulli()
 
		--log("Signal Lost : " .. r )
		if (r == 1) then
			counterSyncBeat = counterSyncBeat + alphaSync * counterSyncBeat/betaSync
		end
		
	end

end

function lennard_jones(range)
	local force = 0
	local temp = math.pow(dTarget / range, 2)
	force = -4*epsilon/range * ( math.pow(temp,2) - temp)


return force end

function pattern()
robot.range_and_bearing.set_data(2, 1) -- I am a neighbor


	local t = robot.range_and_bearing
	local x = 0
	local y = 0

	
	for key,tab in pairs(t) do
		
		if(type(tab) == "table") then
--			log("Key : " .. key)
			--log("Table : " .. tab)
--			log("Type : " .. type(tab))
			--log("Range: ")
			--log(tab.range)
			if (tab.data[2] == 1) then
			--	log ("HB : " .. tab.horizontal_bearing)
			--	log ("Range : " .. tab.range)
				local hb = tab.horizontal_bearing
				local range = tab.range
				local lennardJones =  lennard_jones(range)
				
				local temp_x = lennardJones * math.cos(hb)
				local temp_y = lennardJones * math.sin(hb)
				--log("x : " .. temp_x)
				--log("y : " .. temp_y)
				x = x + temp_x
				y = y + temp_y
				
			end
			--[[
			for k,val in pairs(tab.data) do
				log("Data Key : " .. k)
				log("Data Val : " .. val)
				
			end
			--]]
		end

   	end
	-- log("Count : " .. count)
	--log("Total x : " .. x)
	--log("Total y : " .. y)
	
	angle = math.atan2(y,x)
	--log("Angle : " .. angle)


	if (angle >= math.pi) then
		turnSpeed = (math.pi*2 - angle) * -1
	else
		turnSpeed = angle	
	end
	turnSpeed = (turnSpeed * 10) / math.pi

	local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))
	--log("Length : " .. length)
	local normLength = length / maxLength

	if (normLength > 1) then
		normLength = 1
	end
	
	setSpeed(x_Velo/3 * normLength, turnSpeed)
end

