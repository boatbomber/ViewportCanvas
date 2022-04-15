local module = {}

local Chunk = require(script.Chunk)

local CHUNKS = 15

function module.new(ResX: number, ResY: number)
	local Canvas = {
		_Chunks = {},
		_ChangedChunks = {},
		_Active = 0,
		_Pool = nil,
		_Grid = nil,

		Gui = nil,
		Threshold = 15, -- Rerender if you change this!
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

	Canvas.Gui = Gui

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = ResX / ResY
	AspectRatio.Parent = Gui

	local chunkSizeX, chunkSizeY = math.ceil(ResX/CHUNKS), math.ceil(ResY/CHUNKS)

	for chunk = 0, (CHUNKS^2)-1 do
		table.insert(Canvas._Chunks, Chunk.new({
			Id = chunk,
			Threshold = Canvas.Threshold,
			Res = Vector2.new(ResX, ResY),
			Pos = Vector2.new(
				chunk % CHUNKS,
				math.floor(chunk / CHUNKS)
			),
			Size = Vector2.new(chunkSizeX, chunkSizeY),
			Grid = Grid,
			Gui = Gui,
		}))
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

			local chunkX, chunkY = math.floor((x-1)/chunkSizeX), math.floor((y-1)/chunkSizeY)
			local chunk = chunkX + (chunkY*CHUNKS)

			self._ChangedChunks[chunk + 1] = true
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
		for _, chunk in ipairs(self._Chunks) do
			chunk:Clear()
		end
	end

	local lastThreshold = Canvas.Threshold
	function Canvas:Render()
		if lastThreshold ~= Canvas.Threshold then
			lastThreshold = Canvas.Threshold
			for _, chunk in ipairs(self._Chunks) do
				chunk.Threshold = lastThreshold
			end
		end
		for index in pairs(self._ChangedChunks) do
			--print("Computing chunk", index-1)
			self._Active += self._Chunks[index]:Compute()
		end
	end

	return Canvas
end

return module
