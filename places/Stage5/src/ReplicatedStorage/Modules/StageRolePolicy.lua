-- ReplicatedStorage/Modules/StageRolePolicy.lua
--!strict

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Roles = require(RS:WaitForChild("Modules"):WaitForChild("Roles"))

local M = {}

function M.IsTeacher(plr: Player): boolean
        if not plr or not plr.UserId then
                return false
        end

        if RunService:IsStudio() then
                return true
        end

        local role = plr:GetAttribute("userRole")
        if Roles.isTeacherRole(role) then
                return true
        end

        local legacyRole = plr:GetAttribute("Role")
        if typeof(legacyRole) == "string" and legacyRole:lower() == "teacher" then
                return true
        end

        local isTeacherAttr = plr:GetAttribute("isTeacher")
        if typeof(isTeacherAttr) == "boolean" then
                return isTeacherAttr
        end

        return false
end

-- 이 플레이어가 "스테이지 클라이언트 흐름(퀴즈/컷씬/포탈)"을 스킵해야 하는지
function M.ShouldSkipStageClientFlow(plr: Player): boolean
        return M.IsTeacher(plr)
end

return M
