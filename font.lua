lemon_signs.font = {}

local bdf_file
local bdf

lemon_signs.font.open_file = function ()
    bdf_file = io.open(
        minetest.get_modpath("lemon_signs") .. "/textures/GohuFont-TTF/gohufont-11.bdf", "r")
    bdf = bdf_file:read("*a")
end

lemon_signs.font.get_adjustments = function (char)

    local char_pos = bdf:find("ENCODING "..(lemon_signs.char_code(char)), 1, true)
    
    local bbx_width_str, bbx_height_str, bbx_x_str, bbx_y_str =
        bdf:match("BBX (%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+)", char_pos)
    
    local bbx_width = tonumber(bbx_width_str)
    local bbx_height = tonumber(bbx_height_str)
    local bbx_x = tonumber(bbx_x_str)
    local bbx_y = tonumber(bbx_y_str)
    
    local adjust_x = bbx_width + bbx_x
    local adjust_y = bbx_height + bbx_y
    
    return adjust_x, adjust_y
    
end

lemon_signs.font.foo = function (char)
    
    local bit = lemon_signs.bit
    local hasbit = lemon_signs.hasbit
    
    local char_pos = bdf:find("ENCODING "..(lemon_signs.char_code(char)), 1, true)
    
    local bitmap_str = bdf:match("BITMAP([%x%s]+)ENDCHAR", char_pos)
    
    local bitmap = {}
    
    for line in bitmap_str:gmatch("%x+") do
        table.insert(bitmap, tonumber(line, 16))
    end
    
    local pixels = {}
    
    for i, v in ipairs(bitmap) do
        local str = ""
        for ii = 8, 1, -1 do
            if hasbit(v, bit(ii)) then
                str = str.."8"
                table.insert(pixels, {8 - ii, i - 1})
            else str = str.."-" end
        end
    end
    
    return pixels
    
end

lemon_signs.font.close_file = function () bdf_file:close() end
