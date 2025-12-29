-- ReplicatedStorage/Modules/StageRolePolicy.lua
--!strict

local M = {}
local Roles = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Roles"))

-- 선생님 여부: userRole Attribute 기반
function M.IsTeacher(plr: Player): boolean
        if not plr then
                return false
        end

        local role = plr:GetAttribute("userRole")
        if Roles.isTeacherRole(role) then
                return true
        end

        local flag = plr:GetAttribute("isTeacher")
        return flag == true
end

-- 이 플레이어가 "스테이지 클라이언트 흐름(퀴즈/컷씬/포탈)"을 스킵해야 하는지
function M.ShouldSkipStageClientFlow(plr: Player): boolean
	return M.IsTeacher(plr)
end

return M
