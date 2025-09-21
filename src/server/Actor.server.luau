local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules

local Actor = require(Modules.Actor)

local MAX_ACTORS = 3
local DEFAULT_MAX_TIME = 300
local DEFAULT_MUTATE_CHANCE = 0.001
local SLOW_WALK_SPEED = 3
local NORMAL_WALK_SPEED = 16

local TimeElapsedPerActor = {}




for i = 1, MAX_ACTORS do
    local uniqueKey = HttpService:GenerateGUID()

    local name = RunService:IsStudio() and "TestActor" or "Get Random Name"
    local mutation = "Get Random Mutation"
    local size = 1 -- TODO: Get Random Size
    local position = Vector3.new(5, 5, 5) -- TODO: Get Random Position
    local moveToPosition = Vector3.new(10, 5, 10) -- TODO:  Get Random Move To Position

    TimeElapsedPerActor[uniqueKey] = 0

    Actor.Spawn(uniqueKey, name, mutation, size, position, moveToPosition)
end




Players.PlayerAdded:Connect(function(player: Player)
    local currentActors = Actor.GetActors()
    Actor.Update:FireClient(player, currentActors)
end)

Actor.TriggeredPrompt.OnServerEvent:Connect(function(player: Player, uniqueKey: string)
    local humanoid = player.Character 
    and player.Character:FindFirstChild("Humanoid") :: Humanoid
    if humanoid then
        humanoid.WalkSpeed = SLOW_WALK_SPEED
        Actor.PickUp:FireAllClients(player.UserId, uniqueKey)
    end
end)

Actor.TouchedBase.OnServerEvent:Connect(function(player: Player, uniqueKey: string)
    local humanoid = player.Character 
    and player.Character:FindFirstChild("Humanoid") :: Humanoid
    if humanoid then
        humanoid.WalkSpeed = NORMAL_WALK_SPEED
        Actor.Drop:FireAllClients(uniqueKey)
    end
end)

RunService.PostSimulation:Connect(function(step: number)
    for uniqueKey, timeElapsed in TimeElapsedPerActor do
        if math.random() < DEFAULT_MUTATE_CHANCE then
            local mutation = ""
            Actor.Mutate(uniqueKey, mutation)
        end

        if timeElapsed >= DEFAULT_MAX_TIME then
            Actor.Despawn(uniqueKey)
        else
            TimeElapsedPerActor[uniqueKey] += step
        end
    end
end)
