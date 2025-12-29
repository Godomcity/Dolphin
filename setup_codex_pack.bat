@echo off
setlocal

cd /d C:\Users\wodyd\Project\Dolphin

if not exist ".github" mkdir ".github"

echo Writing .gitignore...
> ".gitignore" (
  echo # Rojo port temp / backups
  echo places/*/_port/
  echo places/*/*.rbxl
  echo places/*/*.rbxlx
  echo.
  echo # OS / editor
  echo .DS_Store
  echo Thumbs.db
  echo .vscode/
  echo *.log
  echo.
  echo # Optional (uncomment if you use npm tooling)
  echo # node_modules/
  echo # package-lock.json
  echo # pnpm-lock.yaml
)

echo Writing AGENTS.md...
> "AGENTS.md" (
  echo # Codex Instructions (Dolphin / Rojo)
  echo.
  echo ## Project model
  echo - This repo is a Roblox game using Rojo.
  echo - Source of truth is the filesystem. Studio is for playtesting only.
  echo.
  echo ## Allowed edit locations
  echo - places/**/src/**
  echo - shared/**   ^(only if this folder exists and is used^)
  echo.
  echo ## Hard rules (MUST)
  echo 1^) Never touch Workspace/map/terrain.
  echo    - Do not add "Workspace" mounts to any *.project.json.
  echo    - Do not generate or edit files representing map data.
  echo.
  echo 2^) Preserve script types by filename suffix:
  echo    - *.server.lua  = Script
  echo    - *.client.lua  = LocalScript
  echo    - *.lua         = ModuleScript
  echo.
  echo 3^) Keep each place isolated:
  echo    - Place-specific code stays under places/^<Place^>/src/...
  echo    - Do not move code between places unless explicitly requested.
  echo.
  echo 4^) Keep diffs small and reviewable:
  echo    - Avoid sweeping refactors or mass reformatting.
  echo    - Change only what is necessary for the task.
  echo.
  echo ## Working style
  echo - Before editing: list the exact files you plan to change.
  echo - After editing: summarize
  echo   - Files changed
  echo   - Why
  echo   - How to test (Rojo serve + Studio playtest)
  echo   - Any risks / follow-ups
  echo.
  echo ## PR conventions
  echo - PR title: [PlaceName] short summary
  echo - PR description: include test steps and safety checklist results
)

echo Writing CODEX_PROMPT_TEMPLATE.md...
> "CODEX_PROMPT_TEMPLATE.md" (
  echo # Codex Web Prompt Template (copy/paste)
  echo.
  echo ## Rules
  echo - Modify ONLY: places/**/src/** ^(and shared/** only if it exists^)
  echo - Never touch Workspace/map/terrain.
  echo - Do NOT add Workspace mounts to any *.project.json.
  echo - Preserve script suffix types: *.server.lua / *.client.lua / *.lua
  echo - Keep changes minimal; avoid unrelated formatting.
  echo.
  echo ## Task
  echo - Goal:
  echo - Constraints:
  echo - Expected behavior:
  echo.
  echo ## Target files (must list paths)
  echo - places/StageX/src/ServerScriptService/...
  echo - places/StageX/src/ReplicatedStorage/...
  echo.
  echo ## How to test (local)
  echo 1^) git pull
  echo 2^) rojo serve places/^<Place^>/^<Place^>.project.json
  echo 3^) Connect in Studio then playtest
)

echo Writing .github/pull_request_template.md...
> ".github\pull_request_template.md" (
  echo ## What changed
  echo - 
  echo.
  echo ## Files touched
  echo - 
  echo.
  echo ## Safety checks (Rojo)
  echo - [ ] No Workspace mounts added to any *.project.json
  echo - [ ] Script suffixes preserved (*.server.lua / *.client.lua / *.lua)
  echo - [ ] Only edited under places/**/src/** (and shared/** if used)
  echo.
  echo ## How to test locally
  echo 1^) git pull
  echo 2^) rojo serve places/^<Place^>/^<Place^>.project.json
  echo 3^) Connect in Studio and playtest
)

echo.
echo Done. Created/updated:
echo - .gitignore
echo - AGENTS.md
echo - CODEX_PROMPT_TEMPLATE.md
echo - .github\pull_request_template.md
echo.
pause

endlocal
