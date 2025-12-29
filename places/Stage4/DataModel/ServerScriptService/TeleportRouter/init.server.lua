-- ServerScriptService/TeleportRouter.server.lua
--!strict
-- 클라이언트: TeleportUtil.Go(targetPlaceId, { sessionId?, device?, reason?, meta? })
-- 서버: SessionRouter로 ReservedServerAccessCode 확보 → TeleportAsync 실행
-- 실패 시 TeleportToPrivateServer 1회 폴백
-- 실패/에러는 Remotes.Teleport_Result 로 개별 플레이어에게 전송

local modules = script.Parent:WaitForChild("Modules")
local SessionRouter = require(modules:WaitForChild("SessionRouter"))
local TeleportRouterCore = require(modules:WaitForChild("TeleportRouterCore"))

local function buildTeleportData(_: Player, payload: any, sessionId: string)
        local tpData = TeleportRouterCore.buildDefaultTeleportData(payload, sessionId)
        tpData.meta = tpData.meta or {}
        tpData.meta.stage = "Stage4"
        return tpData
end

TeleportRouterCore.start({
        sessionRouter = SessionRouter,
        buildTeleportData = buildTeleportData,
})

print("[TeleportRouter] READY (TeleportUtil + SessionRouter 통합)")
