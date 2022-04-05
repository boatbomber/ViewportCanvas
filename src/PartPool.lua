local module = {}

local OFF_SCREEN = Vector3.new(100_000, 100_000, 0)

function module.new(original: BasePart, initSize: number?)
	initSize = initSize or 50

	local Pool = {
		_Available = table.create(initSize),
		_Source = original:Clone(),
		_Index = initSize,
	}

	for i = 1, initSize do
		Pool._Available[i] = Pool._Source:Clone()
	end

	function Pool:Get()
		if self._Index > 0 then
			local object = self._Available[self._Index]
			table.remove(self._Available, self._Index)
			self._Index -= 1
			return object
		end

		return self._Source:Clone()
	end

	function Pool:Return(object: GuiObject)
		object.Position = OFF_SCREEN
		table.insert(self._Available, object)
		self._Index += 1
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
