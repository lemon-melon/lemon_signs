local DISPLAY_RES = 128
local CHAR_WIDTH = 6
local CHAR_HEIGHT = 11
local BORDER_FRACTION = 1 / 32
local BORDER_WIDTH = BORDER_FRACTION * DISPLAY_RES
local X_PADDING = 1.5 / 32 * DISPLAY_RES
local Y_PADDING = 1.5 / 32 * DISPLAY_RES

local parse_instruction = function (str)
    local instruction = str:match("^<(%a+)")
    if instruction == "bg" then
        local color = str:match("^<bg (#%x+)>")
        return {"background_color", color}
    elseif instruction == "bdr" then
        local color = str:match("^<bdr (#%x+)>")
        return {"border_color", color}
    elseif instruction == "c" then
        local color = str:match("^<c (#%x+)>")
        return {"color", color}
    elseif instruction == "dotted" then
        return {"dotted"}
    elseif instruction == "undotted" then
        return {"undotted"}
    elseif instruction == "n" then
        -- new_size will possibly be nil.
        local new_size = str:match("^<n s=(%d+)>")
        return {"newline", tonumber(new_size)}
    elseif instruction == "lt" then
        return {"text", "<"}
    elseif instruction == "gt" then
        return {"text", ">"}
    elseif instruction == "display" then
        local size_x, size_y = str:match("^<display (%d+) (%d+)>")
        return {"display_size", tonumber(size_x), tonumber(size_y)}
    end
end

local parse_text = function (str)
    if not str then return "" end
    local parts = {}
    local i = 1
    while i <= #str do
        local remaining = str:sub(i)
        local match_instruction = remaining:match("^<[^>]*>")
        if match_instruction then
            local instruction = parse_instruction(match_instruction)
            if instruction ~= nil then table.insert(parts, instruction) end
            i = i + #match_instruction
        else
            local match_text = remaining:match("^[^<]*")
            table.insert(parts, {"text", match_text})
            i = i + #match_text
        end
    end
    return parts
end

local get_char_filename = function (char)
    return "character_"..(lemon_signs.char_code(char))..".png"
end

lemon_signs.generate_textures = function (str)
    
    -- For debugging: start the string with ! to use it as the texture.
    if str:sub(1, 1) == "!" then return str:sub(2) end
    
    lemon_signs.font.open_file()
    
    local parts = parse_text(str)
    
    -- (21/Oct/2017) Until I think of better variable names.
    local AAA = {
        background_color = lemon_signs.default_colors.background,
        border_color = lemon_signs.default_colors.border,
        display_size = {x = 1, y = 1},
    }
    local BBB = {}
    
    local color = lemon_signs.default_colors.foreground
    local line_font_size = 1
    local is_dotted = false
    
    local XXX = 0
    local YYY = 0
    
    local encountered_text = false
    
    for i = 1, #parts do
        local instruction = parts[i][1]
        if instruction == "background_color" then
            local background_color = parts[i][2]
            AAA.background_color = background_color
        elseif instruction == "border_color" then
            local border_color = parts[i][2]
            AAA.border_color = border_color
        elseif instruction == "color" then
            color = parts[i][2]
        elseif instruction == "dotted" then
            is_dotted = true
        elseif instruction == "undotted" then
            is_dotted = false
        elseif instruction == "newline" then
            XXX = 0
            -- Allows you to use <n s=42> to change font size at the start of the string.
            if encountered_text == true then YYY = YYY + 1 * line_font_size end
            local new_size = parts[i][2]
            if new_size ~= nil then line_font_size = new_size end
        elseif instruction == "text" then
            encountered_text = true
            local start_x = XXX
            local start_y = YYY
            local text = parts[i][2]
            for ii = 1, #text do
                XXX = XXX + 1 * line_font_size
            end
            table.insert(BBB, {text = text, color = color, x = start_x, y = start_y,
                font_size = line_font_size, is_dotted = is_dotted})
        elseif instruction == "display_size" then
            AAA.display_size.x = parts[i][2]
            AAA.display_size.y = parts[i][3]
        end
    end
    
    -- minetest.chat_send_all(minetest.write_json({AAA = AAA, BBB = BBB}, true))
    
    local display_width = DISPLAY_RES * AAA.display_size.x
    local display_height = DISPLAY_RES * AAA.display_size.y
    
    local textures = {}
    
    local bg = "[combine:"..display_width.."x"..display_height
    
    -- Background color.
    bg = bg.."^([combine:1x1:0,0=pixel_1.png^[colorize:"..
        AAA.background_color.."^[resize:"..display_width.."x"..display_height..")"
    
    -- Top border.
    bg = bg.."^([combine:1x1:0,0=pixel_1.png^[resize:"..
            display_width.."x"..BORDER_WIDTH.."^[colorize:"..AAA.border_color..")"
    
    -- Left-hand border.
    bg = bg.."^([combine:1x1:0,0=pixel_1.png^[resize:"..
            BORDER_WIDTH.."x"..display_height.."^[colorize:"..AAA.border_color..")"
    
    -- Right-hand border.
    bg = bg.."^([combine:"..display_width.."x1"
    for i = (display_width - BORDER_WIDTH), display_width do
        bg = bg..":"..i..",0=pixel_1.png"
    end
    bg = bg.."^[resize:"..display_width.."x"..display_height..
            "^[colorize:"..AAA.border_color..")"
    
    -- Bottom border.
    bg = bg.."^([combine:1x"..display_height
    for i = (display_height - BORDER_WIDTH), display_height do
        bg = bg..":0,"..i.."=pixel_1.png"
    end
    bg = bg.."^[resize:"..display_width.."x"..display_height..
            "^[colorize:"..AAA.border_color..")"
    
    table.insert(textures, bg)
    
    -- local texture = "[combine:"..display_width.."x"..display_height
    
    for i, v in ipairs(BBB) do
        local text = v.text
        local t = "[combine:"..display_width.."x"..display_height
        for ii = 1, #text do
            local char = text:sub(ii, ii)
            local pixels = lemon_signs.font.foo(char)
            local adjust_x, adjust_y = lemon_signs.font.get_adjustments(char)
            for iii, vv in ipairs(pixels) do
                local x_pos =
                    (X_PADDING + v.x*CHAR_WIDTH + v.font_size*(ii*CHAR_WIDTH + vv[1] - adjust_x))
                local y_pos =
                    (Y_PADDING + v.y*CHAR_HEIGHT + v.font_size*(vv[2] + CHAR_HEIGHT - adjust_y))
                local pixel_size = (v.font_size)
                t = t..":"..x_pos..","..y_pos.."=pixel_"..pixel_size..".png"
            end
        end
        --[[
        texture = texture.."^("..t
        texture = texture.."^[colorize:"..(v.color)
        texture = texture..")"
        --]]
        table.insert(textures, t.."^[colorize:"..(v.color))
        -- I've managed to use a texture up to 65190 characters in length without Minetest crashing.
        -- I guess Minetest crashes if the texture is 65536 characters (because 2 ^ 16).
        -- minetest.chat_send_all("The texture string comprises "..#t.." characters!")
    end
    
    -- texture = texture.."^[combine:"..display_width.."x"..display_height..":100,100=character_background.png"
    
    -- minetest.chat_send_all(texture)
    
    lemon_signs.font.close_file()
    
    -- table.insert(textures, texture)
    
    return AAA.display_size, textures
    
end

lemon_signs.generate_other_texture = function ()
    return "pixel_1.png^[colorize:"..lemon_signs.default_colors.display_back
end
