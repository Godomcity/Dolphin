--!strict

local M = {}

local RS = game:GetService("ReplicatedStorage")

local Roles = require(RS:WaitForChild("Modules"):WaitForChild("Roles"))

local function hasTeacherAttribute(plr: Player): boolean
        if not plr or not plr.Parent then
                return false
        end

        local roleAttr = plr:GetAttribute("userRole") or plr:GetAttribute("Role")
        if Roles.isTeacherRole(roleAttr) then
                return true
        end

        return plr:GetAttribute("isTeacher") == true
end

function M.IsTeacher(plr: Player): boolean
        return hasTeacherAttribute(plr)
end

-- 이 플레이어가 "스테이지 클라이언트 흐름(퀴즈/컷씬/포탈)"을 스킵해야 하는지
function M.ShouldSkipStageClientFlow(plr: Player): boolean
	return M.IsTeacher(plr)
end

return M
