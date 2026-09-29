--[[
    ABSTRACTED CORE ENGINE (Part 1)
    Bulletproof utility, tweening, and tracking engine.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Engine = {
    Version = "1.1.0-Engine",
    Connections = {},
    Themes = {
        Default = { 
            Bg = Color3.fromRGB(20, 20, 20), Topbar = Color3.fromRGB(30, 30, 30), 
            TabBg = Color3.fromRGB(40, 40, 40), Accent = Color3.fromRGB(90, 130, 255), 
            Text = Color3.fromRGB(255, 255, 255), TextDark = Color3.fromRGB(150, 150, 150), 
            ElementBg = Color3.fromRGB(25, 25, 25), Hover = Color3.fromRGB(35, 35, 35)
        }
    }
}

function Engine.Tween(inst, props, dur)
    if not inst or not inst.Parent then return end
    local tw = TweenService:Create(inst, TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

function Engine.Create(cls, props, children)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    return inst
end

function Engine.Connect(sig, cb)
    local conn = sig:Connect(cb)
    table.insert(Engine.Connections, conn)
    return conn
end

function Engine.GetSafeParent()
    if type(gethui) == "function" then 
        local success, hui = pcall(gethui)
        if success and hui then return hui end
    end
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        local canWrite = pcall(function() local test = Instance.new("Folder", coreGui); test:Destroy() end)
        if canWrite then return coreGui end
    end
    local player = Players.LocalPlayer
    while not player do task.wait(); player = Players.LocalPlayer end
    return player:WaitForChild("PlayerGui")
end

function Engine.ApplyTooltip(inst, textData, win)
    if not textData or not win or not win.Tooltip then return end
    local isHovered = false
    
    Engine.Connect(inst.MouseEnter, function()
        isHovered = true
        win.Tooltip.Label.Text = "..."
        win.Tooltip.Size = UDim2.new(0, 40, 0, 25)
        
        task.spawn(function()
            local text = type(textData) == "function" and textData() or textData
            if isHovered and win.Tooltip then
                win.Tooltip.Label.Text = text
                local bounds = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(300, 100))
                win.Tooltip.Size = UDim2.new(0, bounds.X + 20, 0, bounds.Y + 10)
            end
        end)
        
        task.spawn(function()
            task.wait(0.2)
            if isHovered and win.Tooltip and not win.IsMinimized then
                win.Tooltip.Visible = true
            end
        end)
        
        while isHovered and win.Tooltip do
            local ms = UserInputService:GetMouseLocation()
            if win.Container and win.Container.Parent then
                win.Tooltip.Position = UDim2.new(0, math.clamp(ms.X + 15, 0, win.Container.AbsoluteSize.X - win.Tooltip.Size.X.Offset), 0, ms.Y + 15)
            end
            RunService.RenderStepped:Wait()
        end
    end)
    
    Engine.Connect(inst.MouseLeave, function() 
        isHovered = false
        if win.Tooltip then win.Tooltip.Visible = false end
    end)
end

function Engine.ApplyTag(parent, tagText, rightOffset, topOffset)
    if not tagText then return end
    Engine.Create("Frame", { Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(1, -(rightOffset or 10), topOffset and 0 or 0.5, topOffset or -9), AnchorPoint = Vector2.new(1, topOffset and 0 or 0), BackgroundColor3 = Engine.Themes.Default.Accent, Parent = parent }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
        Engine.Create("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = tagText, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1,1,1), TextYAlignment = Enum.TextYAlignment.Center })
    })
end

return Engine
