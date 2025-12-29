-- ServerScriptService/GameBootstrap.lua
-- 텔레포트 데이터로 속성 세팅 + 화이트리스트 기반 Role 강제 오버라이드

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleConfig = require(script.Parent:WaitForChild("RoleConfig"))
local Roles = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Roles"))

local function normalizeRole(roleValue: any): string
    if Roles.isTeacherRole(roleValue) then
        return Roles.TEACHER
    end
    if typeof(roleValue) == "string" and roleValue:lower() == "teacher" then
        return Roles.TEACHER
    end
    return tostring(roleValue or "")
end

local function applyFromTeleportData(player: Player, td: table)
    if not td then
        return
    end
    local function setAttr(k, v)
        player:SetAttribute(k, v)
    end

    if td.session then
        local roleValue = normalizeRole((td.session :: any).role)
        local sessionId = tostring(td.session.id or "")
        local roomCode = tostring((td.session :: any).roomCode or "")

        setAttr("sessionId", sessionId)
        setAttr("userRole", roleValue)
        setAttr("isTeacher", Roles.isTeacherRole(roleValue))
        setAttr("roomCode", roomCode)

        setAttr("SessionId", sessionId) -- 🔙 호환용
        setAttr("InviteCode", tostring(td.session.invite or ""))
        setAttr("Role", roleValue)
        setAttr("PartyId", tostring(td.session.partyId or ""))
    end
    if td.player then
        setAttr("Device", tostring(td.player.device or "")) -- "mobile"|"desktop"
    end
    setAttr("SelectedStage", tonumber(td.selectedStage or 1))
end

local function enforceRoleOverride(player: Player)
    -- ⚠️ API 없을 때는 여기서 최종 결정을 강제
    local roleValue = player:GetAttribute("userRole") or player:GetAttribute("Role")
    if Roles.isTeacherRole(roleValue) then
        player:SetAttribute("userRole", Roles.TEACHER)
        player:SetAttribute("isTeacher", true)
        return
    end

    if RoleConfig.TEACHER_IDS[player.UserId] then
        player:SetAttribute("userRole", Roles.TEACHER)
        player:SetAttribute("isTeacher", true)
    else
        -- 화이트리스트가 아니면 전부 학생으로 고정
        player:SetAttribute("userRole", tostring(roleValue or "student"))
        player:SetAttribute("isTeacher", false)
    end
end

Players.PlayerAdded:Connect(function(plr)
    local td
    pcall(function()
        td = TeleportService:GetPlayerTeleportData(plr)
    end)

    -- 텔레포트 데이터 반영(있으면)
    if td then
        applyFromTeleportData(plr, td)
    else
        -- 기본값
        plr:SetAttribute("SelectedStage", 1)
    end

    -- ✅ 최종 Role 강제 오버라이드 (화이트리스트 기반)
    enforceRoleOverride(plr)
end)
