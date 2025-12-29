-- ServerScriptService/Modules/TeleportRouterCore.lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local TeleportRouterCore = {}

export type TeleportRouterConfig = {
        sessionRouter: any,
        cooldownSeconds: number?,
        buildTeleportData: ((player: Player, payload: any, sessionId: string) -> {[string]: any}?)?,
        onLog: ((context: string, details: {[string]: any}) -> ())?,
}

local function dedupeChild(parent: Instance, child: Instance)
        for _, other in ipairs(parent:GetChildren()) do
                if other ~= child and other.Name == child.Name and other.ClassName == child.ClassName then
                        other:Destroy()
                end
        end
end

function TeleportRouterCore.ensureRemotes()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes or not remotes:IsA("Folder") then
                        remotes = Instance.new("Folder")
                        remotes.Name = "Remotes"
                        remotes.Parent = ReplicatedStorage
        end
        dedupeChild(ReplicatedStorage, remotes)

        local request = remotes:FindFirstChild("Teleport_Request")
        if not request or not request:IsA("RemoteEvent") then
                        request = Instance.new("RemoteEvent")
                        request.Name = "Teleport_Request"
                        request.Parent = remotes
        end
        dedupeChild(remotes, request)

        local result = remotes:FindFirstChild("Teleport_Result")
        if not result or not result:IsA("RemoteEvent") then
                        result = Instance.new("RemoteEvent")
                        result.Name = "Teleport_Result"
                        result.Parent = remotes
        end
        dedupeChild(remotes, result)

        return request, result
end

function TeleportRouterCore.createCooldown(seconds: number?)
        local duration = seconds or 2
        local lastTick: {[number]: number} = {}

        return function(plr: Player): boolean
                        local now = os.clock()
                        local prev = lastTick[plr.UserId] or 0
                        if (now - prev) < duration then
                                        return false
                        end
                        lastTick[plr.UserId] = now
                        return true
        end
end

function TeleportRouterCore.extractSessionId(plr: Player, payload: any): string?
        if typeof(payload) == "table" and typeof(payload.sessionId) == "string" and #payload.sessionId > 0 then
                        return payload.sessionId
        end

        local sidAttr = plr:GetAttribute("sessionId")
        if typeof(sidAttr) == "string" and #sidAttr > 0 then
                        return sidAttr
        end

        return nil
end

function TeleportRouterCore.buildDefaultTeleportData(payload: any, sessionId: string)
        local tpData: {[string]: any} = {
                        sessionId   = sessionId,
                        reason      = (typeof(payload) == "table" and typeof(payload.reason) == "string" and payload.reason) or "route",
                        device      = (typeof(payload) == "table" and typeof(payload.device) == "string" and payload.device) or "pc",
                        fromPlaceId = game.PlaceId,
        }

        if typeof(payload) == "table" and typeof(payload.meta) == "table" then
                        tpData.meta = payload.meta
        end

        return tpData
end

function TeleportRouterCore.teleportWithFallback(targetPlaceId: number, playersToTeleport: {Player}, reservedCode: string, teleportData: {[string]: any}?, onLog: ((context: string, details: {[string]: any}) -> ())?)
        local opts = Instance.new("TeleportOptions")
        opts.ReservedServerAccessCode = reservedCode
        if teleportData then
                        opts:SetTeleportData(teleportData)
        end

        local ok, err = pcall(function()
                        TeleportService:TeleportAsync(targetPlaceId, playersToTeleport, opts)
        end)
        if ok then
                        if onLog then
                                        onLog("teleport_async", { placeId = targetPlaceId, reservedCode = reservedCode })
                        end
                        return true
        end

        local okOld, errOld = pcall(function()
                        TeleportService:TeleportToPrivateServer(targetPlaceId, reservedCode, playersToTeleport, nil, teleportData)
        end)
        if not okOld then
                        return false, tostring(err) .. " / " .. tostring(errOld)
        end

        if onLog then
                        onLog("teleport_fallback", { placeId = targetPlaceId, reservedCode = reservedCode, error = tostring(err) })
        end
        return true
end

function TeleportRouterCore.start(config: TeleportRouterConfig)
        local sessionRouter = config.sessionRouter
        if not sessionRouter or typeof(sessionRouter.GetOrCreate) ~= "function" then
                        error("sessionRouter with GetOrCreate is required", 2)
        end

        local requestRemote, resultRemote = TeleportRouterCore.ensureRemotes()
        local canTeleport = TeleportRouterCore.createCooldown(config.cooldownSeconds)
        local buildTeleportData = config.buildTeleportData or function(plr: Player, payload: any, sessionId: string)
                        return TeleportRouterCore.buildDefaultTeleportData(payload, sessionId)
        end

        local function fireError(plr: Player, code: string, msg: string)
                        resultRemote:FireClient(plr, {
                                        ok = false,
                                        code = code,
                                        msg = msg,
                        })
        end

        requestRemote.OnServerEvent:Connect(function(plr: Player, payload: any)
                        if not plr or not plr.Parent then
                                        return
                        end

                        if not canTeleport(plr) then
                                        return
                        end

                        if typeof(payload) ~= "table" then
                                        fireError(plr, "bad_payload", "invalid payload")
                                        return
                        end

                        local targetPlaceId = tonumber(payload.targetPlaceId)
                        if not targetPlaceId then
                                        fireError(plr, "missing_target", "targetPlaceId is required.")
                                        return
                        end

                        local sessionId = TeleportRouterCore.extractSessionId(plr, payload)
                        if not sessionId then
                                        fireError(plr, "missing_sessionId", "세션 코드가 없습니다. 로비에서 입장코드를 입력하세요.")
                                        return
                        end

                        local okCode, reservedCode, err = sessionRouter.GetOrCreate(sessionId, targetPlaceId)
                        if not okCode or not reservedCode then
                                        fireError(plr, "reserve_failed", tostring(err))
                                        return
                        end

                        local teleportData = buildTeleportData(plr, payload, sessionId)
                        local okTeleport, teleportErr = TeleportRouterCore.teleportWithFallback(targetPlaceId, { plr }, reservedCode, teleportData, config.onLog)
                        if not okTeleport and teleportErr then
                                        fireError(plr, "teleport_failed", teleportErr)
                        end
        end)

        return requestRemote, resultRemote
end

return TeleportRouterCore
