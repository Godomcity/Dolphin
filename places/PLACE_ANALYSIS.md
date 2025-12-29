# Place-by-place code analysis

This document summarizes the core server-side flows for each Roblox place in the Dolphin project.

## Lobby
- Teleport entry point that receives `Teleport_Request` from clients, enforces a 2-second per-player cooldown, and forwards players to target places via reserved server codes from `SessionRouter`.
- Includes attribute-based session ID recovery when clients don't pass an explicit ID and falls back to legacy `TeleportToPrivateServer` if `TeleportAsync` fails.
- Errors are returned to the requesting client through `Teleport_Result` with descriptive codes.

## Hub
- Centralized teacher-controlled staging area: the teacher opens a stage via `Hub_OpenStage`, which checks permissions, records the cohort size (students only) with `QuizStartCountStore`, and triggers `QuizRun.StartCohort` for all players.
- Portal state is synchronized to clients and a start sound plays when Stage1 opens.

## Stage1
- `SessionBootstrap` restores the `sessionId` attribute from teleport data (supporting old and new schemas) when players join, logs teleport context for debugging, and persists resume info for reconnects.

## Stage2
- Teleport router mirrors Lobby behavior but allows extra `meta` payload to ride along with teleport data. Retrieves/creates reserved server codes through `SessionRouter` before teleporting and reports errors back via `Teleport_Result`.

## Stage3
- `Stage3ProgressService` prepares RemoteFunctions/Events for quest, cutscene, object clean-up, and quiz tracking keyed by `sessionId:userId`.
- On progress requests it loads stage state from `SessionProgress`, logs diagnostic counts, and returns quest/quiz flags to the client. Quest, cutscene, object clean, and quiz events update server-side progress stores.

## Stage4
- `Stage4ProgressService` mirrors Stage3’s remote preparation and progress synchronization, including quest, cutscene, cleaned object, quiz solved, and quiz runtime channels keyed to session-aware IDs.

## Stage5
- `GameBootstrap` reads teleport data to set player attributes (session, device, selected stage) then enforces role overrides with a whitelist-backed teacher ID map.
- `Stage5ProgressService` reuses the shared progress pattern, exposing remotes for quests, cutscenes, cleaned objects, quiz correctness, and quiz runtime updates, persisting them via `SessionProgress` under the Stage5 index.
