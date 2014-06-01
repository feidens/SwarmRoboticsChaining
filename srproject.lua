-- Put your global variables here

-- Variables Second Approach

p_chain = 0.99            -- prob. threshold to be part of a chain (Explore -> Chain)
p_leave = 1 - p_chain     -- prob. threshold to leave a chain as last member of it (Chain -> Explore)
p_search = p_chain / 3    -- prob. threshold to abort exploration and search nest or prey (Explore -> Search)

b_search = 0
b_exploration = 1
b_chain = 2
b_end = 3

-- 0 := Search nest/prey
-- 1 := Exploration
-- 2 := Chain member
-- 3 := End state

behavior = b_exploration
behavior_old = b_exploration

wait_time = 0

valid_chain_member = 0

chain_color = 0
-- 1:= green
-- 2:= red
-- 3:= blue
color_green = 1
color_red = 2
color_blue = 3
color_prey = 4

-------------------------------------------
-------------------------------------------
-------------------------------------------

-- variable for chain task
part_of_chain = 0
stigma_chain = 0.5
p_bpoc = 0 -- prob. to become part of chain
stigma_chain_delta = 0.3
stigma_chain_alpha = 0.1
found_prey = 0
search_nest = 40
leaves_nest = 0
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
dTarget = 120
epsilon = 20
maxLength = dTarget / 5


--[[
-- cool clustering in small rectangles
dTarget = 60
epsilon = 50
maxLength = dTarget / 8
--]]
--


collision = 0
collisionLeft = 0
collisionRight = 0


--- com overview
comData={
1, -- chain first 	- 1 or 0 		-	1
1, -- chain second	- 1 := neighb.	-	2
1, -- chain third	- 1 := true		-	3
1, -- found prey					-	4
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

	groundIsWhite = 1
	valid_chain_member = 0

	wait_time = 0
-------------------------------------------
-------------------------------------------
-------------------------------------------

	-- initialize counterSyncBeat with a random value < tMax
	counterSyncBeat = robot.random.uniform(tMax)
	-- log("counterSyncBeat init : " .. counterSyncBeat)

	x_Velo = 30
	y_Velo = 30

	search_nest = 40
	leaves_nest = 0

	found_prey = 0
	robot.in_chain = 0
	part_of_chain = 0
	stigma_chain = 0.5
	p_bpoc = 0 -- prob. to become part of chain

	-- id used to recognize an element in the chain
	-- if we see this rID we save it and use it for
	-- orientation
	rID = robot.random.uniform(1,1000)


	setSpeed(30, 0)


end



function setSpeed(speed, turnSpeed)

	leftSpeed = speed
	rightSpeed = speed

	 --  curve
	if ((leftSpeed - turnSpeed) <= 0) then
		--log("1")
		leftSpeed = math.max(-30, leftSpeed - turnSpeed)

	else
		--log("2")
		leftSpeed = math.min(30, leftSpeed - turnSpeed)
	end

	if ((rightSpeed + turnSpeed) <= 0) then
		--log("3")
		rightSpeed = math.max(-30, rightSpeed + turnSpeed)

	else
		--log("4")
		rightSpeed = math.min(30, rightSpeed + turnSpeed)
	end
	--log("left" .. leftSpeed)
	--log("right" .. rightSpeed)
	robot.wheels.set_velocity(leftSpeed, rightSpeed)


end


function isTail()
	local isTail = 0

	-- robot is tail if it recieves only one chain member
	local m_count = count_message_recieved_in(1)
	m_count = m_count + count_message_recieved_in(2)
	m_count = m_count + count_message_recieved_in(3)

	if (m_count <=1) then
		isTail = 1
	end

return isTail end

function step_b_chain()
	-- first we have to set an appropriate signal for the relative
	-- prosition in the chain





	if (valid_chain_member == 0) then

		if(count_green_members == 0) and (count_red_members == 0) and (count_blue_members == 1) or (count_chain_sum == 0) then -- end of the chain -> green
			robot.range_and_bearing.set_data(1, 1)
			robot.leds.set_all_colors("green")
			valid_chain_member = 1
			chain_color = color_green
			setSpeed(0,0)
		end

		if(count_green_members == 1) and (count_red_members == 0) and (count_blue_members == 0) then -- end of the chain
			robot.range_and_bearing.set_data(2, 1)
			robot.leds.set_all_colors("red")
			valid_chain_member = 1
			chain_color = color_red
			setSpeed(0,0)
		end

		if(count_green_members == 0) and (count_red_members == 1) and (count_blue_members == 0) then -- end of the chain
			robot.range_and_bearing.set_data(3, 1)
			robot.leds.set_all_colors("blue")
			valid_chain_member = 1
			chain_color = color_blue
			setSpeed(0,0)
		end



	end

	if (valid_chain_member == 0) then
		-- still not a valid chain member than test if the robot found the prey
		if (isOnPrey() == false) then
			reset_all()
			behavior_change(b_exploration)
		end



	end

	if (isTail() == 1 and groundIsWhite >=0.9) then
		r_leave = robot.random.uniform()
		--log("r_leave" .. r_leave)
		--log("p_leave" .. p_leave)
		if (r_leave < p_leave) then
			reset_all()
			robot.wheels.set_velocity(30,30)
			behavior_change(b_exploration)
		end

	end

	if (valid_chain_member == 1) and (groundIsWhite >=0.9)then -- expand distance

		if (count_chain_sum >=2) then

			--patternExpand()


		else
			setSpeed(0,0)
		end

	end



end


function isOnPrey()

	-- only one per prey
	if (groundIsWhite == 0 and (count_message_recieved_in(4) == 0)) then
		robot.range_and_bearing.set_data(4, 1)
		robot.leds.set_all_colors("white")
		valid_chain_member = 1
		chain_color = color_prey
		setSpeed(0,0)
		behavior_change(b_end)
		return true
	else
		return false
	end
end


function reset_all()
	robot.range_and_bearing.set_data(3, 0)
	robot.range_and_bearing.set_data(2, 0)
	robot.range_and_bearing.set_data(1, 0)
	valid_chain_member = 0
	robot.leds.set_all_colors("black")


end

function step_b_search()




	if (leaves_nest == 1) then -- robot leaves the nest and tries to become nest keeper
		--log("groundIsWhite" .. groundIsWhite)
		if(search_nest >0) and (groundIsWhite >= 0.5)then
			--log("backwards!")
			--setSpeed(-15,0)
			search_nest = search_nest - 1
		else
			behavior_change(b_chain)
		end

	end

	if ((robot.motor_ground[1].value + robot.motor_ground[2].value) / 2 == 1) and ((robot.motor_ground[3].value + robot.motor_ground[4].value) / 2 < 1) then
			-- robot leaves the nest
			-- become nest keeper
			--log("Leaving nest")
		if(count_message_recieved_in(1) == 0) then

			leaves_nest = 1
		else
			behavior_change(b_exploration)
			log("b_exploration")
		end


	end

	if(count_green_members >0) and (leaves_nest < 1)then
		behavior_change(b_exploration)
	end



end


function step_b_exploration()


	log("AWDWADWDAWDWDAWDAWDAW")
	reset_all();
	setSpeed(30,0)
	--exploration_along_chain()


	if (isTail() == 1) then
		r_chain = robot.random.uniform()
		log("r_chain" .. r_chain)
		log("p_chain" .. p_chain)
		if (r_chain <= p_chain) then
			behavior_change(b_chain)
		end
	end

	-- look for prey
	--isOnPrey()
	-- if(groundIsWhite == 0) then
	-- 	log("groundIsWhite" .. groundIsWhite)
	-- 	behavior_change(b_chain)
	-- end



end

function behavior_change(new_behavior)
	wait_time = robot.random.uniform() * 10 + 1
	log("wait_time" .. wait_time)
	behavior = new_behavior
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	-- basic step setup
	proximity_table = table.copy(robot.proximity)

	count_green_members = count_message_recieved_in(1)
	count_red_members = count_message_recieved_in(2)
	count_blue_members = count_message_recieved_in(3)
	count_chain_sum = count_green_members + count_blue_members + count_red_members

	groundIsWhite = robot.motor_ground[1].value + robot.motor_ground[2].value + robot.motor_ground[3].value + robot.motor_ground[4].value

	groundIsWhite = groundIsWhite / 4

	if(wait_time >1) then
		wait_time = wait_time - 1
	else


		-- if(behavior == b_search) then -- robot in search behavior
		--
		-- 	step_b_search();
		--
		-- 	collisionHandling()
		--
		-- 	collisionDetection()
		--
		-- end

		if(behavior == b_exploration) then -- robot in exploration behavior

			step_b_exploration()

			collisionHandling()

			collisionDetection()

		end


		if(behavior == b_chain) then -- robot in chain behavior

			step_b_chain()

		end

		if(behavior == b_end) then -- robot in end behavior

		end

	end




end


function exploration_along_chain()
	-- body

	local t = robot.range_and_bearing
	local x = 0
	local y = 0

	if (count_message_recieved_in(1) >= 1) or (count_message_recieved_in(2) >=1) or (count_message_recieved_in(3) >=1) then

		for key,tab in pairs(t) do

			if(type(tab) == "table") then
				--log("Key : " .. key)
				--log("Table : " .. tab)
				--log("Type : " .. type(tab))
				--log("Range: ")
				--log(tab.range)
				if (tab.data[1] == 1) or (tab.data[2] == 1) or (tab.data[3] == 1) then
				--	log ("HB : " .. tab.horizontal_bearing)
				--	log ("Range : " .. tab.range)

					--log("Lastseen " .. lastSeenID)
					local hb = tab.horizontal_bearing
					range = tab.range
					local lennardJones =  lennard_jones(range)
					--log("leanrd" .. lennardJones)
					local temp_x = math.cos(hb)
					local temp_y = math.sin(hb)

					local temp_angle = math.atan2(temp_y,temp_x)

					--log("temp_angle " .. temp_angle)

					if (temp_angle <= math.pi/3) and (temp_angle >= -math.pi/3) then
						--temp_x = lennardJones * math.cos(hb)
						--temp_y = lennardJones * math.sin(hb)

						--log("Range " .. range)
						if (range >= 5) then

							x = x + temp_x
							y = y + temp_y

							--log("YESSSSSS")
						end
					else
						--log("NOOOOOO")
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
		turnSpeed = (turnSpeed * 16) / math.pi

		local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))
		--log("Length : " .. length)
		local normLength = length / maxLength

		if (normLength > 1) then
			normLength = 1
		end
		-- log("TURN BY: " .. turnSpeed)
		setSpeed(x_Velo, turnSpeed / normLength)

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
k = findMaxKey(proximity_table)
r = robot.random.bernoulli(0.9)

if (collisionLeft == 1) then
	--robot.wheels.set_velocity(x_Velo,-y_Velo)


	--log("r : " .. r)
	if (r == 1) then
		k = 14
	end
	if (k == 12) or ( k == 13) or (k == 14)then
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
		k = 17
	end
	if (k == 17) or ( k == 16) or (k == 15)then
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

if (nobodyThere(proximity_table) == 1) then
		collisionLeft = 0
		collisionRight = 0
		collision = 0
end



end


function collisionDetection()
-- DETECT



if(collision == 0) then
	--robot.wheels.set_velocity(0,0)

	closeValueRight =  proximity_table[24].value +  proximity_table[23].value  +  proximity_table[22].value + proximity_table[21].value + proximity_table[20].value
	closeValueLeft =   proximity_table[1].value + proximity_table[2].value + proximity_table[3].value + proximity_table[4].value + proximity_table[5].value

	maxValue = closeValueLeft + closeValueRight
	--log("Max Value : " .. maxValue)
	if (maxValue > 0.02) then
		if (closeValueLeft >= closeValueRight) then -- left
			collisionLeft = 1
			collisionRight = 0
			collision = 1
			robot.wheels.set_velocity(30/2,-30/4)
			--robot.leds.set_all_colors("yellow")

		else -- right
			collisionRight = 1
			collisionLeft = 0
			collision = 1
			robot.wheels.set_velocity(-30/4,30/2)
			--robot.leds.set_all_colors("red")
		end

	else
		collisionLeft = 0
		collisionRight = 0
		collision = 0

		setSpeed(leftSpeed, 0)
		--[[
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
		]]
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

function lennard_jones(range)
	local force = 0
	local temp = math.pow(dTarget / range, 2)
	force = -4*epsilon/range * ( math.pow(temp,2) - temp)


return force end


--
--
-- function setForceSpeed(speed, turnSpeed)
-- 	local leftSpeed = speed
-- 	local rightSpeed = speed
--
-- 	--  curve
-- 	leftSpeed = leftSpeed - turnSpeed
-- 	rightSpeed = rightSpeed + turnSpeed
--
--
--
-- 	robot.wheels.set_velocity(leftSpeed, rightSpeed)
--
--
-- end
--
--
-- function patternExpand()
--
--
--
-- 	local t = robot.range_and_bearing
-- 	local x = 0
-- 	local y = 0
--
--
-- 	for key,tab in pairs(t) do
--
-- 		if(type(tab) == "table") then
-- --			log("Key : " .. key)
-- 			--log("Table : " .. tab)
-- --			log("Type : " .. type(tab))
-- 			--log("Range: ")
-- 			--log(tab.range)
-- 			-- is it a green, red or blue chain member than calculate the force
-- 			if (tab.data[1] == 1) or (tab.data[2] == 1) or (tab.data[3] == 1) then
-- 			--	log ("HB : " .. tab.horizontal_bearing)
-- 			--	log ("Range : " .. tab.range)
-- 				local hb = tab.horizontal_bearing
-- 				local range = tab.range
-- 				local force =  lennard_jones(range)
--
-- 				local temp_x = force * math.cos(hb)
-- 				local temp_y = force * math.sin(hb)
-- 				--log("x : " .. temp_x)
-- 				--log("y : " .. temp_y)
-- 				x = x + temp_x
-- 				y = y + temp_y
--
-- 			end
-- 			--[[
-- 			for k,val in pairs(tab.data) do
-- 				log("Data Key : " .. k)
-- 				log("Data Val : " .. val)
--
-- 			end
-- 			--]]
-- 		end
--
-- 		end
-- 	-- log("Count : " .. count)
-- 	--log("Total x : " .. x)
-- 	--log("Total y : " .. y)
--
-- 	angle = math.atan2(y,x)
-- 	--log("Angle : " .. angle)
--
--
-- 	if (angle >= math.pi) then
-- 		turnSpeed = (math.pi*2 - angle) * -1
-- 	else
-- 		turnSpeed = angle
-- 	end
-- 	turnSpeed = (turnSpeed * 10) / math.pi
--
-- 	local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))
-- 	--log("Length : " .. length)
-- 	local normLength = length / maxLength
--
-- 	if (normLength > 1) then
-- 		normLength = 1
-- 	end
--
-- 	setForceSpeed(x_Velo/3 * normLength, turnSpeed)
-- end
