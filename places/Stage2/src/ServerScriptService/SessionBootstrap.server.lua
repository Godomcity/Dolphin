--!strict
-- 플레이어가 텔레포트로 들어왔을 때
-- TeleportData 안에 있는 sessionId/session.id 를 Player.Attribute("sessionId") 로 복원
-- + Stage1에서는 SessionResume에 "지금 Stage1에 있다" 라는 정보도 저장
-- + 디버그용으로 JobId / TeleportData 로그

local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local SessionResume = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("SessionResume"))
local Roles = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Roles"))

local playerPassThrough = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PlayerPassThrough"))
playerPassThrough.Enable()

local STAGE_NUMBER = 2

local function extractSessionIdFromTeleportData(td: any): string?
        if typeof(td) ~= "table" then
                return nil
        end

        -- ① 옛날 구조: TeleportData.sessionId
        if typeof(td.sessionId) == "string" and #td.sessionId > 0 then
                return td.sessionId
        end

        -- ② 지금 구조: TeleportData.session.id
        local sess = (td :: any).session
        if typeof(sess) == "table" and typeof(sess.id) == "string" and #sess.id > 0 then
                return sess.id
        end

        return nil
end

local function extractUserRoleFromTeleportData(td: any): string?
        if typeof(td) ~= "table" then
                return nil
        end

        local p = (td :: any).player
        if typeof(p) == "table" and typeof(p.userRole) == "string" and #p.userRole > 0 then
                return p.userRole
        end

        if typeof(td.userRole) == "string" and #td.userRole > 0 then
                return td.userRole
        end

        local session = (td :: any).session
        if typeof(session) == "table" then
                local sp = (session :: any).player
                if typeof(sp) == "table" and typeof(sp.userRole) == "string" and #sp.userRole > 0 then
                        return sp.userRole
                end
        end

        return nil
end

local function extractRoomCodeFromTeleportData(td: any): string?
        if typeof(td) ~= "table" then
                return nil
        end

        local session = (td :: any).session
        if typeof(session) == "table" and typeof(session.roomCode) == "string" and #session.roomCode > 0 then
                return session.roomCode
        end

        if typeof(td.roomCode) == "string" and #td.roomCode > 0 then
                return td.roomCode
        end

        return nil
end

local function getTeleportData(plr: Player): any
        local ok, joinData = pcall(function()
                return plr:GetJoinData()
        end)
        if not ok or typeof(joinData) ~= "table" then
                return nil
        end

        local td = joinData.TeleportData
        if typeof(td) ~= "table" then
                return nil
        end

        return td
end

local function debugPrintJoinData(plr: Player)
        local ok, joinData = pcall(function()
                return plr:GetJoinData()
        end)
        if not ok or typeof(joinData) ~= "table" then
                print("[Stage1 SessionBootstrap]", plr.Name, "GetJoinData failed or not table")
                return
        end

        local td = joinData.TeleportData
        if typeof(td) ~= "table" then
                print("[Stage1 SessionBootstrap]", plr.Name, "TeleportData missing")
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
                "[Stage1 SessionBootstrap] JobId=%s PlaceId=%d Player=%s TD.sessionId=%s privateCode=%s fromPlaceId=%s reason=%s",
                game.JobId,
                game.PlaceId,
                plr.Name,
                tostring(sid or (td :: any).sessionId),
                tostring(priv),
                tostring(fromPlaceId),
                tostring(reason)
                ))
end

Players.PlayerAdded:Connect(function(plr: Player)
        print(string.format(
                "[Stage1 SessionBootstrap] PlayerAdded JobId=%s PlaceId=%d Player=%s",
                game.JobId, game.PlaceId, plr.Name
                ))

        local td = getTeleportData(plr)
        local sid = plr:GetAttribute("sessionId")
        local userRole: string? = nil
        local roomCode: string? = nil

        if not sid or sid == "" then
                sid = extractSessionIdFromTeleportData(td)
                if sid and sid ~= "" then
                        plr:SetAttribute("sessionId", sid)
                end
        end

        userRole = extractUserRoleFromTeleportData(td)
        roomCode = extractRoomCodeFromTeleportData(td)

        local finalSid = plr:GetAttribute("sessionId")
        print(("[Stage1 SessionBootstrap] %s sessionId = %s"):format(plr.Name, tostring(finalSid)))

        -- 디버그용: JoinData 전체 로그
        debugPrintJoinData(plr)

        if userRole and #userRole > 0 then
                plr:SetAttribute("userRole", userRole)
                plr:SetAttribute("isTeacher", Roles.isTeacherRole(userRole))
        end

        if roomCode and #roomCode > 0 then
                plr:SetAttribute("roomCode", roomCode)
        end

        print(
                "[Stage1 SessionBootstrap]",
                plr.Name,
                "sessionId =", plr:GetAttribute("sessionId"),
                "userRole =", plr:GetAttribute("userRole"),
                "isTeacher =", plr:GetAttribute("isTeacher"),
                "roomCode =", plr:GetAttribute("roomCode")
        )

        -- 2) Stage1 재접속용 Resume 정보 저장
        if finalSid and finalSid ~= "" then
                print(("[Stage1 SessionBootstrap] Save Resume: userId=%d sid=%s stage=%d placeId=%d"):format(
                        plr.UserId, finalSid, STAGE_NUMBER, game.PlaceId
                        ))
                SessionResume.Save(plr, finalSid, STAGE_NUMBER, game.PlaceId)
        end
end)

print("[Stage1 SessionBootstrap] READY (with SessionResume + debug)")
