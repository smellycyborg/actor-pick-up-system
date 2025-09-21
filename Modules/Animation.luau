local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = ReplicatedStorage:WaitForChild("Animations")

local Animation = {}

local AnimationsPerCharacter = {}

local dontRepeats = {}

function Animation.LoadCharacter(character: Model, uniqueKey: string)
    if not character:IsA("Model") then
        return
    end

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator", humanoid)
    end

    if not AnimationsPerCharacter[uniqueKey] then
        AnimationsPerCharacter[uniqueKey] = {}
    end

    for _, animation: Animation in Animations:GetChildren() do
        if animation:IsA("Animation") then
            local track = animator:LoadAnimation(animation)
            AnimationsPerCharacter[uniqueKey][animation.Name] = track

            track.Stopped:Connect(function()
                
            end)
        end
    end
end




Animation.PlayAnimation = Instance.new("BindableEvent", ReplicatedStorage)
Animation.OnPlayAnimation = Animation.PlayAnimation.Event
Animation.StopAnimations = Instance.new("BindableEvent", ReplicatedStorage)
Animation.OnStopAnimations = Animation.StopAnimations.Event




Animation.OnPlayAnimation:Connect(function(animationName: string, uniqueKey: string)
    local shouldRepeat = true
    if table.find(dontRepeats, animationName) then
        shouldRepeat = false
    end

    for name, anim in AnimationsPerCharacter[uniqueKey] do
        anim:stop()
    end
    
    local animation = AnimationsPerCharacter[uniqueKey][animationName]
    animation:play(shouldRepeat)
end)

Animation.OnStopAnimations:Connect(function(uniqueKey: string)  
    for name, anim in AnimationsPerCharacter[uniqueKey] do
        anim:stop()
    end
end)

return Animation