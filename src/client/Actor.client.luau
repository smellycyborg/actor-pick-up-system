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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Actors = {}
local ActorsPickedUp = {}
local SpawnInfoPerActor = {}




local ActorClonesWorkspace = Instance.new("Folder", Workspace)
ActorClonesWorkspace.Name = "ActorClonesWorkspace"
local ActorClonesReplicated = Instance.new("Folder", Workspace)
ActorClonesReplicated.Name = "ActorClonesReplicated"

local ActorBillboards = Instance.new("ScreenGui", playerGui)
ActorBillboards.Name = "ActorBillboards"




local function addActor(uniqueKey: string, data: {[string]: any})
    local actorModel = ActorClonesReplicated:FindFirstChild(data.name) :: Model
    if not actorModel then
        error(`Actor model {data.name} does not exist in ActorModels`)
    end

    actorModel.Name = uniqueKey
    actorModel:ScaleTo(data.size)
    actorModel:PivotTo(CFrame.new(data.position))

    local prompt = Instance.new("ProximityPrompt")
    prompt.Triggered:Connect(function(playerTriggered: Player)
        prompt.Enabled = false

        ActorsPickedUp[uniqueKey] = playerTriggered.UserId
    end)
    prompt.Parent = actorModel.PrimaryPart

    actorModel.Parent = ActorClonesWorkspace

    Animation.LoadCharacter(actorModel, uniqueKey)

    local billboard = ActorBillboards:FindFirstChild("ActorBillboard")
    billboard.Name = uniqueKey
    billboard.Adornee = actorModel.PrimaryPart
    billboard.Enabled = true

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



Actor.OnDropActor:Connect(function(uniqueKey: string)
    if ActorsPickedUp[uniqueKey] then
        ActorsPickedUp[uniqueKey] = nil

        local actorModel = ActorClonesWorkspace:FindFirstChild(uniqueKey)
        if not actorModel then
            return
        end

        actorModel.PrimaryPart.Anchored = false

        local prompt = actorModel:FindFirstChild("ProximityPrompt", true)
        if prompt then
            prompt.Enabled = true
        end

        -- TODO: delay/ set new move to position/ state 
    end
end)

Actor.OnUpdateActors:Connect(function(currentActors: any)  
    for uniqueKey, data in Actors do
        local currentData = currentActors[uniqueKey]
        if not currentData then
            removeActor(uniqueKey)
        else
            local actorModel = ActorClonesWorkspace:FindFirstChild(uniqueKey)
            if not actorModel then
                addActor(uniqueKey, data)
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

            -- TODO:  Update billboard depsawn time
        end
    end

    for actorKey, userId in ActorsPickedUp do
        local otherPlayer = Players:GetPlayerByUserId(userId)
        if not otherPlayer then
            continue
        end
        local rootPart = otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            continue
        end
        local actorModel = ActorClonesWorkspace:FindFirstChild(actorKey)
        if not actorModel then
            continue
        end

        local newCFrame = rootPart.CFrame -- TODO: get the offset cframe

        if actorModel.PrimaryPart.Anchored ~= true then
            actorModel.PrimaryPart.Anchored = true
        end

        actorModel:PivotTo(newCFrame)
    end
end)
