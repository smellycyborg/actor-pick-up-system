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
    local name = "Get Random Name"
    local mutation = "Get Random Mutation"
    local size = "Get Random Size"
    local position = "Get Random Position"

    Actor.Spawn(uniqueKey, name, mutation, size, position)
end




Players.PlayerAdded:Connect(function(player: Player)  
    Actor.UpdateActors:FireClient(player, Actor.GetActors())
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
