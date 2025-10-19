-- ...existing code...
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create window and tabs (apply custom theme if the library accepts a table)
local Window = Rayfield:CreateWindow({
    Name = "DEPR!VEDDD | PLS DONATE 💰",
    Icon = 0,
    LoadingTitle = "UI is loading. Give it some time!",
    LoadingSubtitle = "by mattyyy💖",
    ShowText = "PLS DONATE 💰 ",
    Theme = customTheme, -- Rayfield may accept a theme table; if not, it will still work with default
    ToggleUIKeybind = "v",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FileName = "BIPVHUB_PlsDonate" },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local BegTab = Window:CreateTab("Begging", 6031075938)
local EvacTab = Window:CreateTab("Evacuation", 6031280894)
local EmoteTab = Window:CreateTab("Emote", 6031290001)
local WebhookTab = Window:CreateTab("Webhook", 6031292222)
-- BoothTab removed

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = (pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser")) or nil

-- Settings / state
local autoBeg = true
local autoEvac = true
local autoThank = false
local emoteId = "10714171628"
local serverHopDelay = 20 -- minutes
local boothSlot = nil
local autoHopOnBotDetection = true -- UI toggle: auto hop when bot appearance detected

-- VC join settings
-- VC join settings removed: no VC join behavior will be performed


-- ...existing code...
-- Settings / state
local autoBeg = true
local autoEvac = true
local autoThank = true
local emoteId = "10714171628"
    local serverHopDelay = 20 -- minutes
-- prevent automatic hops for a short startup grace period (in seconds)
local autoHopsEnabled = false
local startupGraceSeconds = 15
task.spawn(function()
    task.wait(startupGraceSeconds)
    autoHopsEnabled = true
end)
local boothSlot = nil

-- AR stare / booth-facing state
local currentBoothPart = nil -- the booth part we placed at (set when claim succeeds)
local defaultFacingCFrame = nil -- preferred CFrame to restore when not staring at players
    local arStareEnabled = true -- whether the bot should stare at nearby players (12 studs). Default disabled per request.

-- Default webhook (applied to UI and used on join)
local webhookUrl = "https://discord.com/api/webhooks/1360626788514009199/3XW3Cizo64ty6PI5tUm6BJX355MBOpfO0k2mT4snkk_CqW3CMkrXoH4RrGCtLiwbyT1X"


-- Thank you messages (7 entries)
local thankMessages = {
    "Thank you so much for the donation! 💖",
    "Huge thanks — I really appreciate it! 🙏",
    "Thanks a lot! You made my day! 😊",
    "Thanks for the support! Every bit helps! 💜",
    "Wow, thank you! Means a lot! ✨",
    "I appreciate the donation — thank you! 🙌",
    "You're amazing — thank you for donating! 💫"
}

-- Important booth slots
local importantBoothSlots = {
    24,16,18,36,37,29,35,34,26,28,
    11,17,25,23,22,13,32,20,30,12,
    33,15,14,31,21,19
}

-- Anti toggles (anti-lag forced on)
local antiAfkEnabled = true

-- Emote presets
local emotePresets = {
    ["24k goldn"]="10714171628",
}

-- Helpers
local function stopAllAnimations()
    local pl = Players.LocalPlayer
    if not pl or not pl.Character then return end
    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        pcall(function() t:Stop() end)
    end
end

local function playEmoteById(id)
    if not id then return end
    local pl = Players.LocalPlayer
    if not pl then return end
    local char = pl.Character or pl.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    stopAllAnimations()
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(id)
    local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
    if not ok or not track then return end
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = true
    pcall(function() track:Play() end)
end

-- Anti-AFK
pcall(function()
    local pl = Players.LocalPlayer
    if not pl then return end
    pl.Idled:Connect(function()
        if not antiAfkEnabled then return end
        pcall(function()
            local vu = VirtualUser or (pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser"))
            if not vu then return end
            vu:CaptureController()
            if typeof(vu.Button2Down) == "function" and typeof(vu.Button2Up) == "function" then
                vu:Button2Down(Vector2.new(0,0)); task.wait(0.06); vu:Button2Up(Vector2.new(0,0))
            elseif typeof(vu.ClickButton2) == "function" then
                vu:ClickButton2(Vector2.new(0,0))
            end
        end)
    end)
end)

-- Claim & teleport to booth
local function claimAndTeleportToBooth()
    local player = Players.LocalPlayer
    if not player then return end

    local guiRoot = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    if not guiRoot then return end

    local mapUI = guiRoot:FindFirstChild("MapUIContainer") or guiRoot:FindFirstChild("MapUI")
    if not mapUI then
        local ok, m = pcall(function() return guiRoot:WaitForChild("MapUIContainer", 3) end)
        mapUI = ok and m or mapUI
        if not mapUI then return end
    end

    local boothUI = (mapUI:FindFirstChild("MapUI") and mapUI.MapUI:FindFirstChild("BoothUI")) or mapUI:FindFirstChild("BoothUI")
    if not boothUI then
        local ok, b = pcall(function() return mapUI:WaitForChild("BoothUI", 3) end)
        boothUI = ok and b or boothUI
        if not boothUI then return end
    end

    local unclaimed = {}
    -- build unclaimed list (prioritize important slots)
    for _, v in ipairs(boothUI:GetChildren()) do
        if v:FindFirstChild("Details") and v.Details.Owner and tostring(v.Details.Owner.Text):lower() == "unclaimed" then
            local slot = tonumber(string.match(tostring(v.Name or v), "%d+"))
            if slot and table.find(importantBoothSlots, slot) then table.insert(unclaimed, slot) end
        end
    end

    if #unclaimed == 0 then
        for _, v in ipairs(boothUI:GetChildren()) do
            if v:FindFirstChild("Details") and v.Details.Owner and tostring(v.Details.Owner.Text):lower() == "unclaimed" then
                local slot = tonumber(string.match(tostring(v.Name or v), "%d+"))
                if slot then table.insert(unclaimed, slot) end
            end
        end
    end

    if #unclaimed == 0 then return end

    boothSlot = unclaimed[1]
    local claimedSuccessfully = false
    local boothPart = nil

    -- helper: attempt to locate boothPart in Workspace (returns part or nil)
    local function findBoothPart(slot)
        if not slot then return nil end
        local ok, parts = pcall(function() return Workspace:FindFirstChild("BoothInteractions") and Workspace.BoothInteractions:GetChildren() or {} end)
        if ok and parts then
            for _, p in ipairs(parts) do
                local okAttr, val = pcall(function() return p:GetAttribute("BoothSlot") end)
                if okAttr and val == slot then return p end
            end
        end
        return nil
    end

    local function tryInvokeClaim(slot)
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
            if remotes and remotes:FindFirstChild("ClaimBooth") then
                pcall(function() remotes.ClaimBooth:InvokeServer(slot) end)
            else
                if remotes and type(require) == "function" then
                    pcall(function()
                        local ok, module = pcall(function() return require(remotes) end)
                        if ok and module and typeof(module.Event) == "function" then
                            pcall(function() module.Event("ClaimBooth"):InvokeServer(slot) end)
                        end
                    end)
                end
            end
        end)
    end

    -- Attempt claim with retries; also consider boothPart appearing in Workspace as success
    for attempt = 1, 3 do
        tryInvokeClaim(boothSlot)
        -- wait and poll for either UI update or boothPart creation
        local startT = tick()
        while tick() - startT < 6 do
            -- check booth UI owner text
            pcall(function()
                for _, v in ipairs(boothUI:GetChildren()) do
                    local slot = tonumber(string.match(tostring(v.Name or v), "%d+"))
                    if slot == boothSlot and v:FindFirstChild("Details") and v.Details.Owner then
                        if tostring(v.Details.Owner.Text or ""):lower() ~= "unclaimed" then
                            claimedSuccessfully = true
                        end
                        break
                    end
                end
            end)
            -- check Workspace for booth part
            local foundPart = findBoothPart(boothSlot)
            if foundPart then
                boothPart = foundPart
                claimedSuccessfully = true
            end
            if claimedSuccessfully then break end
            task.wait(0.25)
        end
        if claimedSuccessfully then break end
        task.wait(0.15 + math.random() * 0.12)
    end

    -- If claim still not successful, schedule a persistent hop (non-blocking) and notify, then return
    if not claimedSuccessfully then
        pcall(function()
            Rayfield:Notify({ Title = "Booth Claim", Content = ("Failed to claim booth #%s after attempts. Will hop if necessary." ):format(tostring(boothSlot)), Duration = 6 })
        end)
        task.spawn(function()
            task.wait(0.8)
            pcall(function() if autoHopsEnabled then StartSzzePersistentHop(21, 23) end end)
        end)
        return
    end

    -- ensure we have the boothPart; if not yet found try a final quick lookup with WaitForChild
    if not boothPart then
        local ok, children = pcall(function() return Workspace:WaitForChild("BoothInteractions", 3) and Workspace.BoothInteractions:GetChildren() or {} end)
        if ok and children then
            for _, v in ipairs(children) do
                local okAttr, val = pcall(function() return v:GetAttribute("BoothSlot") end)
                if okAttr and val == boothSlot then boothPart = v; break end
            end
        end
    end

    if not boothPart then
        pcall(function()
            Rayfield:Notify({ Title = "Booth Claim", Content = "Attempted to claim booth #" .. tostring(boothSlot) .. " (could not locate booth part).", Duration = 6 })
        end)
        return
    end

    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local boothLook = boothPart.CFrame.LookVector
    -- Attempt to move player to a point in front of the booth (not on top) and face away from the booth.
    local forward = -boothLook
    local upOffset = Vector3.new(0, 1, 0)
    local forwardDistance = 4 -- studs in front of the booth
    local targetPos = boothPart.Position + forward * forwardDistance + upOffset
    local lookPoint = targetPos + forward
    local targetCFrame = CFrame.new(targetPos, lookPoint)

        -- Teleport directly to the target position (instant placement)
        do
            isNavigatingToBooth = true
            pcall(function() if hrp then hrp.CFrame = targetCFrame end end)
            isNavigatingToBooth = false
        end

        -- quick check: if placed inside/too close to the booth, flip to the other side and teleport immediately
        task.wait(0.08)
        local placedPos = (hrp and hrp.Position) or (char and (char.PrimaryPart and char.PrimaryPart.Position) )
        if placedPos then
            local dist = (placedPos - boothPart.Position).Magnitude
            if dist < 1.8 then
                forward = -forward
                targetPos = boothPart.Position + forward * forwardDistance + upOffset
                lookPoint = targetPos + forward
                targetCFrame = CFrame.new(targetPos, lookPoint)
                pcall(function() if hrp then hrp.CFrame = targetCFrame end end)
            end
        end

    -- store booth-facing preferences
    currentBoothPart = boothPart
    defaultFacingCFrame = targetCFrame

    local keys = {}
    for _, id in pairs(emotePresets) do table.insert(keys, id) end
    if #keys > 0 then
        math.randomseed(tick() + tonumber(tostring(os.time()):sub(-6)))
        local chosenId = keys[math.random(1, #keys)]
        playEmoteById(chosenId)
    end

    if not claimedSuccessfully then
        task.wait(0.5)
        pcall(function()
            for _, v in ipairs(boothUI:GetChildren()) do
                local slot = tonumber(string.match(tostring(v.Name or v), "%d+"))
                if slot == boothSlot and v:FindFirstChild("Details") and v.Details.Owner then
                    if tostring(v.Details.Owner.Text):lower() ~= "unclaimed" then claimedSuccessfully = true end
                    break
                end
            end
        end)
    end

    if claimedSuccessfully then
        pcall(function()
            Rayfield:Notify({ Title = "nice, you claimed a booth b4 someone else did, LMAO", Content = "You successfully claimed booth #" .. tostring(boothSlot), Duration = 6 })
        end)
    else
        pcall(function()
            Rayfield:Notify({ Title = "Booth Claim Attempted", Content = "Tried to claim booth #" .. tostring(boothSlot) .. ". If you were not claimed, try again.", Duration = 6 })
        end)
    end

    pcall(function()
        MainTab:CreateParagraph({ Title = "Booth Info", Content = "Your booth slot # is " .. (boothSlot or "N/A") .. "." })
    end)
end

    -- auto-apply booth text removed per user request

-- forward-declare Szze persistent hop to avoid nil calls before implementation is defined
local StartSzzePersistentHop = StartSzzePersistentHop or function(minPlayers, maxPlayers) end

    -- Bot-detection: scan booth texts for flagged phrases and server-hop if too many found
    -- Expanded with more common bot words
    local flaggedTexts = { 'spin', 'jump', 'helicopter', '+1 speed', 'gifting donations', 'goal', '5x', 'multiply', 'multiply your', 'help', 'pls', 'raising', }
    -- require more than 10 flagged booths before non-critical action (user requested >10)
    local flaggedThreshold = 11
    local criticalThreshold = 12 -- immediate hop if number of suspicious booths is above this (>11)
    -- reduce notification spam: only notify when threshold exceeded or when count changes and cooldown has elapsed
    local lastScanCount = 0
    local lastNotifyTime = 0
    local notifyCooldown = 30 -- seconds between non-threshold notifications
    local pendingConfirmation = false
    local confirmationTimeout = 10 -- seconds to wait between scans for confirmation
    local function isTextFlagged(txt)
        if not txt or txt == '' then return false end
        local norm = tostring(txt):lower()
        for _, ft in ipairs(flaggedTexts) do
            -- match word boundaries where possible by stripping non-alphanum from pattern
            local pattern = ft:gsub('%W','')
            if pattern ~= '' and string.find(norm, '%f[%a]'..pattern..'%f[%A]') then return true end
            -- fallback to simple substring
            if string.find(norm, ft, 1, true) then return true end
        end
        return false
    end

    local function checkForBots()
        local guiRoot = Players.LocalPlayer and (Players.LocalPlayer:FindFirstChild('PlayerGui') or Players.LocalPlayer:WaitForChild('PlayerGui',3))
        if not guiRoot then return false end
        local mapUI = guiRoot:FindFirstChild('MapUIContainer') or guiRoot:FindFirstChild('MapUI')
        if not mapUI then return false end
        local boothUI = (mapUI:FindFirstChild('MapUI') and mapUI.MapUI:FindFirstChild('BoothUI')) or mapUI:FindFirstChild('BoothUI')
        if not boothUI then return false end

        local uniqueFlagged = {}
        local flaggedOwners = {}

        for _, ui in ipairs(boothUI:GetDescendants()) do
            local nameLower = tostring(ui.Name or ''):lower()
            if ui:IsA('TextLabel') and (nameLower:find('sign') or nameLower:find('text') or nameLower:find('label')) then
                local txt = tostring(ui.Text or '')
                if isTextFlagged(txt) then
                    local norm = tostring(txt):gsub('%s+',' '):gsub('%p+',''):lower()
                    if not uniqueFlagged[norm] then
                        uniqueFlagged[norm] = true
                        -- try to find owner for this sign's ancestor booth (if available)
                        local ownerName = nil
                        local boothParent = ui
                        for i = 1, 6 do
                            if boothParent.Parent then boothParent = boothParent.Parent end
                        end
                        if boothParent and boothParent:FindFirstChild('Details') and boothParent.Details:FindFirstChild('Owner') then
                            ownerName = tostring(boothParent.Details.Owner.Text or '')
                        end
                        table.insert(flaggedOwners, { text = norm, owner = ownerName })
                    end
                end
            end
        end

        local count = 0
        local suspiciousOwners = {}
        for _, v in ipairs(flaggedOwners) do
            local owner = v.owner
            local ownerSuspicious = false
            if not owner or owner:lower() == 'unclaimed' or owner == '' then
                -- no owner, treat sign itself as suspicious
                ownerSuspicious = true
            else
                        -- check if owner is present in Players (match username or display name, case-insensitive)
                local pl = nil
                local ownerTrim = tostring(owner or ''):match('^%s*(.-)%s*$') or ''
                local ownerLower = ownerTrim:lower()
                for _, cand in ipairs(Players:GetPlayers()) do
                    local n = tostring(cand.Name or ''):lower()
                    local d = tostring(cand.DisplayName or ''):lower()
                    if n == ownerLower or d == ownerLower then pl = cand; break end
                end
                if not pl then
                    -- owner not in-server: suspicious but lower weight
                    ownerSuspicious = true
                else
                    -- check recent chat spam for owner
                    local chats = recentChats[pl.UserId] or {}
                    if #chats >= chatSpamThreshold then ownerSuspicious = true end
                    -- optional: check account age if available via Player.AccountAge (approx days played)
                    local ok, accAge = pcall(function() return pl.AccountAge end)
                    if ok and type(accAge) == 'number' then
                        -- new accounts (less than 3 days) are more suspicious
                        if accAge < 3 then ownerSuspicious = true end
                    end
                end
            end
            if ownerSuspicious then
                count = count + 1
                suspiciousOwners[v.owner or 'unknown'] = true
            end
        end

        -- immediate silent hop on critical threshold; otherwise selective notifications and two-step confirmation before hopping
        if count > criticalThreshold then
            -- critical: hop immediately without spamming notifications
            -- send a single webhook alert describing the critical detection (sample owners list)
            pcall(function()
                local owners = {}
                for o, _ in pairs(suspiciousOwners) do table.insert(owners, tostring(o)) end
                local ownersStr = (#owners > 0) and table.concat(owners, ", ") or "N/A"
                pcall(function() sendWebhookNotification(("Critical bot detection: %d suspicious booths — owners/sample: %s. PlaceId=%s JobId=%s"):format(count, ownersStr, tostring(game.PlaceId), tostring(game.JobId))) end)
            end)
                pcall(function() if autoHopsEnabled then StartSzzePersistentHop(21, 23, true) end end)
            lastScanCount = count
            return count
        end
        local now = tick()
        local shouldNotify = false
        local notifyType = nil
        if count >= flaggedThreshold then
            -- high severity -> require confirmation unless already pending
            if not pendingConfirmation then
                pendingConfirmation = true
                pcall(function()
                    Rayfield:Notify({ Title = "Bot Detection", Content = ("High flagged booth texts: %d — re-scanning to confirm before hopping."):format(count), Duration = 6 })
                end)
                lastNotifyTime = now
                -- schedule confirmation re-scan
                task.spawn(function()
                    task.wait(confirmationTimeout)
                    pcall(function()
                        local ok, still = pcall(checkForBots)
                        -- if the re-scan still finds at-or-above the flagged threshold, perform a forced Szze persistent hop
                        if ok and type(still) == 'number' and still >= flaggedThreshold then
                            pcall(function() if autoHopsEnabled then StartSzzePersistentHop(21, 23, true) end end)
                        end
                        pendingConfirmation = false
                    end)
                end)
            end
            lastScanCount = count
            return count
        elseif count > 0 and count ~= lastScanCount and (now - lastNotifyTime) >= notifyCooldown then
            shouldNotify = true
            notifyType = 'change'
        end

        if shouldNotify then
            pcall(function()
                Rayfield:Notify({ Title = "Bot Scan", Content = ("Flagged unique suspicious signs: %d"):format(count), Duration = 4 })
            end)
            lastNotifyTime = now
        end

        lastScanCount = count
        return false
    end

    -- periodic bot-scan
    -- run an initial scan immediately and then periodically (always enabled)
    pcall(checkForBots)
    task.spawn(function()
        while true do
            task.wait(10)
            pcall(checkForBots)
        end
    end)

    -- population-based server hop removed per user request

    -- Appearance/item-based detector removed per user request.
    -- Bot detection is handled via booth-text scanning (checkForBots) which is Szze-style and still active above.

-- Anti-sit
local function antiSitLoop()
    while true do
        local char = Players.LocalPlayer and Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then hum.Sit = false; hum.Jump = true end
        end
        task.wait(0.05)
    end
end
task.spawn(antiSitLoop)

-- Begging messages
local begMessages = {
    "YOULL NEVER SEE ME AGAIN AFTER I LEAVE, DONT MISS OUT ON THIS OPPORTUNITY",
    "DONT TRUST ME? PURCHASE A GAMEPASS AND YOULL SEE.",
    "ROBUX INVESTMENT OF THE YEAR, 5X YOUR RETURN GUARANTEED",
    "I MULTIPLY UR DONATION BY 5, ITS AS SIMPLE AS THAT VRO 🙂‍↔️",
    "IM LEAVING SOON, COME DONATE AND I WILL DONO BACK",
    "YOULL PROLY NEVER COME ACROSS ME AGAIN. MULTIPLY YOUR DONOS BY 5 RNN",
    "ITS A ONE TIME THING, COME GRAB THE DEAL AND ENJOY THE PROFITS",
    "USER, MYMELODY56219 PURCHASED MY GAMEPASS OF 50R$ AND RECEIVED 250 BACK",
    "ILIKEGATOS912 ACTUALLY GOT THE ROBUX BACK 5X RETURN, LOOK HER UPP",
    "DON'T BELIEVE ME? TRY IT AND YOULL IMMEDIATELY SEE THE RESUTLS",
    "I PROMISE YOU WONT REGRET IT, 5X YOUR DONATION BACK",
    "YO IM LIVE ON STREAM RIGHT NOW MULTIPLYING DONATIONS BY 5, COME JOIN",
    "I PROMISE YOU WONT REGRET IT, 5X YOUR DONATION BACK",
    "I HAVE AN INSANE AMOUNT OF FUNDS ATM, DONATE BEFORE ITS ALL GONE",
    "DON'T LEAVE ME HANGING HERE, U CAN LITERALLY GET 250R$ BY GIVING ME 50R$",
}
local function sendMessage()
    if not autoBeg then return end
    if TextChatService and TextChatService.TextChannels then
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then channel:SendAsync(begMessages[math.random(1, #begMessages)]) end
    end
end
task.spawn(function()
    task.wait(20)
    while true do
        if autoBeg then sendMessage() end
                wait(_G.BegDelay or 20)
    end
end)

-- Auto thank on donation (sends a random thank message)
task.spawn(function()
    local player = Players.LocalPlayer
    if not player then return end
    local leaderstats = player:WaitForChild("leaderstats", 10)
    if not leaderstats then return end
    local raised = leaderstats:WaitForChild("Raised", 10)
    if not raised then return end
    local lastValue = raised.Value
    raised:GetPropertyChangedSignal("Value"):Connect(function()
        if raised.Value > lastValue then
            if autoThank then
                local channel = TextChatService and TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    math.randomseed(tick() + tonumber(tostring(os.time()):sub(-6)))
                    channel:SendAsync(thankMessages[math.random(1, #thankMessages)])
                end
            end
            lastValue = raised.Value
        end
    end)
end)

-- Webhook helper (replace the previous implementation). Treat only nil/empty as "unset".
local function sendWebhookNotification(message)
    if not webhookUrl or webhookUrl == "" then
        Rayfield:Notify({ Title = "Webhook", Content = "No webhook set. Set one in the Webhook tab.", Duration = 4 })
        return false
    end

    local okPayload, payload = pcall(function()
        return HttpService:JSONEncode({ content = tostring(message) })
    end)
    if not okPayload then
        Rayfield:Notify({ Title = "Webhook", Content = "Failed to build webhook payload.", Duration = 4 })
        return false
    end

    local okReq, res = pcall(function()
        if syn and syn.request then
            return syn.request({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        end
        if request then
            return request({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        end
        if HttpService and typeof(HttpService.RequestAsync) == "function" then
            return HttpService:RequestAsync({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        end
        -- fallback (may error if HTTP disabled)
        HttpService:PostAsync(webhookUrl, payload, Enum.HttpContentType.ApplicationJson)
        return { Success = true }
    end)

    if not okReq then
        Rayfield:Notify({ Title = "Webhook Error", Content = "Failed to send webhook request.", Duration = 4 })
        return false
    end

    if type(res) == "table" then
        if res.Success == false or (res.StatusCode and (res.StatusCode < 200 or res.StatusCode >= 300)) then
            Rayfield:Notify({ Title = "Webhook Error", Content = "Webhook returned non-2xx response.", Duration = 4 })
            return false
        end
    end

    return true
end

-- Fire the webhook once on script load (best-effort, non-blocking)
pcall(function()
    if webhookUrl and webhookUrl ~= "" then
        local pl = Players.LocalPlayer
        sendWebhookNotification(("Script loaded for player %s (PlaceId=%s)"):format(tostring(pl and pl.Name or "Unknown"), tostring(game.PlaceId)))
    end
end)

-- Notify when joined server
local function notifyServerJoin()
    local count = #Players:GetPlayers()
    local msg = ("Joined server with %d players."):format(count)
    Rayfield:Notify({ Title = "Server Join", Content = msg, Duration = 5 })
    sendWebhookNotification("Character has joined a server. Player count: " .. tostring(count))
end

-- Helper: re-query server list to get fresh server info for a specific server id
local function fetchServerInfo(placeId, targetServerId)
    local cursor = ""
    while true do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=2&limit=100%s")
            :format(placeId, cursor ~= "" and "&cursor=" .. cursor or "")
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then return nil end
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 or not data or not data.data then return nil end
        for _, server in ipairs(data.data) do
            if tostring(server.id) == tostring(targetServerId) then
                return server
            end
        end
        if data.nextPageCursor then cursor = data.nextPageCursor else break end
    end
    return nil
end

-- Improved ServerHop with pre-check to avoid teleporting to full servers and ignoring "server is full" errors
-- Legacy ServerHop removed; using SzzeServerHop / StartSzzePersistentHop exclusively

-- Szze-style aggressive server hop: aggressively poll server list ("shop" calls) and attempt teleports to servers matching target range
local function SzzeServerHop(minPlayers, maxPlayers)
    minPlayers = minPlayers or 24; maxPlayers = maxPlayers or 25
    local startTime = tick()
    local maxDuration = 7 -- seconds overall for this single attempt
    -- decide which placeId to target: always use the current game's placeId (no VC joins)
    local function choosePlaceId()
        return game.PlaceId
    end

    local placeId = choosePlaceId()
    local jobId = tostring(game.JobId)

    -- aggressively iterate over pages and collect candidates; repeat quickly if none found
    for attempt = 1, 8 do
        local cursor = ""
        local candidates = {}
        while true do
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=2&limit=100%s"):format(placeId, cursor ~= "" and "&cursor="..cursor or "")
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if not ok or not res then break end
            local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
            if not ok2 or not data or not data.data then break end
            for _, server in ipairs(data.data) do
                local sid = tostring(server.id)
                local playing = tonumber(server.playing) or 0
                local maxp = tonumber(server.maxPlayers) or 1000
                if sid ~= jobId and playing >= minPlayers and playing <= maxPlayers and playing < maxp then
                    table.insert(candidates, { id = sid, playing = playing, maxPlayers = maxp })
                end
            end
            if data.nextPageCursor then cursor = data.nextPageCursor else break end
            -- small pause to avoid hammering too hard but still be aggressive
            task.wait(0.02)
        end

        if #candidates > 0 then
            -- preferentially try servers with higher player counts within range
            table.sort(candidates, function(a,b) return a.playing > b.playing end)
            for _, entry in ipairs(candidates) do
                local target = entry.id
                -- fresh-check
                local fresh = fetchServerInfo(placeId, target)
                if fresh then
                    local playing = tonumber(fresh.playing) or 0
                    local maxp = tonumber(fresh.maxPlayers) or 1000
                    if playing >= minPlayers and playing <= maxPlayers and playing < maxp then
                        pcall(function() Rayfield:Notify({ Title = "Szze Hop", Content = ("Attempting teleport to server (%s players)"):format(playing), Duration = 4 }) end)
                        pcall(function() sendWebhookNotification("SzzeServerHop: teleporting to server id: " .. tostring(target) .. " playing=" .. tostring(playing)) end)
                        local oldJob = game.JobId
                        local ok, err = pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, target, Players.LocalPlayer)
                        end)
                        if ok then
                            -- wait a short while for job change but bound by overall maxDuration
                            local teleWaitIters = 10
                            for i=1, teleWaitIters do
                                task.wait(0.25)
                                if tostring(game.JobId) ~= tostring(oldJob) then
                                    return true
                                end
                                if (tick() - startTime) > maxDuration then
                                    -- timed out overall
                                    return false
                                end
                            end
                        else
                            -- on error, continue to next candidate
                            pcall(function() sendWebhookNotification("SzzeServerHop teleport error: " .. tostring(err)) end)
                        end
                    end
                end
            end
        end

        -- if we didn't teleport yet, do a very short wait and retry (aggressive)
        if (tick() - startTime) > maxDuration then break end
        task.wait(0.05 + math.random() * 0.07)
    end

    return false
end

-- persistent Szze hop with cooldown/guard to avoid overlapping persistent hops
local szzeHopRunning = false
local lastSzzeHopTime = 0
StartSzzePersistentHop = function(minPlayers, maxPlayers, force)
    minPlayers = minPlayers or 24; maxPlayers = maxPlayers or 25
    -- enforce serverHopDelay (in minutes) between persistent hops unless forced
    local now = tick()
    if not force and (now - lastSzzeHopTime) < (serverHopDelay * 60) then return end
    if szzeHopRunning then return end
    szzeHopRunning = true
    lastSzzeHopTime = now
    task.spawn(function()
        while true do
            local ok, res = pcall(function() return SzzeServerHop(minPlayers, maxPlayers) end)
            if ok and res == true then break end
            task.wait(0.8 + math.random() * 1.2)
        end
        szzeHopRunning = false
    end)
end

-- periodic server-hop task (uses default range 23-25 and will retry until success)
    task.spawn(function()
        while true do
            task.wait(serverHopDelay * 60)
            pcall(function()
                -- only start if cooldown has passed and not already running
                    if (tick() - lastSzzeHopTime) >= (serverHopDelay * 60) and not szzeHopRunning and autoHopsEnabled then
                    StartSzzePersistentHop(21, 23)
                end
            end)
        end
    end)

-- Evacuate on mod detection
local modUsernames = { ["haz3mn"]=true, ["zenuux"]=true, ["kreekcraft"]=true }
local function kickAndHop()
    Players.LocalPlayer:Kick("A moderator has been detected. Server hopping...")
    task.wait(2)
        pcall(function() if autoHopsEnabled then StartSzzePersistentHop(21, 23) end end)
end
local function scanForModsAndEvacuate()
    for _, p in ipairs(Players:GetPlayers()) do
        if modUsernames[string.lower(p.Name or "")] or modUsernames[string.lower(p.DisplayName or "")] then kickAndHop(); return end
    end
end
task.spawn(function() while true do if autoEvac then scanForModsAndEvacuate() end; task.wait(5) end end)
Players.PlayerAdded:Connect(function(p)
    if modUsernames[string.lower(p.Name or "")] or modUsernames[string.lower(p.DisplayName or "")] then kickAndHop() end
end)

-- Wear last outfit auto-confirm
local function tryFireWearLastOutfitOnce()
    pcall(function()
        local pl = Players.LocalPlayer
        if not pl then return end
        local function tryFireOnObject(obj)
            if not obj then return false end
            for _, d in ipairs(obj:GetDescendants()) do
                if d.Name == "PromptResult" then
                    if typeof(d.FireServer) == "function" then pcall(function() d:FireServer(true) end); return true
                    elseif typeof(d.InvokeServer) == "function" then pcall(function() d:InvokeServer(true) end); return true end
                end
            end
            return false
        end
        local pg = pl:FindFirstChild("PlayerGui") or pl:WaitForChild("PlayerGui", 5)
        if pg and tryFireOnObject(pg) then return end
        for _, c in ipairs(pl:GetChildren()) do
            if c.Name == "PromptResult" then
                if typeof(c.FireServer) == "function" then pcall(function() c:FireServer(true) end); return
                elseif typeof(c.InvokeServer) == "function" then pcall(function() c:InvokeServer(true) end); return end
            end
        end
    end)
end
tryFireWearLastOutfitOnce()

do
    local pl = Players.LocalPlayer
    if pl then
        local function onDescendantAdded(desc)
            if not desc then return end
            if desc.Name == "PromptResult" then
                pcall(function()
                    if typeof(desc.FireServer) == "function" then desc:FireServer(true)
                    elseif typeof(desc.InvokeServer) == "function" then desc:InvokeServer(true) end
                end)
            elseif desc.Name == "PromptWearLastOutfit" then
                pcall(function()
                    for _, d in ipairs(desc:GetDescendants()) do
                        if d.Name == "PromptResult" then
                            if typeof(d.FireServer) == "function" then d:FireServer(true); break
                            elseif typeof(d.InvokeServer) == "function" then d:InvokeServer(true); break end
                        end
                    end
                end)
            end
        end
        if pl:FindFirstChild("PlayerGui") then
            pl.PlayerGui.DescendantAdded:Connect(onDescendantAdded)
        else
            pl:GetPropertyChangedSignal("PlayerGui"):Connect(function()
                if pl.PlayerGui then pl.PlayerGui.DescendantAdded:Connect(onDescendantAdded) end
            end)
        end
        pl.ChildAdded:Connect(function(child)
            if child and child.Name == "PromptResult" then
                pcall(function()
                    if typeof(child.FireServer) == "function" then child:FireServer(true)
                    elseif typeof(child.InvokeServer) == "function" then child:InvokeServer(true) end
                end)
            end
        end)
    end
end

-- UI content
do
    local pl = Players.LocalPlayer
    local name = "Player"
    if pl then name = pl.DisplayName or pl.Name or "Player" end
    MainTab:CreateParagraph({ Title = "Welcome", Content = "Hello, " .. tostring(name) .. " — you are now using matty's auto farm script. Use the toggles below to configure features." })
end

MainTab:CreateParagraph({ Title = "Main Features", Content = "- Instant teleport to claimed booth\n- Anti-lag (always on)\n- Auto-evac + auto-thank" })
MainTab:CreateParagraph({ Title = "Server Info", Content = "You joined a server with " .. #Players:GetPlayers() .. " players.\nYour booth slot # will be shown after claiming a booth." })

MainTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = antiAfkEnabled, Callback = function(val) antiAfkEnabled = val end })

MainTab:CreateToggle({
    Name = "Disable 3D Rendering (default ON)",
    CurrentValue = disableRendering,
    Callback = function(val)
        disableRendering = val
        pcall(function()
            RunService:Set3dRenderingEnabled(not val)
        end)
    end
})

-- Anti-lag feature: aggressively disable visual effects and decals to improve FPS
local antiLagEnabled = true
local antiLagSnapshot = { parts = {}, lighting = {} }
local function applyAntiLag(enable)
    if enable then
        antiLagSnapshot.parts = {}
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                -- skip invalid or removed objects
                if obj and obj.Parent then
                    -- disable particle/beam/trail/sparkle/fire/smoke
                    if obj:IsA('ParticleEmitter') or obj:IsA('Trail') or obj:IsA('Beam') or obj:IsA('Sparkles') or obj:IsA('Fire') or obj:IsA('Smoke') then
                        antiLagSnapshot.parts[obj] = antiLagSnapshot.parts[obj] or {}
                        antiLagSnapshot.parts[obj].Enabled = obj.Enabled
                        pcall(function() obj.Enabled = false end)
                    end
                    -- hide decals and textures
                    if obj:IsA('Decal') or obj:IsA('Texture') then
                        antiLagSnapshot.parts[obj] = antiLagSnapshot.parts[obj] or {}
                        antiLagSnapshot.parts[obj].Transparency = obj.Transparency
                        pcall(function() obj.Transparency = 1 end)
                    end
                    -- small gui optimization: disable SurfaceGuis
                    if obj:IsA('SurfaceGui') or obj:IsA(' BillboardGui') then
                        antiLagSnapshot.parts[obj] = antiLagSnapshot.parts[obj] or {}
                        if typeof(obj.Enabled) == 'boolean' then
                            antiLagSnapshot.parts[obj].Enabled = obj.Enabled
                            pcall(function() obj.Enabled = false end)
                        end
                    end
                end
            end
            -- lighting adjustments
            local Lighting = game:GetService('Lighting')
            antiLagSnapshot.lighting.GlobalShadows = Lighting.GlobalShadows
            antiLagSnapshot.lighting.Brightness = Lighting.Brightness
            antiLagSnapshot.lighting.OutdoorAmbient = Lighting.OutdoorAmbient
            antiLagSnapshot.lighting.Ambient = Lighting.Ambient
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.Brightness = 1
                Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
                Lighting.Ambient = Color3.fromRGB(128,128,128)
            end)
        end)
    else
        pcall(function()
            for obj, props in pairs(antiLagSnapshot.parts or {}) do
                if obj and obj.Parent then
                    pcall(function()
                        if props.Enabled ~= nil and typeof(obj.Enabled) == 'boolean' then obj.Enabled = props.Enabled end
                        if props.Transparency ~= nil and (obj:IsA('Decal') or obj:IsA('Texture')) then obj.Transparency = props.Transparency end
                    end)
                end
            end
            local Lighting = game:GetService('Lighting')
            if antiLagSnapshot.lighting then
                pcall(function()
                    Lighting.GlobalShadows = antiLagSnapshot.lighting.GlobalShadows or Lighting.GlobalShadows
                    Lighting.Brightness = antiLagSnapshot.lighting.Brightness or Lighting.Brightness
                    Lighting.OutdoorAmbient = antiLagSnapshot.lighting.OutdoorAmbient or Lighting.OutdoorAmbient
                    Lighting.Ambient = antiLagSnapshot.lighting.Ambient or Lighting.Ambient
                end)
            end
            antiLagSnapshot = { parts = {}, lighting = {} }
        end)
    end
end

MainTab:CreateToggle({ Name = "Anti-Lag (aggressive)", CurrentValue = antiLagEnabled, Callback = function(v)
    antiLagEnabled = v
    pcall(function() applyAntiLag(v) end)
end })

MainTab:CreateButton({ Name = "Server Hop (Szze) - persistent (21-23)", Callback = function()
    task.spawn(function()
        pcall(function() StartSzzePersistentHop(21, 23) end)
    end)
end })
MainTab:CreateSlider({ Name = "Server Hop Delay", Range = {5, 60}, Increment = 5, Suffix = "minutes", CurrentValue = serverHopDelay, Callback = function(v) serverHopDelay = v end })
MainTab:CreateToggle({ Name = "Auto Hop on Bot Detection", CurrentValue = autoHopOnBotDetection, Callback = function(v) autoHopOnBotDetection = v end })

-- Test Donation Button (simulates a donation for testing)
MainTab:CreateButton({
    Name = "Test Donation (simulate dono)",
    Callback = function()
        local pl = game:GetService("Players").LocalPlayer
        if not pl then return end
        local leaderstats = pl:FindFirstChild("leaderstats") or pl:WaitForChild("leaderstats", 5)
        if not leaderstats then return end
        local raised = leaderstats:FindFirstChild("Raised") or leaderstats:WaitForChild("Raised", 5)
        if not raised then return end
        local old = raised.Value
        raised.Value = old + math.random(1, 10)
        Rayfield:Notify({ Title = "Test Donation", Content = "Simulated a donation! Raised is now " .. tostring(raised.Value), Duration = 4 })
    end
})

BegTab:CreateParagraph({ Title = "Begging Features", Content = "Begging messages are currently disabled." })
BegTab:CreateToggle({ Name = "Auto Beg", CurrentValue = autoBeg, Callback = function(val) autoBeg = val end })
BegTab:CreateSlider({
    Name = "Begging Delay (seconds)",
    Range = {2, 60},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 8,
    Flag = "BegDelay",
    Callback = function(value)
        _G.BegDelay = value
    end,
})

EvacTab:CreateParagraph({ Title = "Evacuation Features", Content = "Auto-evacuation when a watched user is detected." })
EvacTab:CreateParagraph({ Title = "Watched Users", Content = "1. haz3mn\n2. zenuux\n3. kreekcraft" })
EvacTab:CreateToggle({ Name = "Auto Evacuate (Detect Mods)", CurrentValue = autoEvac, Callback = function(val) autoEvac = val end })

EmoteTab:CreateParagraph({ Title = "Emote Features", Content = "Play preset emotes or input an emote asset ID." })
EmoteTab:CreateButton({ Name = "Stop Emote", Callback = stopAllAnimations })
EmoteTab:CreateInput({ Name = "Input Asset ID", PlaceholderText = "Enter Emote Asset ID", RemoveTextAfterFocusLost = false, CurrentValue = emoteId, Callback = function(val) emoteId = val end })
EmoteTab:CreateButton({ Name = "Play Catalog Emote", Callback = function() playEmoteById(emoteId) end })
EmoteTab:CreateParagraph({ Title = "Preset Emotes", Content = "Tap a preset to play it." })
for name, id in pairs(emotePresets) do
    EmoteTab:CreateButton({ Name = name, Callback = (function(i) return function() playEmoteById(i) end end)(id) })
end

-- Auto-Reply (AR) feature
local ARTab = Window:CreateTab("AR", 6031300001)
-- Auto Reply (AR) is enforced ON by default and cannot be turned off by the UI toggle below.
local autoReplyEnabled = false
local autoReplyNoRespond = false

-- Pattern-driven replies (from user ChatPatterns). These are checked first and support Lua-style captures
local PatternReplies = {
    -- Greetings
    { TriggerPattern = "hello", ReplyPool = { "hey", "hi", "hello", "yo", "hey there", "sup" } },
    { TriggerPattern = "hi", ReplyPool = { "hey", "hello", "hi there", "yo", "wassup" } },
    { TriggerPattern = "yo", ReplyPool = { "yo", "sup", "hey", "what’s good" } },
    { TriggerPattern = "sup", ReplyPool = { "not much, you?", "chilling", "just walking around", "nm, what about you" } },
    { TriggerPattern = "hey", ReplyPool = { "hey", "hi", "what’s up", "yo", "hey hey" } },

    -- How are you / hru / similar
    { TriggerPattern = "how are you", ReplyPool = { "i’m good, you?", "doing fine, you?", "pretty chill today", "can’t complain", "feeling alright" } },
    { TriggerPattern = "hru", ReplyPool = { "i’m good hbu", "fine, you?", "doing okay", "pretty good", "can’t complain" } },
    { TriggerPattern = "how you doing", ReplyPool = { "i’m alright, you?", "doing okay", "not bad, just hanging", "fine, thanks" } },
    { TriggerPattern = "how’s it going", ReplyPool = { "going good", "all good here", "pretty good", "just chilling" } },

    -- Donation / money talk
    { TriggerPattern = "donate", ReplyPool = { "donate to me first and i’ll dono you back", "i usually donate after i get some too", "i can if you help me first", "donate me first and i’ll return the favor", "trying to save up before donating more" } },
    { TriggerPattern = "pls donate", ReplyPool = { "you donate me first, then i’ll donate you back", "help me out first and i’ll return it", "donate first, i’ll match it", "i dono back if you go first" } },
    { TriggerPattern = "robux", ReplyPool = { "trying to earn more too", "we all want robux haha", "yeah i’m saving for a goal", "not much left right now" } },

    -- Likes and opinions (with captures)
    { TriggerPattern = "do you like (.+)", ReplyPool = { "yeah i like %1", "of course, %1 are nice", "i do, actually", "yeah %1 are cool" } },
    { TriggerPattern = "favorite (.+)", ReplyPool = { "i don’t really have a favorite %1", "probably something simple for %1", "hard to pick one %1", "i guess i like most %1" } },

    -- Ghosts / random chat
    { TriggerPattern = "do you believe in ghosts", ReplyPool = { "sometimes i think i’ve seen one", "maybe, i’m not sure", "yeah, once in a while", "can’t say for sure" } },

    -- Random casual replies
    { TriggerPattern = "what are you doing", ReplyPool = { "just walking around", "talking to people", "looking for cool booths", "not much" } },
    { TriggerPattern = "wyd", ReplyPool = { "not much, you?", "just chilling", "walking around here", "nothing much" } },
    { TriggerPattern = "what’s up", ReplyPool = { "nm, you?", "just here", "not much", "same old" } },
    { TriggerPattern = "how old are you", ReplyPool = { "not that old", "idk, i stopped counting", "young enough", "old enough" } },
    { TriggerPattern = "who made you", ReplyPool = { "a dev did", "someone scripted me", "not sure who exactly", "a kind person built me" } },
    { TriggerPattern = "where are you from", ReplyPool = { "from around here", "i just spawned in", "this place is my home", "nowhere specific" } },

    -- Thanks / manners
    { TriggerPattern = "thank", ReplyPool = { "np", "no problem", "you’re welcome", "all good", "anytime" } },

    -- Goodbyes
    { TriggerPattern = "bye", ReplyPool = { "bye", "see ya", "take care", "later", "peace" } },
    { TriggerPattern = "goodnight", ReplyPool = { "night", "sleep well", "see you later", "take care" } },

    -- Misc
    { TriggerPattern = "can you (.+)", ReplyPool = { "maybe i can %1", "i’ll try to %1", "not sure i can %1 though", "i’ll see if i can %1" } },
    { TriggerPattern = "why", ReplyPool = { "idk honestly", "just how it is", "no clue", "that’s a good question" } },
    { TriggerPattern = "what time", ReplyPool = { "no idea", "time doesn’t really matter here", "not sure", "probably late" } }
}

-- Extra casual / social responses (user-provided) — appended to PatternReplies
local ExtraPatternReplies = {
    { TriggerPattern = "you afk", ReplyPool = { "nah, i’m here", "just chilling, not afk", "nope, still around", "maybe a little afk haha" } },
    { TriggerPattern = "are you a bot", ReplyPool = { "nah, just talkative", "do i sound like one?", "maybe a little", "nope, real person here", "depends who’s asking" } },
    { TriggerPattern = "goal", ReplyPool = { "trying to reach 1k soon", "not far from my goal", "just saving up slowly", "still working toward it" } },
    { TriggerPattern = "nice stand", ReplyPool = { "thanks, appreciate it", "glad you like it", "thanks a lot", "took a while to set it up" } },
    { TriggerPattern = "how much", ReplyPool = { "depends what you mean", "not sure yet", "a few robux maybe", "trying to hit around 500" } },
    { TriggerPattern = "you rich", ReplyPool = { "nah, not really", "trying to be haha", "just average", "i wish" } },
    { TriggerPattern = "you poor", ReplyPool = { "kinda", "yeah, broke rn", "working on it", "trying to earn something" } },
    { TriggerPattern = "best item", ReplyPool = { "probably some limited", "idk, i like simple hats", "hard to pick one", "i think accessories look best" } },
    { TriggerPattern = "favorite game", ReplyPool = { "this one’s up there", "i play a few others too", "probably this one rn", "depends on the day" } },
    { TriggerPattern = "play any games", ReplyPool = { "yeah, a few", "sometimes", "mostly chill games", "depends on what i feel like" } },
    { TriggerPattern = "do you trade", ReplyPool = { "not much lately", "sometimes when i get good items", "i used to", "not really into trading rn" } },
    { TriggerPattern = "wanna be friends", ReplyPool = { "sure, why not", "yeah we can be friends", "of course", "yea, sounds good" } },
    { TriggerPattern = "add me", ReplyPool = { "i’ll try later", "maybe after this", "send a request", "if i see it, i’ll accept" } },
    { TriggerPattern = "you good", ReplyPool = { "yeah i’m fine", "i’m chill", "all good here", "doing alright" } },
    { TriggerPattern = "what you selling", ReplyPool = { "just a few gamepasses", "some cheap ones", "nothing too crazy", "check the booth, it’s all there" } },
    { TriggerPattern = "when you join", ReplyPool = { "just a few mins ago", "not long ago", "been here for a bit", "just spawned in" } },
    { TriggerPattern = "you real", ReplyPool = { "as real as i can be", "yeah, i’m real", "depends on what you call real", "pretty much" } },
    { TriggerPattern = "tell me a joke", ReplyPool = { "why did the player stand still? waiting for robux", "robux isn’t happiness, but it helps", "booths be quiet till someone donates", "why join pls donate? to learn patience" } },
    { TriggerPattern = "what’s your goal", ReplyPool = { "about 1k", "trying for 500", "just saving whatever i get", "no goal really, just seeing what happens" } },
    { TriggerPattern = "you lagging", ReplyPool = { "a little bit yeah", "my walk’s kinda weird", "it’s just my wifi", "lag spike maybe" } },
    { TriggerPattern = "you cool", ReplyPool = { "i try to be", "guess so", "yeah a little", "i’d say so" } },
    { TriggerPattern = "what’s your booth", ReplyPool = { "it’s right there", "look for my name on it", "you can’t miss it", "check the one with the blue text" } },
    { TriggerPattern = "you bored", ReplyPool = { "kinda", "a bit", "just trying to pass time", "nah, i’m good" } },
    { TriggerPattern = "why you walking weird", ReplyPool = { "that’s just how i move", "idk, lag maybe", "walking style glitch haha", "trying to get somewhere" } },
    { TriggerPattern = "who’s your owner", ReplyPool = { "idk, i just spawned here", "some dev i think", "someone nice made me", "i don’t remember" } },
    { TriggerPattern = "you tired", ReplyPool = { "a little", "yeah kinda", "not really", "nah, i’m good" } },
    { TriggerPattern = "can i have robux", ReplyPool = { "you donate me first, then i got you", "help me out first", "donate to me and i’ll dono you back", "depends, maybe if i get more" } },
    { TriggerPattern = "what’s your username", ReplyPool = { "same as above my booth", "you can see it on the stand", "it’s right here above me", "look up, it’s right there" } },
    { TriggerPattern = "you funny", ReplyPool = { "i try", "glad you think so", "not really, but thanks", "sometimes" } },
    { TriggerPattern = "what’s your favorite color", ReplyPool = { "blue probably", "green looks nice", "red’s cool too", "idk, i like most colors" } },
    { TriggerPattern = "what’s your favorite animal", ReplyPool = { "dogs for sure", "cats maybe", "pandas are nice", "hard to pick one" } }
}

-- Add additional short/casual patterns for yes/no, donate flows, and hru
do
    local extras = {
        { TriggerPattern = "^no$", ReplyPool = { "oh okay..", "ah, alright then..", "no worries" } },
        { TriggerPattern = "^nah$", ReplyPool = { "oh okay..", "ah, alright then..", "no worries" } },
        { TriggerPattern = "^nope$", ReplyPool = { "oh okay..", "ah, alright then..", "no worries" } },
        { TriggerPattern = "^yes$", ReplyPool = { "wooo, come purchase a gamepass then, il be waiting..", "sweet! come purchase a gamepass and i'll be waiting :)" } },
        { TriggerPattern = "^yeah$", ReplyPool = { "wooo, come purchase a gamepass then, il be waiting..", "nice! go buy the gamepass and i'll wait" } },
        { TriggerPattern = "donate", ReplyPool = { "you donate me first, then i'll donate you back", "dono first and ill dono back", "dono first and i'll dono back :)" } },
        { TriggerPattern = "dono", ReplyPool = { "you donate me first, then i'll donate you back", "dono first and ill dono back", "i'll dono back after you dono first" } },
        { TriggerPattern = "i donate", ReplyPool = { "nice! donate first and i'll dono back", "ty, donate first and i'll match when i can" } },
        { TriggerPattern = "i'll donate", ReplyPool = { "awesome! donate first and i'll dono back", "sounds good — donate first and i'll return something" } },
        { TriggerPattern = "how are you", ReplyPool = { "good, hbu", "i'm good, how about you?", "doing fine, hbu" } },
        { TriggerPattern = "hru", ReplyPool = { "good, how about you", "i'm good hbu", "doing good, you?" } },
        { TriggerPattern = "ill pass", ReplyPool = { "oh okay..", "no worries, maybe next time" } },
        { TriggerPattern = "i'm good", ReplyPool = { "nice, glad to hear", "sweet :)" } },
        { TriggerPattern = "what are you doing", ReplyPool = { "just walking around", "talking to people", "looking for cool booths" } },
        { TriggerPattern = "wyd", ReplyPool = { "not much, you?", "just chilling", "walking around here" } },
        { TriggerPattern = "sup", ReplyPool = { "not much, you?", "chilling", "what's up" } }
    ,{ TriggerPattern = "scam", ReplyPool = { "nah, not a scam, i've donated to many other users before", "nah not a scam — i've donated to others before, promise" } }
    ,{ TriggerPattern = "is this a scam", ReplyPool = { "nah, not a scam, i've donated to many other users before", "nope, it's legit, i've donated before" } }
    ,{ TriggerPattern = "how to donate", ReplyPool = { "just press the donate button on my booth", "click my booth and hit donate — donate first and i'll match" } }
    ,{ TriggerPattern = "what do you sell", ReplyPool = { "a few gamepasses, check the booth UI", "some gamepasses and stuff — see the booth" } }
    ,{ TriggerPattern = "gamepass", ReplyPool = { "i have a small gamepass for donations", "buy the gamepass to support me" } }
    ,{ TriggerPattern = "how much for", ReplyPool = { "depends — check the booth for prices", "prices vary, check the booth UI" } }
    ,{ TriggerPattern = "where is your booth", ReplyPool = { "it's right behind me", "check above me — that's my booth" } }
    }
    for _, v in ipairs(extras) do table.insert(ExtraPatternReplies, v) end
end

-- append ExtraPatternReplies into PatternReplies
for _, v in ipairs(ExtraPatternReplies) do table.insert(PatternReplies, v) end

-- AR enhancements
    local perPlayerCooldown = 12 -- seconds between replies to the same player
    local replyTimestamps = {} -- map player.UserId -> last reply tick
    local arResponseDelay = 2.5 -- seconds to wait before sending an AR reply
local replyHistory = {} -- map userId -> last reply string (avoid repeating)
-- dedupe recent messages to avoid duplicate replies for the same chat message
local recentMessageHashes = {} -- map hash -> timestamp
local recentMessageWindow = 2 -- seconds during which a repeated identical message is ignored
-- track recent chat timestamps per player for bot/activity heuristics
local recentChats = {} -- map userId -> array of timestamps
local chatWindow = 12 -- seconds to consider recent chat activity
local chatSpamThreshold = 3 -- messages within window considered spammy
-- Promotion messages cooldown (avoid spamming promotional lines)
local promotionCooldown = 200 -- seconds between promotional messages
local lastPromotionTime = 0
-- AR current target (keeps the chosen nearby player between ticks)
local currentTarget = nil -- { Root = Instance, Player = Player }
-- Navigation state
local isNavigatingToBooth = false
local navigationWalkSpeed = 30 -- temporary increased walkspeed while navigating

-- Create a non-disabling toggle: show current state but ignore attempts to toggle it off.
ARTab:CreateToggle({ Name = "Auto Reply (AR) (Always Enabled)", CurrentValue = autoReplyEnabled, Callback = function(v)
    -- keep AR forced on; do not allow user to disable via the toggle
    if not autoReplyEnabled then autoReplyEnabled = true end
    -- optionally provide a subtle notification if they attempt to turn it off
    if v == false then
        pcall(function()
            Rayfield:Notify({ Title = "Auto Reply", Content = "Auto Reply is required and cannot be disabled.", Duration = 4 })
        end)
    end
end })
ARTab:CreateToggle({ Name = "Skip Unrecognized Messages", CurrentValue = autoReplyNoRespond, Callback = function(v) autoReplyNoRespond = v end })
ARTab:CreateParagraph({ Title = "AR Info", Content = "Replies when nearby players chat. Uses expanded keyword checks and per-player cooldowns. Only one reply will be sent per message." })

ARTab:CreateToggle({ Name = "Face Nearby Players (AR stare)", CurrentValue = arStareEnabled, Callback = function(v)
    arStareEnabled = v
end })

-- AR reply delay slider (0-10s)
ARTab:CreateSlider({ Name = "AR Reply Delay (seconds)", Range = {0, 10}, Increment = 1, CurrentValue = arResponseDelay, Callback = function(v)
    arResponseDelay = math.max(0, tonumber(v) or 0)
end })

-- ChatPatterns merge input: paste a Lua table representation (safe load) and press Merge
local chatPatternsInput = ""
ARTab:CreateInput({ Name = "Paste ChatPatterns (Lua table)", PlaceholderText = "paste a Lua table here (e.g. { Greetings = { Keywords = {...}, Lines = {...} } })", RemoveTextAfterFocusLost = false, CurrentValue = chatPatternsInput, Callback = function(v) chatPatternsInput = v end })
ARTab:CreateButton({ Name = "Merge ChatPatterns", Callback = function()
    if not chatPatternsInput or chatPatternsInput == '' then
        pcall(function() Rayfield:Notify({ Title = "AR Merge", Content = "No ChatPatterns pasted.", Duration = 4 }) end)
        return
    end
    -- try to load the pasted text as a Lua table expression
    local ok, res = pcall(function()
        local f = loadstring("return " .. chatPatternsInput)
        if not f then error('invalid lua') end
        return f()
    end)
    if not ok or type(res) ~= 'table' then
        pcall(function() Rayfield:Notify({ Title = "AR Merge", Content = "Failed to parse ChatPatterns. Ensure it's a Lua table expression.", Duration = 6 }) end)
        return
    end
    -- merge res into Responses
    local merged = 0
    for cat, entry in pairs(res) do
        if type(entry) == 'table' then
            Responses[cat] = Responses[cat] or { Keywords = {}, Lines = {} }
            -- merge Keywords
            if type(entry.Keywords) == 'table' then
                for _, kw in ipairs(entry.Keywords) do
                    local s = tostring(kw)
                    local found = false
                    for _, existing in ipairs(Responses[cat].Keywords) do if existing == s then found = true; break end end
                    if not found then table.insert(Responses[cat].Keywords, s) end
                end
            end
            -- merge Lines
            if type(entry.Lines) == 'table' then
                for _, ln in ipairs(entry.Lines) do
                    local s = tostring(ln)
                    local found = false
                    for _, existing in ipairs(Responses[cat].Lines) do if existing == s then found = true; break end end
                    if not found then table.insert(Responses[cat].Lines, s); merged = merged + 1 end
                end
            end
        end
    end
    pcall(function() Rayfield:Notify({ Title = "AR Merge", Content = ("Merged %d new reply lines into Responses."):format(merged), Duration = 4 }) end)
end })

local function trySendChatReply(text)
    -- delay sending to appear more natural and avoid instant bot-like replies
    task.spawn(function()
        -- add a small randomized extra delay between 0.2 and 1.2 seconds
        local extra = 0.2 + math.random() * 1.0
        task.wait((arResponseDelay or 0) + extra)
        pcall(function()
            local channel = TextChatService and TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(text) else Players:Chat(text) end
        end)
    end)
end

-- New handler: keyword-based category matching with priority fallbacks
local function pickResponseForMessage(msgLower, uid)
    -- 1) PatternReplies (user-provided patterns with capture support)
    for _, pat in ipairs(PatternReplies) do
        local patStr = tostring(pat.TriggerPattern or ''):lower()
        if patStr ~= '' then
            -- Prefer whole-word/frontier matches first to avoid substring preemption
            local ok, captures = pcall(function()
                -- try frontier (whole-word) match first: %f[] ensures word boundaries
                local frontierPat = "%f[%w]" .. patStr .. "%f[%W]"
                if string.match(msgLower, frontierPat) then
                    -- try to collect captures if the TriggerPattern is a pattern with captures
                    local m = { string.match(msgLower, patStr) }
                    if #m > 0 then return m end
                    return true
                end
                -- fallback to a plain substring search (safe, plain = true)
                local s = string.find(msgLower, patStr, 1, true)
                if s then return true end
                -- final attempt: allow full pattern matching (for patterns with captures)
                local m2 = { string.match(msgLower, patStr) }
                if #m2 > 0 then return m2 end
                return false
            end)
            if ok and captures then
                -- pick a reply and substitute captures (supports %1, %2 .. in reply strings)
                local pool = pat.ReplyPool or pat.ReplyPool or {}
                if type(pool) == 'table' and #pool > 0 then
                    local chosen = pool[math.random(1, #pool)]
                    if type(captures) == 'table' and #captures > 0 then
                        for i = 1, #captures do
                            chosen = string.gsub(chosen, '%%'..i, tostring(captures[i]))
                        end
                    end
                    -- optional debug logging to trace pattern matches
                    if _G.__AR_DEBUG then
                        pcall(function()
                            print(('[AR DEBUG] matched pattern "%s" for msg "%s" -> reply "%s"'):format(patStr, msgLower, tostring(chosen)))
                        end)
                    end
                    -- avoid repeating same reply to uid where possible
                    if uid then
                        local last = replyHistory[uid]
                        local attempts = 0
                        while last and chosen == last and attempts < 6 and #pool > 1 do
                            chosen = pool[math.random(1, #pool)]
                            attempts = attempts + 1
                        end
                    end
                    return chosen
                end
            end
        end
    end
    -- check categories in a reasonable order — Donations and Greetings first, then others
    local priority = { "Donations", "Greetings", "Thanks", "Questions", "Praise", "Casual", "AFK", "System", "Negative" }
    for _, cat in ipairs(priority) do
        local entry = Responses[cat]
        if entry and entry.Keywords and entry.Lines and #entry.Lines > 0 then
            for _, kw in ipairs(entry.Keywords) do
                -- use plain substring match for multi-word keywords too
                if string.find(msgLower, kw, 1, true) then
                    -- pick a randomized line but avoid repeating the last reply to this uid when possible
                    local lines = entry.Lines
                    local chosen = lines[math.random(1, #lines)]
                    if uid then
                        local last = replyHistory[uid]
                        local attempts = 0
                        while last and chosen == last and attempts < 6 and #lines > 1 do
                            chosen = lines[math.random(1, #lines)]
                            attempts = attempts + 1
                        end
                    end
                    return chosen
                end
            end
        end
    end
    -- if none matched, return nil (caller will handle 'Other' depending on autoReplyNoRespond)
    return nil
end

local function handleAutoReply(speakerPlayer, message)
    -- Szze-style: always check nearby chat (12 studs), dedupe, cooldowns; respect Skip Unrecognized Messages
    if not speakerPlayer or speakerPlayer == Players.LocalPlayer then return end
    if not message or type(message) ~= 'string' then return end
    if isNavigatingToBooth then return end -- avoid AR interrupting navigation
    local myChar = Players.LocalPlayer and Players.LocalPlayer.Character
    local theirChar = speakerPlayer and speakerPlayer.Character
    if not myChar or not theirChar then return end
    -- prefer HumanoidRootPart, fallback to PrimaryPart
    local myRoot = myChar:FindFirstChild('HumanoidRootPart') or myChar.PrimaryPart
    local theirRoot = theirChar:FindFirstChild('HumanoidRootPart') or theirChar.PrimaryPart
    if not myRoot or not theirRoot then return end
    local distance = (myRoot.Position - theirRoot.Position).Magnitude
    if distance > 9 then return end -- 9-stud proximity requirement

    local uid = (speakerPlayer and speakerPlayer.UserId) or nil
    if uid and replyTimestamps[uid] and (tick() - replyTimestamps[uid]) < perPlayerCooldown then return end

    local msgLower = string.lower(message)
    local hash = msgLower .. '|' .. tostring(speakerPlayer.UserId)
    local now = tick()
    for h, t in pairs(recentMessageHashes) do if now - t > recentMessageWindow then recentMessageHashes[h] = nil end end
    if recentMessageHashes[hash] then return end
    recentMessageHashes[hash] = now

    -- Try to pick a response from categories
    local chosen = pickResponseForMessage(msgLower, uid)
    if not chosen then
        if autoReplyNoRespond then
            return
        end
        -- fallback to Other category
        local other = Responses.Other
        if other and other.Lines and #other.Lines > 0 then chosen = other.Lines[math.random(1, #other.Lines)] end
    end

    if chosen then
        -- send reply (trySendChatReply applies its own randomized delay)
        task.spawn(function()
            trySendChatReply(chosen)
            if uid then
                replyTimestamps[uid] = tick()
                replyHistory[uid] = chosen
            end
        end)
    end

    -- promotional messages are handled by a proximity-duration watcher (separate task)
end

-- Attach to existing players and future players
local function recordChatAndHandle(p, msg)
    pcall(function()
        if p and p.UserId then
            recentChats[p.UserId] = recentChats[p.UserId] or {}
            table.insert(recentChats[p.UserId], tick())
            -- purge old entries
            for i = #recentChats[p.UserId], 1, -1 do
                if tick() - recentChats[p.UserId][i] > chatWindow then table.remove(recentChats[p.UserId], i) end
            end
        end
    end)
    pcall(function() handleAutoReply(p, msg) end)
end

for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(msg) recordChatAndHandle(p, msg) end)
end
Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg) recordChatAndHandle(p, msg) end)
end)

-- Proximity-duration monitor: track players within 9 studs; if they stay >= 6s, send promotional messages
do
    local proximityEntry = {} -- map userId -> enterTick
    local checkInterval = 0.25
    local requiredDuration = 6 -- seconds in range to trigger promo
    task.spawn(function()
        while true do
            task.wait(checkInterval)
            -- skip while navigating to booth to avoid interrupting movement
            if isNavigatingToBooth then
                -- continue to next iteration
            else
                local pl = Players.LocalPlayer
                if pl and pl.Character then
                    local hrp = pl.Character:FindFirstChild('HumanoidRootPart') or pl.Character.PrimaryPart
                    if hrp then
                        local now = tick()
                        local nearbyList = {}
                        for _, other in ipairs(Players:GetPlayers()) do
                            if other ~= pl and other.Character then
                                local otr = other.Character:FindFirstChild('HumanoidRootPart') or other.Character.PrimaryPart
                                if otr then
                                    local d = (otr.Position - hrp.Position).Magnitude
                                    if d <= 9 then
                                        table.insert(nearbyList, other)
                                        if not proximityEntry[other.UserId] then proximityEntry[other.UserId] = now end
                                    else
                                        proximityEntry[other.UserId] = nil
                                    end
                                end
                            end
                        end

                        -- remove entries for players no longer present
                        for uid, t in pairs(proximityEntry) do
                            local found = false
                            for _, o in ipairs(nearbyList) do if o.UserId == uid then found = true; break end end
                            if not found then proximityEntry[uid] = nil end
                        end

                        -- check if any have been in range long enough
                        if #nearbyList > 0 then
                            local longEnough = {}
                            for _, o in ipairs(nearbyList) do
                                local s = proximityEntry[o.UserId]
                                if s and (now - s) >= requiredDuration then table.insert(longEnough, o) end
                            end
                            if #longEnough > 0 and (now - lastPromotionTime) >= promotionCooldown then
                                -- decide single vs multi
                                if #longEnough == 1 then
                                    task.spawn(function()
                                        task.wait(arResponseDelay)
                                        trySendChatReply("you willing to donate for 5x the amount of robux back?")
                                    end)
                                else
                                    task.spawn(function()
                                        task.wait(arResponseDelay)
                                        trySendChatReply("hey you guys willing to dono for a 5x dono back?")
                                    end)
                                end
                                lastPromotionTime = now
                                -- clear proximity entries so we don't repeat immediately
                                for _, o in ipairs(longEnough) do proximityEntry[o.UserId] = nil end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- AR stare loop: face nearby players (within 12 studs) while they're close; otherwise face away from booth
task.spawn(function()
    while true do
        task.wait(0.08)
        if arStareEnabled then
            local pl = Players.LocalPlayer
            if pl and pl.Character then
                local hrp = pl.Character:FindFirstChild('HumanoidRootPart') or pl.Character.PrimaryPart
                if hrp then
                    -- pick a random nearby player within 5 studs (excluding self); follow them while in range
                    local candidates = {}
                    for _, other in ipairs(Players:GetPlayers()) do
                        if other ~= pl and other.Character then
                            local otr = other.Character:FindFirstChild('HumanoidRootPart') or other.Character.PrimaryPart
                            if otr then
                                local d = (otr.Position - hrp.Position).Magnitude
                                if d <= 9 then table.insert(candidates, {root = otr, player = other, dist = d}) end
                            end
                        end
                    end

                    if #candidates > 0 then
                        -- choose a random candidate (or keep previous target if still valid)
                        local chosen = nil
                        if currentTarget and currentTarget.Player then
                            for _, c in ipairs(candidates) do if c.player == currentTarget.Player then chosen = c; break end end
                        end
                        if not chosen then chosen = candidates[math.random(1, #candidates)] end

                        -- store target reference so we can keep facing them until they leave
                        currentTarget = { Root = chosen.root, Player = chosen.player }

                        -- face the target, yaw-only, and smooth the rotation to mimic first-person look
                        pcall(function()
                            local targetPos = chosen.root.Position
                            -- compute direction on XZ plane only (yaw)
                            local fromPos = hrp.Position
                            local toPos = Vector3.new(targetPos.X, fromPos.Y, targetPos.Z)
                            local dir = (toPos - fromPos).Unit
                            -- current look vector
                            local fromLook = hrp.CFrame.LookVector
                            local fromLookXZ = Vector3.new(fromLook.X, 0, fromLook.Z)
                            if fromLookXZ.Magnitude < 0.001 then fromLookXZ = Vector3.new(0,0,-1) end
                            fromLookXZ = fromLookXZ.Unit
                            local toLookXZ = Vector3.new(dir.X, 0, dir.Z).Unit
                            -- lerp the XZ look vector for smoothing
                            local t = 0.45
                            local newLook = fromLookXZ:Lerp(toLookXZ, t)
                            if newLook.Magnitude > 0.001 then newLook = newLook.Unit end
                            -- apply yaw-only facing while preserving Y position
                            if not isNavigatingToBooth then
                                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(newLook.X, 0, newLook.Z))
                            end
                        end)
                    else
                        -- no players nearby; clear current target and restore facing away from booth
                        currentTarget = nil
                        if currentBoothPart and defaultFacingCFrame then
                            local lookVec = defaultFacingCFrame.LookVector
                            pcall(function() hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z)) end)
                        end
                    end
                end
            end
        end
    end
end)

-- Webhook tab UI (persisted via Rayfield config, but always uses the above webhook)
WebhookTab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        local ok = false
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local payload = HttpService:JSONEncode({ content = "Test webhook from PLS DONATE script." })
            if syn and syn.request then
                syn.request({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
            elseif request then
                request({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
            elseif HttpService and typeof(HttpService.RequestAsync) == "function" then
                HttpService:RequestAsync({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
            else
                HttpService:PostAsync(webhookUrl, payload, Enum.HttpContentType.ApplicationJson)
            end
            ok = true
        end)
        if ok then
            Rayfield:Notify({ Title = "Webhook", Content = "Test message sent.", Duration = 4 })
        else
            Rayfield:Notify({ Title = "Webhook", Content = "Test failed. Check webhook or HTTP permissions.", Duration = 5 })
        end
    end,
})

-- Kick and server hop upon donation
-- legacy helper; updated to target 26-28
local function serverHop26to28()
    local httpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlaceId = game.PlaceId
    local JobId = game.JobId
    local req = syn and syn.request or http and http.request or http_request or request
    if not req then return end
    local response = req({
        Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", PlaceId)
    })
    local body = httpService:JSONDecode(response.Body)
    local servers = {}
    for _, server in pairs(body.data) do
        if server.playing >= 26 and server.playing <= 28 and server.id ~= JobId then
            table.insert(servers, server)
        end
    end
    if #servers > 0 then
        local selectedServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(PlaceId, selectedServer.id, LocalPlayer)
    end
end

pcall(function()
    local pl = game:GetService("Players").LocalPlayer
    if not pl then return end
    local leaderstats = pl:WaitForChild("leaderstats", 15)
    if not leaderstats then return end
    local raised = leaderstats:WaitForChild("Raised", 15)
    if not raised then return end
    local lastValue = raised.Value
    raised:GetPropertyChangedSignal("Value"):Connect(function()
        local ok, newValue = pcall(function() return raised.Value end)
        if not ok or type(newValue) ~= "number" then return end
        if newValue > lastValue then
            -- Kick the local player to present the disconnect dialog (emulates the old UX), then start a persistent hop
            pcall(function()
                Rayfield:Notify({ Title = "Donation Received", Content = "Donation detected — kicking then hopping...", Duration = 5 })
            end)
            pcall(function() pl:Kick("Donation received! Server hopping...") end)
            task.wait(1.5)
            pcall(function() sendWebhookNotification(("@everyone 💰 Player %s received a donation! New total: %d"):format(tostring(pl.Name or "Unknown"), newValue)) end)
            pcall(function() if autoHopsEnabled then StartSzzePersistentHop(21, 23, true) end end)
        end
        lastValue = newValue
    end)
end)

-- Notify on UI execution
pcall(function()
    Rayfield:Notify({
        Title = "Matty's PLS DONATE Script",
        Content = "thanks for using matty's auto farm script — attempting to claim a booth now.",
        Duration = 10,
        BackgroundColor = customTheme.NotificationBackground
    })
end)

-- Ensure anti-lag is applied immediately on script execution (best-effort)
pcall(function() if applyAntiLag and typeof(applyAntiLag) == 'function' then applyAntiLag(true) end end)

-- Initial booth claim & walk: attempt immediately once character is available and on each respawn
task.spawn(function()
    local pl = Players.LocalPlayer
    if not pl then return end

    local function doClaimNow()
        local char = pl.Character or pl.CharacterAdded:Wait()
        pcall(claimAndTeleportToBooth)
    end

    doClaimNow()

    pl.CharacterAdded:Connect(function()
        doClaimNow()
    end)
end)

-- notify to webhook and UI on character join
local pl = Players.LocalPlayer
if pl then
    pl.CharacterAdded:Connect(function()
        notifyServerJoin()
    end)
    notifyServerJoin()
end


-- Donation listener: notifies UI + webhook and optionally sends auto-thank. defensive, no runtime errors.
pcall(function()
    local pl = Players.LocalPlayer
    if not pl then return end

    local leaderstats = pl:WaitForChild("leaderstats", 15)
    if not leaderstats then return end

    local raised = leaderstats:WaitForChild("Raised", 15)
    if not raised then return end

    local lastValue = raised.Value
    raised:GetPropertyChangedSignal("Value"):Connect(function()
        local ok, newValue = pcall(function() return raised.Value end)
        if not ok or type(newValue) ~= "number" then return end

        if newValue > lastValue then
            local delta = newValue - lastValue
            -- UI notification
            pcall(function()
                Rayfield:Notify({
                    Title = "Donation Received CONGRATS💰",
                    Content = ("Received %d  — Total: %d"):format(delta, newValue),
                    Duration = 6,
                    BackgroundColor = (customTheme and customTheme.NotificationBackground) or nil
                })
            end)

            -- Webhook notify (best-effort)
            pcall(function()
                if type(sendWebhookNotification) == "function" and webhookUrl and webhookUrl ~= "" then
                    sendWebhookNotification(("Player %s received a donation of %d. New total: %d"):format(tostring(pl.Name or "Unknown"), delta, newValue))
                end
            end)

            -- Auto-thank in chat if enabled
            if autoThank then
                pcall(function()
                    local channel = TextChatService and TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel and thankMessages and #thankMessages > 0 then
                        math.randomseed(tick() + tonumber(tostring(os.time()):sub(-6)))
                        channel:SendAsync(thankMessages[math.random(1, #thankMessages)])
                    end
                end)
            end
        end

        lastValue = newValue
    end)
end)

print("PLS DONATE SCRIPT BY 4rcxus.")
print("scam config loaded, happy scamming.")
print("CREATED THIS SCRIPT ALONE (: ")
-- ...existing code...