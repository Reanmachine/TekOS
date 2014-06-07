-- Reanmachine TekOS
-- APP: Quarry

local place_x = 0
local place_y = 0
local place_z = 0

local dump_x = -1
local dump_y = 0

local orientation_north = 0
local orientation_east 	= 1
local orientation_south = 2
local orientation_west	= 3

local orientation 		= orientation_north

function increment_place_forward()
	if orientation == orientation_north then place_y = place_y + 1 end
	if orientation == orientation_east then place_x = place_x + 1 end
	if orientation == orientation_south then place_y = place_y - 1 end
	if orientation == orientation_west then place_x = place_x - 1 end
end

function increment_place_up()
	place_z = place_z - 1
end

function increment_place_down()
	place_z = place_z + 1
end

function face(target_orientation)
	local rotations = (target_orientation - orientation) % 4
	local direction = 1 -- right

	if rotations == 0 then return end
	if rotations == 3 then
		rotations = 1
		direction = -1
	end

	for r = 1, (rotations + 1) do
		if direction == 1 then turtle.turnRight() end
		if direction == -1 then turtle.turnLeft() end
	end

	orientation = target_orientation
end

function move(target_orientation, target_distance)
	if orientation ~= target_orientation then face(target_orientation) end

	for i = 1, target_distance do
		if turtle.forward() then
			increment_place_forward()
		else
			false
		end
	end

	return true
end

function move_vertical(distance)
	if distance > 0 then
		for z = 1, distance do
			if turtle.up() then
				increment_place_up()
			else
				return false
			end
		end
	else
		for z = 1, (-1 * distance) do
			if turtle.down() then
				increment_place_down()
			else
				return false
			end
		end
	end

	return true
end

function move_to(target_x, target_y, target_z)
	local current_x = place_x
	local current_y = place_y
	local current_z = place_z

	if target_z < current_z then

		-- Going up, do up first
		move_vertical(target_z - current_z)

	end

	if target_y > current_y then move(orientation_east, target_y - current_y) end
	if target_y < current_y then move(orientation_west, current_y - target_y) end

	if target_x > current_x then move(orientation_north, target_x - current_x) end
	if target_x < current_x then move(orientation_south, current_x - target_x) end

	if target_z > current_z then

		-- Going down, do up last
		move_vertical(target_z - current_z)

	end

end

function has_space()
	for i = 1, 16 do
		if turtle.getItemCount(i) == 0 then
			-- Has space to expand
			return true;
		end
	end

	return false
end

function unload_stuff()
	face(orientation_west)
	for i = 1, 16 do
		turtle.select(i)
		turtle.drop()
	end
end

function dig(span_x, span_y, span_z)
	
	for z = 1, span_z do
		for y = 1, span_y do
			for x = 1, span_x do
				turtle.digDown()
				if not has_space() then
					-- out of space, go offload stuff
					local c_x = place_x
					local c_y = place_y
					local c_z = place_z
					local o = orientation

					move_to(0, 0, 0)
					unload_stuff()
					move_to(c_x, c_y, c_z)
					face(o)
				end

				if x ~= span_x then	move(orientation_east, 1) end
			end

			-- Like a typewriter, return to base before advancing
			move(orientation_west, span_x)
			if y ~= span_y then move(orientation_north, 1) end
		end

		-- return to x = 0, y = 0
		move(orientation_south, span_y)
		move_vertical(1)
	end
end

function usage()
	print("quarry <right> <forward> <down>")
	print("  <right> the number of spaces to the right of the turtle to dig")
	print("  <forward> the number of spaces in front of the turtle to dig")
	print("  <down> the number of spaces down from the turtle to dig")
end

local arg = { ... }

if #arg != 3 then
	print("ERROR: too few arguments")
	usage()
	exit()
end

dig(arg[1], arg[2], arg[3])