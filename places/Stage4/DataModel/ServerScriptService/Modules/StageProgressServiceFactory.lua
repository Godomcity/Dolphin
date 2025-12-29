--!strict
-- Stage 진행도 RemoteFunction/Event 등록 공통 팩토리

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SessionProgress = require(ServerScriptService.Modules:WaitForChild("SessionProgress"))

export type RemoteNameOverrides = {
        getProgress: string?,
        questSync: string?,
        cutsceneFlag: string?,
        objectCleaned: string?,
        quizSolved: string?,
        quizRuntime: string?,
}

export type InitConfig = {
        stageIndex: number,
        remoteNames: RemoteNameOverrides?,
}

local stageStateAccessors = {
        [1] = SessionProgress.GetStage1State,
        [2] = SessionProgress.GetStage2State,
        [3] = SessionProgress.GetStage3State,
        [4] = SessionProgress.GetStage4State,
        [5] = SessionProgress.GetStage5State,
}

local M = {}

local function ensureRemotesFolder(): Folder
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
                remotes = Instance.new("Folder")
                remotes.Name = "Remotes"
                remotes.Parent = ReplicatedStorage
        end
        return remotes
end

local function ensureRemote(remotes: Folder, name: string, className: string)
        local existing = remotes:FindFirstChild(name)
        if existing and existing:IsA(className) then
                return existing
        end
        local inst = Instance.new(className)
        inst.Name = name
        inst.Parent = remotes
        return inst
end

local function buildRemoteNames(stageIndex: number, overrides: RemoteNameOverrides?): RemoteNameOverrides
        local prefix = string.format("Stage%d", stageIndex)
        local names: RemoteNameOverrides = overrides or {}

        names.getProgress = names.getProgress or string.format("RF_%s_GetProgress", prefix)
        names.questSync = names.questSync or string.format("RE_%s_QuestSync", prefix)
        names.cutsceneFlag = names.cutsceneFlag or string.format("RE_%s_CutsceneFlag", prefix)
        names.objectCleaned = names.objectCleaned or string.format("RE_%s_ObjectCleaned", prefix)
        names.quizSolved = names.quizSolved or string.format("RE_%s_QuizSolved", prefix)
        names.quizRuntime = names.quizRuntime or string.format("RE_%s_QuizRuntime", prefix)

        return names
end

local function newStageTemplate()
        return {
                quizSolved = {},
                cutscenes = {},
                questPhase = 0,
                extraTrash = 0,
                cleanedObjects = {},
                quizScore = 0,
                quizTimeSec = 0,
        }
end

function M.init(configOrStageIndex: InitConfig | number, remoteOverrides: RemoteNameOverrides?)
        local stageIndex: number
        local overrideNames: RemoteNameOverrides? = remoteOverrides

        if typeof(configOrStageIndex) == "table" then
                        stageIndex = configOrStageIndex.stageIndex
                        overrideNames = configOrStageIndex.remoteNames or remoteOverrides
        else
                        stageIndex = configOrStageIndex
        end

        assert(typeof(stageIndex) == "number", "StageProgressServiceFactory.init: stageIndex is required")

        local remoteNames = buildRemoteNames(stageIndex, overrideNames)
        local stageTag = string.format("Stage%d", stageIndex)
        local logPrefix = string.format("[%sProgressService]", stageTag)

        local remotes = ensureRemotesFolder()
        local rf_GetProgress = ensureRemote(remotes, remoteNames.getProgress :: string, "RemoteFunction")
        local re_QuestSync = ensureRemote(remotes, remoteNames.questSync :: string, "RemoteEvent")
        local re_CutsceneFlag = ensureRemote(remotes, remoteNames.cutsceneFlag :: string, "RemoteEvent")
        local re_ObjectCleaned = ensureRemote(remotes, remoteNames.objectCleaned :: string, "RemoteEvent")
        local re_QuizSolved = ensureRemote(remotes, remoteNames.quizSolved :: string, "RemoteEvent")
        local re_QuizRuntime = ensureRemote(remotes, remoteNames.quizRuntime :: string, "RemoteEvent")

        local function getKey(plr: Player): string?
                local sid = plr:GetAttribute("sessionId")
                if typeof(sid) ~= "string" or sid == "" then
                        warn(logPrefix, "no sessionId for", plr.Name)
                        return nil
                end
                return string.format("%s:u%d", sid, plr.UserId)
        end

        local function getStageState(plr: Player, key: string): any
                local accessor = stageStateAccessors[stageIndex]
                if accessor then
                        return accessor(plr)
                end
                return SessionProgress.GetStageProgress(key, stageIndex)
        end

        rf_GetProgress.OnServerInvoke = function(plr: Player)
                local key = getKey(plr)
                if not key then
                        return newStageTemplate()
                end

                local st = getStageState(plr, key)

                local cleanedCount = 0
                for _, flag in pairs(st.cleanedObjects or {}) do
                        if flag then cleanedCount += 1 end
                end

                print(("%s GetProgress stage=%d plr=%s key=%s phase=%d extra=%d cleaned=%d score=%d time=%d")
                        :format(logPrefix, stageIndex, plr.Name, key, st.questPhase or 0, st.extraTrash or 0, cleanedCount, st.quizScore or 0, st.quizTimeSec or 0))

                return st
        end

        re_QuestSync.OnServerEvent:Connect(function(plr: Player, phase: any, extra: any)
                local key = getKey(plr)
                if not key then return end

                local nPhase = tonumber(phase) or 0
                local nExtra = tonumber(extra) or 0

                print(("%s QuestSync stage=%d plr=%s phase=%d extra=%d")
                        :format(logPrefix, stageIndex, plr.Name, nPhase, nExtra))

                SessionProgress.SetQuestPhase(key, stageIndex, nPhase)
                SessionProgress.SetExtraTrash(key, stageIndex, nExtra)
        end)

        re_CutsceneFlag.OnServerEvent:Connect(function(plr: Player, flag: any)
                local key = getKey(plr)
                if not key then return end

                local flagStr = tostring(flag)

                print(("%s CutsceneFlag stage=%d plr=%s key=%s flag=%s")
                        :format(logPrefix, stageIndex, plr.Name, key, flagStr))

                SessionProgress.MarkCutscenePlayed(key, stageIndex, flagStr)
        end)

        re_ObjectCleaned.OnServerEvent:Connect(function(plr: Player, objectId: any)
                local key = getKey(plr)
                if not key then return end

                local idStr = tostring(objectId)
                if idStr == "" then return end

                print(("%s ObjectCleaned stage=%d plr=%s key=%s objectId=%s")
                        :format(logPrefix, stageIndex, plr.Name, key, idStr))

                SessionProgress.MarkObjectCleaned(key, stageIndex, idStr)
        end)

        re_QuizSolved.OnServerEvent:Connect(function(plr: Player, qid: any)
                local key = getKey(plr)
                if not key then return end

                local qidStr = tostring(qid)
                if qidStr == "" then return end

                print(("%s QuizSolved stage=%d plr=%s key=%s qid=%s")
                        :format(logPrefix, stageIndex, plr.Name, key, qidStr))

                SessionProgress.MarkQuizSolved(key, stageIndex, qidStr)
        end)

        re_QuizRuntime.OnServerEvent:Connect(function(plr: Player, scoreAny: any, timeAny: any)
                local key = getKey(plr)
                if not key then return end

                local score = tonumber(scoreAny) or 0
                local timeSec = tonumber(timeAny) or 0

                if score < 0 then score = 0 end
                if timeSec < 0 then timeSec = 0 end

                print(("%s QuizRuntime stage=%d plr=%s key=%s score=%d time=%ds")
                        :format(logPrefix, stageIndex, plr.Name, key, score, timeSec))

                SessionProgress.SetQuizRuntime(key, stageIndex, score, timeSec)
        end)

        print(string.format("%s READY (Stage%d progress + cleanedObjects + quizSolved + quizRuntime 기록)", logPrefix, stageIndex))

        return {
                stageIndex = stageIndex,
                remoteNames = remoteNames,
        }
end

return M
