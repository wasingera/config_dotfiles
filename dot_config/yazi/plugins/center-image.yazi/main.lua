-- The built-in image previewer, but centred in the preview pane: yazi draws
-- images at the pane's top-left, so draw once to learn the fitted size, then
-- again offset by half the leftover space.
local M = {}

function M:peek(job)
	local start, url = os.clock(), ya.file_cache(job)
	if not url or not fs.cha(url) then
		url = Url(job.file.path)
	end
	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))

	local area = job.area
	local drawn, err = ya.image_show(url, area)
	if drawn and (drawn.w < area.w or drawn.h < area.h) then
		drawn, err = ya.image_show(url, ui.Rect {
			x = area.x + (area.w - drawn.w) // 2,
			y = area.y + (area.h - drawn.h) // 2,
			w = drawn.w,
			h = drawn.h,
		})
	end
	ya.preview_widget(job, err)
end

function M:seek() end

function M:preload(job) return require("image"):preload(job) end

return M
