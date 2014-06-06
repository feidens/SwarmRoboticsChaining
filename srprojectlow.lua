-- Put your global variables here



-- Variables Second Approach

p_chain = 0.90            -- initial prob. to be part of a chain (Explore -> Chain)
p_leave = 1 - p_chain     -- prob. to leave a chain as last member of it (Chain -> Explore)
p_search = p_chain / 3    -- prob. to abort exploration and search nest or prey (Explore -> Search)
nest_stigmergy = 0

leave_chain_stigmergy = -200



b_nest = 0
b_exploration = 1
b_chain = 2
b_prey = 3

-- 0 := nest
-- 1 := Exploration
-- 2 := Chain member
-- 3 := End state on prey

behavior = b_exploration
behavior_old = b_exploration


wait_time = 0
wait_chain_time = 0


count_chain_sum = 0
valid_chain_member = 0

chain_color = 0
-- 0:= nothing
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






x_Velo = 30
y_Velo = 30


-- variables for chain member expand its distance
dTarget = 20
epsilon = 50
maxLength = dTarget / 8



-- exploration along chain
chain_dTarget = 50
chain_epsilon = 50


-- helper variables for collision detection and handeling
collision = 0
collisionLeft = 0
collisionRight = 0


--- range and bearing device data overview
comData={
1, -- chain first 	-  1 or 0  -	1
1, -- chain second	-  1 or 0  -	2
1, -- chain third	 -  1 or 0	-	3
1, -- found prey		-  1 or 0	-	4
0.0, --			5 to 10 not used
0.0,	--			6
0.0,	--			7
0.0,	--			8
0.0,	--			9
0.0	--			10
}




--[[ This function is executed every time you press the 'execute'
     button ]]
function init()

	-- Experiment
	robot.in_chain = 0


	-- enable distance scanner
	robot.distance_scanner.enable()
	robot.distance_scanner.set_rpm(240)

  -- init ground value
	groundIsWhite = 1
	-- set each robot as a invalid chain member
	valid_chain_member = 0

	-- init the wait time between behavior transitions
	wait_time = 0

-------------------------------------------

	-- standard wheel velocity settings
	x_Velo = 30
	y_Velo = 30




	-- start with the inital speed
	setSpeed(x_Velo, 0)

end



-- seet velocity of robot
function setSpeed(speed, turnSpeed)

	leftSpeed = speed
	rightSpeed = speed

	 --  curve
	if ((leftSpeed - turnSpeed) <= 0) then

		leftSpeed = math.max(-30, leftSpeed - turnSpeed)

	else

		leftSpeed = math.min(30, leftSpeed - turnSpeed)
	end

	if ((rightSpeed + turnSpeed) <= 0) then

		rightSpeed = math.max(-30, rightSpeed + turnSpeed)

	else

		rightSpeed = math.min(30, rightSpeed + turnSpeed)
	end

	robot.wheels.set_velocity(leftSpeed, rightSpeed)


end


-- Returns true if the robot is the tail of a chain
function isTail()

	-- robot is tail if it recieves only one chain member
	local m_count = count_chain_sum

	if (m_count < 2) then

		return true
	end

return false end



-- Decides to which position in the chain the robot will be assigned to
function chain_position_decision()


	-- We decide on a appropriate signal for the relative
	-- position in the chain

	if (valid_chain_member == 0) then


		if (count_green_members == 0) then -- no green
			if ( (count_blue_members == 1) or (count_chain_sum == 0) ) then -- green after blue
				chain_color = color_green
				valid_chain_member = 2
				wait_chain_time = robot.random.uniform() * robot.random.uniform()  + 1
			end
			if ( (count_red_members == 1) and (count_blue_members == 0)  ) then -- blue
				chain_color = color_blue
				valid_chain_member = 2
				wait_chain_time = robot.random.uniform() * robot.random.uniform()  + 1

			end
		end

		if (count_red_members == 0) then -- red
			if ( (count_blue_members == 1) or (count_green_members == 1) ) then
				chain_color = color_red
				valid_chain_member = 2
				wait_chain_time = robot.random.uniform() * robot.random.uniform()  + 1
			end
		end

		if ( count_blue_members == 0 ) then -- blue
			if ( (count_green_members == 1) and (count_red_members == 0) ) then
				chain_color = color_blue
				valid_chain_member = 2
				wait_chain_time = robot.random.uniform() * robot.random.uniform()  + 1
			end
		end



		if (valid_chain_member == 0) then

			chain_color = 0
			valid_chain_member = 0
			robot.in_chain = 0
			-- still not a valid chain member than test if the robot found the prey
			if (isOnPrey() == false) then
				reset_all()
				behavior_change(b_exploration)
			end

		end

	end

end


-- set chain position if there is no other robot with the same color
function set_chain_position()

	-- We set a appropriate signal for the relative
	-- position in the chain

	if (chain_color == color_green ) and (count_green_members == 0) then

		robot.range_and_bearing.set_data(1, 1)
		robot.leds.set_all_colors("green")
		valid_chain_member = 1
		robot.in_chain = 1
		setSpeed(0,0)
	end

	if (chain_color == color_red ) and ( count_red_members == 0 ) then

		robot.range_and_bearing.set_data(2, 1)
		robot.leds.set_all_colors("red")
		valid_chain_member = 1
		robot.in_chain = 1
		setSpeed(0,0)
	end

	if (chain_color == color_blue ) and ( count_blue_members == 0 )then

		robot.range_and_bearing.set_data(3, 1)
		robot.leds.set_all_colors("blue")
		valid_chain_member = 1
		robot.in_chain = 1
		setSpeed(0,0)
	end

	if (valid_chain_member == 2) then
		chain_color = 0
		valid_chain_member = 0
		robot.in_chain = 0
		-- still not a valid chain member than test if the robot found the prey
		if (isOnPrey() == false) then
			reset_all()
			behavior_change(b_exploration)
		end

	end

end




-- Execute chain behavior
-- Robot will leave this behavior depending on the following conditions:
-- If the robot is on the prey the behavior will be changed to b_prey
function step_b_chain()


	-- wait time after a decision on the chain position was made
	if(wait_chain_time >1) then
		wait_chain_time = wait_chain_time - 1
	else

		-- If the robot still has no valid relative position in the chain
		if (valid_chain_member == 0) and (behavior == b_chain) then

			chain_position_decision()

		end
		-- set position according to the previous made decision
		set_chain_position()


	end





	-- if the robot has a valid relative position in the chain
	-- leave the chain if there are other robots with the same position
	-- recognized by color and data send over range and bearing sensors
	if (valid_chain_member == 1) then

		-- look if there is another robot with the same color
		-- if this is true than draw a random number to leave the chain
			if (chain_color == color_green ) and (count_green_members > 0) then

				leave_chain_decision()
			end

			if (chain_color == color_red ) and ( count_red_members > 0 ) then

				leave_chain_decision()
			end

			if (chain_color == color_blue ) and ( count_blue_members > 0 )then

				leave_chain_decision()
			end




		-- expand the distance to the other chain members
		-- we use a force calculated with the lennard jones method to
		-- achieve this pattern
		if (count_chain_sum >=1) then

			patternExpand()
			robot.in_chain = 1

		else
			-- chain is not build longer than one robot than wait
			-- One robot does not make a chain
			robot.in_chain = 0
			setSpeed(0,0)
		end



		-- if robot is tail and not used by other robots to explore
		if ( isTail() == true ) then

			leave_chain_stigmergy = leave_chain_stigmergy - robot.random.uniform() * count_messages_sum
			leave_chain_stigmergy = leave_chain_stigmergy + 2  + 20 * (1- groundIsWhite)-- for tail

		else

			leave_chain_stigmergy = leave_chain_stigmergy - 2 -- for not tail


		end




		-- leave the chain decision made with stigmergy and probabilty
		r_leave = robot.random.uniform()

		if (r_chain <= p_chain) and (leave_chain_stigmergy > 400) then
			wait_chain_time = 50
			behavior_change(b_exploration)
		end


	end


	-- test whether the robot has found the prey
	-- in case change behavior in function isOnPrey
	isOnPrey()

end


-- Decide if the robot should leave the chain
function leave_chain_decision()



		r_leave = robot.random.uniform()

		if (r_leave < p_leave) then
			reset_all()
			robot.wheels.set_velocity(30,30)
			behavior_change(b_exploration)
			return true
		end


		return false
end


-- Test and reaction on the presence of a prey
-- Change behavior to b_prey (Prey behavior) if prey
-- is under the robot
function isOnPrey()

	-- only one per prey
	if (groundIsWhite < 0.5) and (count_prey_members == 0) then
		robot.range_and_bearing.set_data(4, 1)
		robot.leds.set_all_colors("white")
		valid_chain_member = 1
		chain_color = color_prey
		setSpeed(30,0)
		behavior_change(b_prey)
		return true
	else
		return false
	end
end



-- Resets state to pre exploration behavior
function reset_all()
	robot.range_and_bearing.set_data(3, 0)
	robot.range_and_bearing.set_data(2, 0)
	robot.range_and_bearing.set_data(1, 0)
	robot.range_and_bearing.set_data(4, 0)
	valid_chain_member = 0
	robot.in_chain = 0
	leave_chain_stigmergy = 0
	x_Velo = 30
	robot.leds.set_all_colors("black")

end


-- Executes exploration behavior
-- Robot explores along chain and calculate probability
-- to participate in the chain as a chain member and therefore
-- changes to b_chain (Chain behavior)
function step_b_exploration()


	reset_all(); -- resets values to exploration state

	-- explore along the chain if no collision is detected
	if (collision == 0) then

		exploration_along_chain()

	end

	-- wait time after behavior change from chain to exploration
	if(wait_chain_time >1) then
		wait_chain_time = wait_chain_time - 1
	else
		-- calculate probability to participate in perceived chain
		calcPChain()

		-- draw a random value r_chain and
		-- change behavior to chain behavior if
		-- r_chain <= p_chain
		r_chain = robot.random.uniform()
		if (r_chain <= p_chain) then
			behavior_change(b_chain)
		end
	end
	-- look for prey
	isOnPrey()

	-- look for nest
	isOnNest()



end




-- Calculates probability for become a chain member
function calcPChain()



	p_chain = robot.random.uniform() - 1 * ( math.pow( ( 1 + count_chain_sum ), 2 ) /  ( math.pow( ( 1 +  count_messages_sum), 2 ) ) ) - 20 * (1 - groundIsWhite)
	p_chain = p_chain / 2


end


-- Calculates value for become a nest keeper
function calcSNest()

	local nestGround = 1
	if (groundIsWhite > 0.80) then -- ignore Prey spot
		nestGround = groundIsWhite
	end

	nest_stigmergy = nest_stigmergy + (1-2*count_prey_members) - nestGround

end


-- Test and reaction on the presence of a nest
-- Change behavior to b_nest (Nest behavior) if nest
-- is under the robot
function isOnNest()

	-- update nest stigmergy
	calcSNest()

	if (100 <= nest_stigmergy) then

		robot.range_and_bearing.set_data(4, 1)
		robot.leds.set_all_colors("white")
		valid_chain_member = 1
		chain_color = color_prey
		setSpeed(5,0)
		behavior_change(b_nest)
	end

end

-- Wait some uniform chosen time steps before next behavior is activated
function behavior_change(new_behavior)
	wait_time = robot.random.uniform() * 10 + 2
	behavior = new_behavior
end




--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	-- basic step setup

	-- copy proximity table for later use (e.g. Collision Detection)
	proximity_table = table.copy(robot.proximity)

	-- helper variables for the number of chain members
	count_green_members = count_message_recieved_in(1)
	count_red_members = count_message_recieved_in(2)
	count_blue_members = count_message_recieved_in(3)
	count_chain_sum = count_green_members + count_blue_members + count_red_members

	-- helper variable for the number of robots that stands on the prey
	count_prey_members = count_message_recieved_in(4)

	-- helper variable for the number of overall revieved message,
	-- which is equal to the number of robots in range
	count_messages_sum = count_message_recieved()

	-- helper variable for the ground value, 0 == black, 1 == white
	groundIsWhite = robot.motor_ground[1].value + robot.motor_ground[2].value + robot.motor_ground[3].value + robot.motor_ground[4].value
	groundIsWhite = groundIsWhite / 4


	updateMaxRange()

	-- wait before the next behavior is activated
	if(wait_time >1) then
		wait_time = wait_time - 1

	else

		if(behavior == b_nest) then -- robot in nest behavior

			step_b_nest()

		end


		if(behavior == b_exploration) then -- robot in exploration behavior

			collisionHandling()

			collisionDetection()

			step_b_exploration()

		end


		if(behavior == b_chain) then -- robot in chain behavior

			step_b_chain()

		end

		if(behavior == b_prey) then -- robot in end/prey behavior

			step_b_prey()

		end

	end




end


-- Execute nest behavior
-- Robot will leave this behavior depending on nest_stigmergy
-- If there are more nest keepers or robots in range than
-- it is more likely that the robot will begin to explore
function step_b_nest()

	setSpeed(0, 0)

	calcSNest()

	r_nest = robot.random.uniform()
	--log("r_chain" .. r_chain)
	--log("p_chain" .. p_chain)
	if (20 > nest_stigmergy) or (r_nest < 0.02) then
		reset_all()
		setSpeed(x_Velo, 0)
		behavior_change(b_exploration)
	end

end

-- Execute prey behavior
-- Robot will leave this behavior depending on the condition:
-- If there are more prey keepers or robot is no longer on prey
-- the robot will begin to explore
function step_b_prey()

	setSpeed(0, 0)

	if ( count_prey_members > 0 ) or ( groundIsWhite >= 0.5 ) then
		reset_all()
		setSpeed(x_Velo, 0)
		behavior_change(b_exploration)
	end

end

-- Execute exploration of robot along the chain members
-- We use a force calculated with the lennard jones method
function exploration_along_chain()


	local t = robot.range_and_bearing
	local x = 0
	local y = 0

	if ( count_chain_sum > 0 ) then

		for key,tab in pairs(t) do

			if(type(tab) == "table") then

				if (tab.data[1] == 1) or (tab.data[2] == 1) or (tab.data[3] == 1) then

					local hb = tab.horizontal_bearing
					range = tab.range
					local lennardJones =  lennard_jones(range, chain_dTarget, chain_epsilon )

					local temp_x = math.cos(hb)
					local temp_y = math.sin(hb)

					local temp_angle = math.atan2(temp_y,temp_x)


					if (temp_angle <= 1.7) and (temp_angle >= -1.7) then

						temp_x =  lennardJones * math.cos(hb)
						temp_y =  lennardJones * math.sin(hb)


						x = x + temp_x
						y = y + temp_y


					end

				end

			end

	  end

	end



	-- distance scanner
	dist = robot.distance_scanner

	local x = 0
	local y = 0

	-- force attracted to free areas in long range
	for key,tab in pairs(dist.long_range) do



		if(type(tab) == "table") then



			local hb = tab.angle
			range = tab.distance


			--avoid for obstacles
			if(range >= 0)  then
				local lennardJones =  lennard_jones(range, 50, 50 )

				local temp_x = math.cos(hb)
				local temp_y = math.sin(hb)

				local temp_angle = math.atan2(temp_y,temp_x)



					temp_x =  lennardJones * math.cos(hb)
					temp_y =  lennardJones * math.sin(hb)


					x = x + temp_x
					y = y + temp_y

			end


			-- we want to go where nothing is in the way
			if (hb < 1) and (hb > -1) then
				if(range == -2) then
					local lennardJones =  lennard_jones(26, 20, 80)

					local temp_x = math.cos(hb)
					local temp_y = math.sin(hb)

					local temp_angle = math.atan2(temp_y,temp_x)




						temp_x =  50* lennardJones * math.cos(hb)
						temp_y =  50* lennardJones * math.sin(hb)


						x = x + temp_x
						y = y + temp_y

				end
			end
		end

	end

	-- force repellent from near obtacles
	for key,tab in pairs(dist.short_range) do



		if(type(tab) == "table") then



			local hb = tab.angle
			range = tab.distance

			----avoid for obstacles
			if(range >= 0)  then
				local lennardJones =  lennard_jones(range, 15, 20 )

				local temp_x = math.cos(hb)
				local temp_y = math.sin(hb)

				local temp_angle = math.atan2(temp_y,temp_x)




				temp_x =   	10 * lennardJones * math.cos(hb)
				temp_y =  10 * lennardJones * math.sin(hb)


				x = x + temp_x
				y = y + temp_y

			end

		end

	end

		angle = math.atan2(y,x)


		-- correct angle according to the robot's x y plane
		if (angle >= math.pi) then
			turnSpeed = (math.pi*2 - angle) * -1
		else
			turnSpeed = angle
		end
		turnSpeed = (turnSpeed * 8) / math.pi

		local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))

		local normLength = length / (x_Velo/8)


		if (normLength > 1) then
			normLength = 1
		end

		setForceSpeed(x_Velo * normLength, turnSpeed)

end



--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
   -- put your code here

	robot.in_chain = 0
	robot.distance_scanner.enable()
	robot.distance_scanner.set_rpm(240)

end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end


-- Handles the collsion on the left or right side
-- The collisions are sometimes ignored to avoid getting stuck
function collisionHandling()


	if (collision == 1) then


	k = findMaxKey(proximity_table)

	-- random binary variable r
	-- r is used to determine whether a collision will be ignored
	r = robot.random.bernoulli(0.9)

		if (collisionLeft == 1) then

			-- ignore according to r a front collisions
			if (r == 1) then
				k = 14
			end
			-- ignore all collisions from behind
			-- the robot behind will handle this
			if (k == 12) or ( k == 13) or (k == 14)then
				collisionLeft = 0
				collision = 0;
			end

			-- perhaps the other way arround - right
			-- good for situations where a robot get stuck (e.g. corners)
			r = robot.random.bernoulli(0.05)
			if (r == 1) then

				robot.wheels.set_velocity(-x_Velo/4,y_Velo)


			end
		end


		-- same behavior as for the left side
		if (collisionRight == 1) then

			if (r == 1) then
				k = 17
			end
			if (k == 17) or ( k == 16) or (k == 15) then

				collisionRight = 0
				collision = 0;
			end

			-- perhaps the other way arround - left
			r = robot.random.bernoulli(0.05)
			if (r == 1) then

				robot.wheels.set_velocity(x_Velo,-y_Velo/4)

			end
		end


		-- if there is no robot we assume that the collision was somehow
		-- already handled by something
		if (nobodyThere(proximity_table) == 1) then
				collisionLeft = 0
				collisionRight = 0
				collision = 0
		end

	end

end



-- Detect collisions on the left and right side
-- Both sides consider also the front proximity sensors
function collisionDetection()



	-- DETECT
	if(collision == 0) then

		-- helper varaibles for the proximity values of the anterior left and right proxmity values
		closeValueRight =  proximity_table[24].value +  proximity_table[23].value  +  proximity_table[22].value + proximity_table[21].value + proximity_table[20].value
		closeValueLeft =   proximity_table[1].value + proximity_table[2].value + proximity_table[3].value + proximity_table[4].value + proximity_table[5].value

		maxValue = closeValueLeft + closeValueRight

		-- check the sum of left and right whether there is a collsion
		-- next check if it is left or right
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




-- Sums up the data in the ith byte of the range and bearing tables
function count_message_recieved_in(i)
	local t = robot.range_and_bearing
	local count = 0

	for key,tab in pairs(t) do

		if(type(tab) == "table") then

			count = count + tab.data[i]

		end

  end

return count end


-- Calculate the number of recieved tables over range and bearing
-- Since every robots sends some data over range and bearing,
-- the calculated number is equal to the robots in range
function count_message_recieved()
	local t = robot.range_and_bearing
	local count = 0

	for key,tab in pairs(t) do

		if(type(tab) == "table") then

			count = count + 1

		end

  end

return count end


-- Calculating force with the lennard jones method
function lennard_jones(range, target, eps)
	local force = 0
	local temp = math.pow(target / range, 2)
	force = -4*eps/range * ( math.pow(temp,2) - temp)

return force end



-- Set the velocity to speed and turn speed
-- values which were calculated according to a force
function setForceSpeed(speed, turnSpeed)
	local leftSpeed = speed
	local rightSpeed = speed

	--  curve
	leftSpeed = leftSpeed - turnSpeed
	rightSpeed = rightSpeed + turnSpeed

	robot.wheels.set_velocity(leftSpeed, rightSpeed)


end


function updateMaxRange()
	local t = robot.range_and_bearing


	for key,tab in pairs(t) do

		if(type(tab) == "table") then

			dTarget = math.max( tab.range ,  dTarget)

		end

	end
end

-- Robots in the chain will expand its distance according
-- to the range and bearing values of chain members
function patternExpand()


	local t = robot.range_and_bearing
	local x = 0
	local y = 0


	for key,tab in pairs(t) do

		if(type(tab) == "table") then

			-- is it a green, red or blue chain member than calculate the force
			if (tab.data[1] == 1) or (tab.data[2] == 1) or (tab.data[3] == 1) then

				local hb = tab.horizontal_bearing
				local range = tab.range
				local force =  lennard_jones(range, dTarget, epsilon)

				local temp_x = force * math.cos(hb)
				local temp_y = force * math.sin(hb)

				x = x + temp_x
				y = y + temp_y

			end
		end -- end if table has correct format

	end -- end for




	angle = math.atan2(y,x)

	-- correct angle according to the robot's x y plane
	if (angle >= math.pi) then
		turnSpeed = (math.pi*2 - angle) * -1
	else
		turnSpeed = angle
	end
	turnSpeed = (turnSpeed * 10) / math.pi

	local length = math.sqrt( math.pow(x,2) +  math.pow(y,2))

	local normLength = length / maxLength

	if (normLength > 1) then
		normLength = 1
	end

	setForceSpeed(x_Velo/3 * normLength, turnSpeed)
end
