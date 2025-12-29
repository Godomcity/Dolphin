-- ServerScriptService/RoleConfig.lua
-- 임시 교사 화이트리스트: 여기에 UserId 추가하면 해당 유저는 교사로 강제 설정됨
local RoleConfig = {}

RoleConfig.TEACHER_IDS = {
        -- [1234567890] = true, -- 필요시 추가 (userRole이 전달되지 않을 때 대비)
}

return RoleConfig
