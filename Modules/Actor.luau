local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_STATE = "Idle"

local Actor = {}

local Actors: {[string]: {[string]: any}} = {}

function Actor.Spawn(
    uniqueKey: string, 
    name: string, 
    mutation: string, 
    size: Vector3 | number,
    position: Vector3,
    state: string | nil)

    local data = {}

    data.name = name
    data.mutation = mutation
    data.size = size
    data.position = position
    data.state = state or DEFAULT_STATE

    Actors[uniqueKey] = data

    Actor.UpdateActors:FireAllClients(Actors)
end

function Actor.Despawn(uniqueKey: string)
    if not Actors[uniqueKey] then
        return
    end

    Actors[uniqueKey] = nil

    Actor.UpdateActors:FireAllClients(Actors)
end

function Actor.Mutate(uniqueKey: string, mutation: string)
    if not Actors[uniqueKey] then
        return
    end

    Actors[uniqueKey].mutation = mutation

    Actor.UpdateActors:FireAllClients(Actors)
end

function Actor.GetActors()
    return Actors or {}
end

Actor.UpdateActors = Instance.new("RemoteEvent", ReplicatedStorage)
Actor.OnUpdateActors = Actor.UpdateActors.OnClientEvent
Actor.DropActor = Instance.new("RemoteEvent", ReplicatedStorage)
Actor.OnDropActor = Actor.UpdateActors.OnClientEvent
Actor.TriggeredPrompt = Instance.new("RemoteEvent", ReplicatedStorage)
Actor.OnTriggeredPrompt = Actor.TriggeredPrompt.OnServerEvent

return Actor