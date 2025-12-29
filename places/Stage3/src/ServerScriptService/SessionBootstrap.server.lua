-- ServerScriptService/SessionBootstrap.server.lua
--!strict
-- 플레이어가 텔레포트로 들어왔을 때
-- TeleportData 안에 있는 sessionId/session.id 를 Player.Attribute("sessionId") 로 복원
-- + Stage3에서는 SessionResume에 "지금 Stage3에 있다" 라는 정보도 저장
-- + 디버그용으로 JobId / TeleportData 로그

local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

local SessionResume = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("SessionResume"))
local Roles = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Roles"))

local playerPassThrough = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PlayerPassThrough"))
playerPassThrough.Enable()

local STAGE_NUMBER = 3

local function extractSessionId(td: any): string?
    if typeof(td) ~= "table" then
        return nil
    end

    -- ✅ 권장 스키마: TeleportData.session.id
    local session = td.session
    if typeof(session) == "table" and typeof(session.id) == "string" and #session.id > 0 then
        return session.id
    end

    -- 🔙 (혹시) TeleportData.sessionId 로 내려온 경우 대비
    if typeof(td.sessionId) == "string" and #td.sessionId > 0 then
        return td.sessionId
    end

    return nil
end

local function extractUserRole(td: any): string?
    if typeof(td) ~= "table" then
        return nil
    end

    local session = td.session
    if typeof(session) == "table" and typeof(session.role) == "string" and #session.role > 0 then
        return session.role
    end

    return nil
end

local function extractRoomCode(td: any): string?
    if typeof(td) ~= "table" then
        return nil
    end

    -- ✅ 권장 스키마: TeleportData.session.roomCode
    local session = td.session
    if typeof(session) == "table" and typeof(session.roomCode) == "string" and #session.roomCode > 0 then
        return session.roomCode
    end

    -- 🔙 (혹시) TeleportData.roomCode 로 내려온 경우 대비
    if typeof(td.roomCode) == "string" and #td.roomCode > 0 then
        return td.roomCode
    end

    return nil
end

local function debugPrintJoinData(plr: Player)
    local ok, joinData = pcall(function()
        return plr:GetJoinData()
    end)
    if not ok or typeof(joinData) ~= "table" then
        print("[Stage3 SessionBootstrap]", plr.Name, "GetJoinData failed or not table")
        return
    end

    local td = joinData.TeleportData
    if typeof(td) ~= "table" then
        print("[Stage3 SessionBootstrap]", plr.Name, "TeleportData missing")
        return
    end

    local sess = (td :: any).session
    local sid  = nil
    local priv = nil
    local reason = (td :: any).reason
    local fromPlaceId = (td :: any).fromPlaceId

    if typeof(sess) == "table" then
        sid  = (sess :: any).id
        priv = (sess :: any).privateServerCode
    end

    print(string.format(
        "[Stage3 SessionBootstrap] JobId=%s PlaceId=%d Player=%s TD.sessionId=%s privateCode=%s fromPlaceId=%s reason=%s",
        game.JobId,
        game.PlaceId,
        plr.Name,
        tostring(sid or (td :: any).sessionId),
        tostring(priv),
        tostring(fromPlaceId),
        tostring(reason)
        ))
end

local function applyTeleportAttributes(plr: Player)
    local sid: string? = plr:GetAttribute("sessionId")
    local userRole: string? = plr:GetAttribute("userRole")
    local roomCode: string? = plr:GetAttribute("roomCode")

    local ok, joinData = pcall(function()
        return plr:GetJoinData()
    end)

    if ok and typeof(joinData) == "table" then
        local td = joinData.TeleportData
        sid = sid or extractSessionId(td)
        userRole = userRole or extractUserRole(td)
        roomCode = roomCode or extractRoomCode(td)
    end

    -- 스튜디오에서 직접 플레이 눌렀을 때: 디버그용 가짜 세션 부여
    if RunService:IsStudio() and (not sid or #sid == 0) then
        sid = string.format("local-%d-%d", plr.UserId, os.time())
    end

    if sid and #sid > 0 then
        plr:SetAttribute("sessionId", sid)
    end

    if userRole and #userRole > 0 then
        plr:SetAttribute("userRole", userRole)
        plr:SetAttribute("isTeacher", Roles.isTeacherRole(userRole))
    end

    if roomCode and #roomCode > 0 then
        plr:SetAttribute("roomCode", roomCode)
    end
end

Players.PlayerAdded:Connect(function(plr: Player)
    print(string.format(
        "[Stage3 SessionBootstrap] PlayerAdded JobId=%s PlaceId=%d Player=%s",
        game.JobId, game.PlaceId, plr.Name
        ))

    applyTeleportAttributes(plr)

    local finalSid = plr:GetAttribute("sessionId")
    print(
        "[Stage3 SessionBootstrap]",
        plr.Name,
        "sessionId =", plr:GetAttribute("sessionId"),
        "userRole =", plr:GetAttribute("userRole"),
        "isTeacher =", plr:GetAttribute("isTeacher"),
        "roomCode =", plr:GetAttribute("roomCode")
    )

    -- 디버그용: JoinData 전체 로그
    debugPrintJoinData(plr)

    -- 2) Stage3 재접속용 Resume 정보 저장
    if finalSid and finalSid ~= "" then
        print(("[Stage3 SessionBootstrap] Save Resume: userId=%d sid=%s stage=%d placeId=%d"):format(
            plr.UserId, finalSid, STAGE_NUMBER, game.PlaceId
            ))
        SessionResume.Save(plr, finalSid, STAGE_NUMBER, game.PlaceId)
    end
end)

print("[Stage3 SessionBootstrap] READY (with SessionResume + debug)")
