-- The built-in image previewer, but centred in the preview pane with the
-- image's dimensions underneath. yazi draws images at the pane's top-left, so
-- draw once to learn the fitted size, then again offset by half the leftover
-- space (the image and its caption are centred as one block).
local M = {}

-- A blank row, then the caption
local CAPTION_ROWS = 2

function M:peek(job)
	local start, url = os.clock(), ya.file_cache(job)
	if not url or not fs.cha(url) then
		url = Url(job.file.path)
	end
	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))

	local area = job.area
	local room = area { h = math.max(1, area.h - CAPTION_ROWS) }
	local drawn, err = ya.image_show(url, room)
	if not drawn then
		return ya.preview_widget(job, err)
	end

	local x = area.x + (area.w - drawn.w) // 2
	local y = area.y + (area.h - drawn.h - CAPTION_ROWS) // 2
	if x ~= drawn.x or y ~= drawn.y then
		drawn, err = ya.image_show(url, ui.Rect { x = x, y = y, w = drawn.w, h = drawn.h })
		if not drawn then
			return ya.preview_widget(job, err)
		end
	end

	-- The cached preview is downscaled, so read the size from the original
	local info = ya.image_info(Url(job.file.path))
	if not info then
		return ya.preview_widget(job, {})
	end
	local caption = area { y = drawn.y + drawn.h + CAPTION_ROWS - 1, h = 1 }
	ya.preview_widget(job, {
		ui.Text(string.format("%d × %d", info.w, info.h)):area(caption):align(ui.Align.CENTER):fg("gray"),
	})
end

function M:seek() end

function M:preload(job) return require("image"):preload(job) end

return M
