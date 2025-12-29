-- ServerScriptService/SessionBootstrap.server.lua
--!strict
-- 플레이어가 텔레포트로 들어왔을 때 TeleportData.sessionId를 Player.Attribute("sessionId")로 복원

local Players = game:GetService("Players")

local function getTeleportData(plr: Player): (any, string?)
local ok, joinData = pcall(function()
return plr:GetJoinData()
end)

if not ok or typeof(joinData) ~= "table" then
return nil, "GetJoinData failed or not table"
end

local td = joinData.TeleportData
if typeof(td) ~= "table" then
return nil, "TeleportData missing"
end

return td, nil
end

local function extractSessionId(td: any): string?
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

local function extractUserRole(td: any): string?
if typeof(td) ~= "table" then
return nil
end

-- ✅ 권장 스키마: TeleportData.player.userRole
local p = td.player
if typeof(p) == "table" and typeof(p.userRole) == "string" and #p.userRole > 0 then
return p.userRole
end

-- 🔙 (혹시) TeleportData.userRole 로 내려온 경우 대비
if typeof(td.userRole) == "string" and #td.userRole > 0 then
return td.userRole
end

-- 🔙 (예전에 session.player.userRole로 넣었을 수도 있어서) 호환
local session = td.session
if typeof(session) == "table" then
local sp = session.player
if typeof(sp) == "table" and typeof(sp.userRole) == "string" and #sp.userRole > 0 then
return sp.userRole
end
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

local function isTeacherRole(role: string?): boolean
return role == "ROLE_TEACHER"
end

local function debugPrintJoinData(plr: Player, td: any, err: string?)
if err then
print("[SessionBootstrap]", plr.Name, err)
return
end

if typeof(td) ~= "table" then
print("[SessionBootstrap]", plr.Name, "TeleportData missing")
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
"[SessionBootstrap] JobId=%s PlaceId=%d Player=%s TD.sessionId=%s privateCode=%s fromPlaceId=%s reason=%s",
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
local td, tdErr = getTeleportData(plr)

local sid = plr:GetAttribute("sessionId")
if (not sid or sid == "") and td then
sid = extractSessionId(td)
if sid and sid ~= "" then
plr:SetAttribute("sessionId", sid)
end
end

local userRole = extractUserRole(td)
if userRole and #userRole > 0 then
plr:SetAttribute("userRole", userRole)
plr:SetAttribute("isTeacher", isTeacherRole(userRole))
end

local roomCode = extractRoomCode(td)
if roomCode and #roomCode > 0 then
plr:SetAttribute("roomCode", roomCode)
end

print(
"[SessionBootstrap]",
plr.Name,
"sessionId =", plr:GetAttribute("sessionId"),
"userRole =", plr:GetAttribute("userRole"),
"isTeacher =", plr:GetAttribute("isTeacher"),
"roomCode =", plr:GetAttribute("roomCode")
)

debugPrintJoinData(plr, td, tdErr)
end)

print("[SessionBootstrap] READY (reads TeleportData.session.id + userRole/roomCode)")
