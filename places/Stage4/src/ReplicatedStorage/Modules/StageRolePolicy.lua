-- ReplicatedStorage/Modules/StageRolePolicy.lua
--!strict

local Roles = require(script.Parent:WaitForChild("Roles"))

local M = {}

local function isTeacher(plr: Player): boolean
        if not plr or not plr.Parent then
                return false
        end

        local roleAttr = plr:GetAttribute("userRole")
        if Roles.isTeacherRole(roleAttr) then
                return true
        end

        local isTeacherAttr = plr:GetAttribute("isTeacher")
        if typeof(isTeacherAttr) == "boolean" then
                return isTeacherAttr
        end

        return false
end

function M.IsTeacher(plr: Player): boolean
        return isTeacher(plr)
end

-- 이 플레이어가 "스테이지 클라이언트 흐름(퀴즈/컷씬/포탈)"을 스킵해야 하는지
function M.ShouldSkipStageClientFlow(plr: Player): boolean
        return isTeacher(plr)
end

return M
