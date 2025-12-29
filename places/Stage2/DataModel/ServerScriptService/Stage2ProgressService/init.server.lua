-- ServerScriptService/Stage2ProgressService.lua
--!strict
-- Stage2 진행도(퀴즈/퀘스트/컷씬/cleanedObjects) + 클라 동기화

local ServerScriptService = game:GetService("ServerScriptService")

local StageProgressServiceFactory = require(ServerScriptService.Modules:WaitForChild("StageProgressServiceFactory"))

local STAGE_INDEX = 2

StageProgressServiceFactory.init({
        stageIndex = STAGE_INDEX,
})
