local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local originalSkillAnimId = 11365563255
local newExpansionAnimId = 18459220516
local domainTriggered = false

local originalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local function fadeLighting(targetSettings, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(Lighting, tweenInfo, targetSettings):Play()
end

local function applyDomainLighting()
    fadeLighting({
        ClockTime = 0,
        Brightness = 2,
        OutdoorAmbient = Color3.fromRGB(150, 0, 0),
        FogStart = 150,
        FogEnd = 600,
        FogColor = Color3.fromRGB(0, 0, 0)
    }, 0.5)
    
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    TweenService:Create(atmosphere, TweenInfo.new(0.5), {Density = 0.65, Offset = 0.5}):Play()
end

local function spawnPathLights()
    local startPos = humanoidRootPart.Position
    local forwardDir = humanoidRootPart.CFrame.LookVector
    local lights = {}
    
    for i = 1, 6 do
        local lightPart = Instance.new("Part")
        lightPart.Size = Vector3.new(1,1,1)
        lightPart.Transparency = 1
        lightPart.CanCollide = false
        lightPart.Anchored = true
        lightPart.Position = startPos + (forwardDir * (i * 80)) + Vector3.new(0, 15, 0)
        lightPart.Parent = workspace
        table.insert(lights, lightPart)
        
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 0, 0)
        light.Range = 120
        light.Brightness = 4
        light.Shadows = false
        light.Parent = lightPart
    end
    return lights
end

local function cleanupDomain(duration, instancesToClean, weldPart, customTrack)
    if customTrack then customTrack:Stop(duration) end
    fadeLighting(originalLighting, duration)
    
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        TweenService:Create(atmosphere, TweenInfo.new(duration), {Density = 0}):Play()
    end

    if weldPart then
        local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, -60, 20)
        local tweenDown = TweenService:Create(weldPart, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {CFrame = targetCFrame})
        tweenDown:Play()
    end

    task.delay(duration, function()
        for _, instance in ipairs(instancesToClean) do
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
        domainTriggered = false
    end)
end

local function triggerDomain(animLength, customTrack)
    if domainTriggered then return end
    domainTriggered = true

    local voice = Instance.new("Sound")
    voice.SoundId = "rbxassetid://6590147536"
    voice.Parent = game:GetService("SoundService")
    voice.Volume = 3
    voice:Play()
    voice.Ended:Connect(function() voice:Destroy() end)

    local instancesToClean = {}

    local bloodFloor = Instance.new("Part")
    bloodFloor.Name = "BloodPool"
    bloodFloor.Size = Vector3.new(3000, 1, 3000)
    bloodFloor.Position = humanoidRootPart.Position + Vector3.new(0, -1, 0)
    bloodFloor.Anchored = true
    bloodFloor.CanCollide = true
    bloodFloor.Color = Color3.fromRGB(70, 0, 0)
    bloodFloor.Material = Enum.Material.Ice
    bloodFloor.Reflectance = 0.25
    bloodFloor.Parent = workspace
    table.insert(instancesToClean, bloodFloor)

    local spotLight = Instance.new("SpotLight")
    spotLight.Brightness = 15
    spotLight.Angle = 90
    spotLight.Range = 300
    spotLight.Color = Color3.fromRGB(255, 0, 0)
    spotLight.Parent = humanoidRootPart
    table.insert(instancesToClean, spotLight)

    applyDomainLighting()
    
    local pathLights = spawnPathLights()
    for _, light in ipairs(pathLights) do
        table.insert(instancesToClean, light)
    end

    local weldPart = Instance.new("Part")
    weldPart.Name = "MovementAnchor"
    weldPart.Size = Vector3.new(1, 1, 1)
    weldPart.Transparency = 1
    weldPart.CanCollide = false
    weldPart.Anchored = true
    weldPart.Parent = character
    weldPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -60, 20)
    table.insert(instancesToClean, weldPart)

    local modelId = 16639433873
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. modelId)
    end)

    if success and objects[1] then
        local loadedObject = objects[1]
        loadedObject.Parent = workspace
        
        local targetModel = loadedObject:IsA("Model") and loadedObject or loadedObject:FindFirstChildWhichIsA("Model") or loadedObject
        table.insert(instancesToClean, loadedObject)

        if targetModel then
            local mainPart = targetModel:IsA("BasePart") and targetModel or targetModel:FindFirstChild("Main") or targetModel.PrimaryPart
            
            if not mainPart and targetModel:IsA("Model") then
                mainPart = targetModel:FindFirstChildWhichIsA("BasePart")
                targetModel.PrimaryPart = mainPart
            end

            if mainPart then
                for _, part in ipairs(targetModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                        part.CanCollide = false
                    end
                end

                if targetModel:IsA("Model") then
                    targetModel:SetPrimaryPartCFrame(weldPart.CFrame)
                else
                    targetModel.CFrame = weldPart.CFrame
                end

                local weld = Instance.new("WeldConstraint")
                weld.Part0 = mainPart
                weld.Part1 = weldPart
                weld.Parent = mainPart

                local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, 10.5, 20)
                TweenService:Create(weldPart, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = targetCFrame}):Play()
            end
        end
    end

    task.delay(animLength, function()
        cleanupDomain(2, instancesToClean, weldPart, customTrack)
    end)
end

humanoid.AnimationPlayed:Connect(function(animationTrack)
    local assetId = tonumber(animationTrack.Animation.AnimationId:match("%d+"))
    
    if assetId == originalSkillAnimId then
        local duration = animationTrack.Length
        animationTrack:Stop(0)
        
        local newAnim = Instance.new("Animation")
        newAnim.AnimationId = "rbxassetid://" .. newExpansionAnimId
        local newTrack = humanoid:LoadAnimation(newAnim)
        newTrack:Play()
        
        triggerDomain(duration, newTrack)
    end
end)
