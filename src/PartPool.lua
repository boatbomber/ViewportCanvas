local module = {}

local OFF_SCREEN = CFrame.new(100_000, 100_000, 0)

function module.new(original: BasePart, worldModel: WorldRoot, parent: Instance, initSize: number?)
	initSize = math.ceil(initSize or 50)
	parent = parent or worldModel

	original.Archivable = true

	local Pool = {
		_Available = table.create(initSize),
		_Source = original:Clone(),
		_Index = initSize,
		_willCommit = false,
	}

	for i = 1, initSize do
		local p = Pool._Source:Clone()
		p.Parent = parent
		p.CFrame = OFF_SCREEN
		Pool._Available[i] = p
	end

	function Pool:Get()
		local object

		if self._Index > 0 then
			object = self._Available[self._Index]
			table.remove(self._Available, self._Index)
			self._Index -= 1
		else
			object = self._Source:Clone()
			object.Parent = parent
		end

		return object
	end

	function Pool:Return(object: GuiObject)
		table.insert(self._Available, object)
		self._Index += 1
		--object.CFrame = OFF_SCREEN

		if not self._willCommit then
			self._willCommit = true
			task.defer(self._CommitReturns, self)
		end
	end

	function Pool:_CommitReturns()
		self._willCommit = false

		if not self._Available or (#self._Available == 0) then
			return
		end

		local cf = table.create(#self._Available, OFF_SCREEN)
		worldModel:BulkMoveTo(self._Available, cf, Enum.BulkMoveMode.FireCFrameChanged)
	end

	function Pool:Destroy()
		self._Source:Destroy()
		for _, object in ipairs(self._Available) do
			object:Destroy()
		end
		table.clear(self._Available)
		table.clear(self)
	end

	return Pool
end

return module
