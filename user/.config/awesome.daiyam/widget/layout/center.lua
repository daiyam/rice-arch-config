local base  = require("wibox.widget.base")
local dumper = require("dumper")
local gtable = require("gears.table")

local center = {}

function center:layout(context, width, height)
	local result = {}
	local pos = 0
	local spacing = self._private.spacing
	local margin_widget = self._private.margin_widget
	local spacing_widget = self._private.spacing_widget
	local is_y = self._private.dir == "y"
	local is_x = not is_y
	local abspace = math.abs(spacing)
	local spoffset = spacing < 0 and 0 or spacing

	local coords = {}
	local x, y, w, h, _
	for k, v in pairs(self._private.widgets) do
		if is_y then
			_, h = base.fit_widget(self, context, v, width, height - pos);
			table.insert(coords, { 0, pos, width, h })
			
			pos = pos + h + spacing
		else
			w, _ = base.fit_widget(self, context, v, width - pos, height);
			table.insert(coords, { pos, 0, w, height })
			
			pos = pos + w + spacing
		end

		if (is_y and pos-spacing > height) or
			(is_x and pos-spacing > width) then
			break
		end
	end
	
	local dx, dy = 0, 0
	if is_y then
		dy = math.floor((height - pos) / 2)
	else
		dx = math.floor((width - pos) / 2)
	end
	
	if margin_widget ~= nil then
		table.insert(result, base.place_widget_at(margin_widget, 0, 0, is_x and dx or width, is_y and dy or height))
	end
	
	for k, v in pairs(self._private.widgets) do
		x, y, w, h = unpack(coords[k])
		
		x = x + dx
		y = y + dy
		
		if k > 1 and abspace > 0 and spacing_widget then
			table.insert(result, base.place_widget_at(
				spacing_widget,
				is_x and (x - spoffset) or x,
				is_y and (y - spoffset) or y,
				is_x and abspace or w,
				is_y and abspace or h
			))
		end
		
		table.insert(result, base.place_widget_at(v, x, y, w, h))
	end
	
	if margin_widget ~= nil then
		table.insert(result, base.place_widget_at(margin_widget, is_x and x + w or 0, is_y and y + h or 0, is_x and dx or width, is_y and dy or height))
	end
	
	return result
end

function center:add(...)
	local args = { n=select('#', ...), ... }
	assert(args.n > 0, "need at least one widget to add")
	for i=1, args.n do
		base.check_widget(args[i])
		table.insert(self._private.widgets, args[i])
	end
	self:emit_signal("widget::layout_changed")
end


function center:remove(index)
	if not index or index < 1 or index > #self._private.widgets then return false end

	table.remove(self._private.widgets, index)

	self:emit_signal("widget::layout_changed")

	return true
end

function center:remove_widgets(...)
	local args = { ... }

	local recursive = type(args[#args]) == "boolean" and args[#args]

	local ret = true
	for k, rem_widget in ipairs(args) do
		if recursive and k == #args then break end

		local idx, l = self:index(rem_widget, recursive)

		if idx and l and l.remove then
			l:remove(idx, false)
		else
			ret = false
		end

	end

	return #args > (recursive and 1 or 0) and ret
end

function center:get_children()
	return self._private.widgets
end

function center:set_children(children)
	self:reset()
	if #children > 0 then
		self:add(unpack(children))
	end
end

function center:replace_widget(widget, widget2, recursive)
	local idx, l = self:index(widget, recursive)

	if idx and l then
		l:set(idx, widget2)
		return true
	end

	return false
end

function center:swap(index1, index2)
	if not index1 or not index2 or index1 > #self._private.widgets
		or index2 > #self._private.widgets then
		return false
	end

	local widget1, widget2 = self._private.widgets[index1], self._private.widgets[index2]

	self:set(index1, widget2)
	self:set(index2, widget1)

	self:emit_signal("widget::swapped", widget1, widget2, index2, index1)

	return true
end

function center:swap_widgets(widget1, widget2, recursive)
	base.check_widget(widget1)
	base.check_widget(widget2)

	local idx1, l1 = self:index(widget1, recursive)
	local idx2, l2 = self:index(widget2, recursive)

	if idx1 and l1 and idx2 and l2 and (l1.set or l1.set_widget) and (l2.set or l2.set_widget) then
		if l1.set then
			l1:set(idx1, widget2)
			if l1 == self then
				self:emit_signal("widget::swapped", widget1, widget2, idx2, idx1)
			end
		elseif l1.set_widget then
			l1:set_widget(widget2)
		end
		if l2.set then
			l2:set(idx2, widget1)
			if l2 == self then
				self:emit_signal("widget::swapped", widget1, widget2, idx2, idx1)
			end
		elseif l2.set_widget then
			l2:set_widget(widget1)
		end

		return true
	end

	return false
end

function center:set(index, widget2)
	if (not widget2) or (not self._private.widgets[index]) then return false end

	base.check_widget(widget2)

	local w = self._private.widgets[index]

	self._private.widgets[index] = widget2

	self:emit_signal("widget::layout_changed")
	self:emit_signal("widget::replaced", widget2, w, index)

	return true
end

function center:set_margin_widget(wdg)
	self._private.margin_widget = base.make_widget_from_value(wdg)
	self:emit_signal("widget::layout_changed")
end

function center:set_spacing_widget(wdg)
	self._private.spacing_widget = base.make_widget_from_value(wdg)
	self:emit_signal("widget::layout_changed")
end

function center:insert(index, widget)
	if not index or index < 1 or index > #self._private.widgets + 1 then return false end

	base.check_widget(widget)
	table.insert(self._private.widgets, index, widget)
	self:emit_signal("widget::layout_changed")
	self:emit_signal("widget::inserted", widget, #self._private.widgets)

	return true
end

function center:fit(context, orig_width, orig_height)
	local width, height = orig_width, orig_height
	local used_in_dir, used_max = 0, 0

	for _, v in pairs(self._private.widgets) do
		local w, h = base.fit_widget(self, context, v, width, height)
		local in_dir, max
		if self._private.dir == "y" then
			max, in_dir = w, h
			height = height - in_dir
		else
			in_dir, max = w, h
			width = width - in_dir
		end
		if max > used_max then
			used_max = max
		end
		used_in_dir = used_in_dir + in_dir

		if width <= 0 or height <= 0 then
			if self._private.dir == "y" then
				used_in_dir = orig_height
			else
				used_in_dir = orig_width
			end
			break
		end
	end

	local spacing = self._private.spacing * (#self._private.widgets-1)

	if self._private.dir == "y" then
		return used_max, used_in_dir + spacing
	end

	return used_in_dir + spacing, used_max
end

function center:reset()
	self._private.widgets = {}
	self:emit_signal("widget::layout_changed")
	self:emit_signal("widget::reseted")
end

local function get_layout(dir, widget1, ...)
	local ret = base.make_widget(nil, nil, {enable_properties = true})

	gtable.crush(ret, center, true)

	ret._private.dir = dir
	ret._private.widgets = {}
	ret:set_spacing(0)

	if widget1 then
		ret:add(widget1, ...)
	end

	return ret
end

function center.horizontal(...)
	return get_layout("x", ...)
end

function center.vertical(...)
	return get_layout("y", ...)
end


function center:set_spacing(spacing)
	if self._private.spacing ~= spacing then
		self._private.spacing = spacing
		self:emit_signal("widget::layout_changed")
	end
end

function center:get_spacing()
	return self._private.spacing or 0
end

return center
