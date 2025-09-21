local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ActorModels = ReplicatedStorage:WaitForChild("ActorModels")
local Billboards = ReplicatedStorage:WaitForChild("Billboards")

local Actor = require(Modules:WaitForChild("Actor"))
local Animation = require(Modules:WaitForChild("Animation"))

local OBJECT_AMOUNT = 30
local MAX_ACTOR_BILLBOARDS = 30
local ACTOR_MODELS_AMOUNT = 1
local DEFAULT_DESPAWN_TIME = 300
local SPAWN_ANIMATION_TIME = 6

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BaseParts = Workspace:WaitForChild("BaseParts")

local Actors = {}
local ActorsPickedUp = {}
local SpawnInfoPerActor = {}



local filterTab = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local ActorClonesWorkspace = Instance.new("Folder", Workspace)
ActorClonesWorkspace.Name = "ActorClonesWorkspace"
local ActorClonesReplicated = Instance.new("Folder", ReplicatedStorage)
ActorClonesReplicated.Name = "ActorClonesReplicated"

local ActorBillboards = Instance.new("ScreenGui", playerGui)
ActorBillboards.Name = "ActorBillboards"


local function setBillboardText(billboard, data)
    for nameKey, value in data do
        for _, element: TextLabel in billboard:GetDescendants() do
            if not element:IsA("TextLabel") then
                continue
            end
            if string.find(string.lower(element.Name), nameKey) then
                element.Text = value
            elseif element.Name == "TimeLeftLabel" then
                element.Text = DEFAULT_DESPAWN_TIME
            end
        end
    end
end

local function addActor(uniqueKey: string, data: {[string]: any})
    local actorModel = ActorClonesReplicated:FindFirstChild(data.name) :: Model
    if not actorModel then
        warn(`Actor model {data.name} does not exist in ActorModels`)
        return
    end

    actorModel.Name = uniqueKey
    actorModel:ScaleTo(data.size)
    actorModel:PivotTo(CFrame.new(data.position))

    local prompt = Instance.new("ProximityPrompt")
    prompt.RequiresLineOfSight = false
    prompt.Triggered:Connect(function(playerTriggered: Player)
        if playerTriggered == player then
            Actor.TriggeredPrompt:FireServer(uniqueKey)
        end
    end)
    prompt.Parent = actorModel.PrimaryPart

    actorModel.Parent = ActorClonesWorkspace

    Animation.LoadCharacter(actorModel, uniqueKey)
    Animation.PlayAnimation:Fire(data.state, uniqueKey)

    local billboard = ActorBillboards:FindFirstChild("ActorBillboard")
    billboard.Name = uniqueKey
    billboard.Adornee = actorModel.PrimaryPart
    billboard.Enabled = true

    setBillboardText(billboard, data)

    local actorHumanoid = actorModel:FindFirstChild("Humanoid", true) :: Humanoid
    if not actorHumanoid then
        return
    end
    actorHumanoid:MoveTo(data.moveToPosition)
end

local function removeActor(uniqueKey: string)
    local foundBillboard = ActorBillboards:FindFirstChild(uniqueKey)
    if foundBillboard then
        foundBillboard.Enabled = false
        foundBillboard.Name = "ActorBillboard"
        foundBillboard.Adornee = nil
    end
    
    local foundActor = ActorClonesWorkspace:FindFirstChild(uniqueKey)
    if foundActor then
        foundActor.Parent = ActorClonesReplicated
        foundActor.Name = Actors[uniqueKey].name
    end

    Actors[uniqueKey] = nil
end

local function dropActor(uniqueKey: string)
    if ActorsPickedUp[uniqueKey] then
        ActorsPickedUp[uniqueKey] = nil

        local actorModel = ActorClonesWorkspace:FindFirstChild(uniqueKey)
        if not actorModel then
            return
        end

        actorModel.PrimaryPart.Anchored = false

        local prompt = actorModel:FindFirstChild("ProximityPrompt", true)
        prompt.RequiresLineOfSight = false
        prompt.Enabled = true

        -- TODO: delay/ set new move to position/ state 
    end
end




task.spawn(function()
    local timeElapsed = 0
    repeat
        timeElapsed += 1/60

        RunService.PreRender:Wait()
    until #ActorModels:GetChildren() >= ACTOR_MODELS_AMOUNT
    or timeElapsed >= 10

    for _, model in ActorModels do
        for i = 1, OBJECT_AMOUNT do
            local clone = model:Clone()
            clone.Parent = ActorClonesReplicated
        end
    end
end)

for i = 1, MAX_ACTOR_BILLBOARDS do
    local clone = Billboards:WaitForChild("ActorBillboard")
    clone.Enabled = false
    clone.Parent = ActorBillboards
end



Players.PlayerRemoving:Connect(function(otherPlayer: Player)
    for actorKey, userId in ActorsPickedUp do
        if userId == otherPlayer.UserId then
            dropActor(actorKey)
            break
        end
    end
end)

    if ActorsPickedUp[uniqueKey] then
        ActorsPickedUp[uniqueKey] = nil

        local actorModel = ActorClonesWorkspace:FindFirstChild(uniqueKey)
        if not actorModel then
            return
        end

        actorModel.PrimaryPart.Anchored = false


Actor.OnDrop:Connect(function(uniqueKey: string)
    dropActor(uniqueKey)
end)

Actor.OnUpdate:Connect(function(currentActors: any)
    if not next(Actors) then
        Actors = currentActors
    end

    for uniqueKey, data in Actors do
        local currentData = currentActors[uniqueKey]
        if not currentData then
            removeActor(uniqueKey)
        else
            local actorModel = ActorClonesWorkspace:FindFirstChild(uniqueKey)
            if not actorModel 
            and not Actors[uniqueKey].spawning then
                Actors[uniqueKey].spawning = true

                task.delay(SPAWN_ANIMATION_TIME, function()
                    addActor(uniqueKey, data)
                end)

                RunService.PreRender:Wait()
            else
                if data.moveToPosition ~= currentData.moveToPosition then
                    local actorHumanoid = actorModel:FindFirstChild("Humanoid", true) :: Humanoid
                    if not actorHumanoid then
                        continue
                    end
                    actorHumanoid:MoveTo(currentData.moveToPosition)
                end
            end
        end
    end
    Actors = currentActors
end)

RunService.PreSimulation:Connect(function(step: number)
    for actorKey, data in SpawnInfoPerActor do
        if data.timeLeft <= 0 then
            -- TODO: Make label say despawn or whatever
            continue
        end

        SpawnInfoPerActor[actorKey].timeElapsed += step
        if SpawnInfoPerActor[actorKey].timeElapsed >= 1 then
            SpawnInfoPerActor[actorKey].timeElapsed = 0

            SpawnInfoPerActor[actorKey].timeLeft -= 1

            local actorBillboard = ActorBillboards:FindFirstChild(actorKey)
            if actorBillboard then
                setBillboardText(actorBillboard, data)
            end
        end
    end

    for actorKey, userId in ActorsPickedUp do
        local otherPlayer = Players:GetPlayerByUserId(userId)
        if not otherPlayer then
            continue
        end
        local rootPart = otherPlayer.Character 
        and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            continue
        end
        local actorModel = ActorClonesWorkspace:FindFirstChild(actorKey)
        if not actorModel then
            continue
        else
            for _, part in actorModel:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end

        local newCFrame = rootPart.CFrame -- TODO: get the offset cframe

        if actorModel.PrimaryPart.Anchored ~= true then
            actorModel.PrimaryPart.Anchored = true
        end

        actorModel:PivotTo(newCFrame)

        if rootPart then
            local raycastResult = Workspace:Raycast(rootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -1, 0) * 100, raycastParams)
            if raycastResult 
            and raycastResult.Instance.Name == ("Base") then
                Actor.TouchedBase:FireServer(actorKey)
            end
        end
    end
end)