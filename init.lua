-- Based on LCD display in digilines mod.

--[[
    Future plans:
        multiblock displays?
        change font size within line
        the PNG files should all be the same dimensions
            (current workaround: font.lua reads bounding box information
            in the BDF file)
        the PNG files should all be transparent
            (current workaround: "[makealpha:255,255,255")
--]]

lemon_signs = {}

lemon_signs.default_colors = {
    display_back = "#333",
    background = "#555",
    border = "#333",
    foreground = "#EEE",
}

dofile(minetest.get_modpath("lemon_signs") .. "/helpers.lua")
dofile(minetest.get_modpath("lemon_signs") .. "/font.lua")
dofile(minetest.get_modpath("lemon_signs") .. "/textures.lua")

local display_box = {
    type = "wallmounted",
    wall_top = {0, -0.5, -0.5, 0, 0.5, 0.5},
}

local entity_adjustments = {
    [2] = {pos = vector.new(0.436, 0, 0),  yaw = math.pi / -2},
    [3] = {pos = vector.new(-0.436, 0, 0), yaw = math.pi / 2},
    [4] = {pos = vector.new(0, 0, 0.436),  yaw = 0},
    [5] = {pos = vector.new(0, 0, -0.436), yaw = math.pi},
}

local bg_pos_adjustments = {
    [2] = vector.new(0.001, 0, 0),
    [3] = vector.new(-0.001, 0, 0),
    [4] = vector.new(0, 0, 0.001),
    [5] = vector.new(0, 0, -0.001),
}

local get_entity_adjustment = function (pos)
    local adjustment = entity_adjustments[minetest.get_node(pos).param2]
    if adjustment == nil then adjustment = {pos = 0, yaw = 0} end
    return adjustment
end

local get_bg_pos_adjustment = function (pos)
    local adjustment = bg_pos_adjustments[minetest.get_node(pos).param2]
    if adjustment == nil then adjustment = 0 end
    return adjustment
end
        
local add_text_entities = function (pos)
    
    print("add_text_entities: "..pos.x..","..pos.y..","..pos.z)
    
    local adjustment = get_entity_adjustment(pos)
    
    local meta = minetest.get_meta(pos)
    local text = meta:get_string("text")
    
    -- if text == "" then return end
    
    local display_size, front_textures = lemon_signs.generate_textures(text)

    local add_text_entity = function ()
        local text_entity = minetest.add_entity(pos, "lemon_signs:display_text")
        text_entity:setpos(vector.add(text_entity:getpos(), adjustment.pos))
        text_entity:setyaw(adjustment.yaw)
        text_entity:set_properties({
            visual_size = display_size,
        })
        return text_entity
    end

    local other_texture = lemon_signs.generate_other_texture()
    
    for i, v in ipairs(front_textures) do
        -- minetest.chat_send_all("Adding text entity")
        local text_entity = add_text_entity()
        text_entity:set_properties({
            textures = {other_texture, front_textures[i]},
        })
        if i == 1 then
            local pos_adjustment = get_bg_pos_adjustment(pos)
            text_entity:setpos(vector.add(text_entity:getpos(), pos_adjustment))
        end
    end
end

local remove_text_entities = function (pos)
    print("remove_text_entities: "..pos.x..","..pos.y..","..pos.z)
    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    for _, o in ipairs(objects) do
	    local o_entity = o:get_luaentity()
	    if o_entity and o_entity.name == "lemon_signs:display_text" then
		    o:remove()
	    end
    end
end

minetest.register_entity(":lemon_signs:display_text", {
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "upright_sprite",
    textures = {""},
    
    on_activate = function (self, staticdata)
        if staticdata == "old entity" then
            local pos = vector.round(self.object:getpos())
            remove_text_entities(pos)
            add_text_entities(pos)
        end
    end,
    
    get_staticdata = function (self)
        return "old entity"
    end,
})

minetest.register_node("lemon_signs:display", {
    drawtype = "nodebox",
    description = "lemon_signs display",
    tiles = {
        "(display_background.png^[colorize:"..lemon_signs.default_colors.display_back..")"
    },
    
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "wallmounted",
    node_box = display_box,
    selection_box = display_box,
    groups = {choppy = 3, dig_immediate = 2},
    
    after_place_node = add_text_entities,
    
    on_construct = function (pos)
        minetest.get_meta(pos):set_string("formspec", "field[channel;Channel;${channel}]")
    end,
    
    on_destruct = remove_text_entities,
    
    on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
    
    digiline = {
        receptor = {},
        effector = {
            action = function (pos, _, channel, msg)
                local meta = minetest.get_meta(pos)
                local set_chan = meta:get_string("channel")
                if set_chan ~= channel then return end
                
                meta:set_string("text", msg)
                remove_text_entities(pos)
                if msg ~= "" then add_text_entities(pos) end
            end,
        },
    },
})
