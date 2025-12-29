-- ServerScriptService/TeleportRouter.server.lua
--!strict
-- 클라이언트: Remotes.Teleport_Request:FireServer({ targetPlaceId=..., sessionId?=..., reason?, device? })
-- 서버: SessionRouter로 예약코드 확보 → TeleportAsync(ReservedServerAccessCode) 실행
-- 실패 시 TeleportToPrivateServer로 1회 폴백

local modules = script.Parent:WaitForChild("Modules")
local SessionRouter = require(modules:WaitForChild("SessionRouter"))
local TeleportRouterCore = require(modules:WaitForChild("TeleportRouterCore"))

local function buildTeleportData(_: Player, payload: any, sessionId: string)
        local tpData = TeleportRouterCore.buildDefaultTeleportData(payload, sessionId)
        tpData.meta = tpData.meta or {}
        tpData.meta.stage = "Stage5"
        return tpData
end

TeleportRouterCore.start({
        sessionRouter = SessionRouter,
        buildTeleportData = buildTeleportData,
})

print("[TeleportRouter] READY")
