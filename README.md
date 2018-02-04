# lemon_signs

Based on the LCD display in the digilines mod, but with some formatting available.
- <display 2 3> to change the display dimensions
- <c #C0FFEE> to change the foreground color
- <bg #C0FFEE> to change the background color
- <bdr #ABCDEF> to change the border color
- <n> for a newline
- <n s=3> to change the text size
- <lt> and <gt> to use the < and > characters normally

https://github.com/hchargois/gohufont

## Known issues

- The code is very slow.
- When changing font sizes there is sometimes overlap between lines.
- You can't change font size within a line.
- You need to do line wrapping manually.
- Large displays should require multiple blocks.
- No crafting.
- Is there a better licence?
