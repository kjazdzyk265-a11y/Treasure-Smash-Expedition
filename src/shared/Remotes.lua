local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.GetFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function Remotes.GetOrCreate(name: string): RemoteEvent
    local folder = Remotes.GetFolder()
    local remote = folder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
    end
    return remote :: RemoteEvent
end

return Remotes
