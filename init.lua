-- Create public mod table
pointlib = {}

-- Check for custom hand range
local range = minetest.registered_items[""].range or 4

-- Check pointlib visibility
local function visible(node, player)
    -- To prevent a crash from unknown nodes
    local def = minetest.registered_items[node]
    if def == nil then
        return false
    end
    -- Don't show air!
    if def.name == "air" then
        return false
    end
    -- Check if the Player is holding down the sneak key, if they are then show all nodes
    if not player:get_player_control().sneak then
        if def.drawtype == "liquid" or def.drawtype == "flowingliquid" or def.drawtype == "airlike" then
            return false
        end
    end
    -- Make sure the node hasn't requested to be hidden
    if def.groups.not_pointlib_visible and def.groups.not_pointlib_visible ~= 0 then
        return false
    end
    -- If def passes these checks then node is visible
    return true
end

-- Check for closest visible node in ray
function pointlib.update(player)
    -- Get player eyeheight
    local eye_height = player:get_properties().eye_height or 1.625
    -- Get player eye offset
    local eye_offset = player:get_eye_offset()
    -- Create eye position array, all factors considered
    local eye_pos = {}
    -- Somehow one eye_offset unit translates to 0.1 in eye_height unit, use that.
    eye_pos.x = eye_offset.x * 0.1
    eye_pos.y = eye_height + eye_offset.y * 0.1
    eye_pos.z = eye_offset.z * 0.1
    -- Get player (eye) position
    local pos = vector.add(player:get_pos(), eye_pos)
    -- Get player view direction
    local dir = player:get_look_dir()
    -- Get player name
    local name = player:get_player_name()
    -- Cast a ray in this direction
    local ray = minetest.raycast(pos, vector.add(pos, vector.multiply(dir, range)), false, true)
    -- Create variable of node node of possible outcome
    local itemstring = ""
    -- Create variable of node pos position of possible outcome
    local node_pos = {}
    -- Create variable of node description of possible outcome
    local description = ""
    -- Step through ray
    for pointed_thing in ray do
        -- Create variable for nodes found in ray
        local itemstring_in_ray = minetest.get_node(pointed_thing.under).name
        -- Check if node should be ignored or not
        if visible(itemstring_in_ray, player) then
            -- If so, put it in node itemstring outcome variable
            itemstring = itemstring_in_ray
            -- Also record
            node_pos = pointed_thing.under
            -- No need to step further in ray
            break
        end
    end
    -- Execute on_point functions in pointed node's definition
    if itemstring ~= "" and minetest.registered_nodes[itemstring].on_point then
        minetest.registered_nodes[itemstring].on_point(pos, player, node_pos)
    end
    -- Return pointed node itemstring and position to external API function
    return {
        itemstring = itemstring,
        pos = node_pos
    }
end
