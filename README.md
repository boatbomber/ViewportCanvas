# ViewportCanvas
A canvas renderer using greedy meshed parts in a ViewportFrame to draw efficiently in Roblox. Serves as an alternative to [GreedyCanvas](https://github.com/boatbomber/GreedyCanvas) since that one hits Roblox's UI cap.

![landscape-canvas](https://user-images.githubusercontent.com/40185666/161709140-09edba9b-8228-4041-ac82-e077f94abc99.JPG)

![rainbow-canvas](https://user-images.githubusercontent.com/40185666/161709152-379bb77d-1eae-4736-aea6-921b422e1648.JPG)

## API

```Lua
ViewportCanvas.new(ResolutionX: number, ResolutionY: number)
```

returns a new canvas of the specified resolution

```Lua
ViewportCanvas.Threshold: number
```

Defines the greediness of the mesher using CIE76 color distances, should stay between 1 and 30

```Lua
ViewportCanvas:SetParent(Parent: Instance)
```

parents the canvas GUI to the passed Instance

```Lua
ViewportCanvas:SetPixel(X: number, Y: number, Color: Color3)
```

Sets the color of the canvas specified pixel

```Lua
ViewportCanvas:Render()
```

renders the canvas based on the set pixels

**(It will not automatically render, you must call this method when you've completed your pixel updates)**

```Lua
ViewportCanvas:Clear()
```

clears the canvas render


```Lua
ViewportCanvas:Destroy()
```

cleans up the canvas and its GUIs


----------------------

## Demonstration

```Lua
-- Frames
local Demo = script.Parent.Demo
local Ref = script.Parent.Ref

-- Resolution
local ResX, ResY = 16*6, 9*6

-- Create Canvas
local Canvas = require(script.ViewportCanvas).new(ResX, ResY)
Canvas:SetParent(Demo)

-- Draw pixels
for x=1, ResX do
	for y=1, ResY do
		-- Define color
		local v = math.sin(x/ResX) * math.cos(y/ResY)
		local c = Color3.fromHSV(v, 0.9, 0.9)

		-- Set in canvas
		Canvas:SetPixel(x, y, c)

		-- Draw naively for reference
		local pixel = Instance.new("Frame")
		pixel.BorderSizePixel = 0
		pixel.BackgroundColor3 = c
		pixel.Size = UDim2.fromScale(1/ResX, 1/ResY)
		pixel.Position = UDim2.fromScale((1/ResX)*(x-1), (1/ResY)*(y-1))
		pixel.Parent = Ref.Canvas
	end
end

-- Render canvas
Canvas:Render()

-- Expose counts
Demo.TextLabel.Text = string.format("Frames Instances: %d", Canvas._ActiveFrames)
Ref.TextLabel.Text = string.format("Frames Instances: %d", ResX*ResY)
```
