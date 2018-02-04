-- Should be replaced with something supporting Unicode.
lemon_signs.char_code = function (char)
    return string.byte(char)
end

-- http://ricilake.blogspot.co.uk/2007/10/iterating-bits-in-lua.html

lemon_signs.bit = function (p)
    return 2 ^ (p - 1)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
lemon_signs.hasbit = function (x, p)
    return x % (p + p) >= p       
end
