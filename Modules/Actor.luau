local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DEFAULT_STATE = "Idle"

local Actor = {}

local Actors: {[string]: {[string]: any}} = {}




function Actor.Spawn(
    uniqueKey: string, 
    name: string, 
    mutation: string, 
    size: Vector3 | number,
    position: Vector3,
    moveToPosition: Vector3,
    state: string | nil)

    local data = {}

    data.name = name
    data.mutation = mutation
    data.size = size
    data.position = position
    data.moveToPosition = moveToPosition
    data.state = state or DEFAULT_STATE

    Actors[uniqueKey] = data

    Actor.Update:FireAllClients(Actors)
end

function Actor.Despawn(uniqueKey: string)
    if not Actors[uniqueKey] then
        return
    end

    Actors[uniqueKey] = nil

    Actor.Update:FireAllClients(Actors)
end

function Actor.Mutate(uniqueKey: string, mutation: string)
    if not Actors[uniqueKey] then
        return
    end

    Actors[uniqueKey].mutation = mutation

    Actor.Update:FireAllClients(Actors)
end

function Actor.GetActors()
    return Actors or {}
end




Actor.Update = nil
Actor.PickUp = nil
Actor.DropActor = nil
Actor.TriggeredPrompt = nil

if RunService:IsServer() then
    -- on client events
    Actor.Update = Instance.new("RemoteEvent", ReplicatedStorage)
    Actor.Update.Name = "Update"
    Actor.PickUp = Instance.new("RemoteEvent", ReplicatedStorage)
    Actor.PickUp.Name = "PickUp"
    Actor.Drop = Instance.new("RemoteEvent", ReplicatedStorage)
    Actor.Drop.Name = "Drop"

    -- on server events
    Actor.TriggeredPrompt = Instance.new("RemoteEvent", ReplicatedStorage)
    Actor.TriggeredPrompt.Name = "TriggeredPrompt"
    Actor.TouchedBase = Instance.new("RemoteEvent", ReplicatedStorage)
    Actor.TouchedBase.Name = "TouchedBase"
elseif RunService:IsClient() then
    Actor.OnUpdate = ReplicatedStorage:WaitForChild("Update").OnClientEvent
    Actor.OnPickUp = ReplicatedStorage:WaitForChild("PickUp").OnClientEvent
    Actor.OnDrop = ReplicatedStorage:WaitForChild("Drop").OnClientEvent

    Actor.TriggeredPrompt = ReplicatedStorage:WaitForChild("TriggeredPrompt")
    Actor.TouchedBase = ReplicatedStorage:WaitForChild("TouchedBase")
end




return Actor