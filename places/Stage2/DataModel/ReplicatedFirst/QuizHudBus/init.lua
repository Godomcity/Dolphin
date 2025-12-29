-- ReplicatedStorage/Modules/Quiz/QuizHudBus.lua
--!strict
-- QuizClient 에서 Hud.Show / Hud.Progress / Hud.Correct / Hud.Wrong 호출하면
-- HUDGui (Frame/BackGround/BarBackGround/Bar, ProgressText) 를 업데이트한다.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

type UIRefs = {
	gui: ScreenGui,
	frame: Frame,
	bg: Frame,
	barBG: Frame,
	bar: Frame,
	txt: TextLabel,
}

local M = {}

local ui: UIRefs? = nil
local totalQuestions = 0
local curSolved = 0
local flashBusy = false

local TWEEN_FILL = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FLASH = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- ========= UI 찾기 =========
local function findUI(): UIRefs?
	local pg = LP:FindFirstChild("PlayerGui")
	if not pg then
		pg = LP:WaitForChild("PlayerGui")
	end

	-- PlayerGui 안에 HUDGui 가 복제될 때까지 최대 5초 기다림
	local gui = pg:FindFirstChild("HUDGui")
	if not gui then
		gui = pg:WaitForChild("HUDGui", 5)
	end
	if not (gui and gui:IsA("ScreenGui")) then
		return nil
	end

	local frame = gui:FindFirstChild("Frame") or gui:WaitForChild("Frame")
	if not frame or not frame:IsA("Frame") then return nil end

	local bg = frame:FindFirstChild("BackGround") or frame:WaitForChild("BackGround")
	if not bg or not bg:IsA("Frame") then return nil end

	local barBG = bg:FindFirstChild("BarBackGround") or bg:WaitForChild("BarBackGround")
	if not barBG or not barBG:IsA("Frame") then return nil end

	local bar = barBG:FindFirstChild("Bar") or barBG:WaitForChild("Bar")
	if not bar or not bar:IsA("Frame") then return nil end

	local txt = frame:FindFirstChild("ProgressText") or frame:WaitForChild("ProgressText")
	if not txt or not txt:IsA("TextLabel") then return nil end

	return {
		gui   = gui,
		frame = frame,
		bg    = bg,
		barBG = barBG,
		bar   = bar,
		txt   = txt,
	}
end

local function ensureUI(): UIRefs?
	if ui then return ui end
	ui = findUI()
	if not ui then
		warn("[QuizHudBus] HUDGui를 찾을 수 없습니다. StarterGui에 HUDGui를 넣어주세요.")
	end
	return ui
end

-- ========= 표시 유틸 =========
local function setBarRatio(ratio: number)
	local u = ensureUI(); if not u then return end
	ratio = math.clamp(ratio, 0, 1)
	TweenService:Create(u.bar, TWEEN_FILL, {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
end

local function setText(n: number, total: number)
	local u = ensureUI(); if not u then return end
	u.txt.Text = string.format("%d / %d", math.clamp(n, 0, total), total)
end

local function flashBar(color: Color3)
	if flashBusy then return end
	local u = ensureUI(); if not u then return end
	flashBusy = true

	local orig = u.bar.BackgroundColor3
	local t1 = TweenService:Create(u.bar, TWEEN_FLASH, { BackgroundColor3 = color })
	local t2 = TweenService:Create(u.bar, TWEEN_FLASH, { BackgroundColor3 = orig })

	t1:Play()
	t1.Completed:Connect(function()
		t2:Play()
		t2.Completed:Connect(function()
			flashBusy = false
		end)
	end)
end

-- ========= 외부에서 쓰는 함수 =========

-- total 개수로 HUD 초기화 + 표시
function M.Show(total: number)
	local u = ensureUI(); if not u then return end

	totalQuestions = math.max(total or 0, 0)
	curSolved = math.min(curSolved, totalQuestions)

	u.gui.Enabled = true
	u.frame.Visible = true

	u.bar.Size = UDim2.fromScale(0, 1)
	setText(0, totalQuestions)
end

-- 단순 진행도 업데이트
-- QuizClient 에서: Hud.Progress(STATE.Solved.Value, TOTAL_QUESTIONS)
function M.Progress(n: number, total: number)
	local u = ensureUI(); if not u then return end

	totalQuestions = math.max(total or totalQuestions, 0)
	curSolved = math.clamp(n or curSolved, 0, totalQuestions)

	setText(curSolved, totalQuestions)
	if totalQuestions > 0 then
		setBarRatio(curSolved / totalQuestions)
	else
		setBarRatio(0)
	end
end

-- 정답: Progress + 초록 플래시
function M.Correct(n: number, total: number)
	M.Progress(n, total)
	flashBar(Color3.fromRGB(110, 200, 140))
end

-- 오답: 빨간 플래시만
function M.Wrong()
	flashBar(Color3.fromRGB(240, 120, 120))
end

return M
