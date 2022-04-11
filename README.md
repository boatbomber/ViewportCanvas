# ViewportCanvas
A canvas renderer using greedy meshed parts in a ViewportFrame to draw efficiently in Roblox. Serves as an alternative to [GradientCanvas](https://github.com/boatbomber/GradientCanvas) since that one hits Roblox's UI cap.

Here's ViewportCanvas rendering a 4k image (that's 8,294,400 pixels!) using just 1,176,336 Parts. No UI cap to concern yourself with!

![spiderman-4k](https://user-images.githubusercontent.com/40185666/161853706-8585bf17-84db-4e31-b6a8-dfb6e9954547.PNG)

![rainbow-canvas](https://user-images.githubusercontent.com/40185666/161710154-82d50e4f-87c3-4f48-8a51-fc54854cca4e.JPG)

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
local ResX, ResY = 16*10, 9*10

-- Create Canvas
local Canvas = require(script.ViewportCanvas).new(ResX, ResY)
Canvas:SetParent(Demo.Holder)

-- Draw pixels
for x=1, ResX do
	for y=1, ResY do
		-- Define color
		local color = Color3.fromHSV(x/ResX, y/ResY, 1)

		-- Set in canvas
		Canvas:SetPixel(x, y, color)

		-- Draw naively for reference
		local pixel = Instance.new("Frame")
		pixel.BorderSizePixel = 0
		pixel.BackgroundColor3 = color
		pixel.Size = UDim2.fromScale(1/ResX, 1/ResY)
		pixel.Position = UDim2.fromScale((1/ResX)*(x-1), (1/ResY)*(y-1))
		pixel.Parent = Ref.Holder
	end
end

-- Render canvas
Canvas:Render()

-- Expose counts
Demo.Info.Text = string.format("%d Part instances (%.1f%% improvement!)", Canvas._ActiveParts, ((ResX*ResY)-Canvas._ActiveParts)/(ResX*ResY)*100)
Ref.Info.Text = string.format("Frames Instances: %d", ResX*ResY)
```
