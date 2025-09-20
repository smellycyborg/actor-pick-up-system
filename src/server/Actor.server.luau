local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules

local Actor = require(Modules.Actor)

local DEFAULT_MAX_TIME = 300
local DEFAULT_MUTATE_CHANCE = 0.1

local TimeElapsedPerActor = {}

RunService.PostSimulation:Connect(function(step: number)
    for uniqueKey, timeElapsed in Actor.GetActors() do
        if not TimeElapsedPerActor[uniqueKey] then
            TimeElapsedPerActor[uniqueKey] = 0
        end

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
