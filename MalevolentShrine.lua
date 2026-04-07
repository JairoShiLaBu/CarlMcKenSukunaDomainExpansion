local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

-- CONFIGURATION
local SHRINE_FINAL_HEIGHT = 16 
local SHRINE_DEPTH_START = -100
local SHRINE_DISTANCE_BEHIND = 35
local BLOOD_POOL_SIZE = 4000

local originalSkillAnimId = 11365563255
local newExpansionAnimId = 18459220516
local blockedSoundId = "14762092682"
local shrineAssetId = 16639433873
local domainTriggered = false
local assetsLoaded = false

-- PRE-LOAD ASSETS
local shrineCache = nil
local expansionAnim = Instance.new("Animation")
expansionAnim.AnimationId = "rbxassetid://" .. newExpansionAnimId

task.spawn(function()
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. shrineAssetId)
    end)
    
    if success and objects[1] then
        shrineCache = objects[1]
        shrineCache.Name = "ShrineCache"
        shrineCache.Parent = game:GetService("ReplicatedStorage")
        if shrineCache:IsA("Model") then 
            shrineCache:PivotTo(CFrame.new(0, -5000, 0)) 
        end
        ContentProvider:PreloadAsync({expansionAnim, shrineCache})
        assetsLoaded = true
    end
end)

-- Sound Blocker
SoundService.DescendantAdded:Connect(function(sound)
    if sound:IsA("Sound") and (sound.SoundId:match(blockedSoundId) or sound.SoundId == "rbxassetid://" .. blockedSoundId) then
        sound.Volume = 0
        sound:Stop()
    end
end)

local originalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local function applyInstantLighting()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") or obj:IsA("Sky") then
            obj.Parent = nil
            task.delay(12, function() obj.Parent = Lighting end)
        end
    end

    Lighting.ClockTime = 0
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 0, 0)
    Lighting.FogStart = 0 
    Lighting.FogEnd = 350
    Lighting.FogColor = Color3.fromRGB(0, 0, 0)
    
    local domainAtmosphere = Instance.new("Atmosphere")
    domainAtmosphere.Name = "DomainAtmosphere"
    domainAtmosphere.Density = 0.9
    domainAtmosphere.Color = Color3.fromRGB(0, 0, 0)
    domainAtmosphere.Parent = Lighting
end

local function triggerDomain(animLength, customTrack)
    if domainTriggered or not shrineCache then return end
    domainTriggered = true
    
    -- 1. SOUND & LIGHTING
    local voice = Instance.new("Sound")
    voice.SoundId = "rbxassetid://6590147536"
    voice.Parent = SoundService
    voice.Volume = 10
    voice:Play()
    game:GetService("Debris"):AddItem(voice, 10)

    applyInstantLighting()

    local instancesToClean = {}
    local atmosphere = Lighting:FindFirstChild("DomainAtmosphere")
    if atmosphere then table.insert(instancesToClean, atmosphere) end

    -- 2. SHRINE SPAWN & RISE
    local weldPart = Instance.new("Part")
    weldPart.Size = Vector3.new(1, 1, 1)
    weldPart.Transparency = 1
    weldPart.Anchored = true
    weldPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_DEPTH_START, SHRINE_DISTANCE_BEHIND)
    weldPart.Parent = workspace
    table.insert(instancesToClean, weldPart)

    local loadedObject = shrineCache:Clone()
    loadedObject.Parent = workspace
    table.insert(instancesToClean, loadedObject)
    
    local targetModel = (loadedObject:IsA("Model") and loadedObject) or loadedObject:FindFirstChildWhichIsA("Model")
    if targetModel then
        for _, p in ipairs(targetModel:GetDescendants()) do 
            if p:IsA("BasePart") then p.Anchored = false p.CanCollide = false end 
        end
        targetModel:PivotTo(weldPart.CFrame)
        
        local mainPart = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
        if mainPart then
            local weld = Instance.new("WeldConstraint", mainPart)
            weld.Part0 = mainPart; weld.Part1 = weldPart
        end
        
        -- Start rise immediately to ensure it's there when camera snaps
        TweenService:Create(weldPart, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_FINAL_HEIGHT, SHRINE_DISTANCE_BEHIND)
        }):Play()
    end

    -- 3. BLOOD POOL
    local bloodFloor = Instance.new("Part")
    bloodFloor.Size = Vector3.new(BLOOD_POOL_SIZE, 1, BLOOD_POOL_SIZE)
    bloodFloor.Position = humanoidRootPart.Position + Vector3.new(0, -1, 0)
    bloodFloor.Anchored = true
    bloodFloor.CanCollide = false
    bloodFloor.Color = Color3.fromRGB(30, 0, 0)
    bloodFloor.Material = Enum.Material.Ice
    bloodFloor.Parent = workspace
    table.insert(instancesToClean, bloodFloor)

    -- 4. CAMERA SEQUENCE
    camera.CameraType = Enum.CameraType.Scriptable
    local head = character:WaitForChild("Head")
    camera.CFrame = head.CFrame * CFrame.new(0, 0.5, -9) * CFrame.Angles(0, math.pi, 0)

    TweenService:Create(camera, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = head.CFrame * CFrame.new(0, 0.5, -5.5) * CFrame.Angles(0, math.pi, 0)
    }):Play()

    task.delay(2.8, function()
        local behindPos = humanoidRootPart.CFrame * CFrame.new(0, 6, 15) 
        camera.CFrame = CFrame.new(behindPos.Position, humanoidRootPart.Position + (humanoidRootPart.CFrame.LookVector * 100))
        
        TweenService:Create(camera, TweenInfo.new(animLength - 2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            CFrame = camera.CFrame * CFrame.new(0, 2, 10)
        }):Play()
    end)

    -- 5. CLEANUP
    task.delay(animLength, function()
        camera.CameraType = Enum.CameraType.Custom
        customTrack:Stop(1.5)
        
        if weldPart then
            TweenService:Create(weldPart, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_DEPTH_START, SHRINE_DISTANCE_BEHIND)
            }):Play()
        end
        
        if bloodFloor then
            TweenService:Create(bloodFloor, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = bloodFloor.Position + Vector3.new(0, -20, 0),
                Transparency = 1
            }):Play()
        end
        
        TweenService:Create(Lighting, TweenInfo.new(2.5), originalLighting):Play()
        
        task.delay(3.2, function()
            for _, instance in ipairs(instancesToClean) do
                if instance then instance:Destroy() end
            end
            domainTriggered = false
        end)
    end)
end

humanoid.AnimationPlayed:Connect(function(animationTrack)
    local assetId = tonumber(animationTrack.Animation.AnimationId:match("%d+"))
    if assetId == originalSkillAnimId then
        while not assetsLoaded do task.wait(0.1) end
        local originalLen = animationTrack.Length
        animationTrack:Stop(0)
        local newTrack = humanoid:LoadAnimation(expansionAnim)
        newTrack:Play()
        triggerDomain(originalLen, newTrack)
    end
end)
