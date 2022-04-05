local module = {}

local PartPool = require(script.PartPool)
local Util = require(script.Util)

function module.new(ResX: number, ResY: number)
	local Canvas = {
		_Pixels = {},
		_Pool = nil,
		_ActiveParts = 0,

		-- Rerender if you change these!
		Threshold = 15,
		MaxWidth = math.ceil(ResX / 30),
		MaxHeight = math.ceil(ResY / 30),
	}

	-- Generate initial grid of color data
	local Grid = table.create(ResX)
	for x = 1, ResX do
		Grid[x] = table.create(ResY, nil)
	end
	Canvas._Grid = Grid

	-- Create GUIs
	local Gui = Instance.new("Frame")
	Gui.Name = "VPFCanvas"
	Gui.BackgroundTransparency = 1
	Gui.ClipsDescendants = true
	Gui.Size = UDim2.fromScale(1, 1)
	Gui.Position = UDim2.fromScale(0.5, 0.5)
	Gui.AnchorPoint = Vector2.new(0.5, 0.5)

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = ResX / ResY
	AspectRatio.Parent = Gui

	local Container = Instance.new("ViewportFrame")
	Container.Name = "Container"
	Container.Size = UDim2.fromScale(1, 1)
	Container.Ambient = Color3.new(1, 1, 1)
	Container.LightColor = Color3.new(0, 0, 0)
	Container.BackgroundTransparency = 1
	Container.BackgroundColor3 = Color3.new(0, 0, 0)
	Container.Parent = Gui

	local World = Instance.new("WorldModel")
	World.Parent = Container

	local Folder = Instance.new("Folder")
	Folder.Name = "Pixels"
	Folder.Parent = World

	local Camera = Instance.new("Camera")
	Camera.FieldOfView = 20
	Camera.Parent = Container
	Container.CurrentCamera = Camera

	-- Position camera to fit canvas
	do
		local h = (ResY / (math.tan(math.rad(Camera.FieldOfView / 2)) * 2)) + (1 / 2)

		Camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, h), Vector3.zero)
	end

	-- Create a pool of Frame instances with Gradients
	do
		local Pixel = Instance.new("Part")
		Pixel.Color = Color3.new(1, 1, 1)
		Pixel.Size = Vector3.new(1, 1, 1)
		Pixel.Anchored = true
		Pixel.CanCollide = false
		Pixel.Name = "Pixel"

		Canvas._Pool = PartPool.new(Pixel, World, Folder, math.min(ResX * ResX * 0.1, 1000))
		Pixel:Destroy()
	end

	-- Define API

	function Canvas:Destroy()
		self:Clear()
		Gui:Destroy()
		Canvas._Pool:Destroy()
		table.clear(Canvas._Grid)
		table.clear(Canvas)
	end

	function Canvas:SetParent(parent: Instance)
		Gui.Parent = parent
	end

	function Canvas:SetPixel(x: number, y: number, color: Color3)
		local Col = self._Grid[x]

		if Col[y] ~= color then
			Col[y] = color
		end
	end

	function Canvas:GetPixel(x: number, y: number)
		local Col = self._Grid[x]
		if not Col then
			return
		end

		return Col[y]
	end

	function Canvas:Clear()
		for _, pixel in ipairs(Canvas._Pixels) do
			Canvas._Pool:Return(pixel)
		end
	end

	local parts, cfs = table.create(ResX * ResY), table.create(ResX * ResY)
	function Canvas:Render()
		table.clear(parts)
		table.clear(cfs)

		local isVisited = table.create(ResX)
		for x = 1, ResX do
			isVisited[x] = table.create(ResY, false)
		end

		local pixelCount = 0

		for x = 1, ResX do
			for y = 1, ResY do
				local color = self._Grid[x][y]
				if not color then
					continue
				end

				if isVisited[x][y] then
					continue
				end
				isVisited[x][y] = true

				-- Build greedy chunk
				local width, height = 0, 0

				-- Find our width
				for checkX = x + 1, math.min(ResX, x + self.MaxWidth) do
					if isVisited[checkX][y] then
						break
					end

					local newColor = self._Grid[checkX][y]
					if not newColor then
						break
					end
					if Util.DeltaRGB(color, newColor) > self.Threshold then
						break
					end

					isVisited[checkX][y] = true
					width += 1
				end

				-- Find our height
				if self._Grid[x][y + 1] then
					for checkY = y + 1, math.min(ResY, y + self.MaxHeight) do
						local rowMatches = true

						for checkX = x, x + width do
							if isVisited[checkX][checkY] then
								rowMatches = false
								break
							end

							local newColor = self._Grid[checkX][checkY]
							if not newColor then
								rowMatches = false
								break
							end
							if Util.DeltaRGB(color, newColor) > self.Threshold then
								rowMatches = false
								break
							end
						end

						if not rowMatches then
							break
						end
						for checkX = x, x + width do
							isVisited[checkX][checkY] = true
						end
						height += 1
					end
				end

				height += 1
				width += 1

				pixelCount += 1

				local pixel = self._Pixels[pixelCount] or self._Pool:Get()
				pixel.Name = string.format("(%d, %d)-(%d, %d)", x, y, x + width, y + height)
				pixel.Color = color
				pixel.Size = Vector3.new(width, height, 1)
				--pixel.Position = Vector3.new(-ResX/2 + x + width/2, ResY/2 - y - height/2, 0)

				parts[pixelCount] = pixel
				cfs[pixelCount] = CFrame.new(-ResX / 2 + x + width / 2, ResY / 2 - y - height / 2, 0)

				self._Pixels[pixelCount] = pixel
			end
		end

		task.spawn(World.BulkMoveTo, World, parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

		for i = pixelCount + 1, #self._Pixels do
			self._Pool:Return(self._Pixels[i])
			self._Pixels[i] = nil
		end

		self._ActiveParts = pixelCount

		--print(string.format("Rendered %d pixels in %.1f ms", pixelCount, (os.clock()-startClock)*1000))
	end

	return Canvas
end

return module
