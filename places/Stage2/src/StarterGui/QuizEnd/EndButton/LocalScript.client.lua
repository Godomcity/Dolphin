-- LocalScript @ StarterGui/QuizEnd/EndButton
--!strict
-- 선생님만 보임
-- 클릭하면 서버에 Quiz_EndRequest만 보냄
-- (정리+엔딩 컷씬+Hub 텔레포트는 서버 오케스트레이터가 처리)

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player     = Players.LocalPlayer
local endButton  = script.Parent
local quizEndGui = endButton:FindFirstAncestorOfClass("ScreenGui")

local StageRolePolicy = require(RS:WaitForChild("Modules"):WaitForChild("StageRolePolicy"))

local Remotes     = RS:WaitForChild("Remotes")
local RE_QuizEnd  = Remotes:WaitForChild("Quiz_EndRequest") :: RemoteEvent

local isClicked = false
local setupDone = false

local function setButtonVisible(isVisible: boolean)
        if endButton:IsA("GuiObject") then
                endButton.Visible = isVisible
        end
end

local function onEndClicked()
        if isClicked then return end
        isClicked = true

        -- 버튼 GUI 닫기(선생님 화면)
        if quizEndGui then
                quizEndGui.Enabled = false
        end

        -- ✅ 서버가:
        -- 1) 모든 참가자 QuizGui/대사UI 정리
        -- 2) 4문제/10문제 컷씬 취소
        -- 3) 엔딩 컷씬 재생
        -- 4) 컷씬 끝나면 Hub 텔레포트(세션 전체)
        RE_QuizEnd:FireServer({
                sessionId = player:GetAttribute("sessionId"),
        })
end

local function trySetupForTeacher()
        local isTeacher = StageRolePolicy.IsTeacher(player)
        setButtonVisible(isTeacher)
        if not isTeacher or setupDone then
                return
        end

        setupDone = true

        if endButton:IsA("GuiButton") then
                endButton.Activated:Connect(onEndClicked)
        else
                endButton.MouseButton1Click:Connect(onEndClicked)
        end
end

local function onRoleChanged()
        trySetupForTeacher()
end

player:GetAttributeChangedSignal("userRole"):Connect(onRoleChanged)
player:GetAttributeChangedSignal("isTeacher"):Connect(onRoleChanged)
player:GetAttributeChangedSignal("Role"):Connect(onRoleChanged)

trySetupForTeacher()
