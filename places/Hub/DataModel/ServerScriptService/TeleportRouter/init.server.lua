-- ServerScriptService/TeleportRouter.server.lua
--!strict
-- 클라이언트: Remotes.Teleport_Request:FireServer({ targetPlaceId=..., sessionId?=..., reason?, device? })
-- 서버: SessionRouter로 예약코드 확보 → TeleportAsync(ReservedServerAccessCode) 실행
-- 실패 시 TeleportToPrivateServer로 1회 폴백

local modules = script.Parent:WaitForChild("Modules")
local SessionRouter = require(modules:WaitForChild("SessionRouter"))
local TeleportRouterCore = require(modules:WaitForChild("TeleportRouterCore"))

local function buildTeleportData(_: Player, payload: any, sessionId: string)
        return {
                version = 2,
                session = {
                        id = sessionId,
                        fromPlaceId = game.PlaceId,
                        reason = (typeof(payload) == "table" and payload.reason) or "route",
                },
                player = {
                        device = (typeof(payload) == "table" and payload.device) or "pc",
                },
        }
end

TeleportRouterCore.start({
        sessionRouter = SessionRouter,
        buildTeleportData = buildTeleportData,
        onLog = function(context, details)
                print("[TeleportRouter]", context, details.placeId, details.reservedCode)
        end,
})

print("[TeleportRouter] READY (v2 TeleportData: session.id)")
