local PartPool = require(script.Parent.PartPool)
local Util = require(script.Parent.Util)

local module = {}

function module.new(props)
	local Chunk = {
		Grid = props.Grid,
		Threshold = props.Threshold or 15,
		X = props.Pos.X,
		Y = props.Pos.Y,
		Width = props.Size.X,
		Height = props.Size.Y,
		Parts = table.create(100),

		_Active = 0,
	}

	local fillHeight, fillWidth = Chunk.Height/10, Chunk.Width/10
	local xStep, yStep = Chunk.Width/props.Res.X, Chunk.Height/props.Res.Y

	local chunkStartX, chunkStartY = Chunk.X*Chunk.Width + 1, Chunk.Y*Chunk.Height + 1
	local chunkEndX, chunkEndY = math.min(props.Res.X, (Chunk.X+1)*Chunk.Width), math.min(props.Res.Y, (Chunk.Y+1)*Chunk.Height)


	local Container = Instance.new("ViewportFrame")
	Container.Name = "Chunk" .. props.Id
	Container.Size = UDim2.fromScale(xStep, yStep)
	Container.Position = UDim2.fromScale(xStep * Chunk.X, yStep * Chunk.Y)
	Container.Ambient = Color3.new(1, 1, 1)
	Container.LightColor = Color3.new(0, 0, 0)
	Container.BorderMode = Enum.BorderMode.Inset
	Container.BorderSizePixel = 0
	Container.BackgroundTransparency = 1
	Container.BackgroundColor3 = Color3.new(0, 0, 0)
	Container.Parent = props.Gui

	Chunk.Container = Container

	local World = Instance.new("WorldModel")
	World.Parent = Container

	local Folder = Instance.new("Folder")
	Folder.Name = "Pixels"
	Folder.Parent = World

	local Camera = Instance.new("Camera")
	Camera.FieldOfView = 1
	Camera.Parent = Container
	Container.CurrentCamera = Camera

	Camera.CFrame = CFrame.new( -- Position camera to fit canvas
		0,
		0,
		fillHeight / (math.tan(math.rad(Camera.FieldOfView/2)) * 2) - (0.005)
	)

	-- Create a pool of BaseParts
	do
		local Pixel = Instance.new("Part")
		Pixel.Color = Color3.new(1, 1, 0.02)
		Pixel.Size = Vector3.new(0.1, 0.1, 0.1)
		Pixel.Material = Enum.Material.SmoothPlastic
		Pixel.Anchored = true
		Pixel.CanCollide = false
		Pixel.CanTouch = false
		Pixel.Name = "Pixel"

		Chunk._Pool = PartPool.new(Pixel, World, Folder, 5)
		Pixel:Destroy()
	end

	function Chunk:Clear()
		for i, part in ipairs(self.Parts) do
			self._Pool:Return(part)
		end
	end

	local parts, cfs = table.create(100), table.create(100)
	function Chunk:Compute()
		local lastActive = self._Active

		table.clear(parts)
		table.clear(cfs)

		local isVisited = table.create(self.Width)
		for x = chunkStartX, chunkEndX do
			isVisited[x] = table.create(self.Height, false)
		end

		local pixelCount = 0

		for x = chunkStartX, chunkEndX do
			if not self.Grid[x] then break end

			for y = chunkStartY, chunkEndY do
				local color = self.Grid[x][y]
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
				for checkX = x + 1, chunkEndX do
					if isVisited[checkX][y] then
						break
					end

					local newColor = self.Grid[checkX][y]
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
				if self.Grid[x][y + 1] then
					for checkY = y + 1, chunkEndY do
						local rowMatches = true

						for checkX = x, x + width do
							if isVisited[checkX][checkY] then
								rowMatches = false
								break
							end

							local newColor = self.Grid[checkX][checkY]
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

				local pixel = self.Parts[pixelCount] or self._Pool:Get()
				--pixel.Name = string.format("(%d, %d)-(%d, %d)", x, y, x + width, y + height)
				pixel.Color = color
				pixel.Size = Vector3.new(width/10, height/10, 0.01)

				parts[pixelCount] = pixel
				cfs[pixelCount] = CFrame.new(
					(fillWidth/-2) + ((x-chunkStartX)/10) + (pixel.Size.X/2),
					(fillHeight/2) - ((y-chunkStartY)/10) - (pixel.Size.Y/2),
					0
				)

				self.Parts[pixelCount] = pixel
			end
		end

		for i = pixelCount + 1, #self.Parts do
			self._Pool:Return(self.Parts[i])
			self.Parts[i] = nil
		end

		World:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

		self._Active = pixelCount
		return pixelCount - lastActive
	end

	return Chunk
end

return module
