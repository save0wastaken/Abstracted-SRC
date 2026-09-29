--[[
    ABSTRACTED FRAMEWORK API (Part 2)
]]

local Engine = loadstring(game:HttpGet("https://raw.githubusercontent.com/save0wastaken/Abstracted-SRC/main/AbstractedEngine.lua"))()

local Theme = Engine.Themes.Default
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Abstracted = {
    Version = "8.3.0-Framework",
    Elements = {}, 
    LocalizedObjects = {}, 
    CurrentLocale = "en",
    TranslationCache = {} 
}

local Window = {}; Window.__index = Window
local TabMethods = {}; TabMethods.__index = TabMethods
local SectionMethods = {}; SectionMethods.__index = SectionMethods

function Abstracted:UpdateLocalizedObject(obj)
    local data = self.LocalizedObjects[obj]
    if not data or not data.Key or data.Key == "" then return end
    
    local lang = self.CurrentLocale
    if lang == "en" then
        if data.Updater then data.Updater(data.Key)
        else
            if obj:IsA("TextBox") then obj.PlaceholderText = data.Key
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.Text = data.Key end
        end
        return
    end
    
    local cacheKey = lang .. "_" .. data.Key
    if self.TranslationCache[cacheKey] then
        if data.Updater then data.Updater(self.TranslationCache[cacheKey])
        else
            if obj:IsA("TextBox") then obj.PlaceholderText = self.TranslationCache[cacheKey]
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.Text = self.TranslationCache[cacheKey] end
        end
        return
    end
    
    task.spawn(function()
        local safeText = HttpService:UrlEncode(data.Key)
        local url = string.format("https://api.mymemory.translated.net/get?q=%s&langpair=en|%s", safeText, lang)
        
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success then
            local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(response) end)
            if decodeSuccess and decoded and decoded.responseData and decoded.responseData.translatedText then
                local translatedText = decoded.responseData.translatedText
                self.TranslationCache[cacheKey] = translatedText
                
                if obj and obj.Parent then
                    if data.Updater then data.Updater(translatedText)
                    else
                        if obj:IsA("TextBox") then obj.PlaceholderText = translatedText
                        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.Text = translatedText end
                    end
                end
            end
        end
    end)
end

function Abstracted:RegisterLoc(obj, key, customUpdater)
    if not obj or not key then return end
    self.LocalizedObjects[obj] = { Key = key, Updater = customUpdater }
    self:UpdateLocalizedObject(obj)
end

function Abstracted:SetLocale(lang)
    self.CurrentLocale = lang
    for obj, _ in pairs(self.LocalizedObjects) do
        if obj and obj.Parent then
            self:UpdateLocalizedObject(obj)
        end
    end
end

function Abstracted:GetLocAsync(key)
    if not key or key == "" then return "" end
    if self.CurrentLocale == "en" then return key end
    
    local cacheKey = self.CurrentLocale .. "_" .. key
    if self.TranslationCache[cacheKey] then return self.TranslationCache[cacheKey] end
    
    local safeText = HttpService:UrlEncode(key)
    local url = string.format("https://api.mymemory.translated.net/get?q=%s&langpair=en|%s", safeText, self.CurrentLocale)
    
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success then
        local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and decoded and decoded.responseData and decoded.responseData.translatedText then
            local translatedText = decoded.responseData.translatedText
            self.TranslationCache[cacheKey] = translatedText
            return translatedText
        end
    end
    return key
end

function Abstracted:CreateWindow(cfg)
    local self = setmetatable({ Tabs = {}, Settings = cfg, IsMinimized = false }, Window)
    Abstracted.CurrentWindow = self
    local parent = Engine.GetSafeParent()
    
    for _, ui in ipairs(parent:GetChildren()) do if ui.Name == "AbstractedPremium" then ui:Destroy() end end
    self.Container = Engine.Create("ScreenGui", { 
        Name = "AbstractedPremium", 
        Parent = parent, 
        ResetOnSpawn = false, 
        DisplayOrder = 999, 
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Fixes GUI layer overlap bugs
    })
    
    local loader = Engine.Create("Frame", { Size = UDim2.new(0, 280, 0, 90), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Theme.Bg, Parent = self.Container, ClipsDescendants = true }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Engine.Create("UIStroke", { Color = Theme.Topbar, Thickness = 2 }),
        Engine.Create("TextLabel", { Name = "Txt", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center }),
        Engine.Create("Frame", { Name = "BarContainer", Size = UDim2.new(1, -40, 0, 6), Position = UDim2.new(0, 20, 0, 60), BackgroundColor3 = Theme.ElementBg }, {
            Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Engine.Create("Frame", { Name = "Bar", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        })
    })
    Abstracted:RegisterLoc(loader.Txt, "Mounting Environment...")
    
    self.Watermark = Engine.Create("Frame", { Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Theme.Topbar, Parent = self.Container }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
        Engine.Create("TextLabel", { Name = "Data", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left })
    })
    
    local frames = 0
    Engine.Connect(game:GetService("RunService").RenderStepped, function() frames = frames + 1 end)
    task.spawn(function()
        while task.wait(1) do
            if not self.Watermark or not self.Watermark.Parent then break end
            local player = Players.LocalPlayer
            local ping = player and math.floor(player:GetNetworkPing() * 1000) or 0
            self.Watermark.Data.Text = string.format("%s | Powered by Abstract | FPS: %d | Ping: %dms", self.Settings.Title or "Framework", frames, ping)
            frames = 0
        end
    end)
    
    self.Main = Engine.Create("CanvasGroup", { Size = UDim2.new(0, 650, 0, 450), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Theme.Bg, GroupTransparency = 1, Parent = self.Container, ClipsDescendants = true, Active = true, Visible = false }, {
        Engine.Create("UICorner", { Name = "Corner", CornerRadius = UDim.new(0, 8) }),
        Engine.Create("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Topbar, ClipsDescendants = true }, {
            Engine.Create("UICorner", { Name = "Corner", CornerRadius = UDim.new(0, 8) }),
            Engine.Create("TextLabel", { Name = "Title", Size = UDim2.new(0, 200, 0, 25), Position = UDim2.new(0, 15, 0, 12), BackgroundTransparency = 1, Text = cfg.Title or "Abstracted", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left }),
            Engine.Create("TextBox", { Name = "Search", Size = UDim2.new(0, 150, 0, 26), Position = UDim2.new(1, -230, 0, 12), BackgroundColor3 = Theme.ElementBg, Text = "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
            Engine.Create("TextButton", { Name = "Minimize", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -70, 0, 10), BackgroundTransparency = 1, Text = "-", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Theme.TextDark }),
            Engine.Create("TextButton", { Name = "Close", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -35, 0, 10), BackgroundTransparency = 1, Text = "X", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextDark }),
            Engine.Create("TextButton", { Name = "RestoreOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = cfg.Title or "Abstracted", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent, Visible = false, ZIndex = 10 })
        }),
        Engine.Create("Frame", { Name = "Sidebar", Size = UDim2.new(0, 160, 1, -50), Position = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1 }, { Engine.Create("ScrollingFrame", { Name = "Tabs", Size = UDim2.new(1, -10, 1, -20), Position = UDim2.new(0, 5, 0, 10), BackgroundTransparency = 1, ScrollBarThickness = 0 }, { Engine.Create("UIListLayout", { Padding = UDim.new(0, 5) }) }) }),
        Engine.Create("Frame", { Name = "Content", Size = UDim2.new(1, -170, 1, -60), Position = UDim2.new(0, 160, 0, 55), BackgroundTransparency = 1 })
    })

    loader.BarContainer.Bar:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quart", 1.0, true)
    task.wait(1.0)
    Abstracted:RegisterLoc(loader.Txt, "Ready")
    task.wait(0.3)
    
    Engine.Tween(loader, { BackgroundTransparency = 1 }, 0.4)
    Engine.Tween(loader.Txt, { TextTransparency = 1 }, 0.4)
    Engine.Tween(loader.BarContainer, { BackgroundTransparency = 1 }, 0.4)
    Engine.Tween(loader.BarContainer.Bar, { BackgroundTransparency = 1 }, 0.4)
    Engine.Tween(loader.UIStroke, { Transparency = 1 }, 0.4)
    
    self.Main.Visible = true
    Engine.Tween(self.Main, { GroupTransparency = 0 }, 0.4)
    task.wait(0.4)
    loader:Destroy()

    Abstracted:RegisterLoc(self.Main.Topbar.Search, "Search elements...")

    local dToggle, dStart, sPos, dragDist = false, Vector3.new(), UDim2.new(), 0
    local function handleDragStart(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dToggle = true; dStart = i.Position; sPos = self.Main.Position; dragDist = 0 
        end
    end
    Engine.Connect(self.Main.InputBegan, handleDragStart)
    Engine.Connect(self.Main.Topbar.RestoreOverlay.InputBegan, handleDragStart)
    Engine.Connect(UserInputService.InputChanged, function(i) 
        if i.UserInputType == Enum.UserInputType.MouseMovement and dToggle then 
            local d = i.Position - dStart
            dragDist = d.Magnitude
            self.Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) 
        end 
    end)
    Engine.Connect(UserInputService.InputEnded, function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dToggle = false end 
    end)

    local titleWidth = TextService:GetTextSize(cfg.Title or "Abstracted", 14, Enum.Font.GothamBold, Vector2.new(1000, 30)).X
    local pillWidth = math.max(titleWidth + 60, 120)
    
    Engine.Connect(self.Main.Topbar.Minimize.MouseButton1Click, function()
        self.IsMinimized = true
        self.Main.Topbar.Title.Visible = false; self.Main.Topbar.Search.Visible = false; self.Main.Topbar.Minimize.Visible = false; self.Main.Topbar.Close.Visible = false; self.Main.Sidebar.Visible = false; self.Main.Content.Visible = false 
        self.Main.Topbar.RestoreOverlay.Visible = true
        Engine.Tween(self.Main.Corner, { CornerRadius = UDim.new(1, 0) }, 0.4)
        Engine.Tween(self.Main.Topbar.Corner, { CornerRadius = UDim.new(1, 0) }, 0.4)
        Engine.Tween(self.Main, { Size = UDim2.new(0, pillWidth, 0, 40) }, 0.4)
        Engine.Tween(self.Main.Topbar, { Size = UDim2.new(1, 0, 1, 0) }, 0.4)
    end)
    
    Engine.Connect(self.Main.Topbar.RestoreOverlay.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and dragDist < 5 then
            self.IsMinimized = false
            self.Main.Topbar.RestoreOverlay.Visible = false
            Engine.Tween(self.Main.Corner, { CornerRadius = UDim.new(0, 8) }, 0.4)
            Engine.Tween(self.Main.Topbar.Corner, { CornerRadius = UDim.new(0, 8) }, 0.4)
            Engine.Tween(self.Main, { Size = UDim2.new(0, 650, 0, 450) }, 0.4)
            Engine.Tween(self.Main.Topbar, { Size = UDim2.new(1, 0, 0, 50) }, 0.4)
            task.delay(0.3, function()
                if not self.IsMinimized then
                    self.Main.Topbar.Title.Visible = true; self.Main.Topbar.Search.Visible = true; self.Main.Topbar.Minimize.Visible = true; self.Main.Topbar.Close.Visible = true; self.Main.Sidebar.Visible = true; self.Main.Content.Visible = true
                end
            end)
        end
    end)

    Engine.Connect(self.Main.Topbar.Search.Changed, function(prop) 
        if prop == "Text" then 
            local q = self.Main.Topbar.Search.Text:lower()
            for _, el in ipairs(Abstracted.Elements) do 
                el.Instance.Visible = (q == "" or el.Name:lower():match(q)) 
            end 
        end 
    end)

    self.Tooltip = Engine.Create("Frame", { Size = UDim2.new(0, 200, 0, 30), BackgroundColor3 = Theme.Topbar, Visible = false, ZIndex = 100, Parent = self.Container }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 6) }), Engine.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center }) })
    self.Notifs = Engine.Create("Frame", { Size = UDim2.new(0, 250, 1, -20), Position = UDim2.new(1, -260, 0, 10), BackgroundTransparency = 1, Parent = self.Container }, { Engine.Create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10) }) })
    
    Engine.Connect(self.Main.Topbar.Close.MouseButton1Click, function() self:Unload() end)

    self.KeybindsTab = self:CreateTab("Keybinds")
    self.KeybindsSection = self.KeybindsTab:CreateSection("Active Binds", "Left")
    Abstracted:RegisterLoc(self.KeybindsTab.Btn, "Keybinds")
    return self
end

function Window:Notify(title, text, typeOfNotif, dur)
    local nType = type(typeOfNotif) == "string" and typeOfNotif:lower() or "info"
    local timeDur = type(dur) == "number" and dur or (type(typeOfNotif) == "number" and typeOfNotif or 3)
    
    local barCol = Theme.Accent
    if nType == "success" then barCol = Color3.fromRGB(85, 255, 127) 
    elseif nType == "error" then barCol = Color3.fromRGB(255, 85, 85) 
    elseif nType == "warn" then barCol = Color3.fromRGB(255, 170, 0) end
    
    local wrapper = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = self.Notifs })
    local n = Engine.Create("CanvasGroup", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, 50, 0, 0), GroupTransparency = 1, BackgroundColor3 = Theme.ElementBg, Parent = wrapper }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 6) }), 
        Engine.Create("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = barCol }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
        Engine.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 15, 0, 5), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("TextLabel", { Name = "Desc", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 15, 0, 30), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
    })
    
    Abstracted:RegisterLoc(n.Title, title)
    Abstracted:RegisterLoc(n.Desc, text)
    
    Engine.Tween(n, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.4)
    task.delay(timeDur, function() 
        if wrapper.Parent then 
            Engine.Tween(n, { Position = UDim2.new(1, 50, 0, 0), GroupTransparency = 1 }, 0.4).Completed:Connect(function() wrapper:Destroy() end) 
        end 
    end)
end

function Window:Prompt(titleKey, descKey, cb)
    local parentContainer = self.Container or Engine.GetSafeParent()
    local ov = Engine.Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, ZIndex = 100, Parent = parentContainer, Active = true })
    local mod = Engine.Create("CanvasGroup", { Size = UDim2.new(0, 360, 0, 180), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 15), BackgroundColor3 = Theme.Bg, GroupTransparency = 1, ZIndex = 101, Parent = ov }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 8) }), 
        Engine.Create("UIStroke", { Color = Color3.fromRGB(255, 70, 70), Thickness = 1.5 }),
        Engine.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -20, 0, 35), Position = UDim2.new(0, 10, 0, 12), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 70, 70), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 102 }),
        Engine.Create("TextLabel", { Name = "Desc", Size = UDim2.new(1, -40, 0, 70), Position = UDim2.new(0, 20, 0, 50), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 102 }),
        Engine.Create("TextButton", { Name = "Confirm", Size = UDim2.new(0.4, 0, 0, 34), Position = UDim2.new(0.06, 0, 1, -45), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, ZIndex = 102 }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
        Engine.Create("TextButton", { Name = "Cancel", Size = UDim2.new(0.4, 0, 0, 34), Position = UDim2.new(0.54, 0, 1, -45), BackgroundColor3 = Theme.ElementBg, Text = "", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, ZIndex = 102 }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    })
    
    Abstracted:RegisterLoc(mod.Title, titleKey)
    Abstracted:RegisterLoc(mod.Desc, descKey)
    Abstracted:RegisterLoc(mod.Confirm, "Confirm")
    Abstracted:RegisterLoc(mod.Cancel, "Cancel")
    
    Engine.Tween(ov, { BackgroundTransparency = 0.5 }, 0.3)
    Engine.Tween(mod, { Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0 }, 0.3)
    
    local function closePrompt()
        Engine.Tween(ov, { BackgroundTransparency = 1 }, 0.3)
        local closeTween = Engine.Tween(mod, { Position = UDim2.new(0.5, 0, 0.5, -15), GroupTransparency = 1 }, 0.3)
        if closeTween then closeTween.Completed:Connect(function() if ov then ov:Destroy() end end)
        else task.delay(0.3, function() if ov then ov:Destroy() end end) end
    end
    Engine.Connect(mod.Confirm.MouseButton1Click, function() closePrompt(); if cb then cb() end end)
    Engine.Connect(mod.Cancel.MouseButton1Click, function() closePrompt() end)
end

function Window:CreateTab(name)
    local Tab = setmetatable({ Window = self }, TabMethods)
    Tab.Btn = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.TabBg, Text = "", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.TextDark, Parent = self.Main.Sidebar.Tabs }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    Abstracted:RegisterLoc(Tab.Btn, name)
    
    Tab.Content = Engine.Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, Parent = self.Main.Content }, { Engine.Create("UIListLayout", { Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal }) })
    Tab.Left = Engine.Create("Frame", { Size = UDim2.new(0.5, -5, 0, 0), BackgroundTransparency = 1, Parent = Tab.Content }, { Engine.Create("UIListLayout", { Name = "List", Padding = UDim.new(0, 10) }) })
    Tab.Right = Engine.Create("Frame", { Size = UDim2.new(0.5, -5, 0, 0), BackgroundTransparency = 1, Parent = Tab.Content }, { Engine.Create("UIListLayout", { Name = "List", Padding = UDim.new(0, 10) }) })
    
    local function UpdateCanvas()
        local lSize = Tab.Left.List.AbsoluteContentSize.Y; local rSize = Tab.Right.List.AbsoluteContentSize.Y
        Tab.Left.Size = UDim2.new(0.5, -5, 0, lSize); Tab.Right.Size = UDim2.new(0.5, -5, 0, rSize)
        Tab.Content.CanvasSize = UDim2.new(0, 0, 0, math.max(lSize, rSize) + 20)
    end
    Tab.Left.List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    Tab.Right.List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    
    self.Tabs[name] = Tab
    Engine.Connect(Tab.Btn.MouseButton1Click, function() self:SelectTab(name) end)
    if not self.CurrentTab then self:SelectTab(name) end
    return Tab
end

function Window:SelectTab(name)
    self.CurrentTab = name
    for n, t in pairs(self.Tabs) do
        t.Content.Visible = (n == name)
        Engine.Tween(t.Btn, { TextColor3 = (n == name) and Theme.Text or Theme.TextDark, BackgroundColor3 = (n == name) and Theme.Accent or Theme.TabBg }, 0.2)
    end
end

function TabMethods:CreateSection(name, side)
    local tgt = (side == "Right") and self.Right or self.Left
    local Sec = setmetatable({ Window = self.Window }, SectionMethods)
    Sec.Cont = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.ElementBg, Parent = tgt }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Engine.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("Frame", { Name = "Items", Size = UDim2.new(1, -10, 0, 0), Position = UDim2.new(0, 5, 0, 30), BackgroundTransparency = 1 }, { Engine.Create("UIListLayout", { Name = "List", Padding = UDim.new(0, 5) }), Engine.Create("UIPadding", { PaddingBottom = UDim.new(0, 5) }) })
    })
    Abstracted:RegisterLoc(Sec.Cont.Title, name)
    Sec.Items = Sec.Cont.Items
    Sec.Items.List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sec.Items.Size = UDim2.new(1, -10, 0, Sec.Items.List.AbsoluteContentSize.Y + 5)
        Sec.Cont.Size = UDim2.new(1, 0, 0, Sec.Items.List.AbsoluteContentSize.Y + 35)
    end)
    return Sec
end

function SectionMethods:AddButton(c)
    local btn = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Hover, Text = "", Parent = self.Items }, { 
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("TextLabel", { Name = "Lbl", Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left })
    })
    Abstracted:RegisterLoc(btn.Lbl, c.Name)
    Engine.ApplyTag(btn, c.Tag, 10)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(btn, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = btn })
    Engine.Connect(btn.MouseButton1Click, function() if c.Callback then c.Callback() end end)
end

function SectionMethods:AddToggle(c)
    local s = c.Default or false
    local tog = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Hover, Text = "", Parent = self.Items }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("TextLabel", { Name = "Lbl", Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("Frame", { Name = "SwitchBg", Size = UDim2.new(0, 32, 0, 16), Position = UDim2.new(1, -42, 0.5, -8), BackgroundColor3 = s and Theme.Accent or Theme.Bg }, { 
            Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Engine.Create("Frame", { Name = "Knob", Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, s and 18 or 2, 0.5, -6), BackgroundColor3 = Color3.new(1,1,1) }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        })
    })
    Abstracted:RegisterLoc(tog.Lbl, c.Name)
    Engine.ApplyTag(tog, c.Tag, 50)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(tog, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = tog })
    Engine.Connect(tog.MouseButton1Click, function() 
        s = not s
        Engine.Tween(tog.SwitchBg, { BackgroundColor3 = s and Theme.Accent or Theme.Bg }, 0.2)
        Engine.Tween(tog.SwitchBg.Knob, { Position = UDim2.new(0, s and 18 or 2, 0.5, -6) }, 0.2)
        if c.Callback then c.Callback(s) end 
    end)
end

function SectionMethods:AddSlider(c)
    local min, max, cur = c.Min or 0, c.Max or 100, c.Default or 50
    local sl = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Hover, Parent = self.Items }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -80, 0, 20), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("Frame", { Name = "Bar", Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 26), BackgroundColor3 = Theme.Bg }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Engine.Create("Frame", { Name = "Fill", Size = UDim2.new((cur - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) }),
        Engine.Create("TextButton", { Name = "Hit", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
    })
    
    Abstracted:RegisterLoc(sl.Title, c.Name, function(trans) sl.Title.Text = trans .. " : " .. cur end)
    Engine.ApplyTag(sl, c.Tag, 10, 10)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(sl, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = sl })
    
    local drag = false
    Engine.Connect(sl.Hit.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
    Engine.Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
    Engine.Connect(game:GetService("RunService").RenderStepped, function()
        if drag then
            local pct = math.clamp((UserInputService:GetMouseLocation().X - sl.Bar.AbsolutePosition.X) / sl.Bar.AbsoluteSize.X, 0, 1)
            cur = math.floor(min + ((max - min) * pct))
            sl.Bar.Fill.Size = UDim2.new(pct, 0, 1, 0)
            local transName = Abstracted.TranslationCache[Abstracted.CurrentLocale .. "_" .. c.Name] or c.Name
            sl.Title.Text = transName .. " : " .. cur
            if c.Callback then c.Callback(cur) end
        end
    end)
end

function SectionMethods:AddDropdown(c)
    local open, sel = false, c.Multi and {} or (c.Default or "")
    local dd = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 35), ClipsDescendants = true, BackgroundColor3 = Theme.Hover, Parent = self.Items }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    local top = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Text = "", Parent = dd })
    
    -- Added TextTruncate to keep the label safe from running off
    local lbl = Engine.Create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = top })
    
    local lst = Engine.Create("Frame", { Size = UDim2.new(1, -10, 1, -40), Position = UDim2.new(0, 5, 0, 35), BackgroundTransparency = 1, Visible = false, Parent = dd }, { Engine.Create("UIListLayout", { Padding = UDim.new(0, 2) }) })

    local function getC(k) return Abstracted.TranslationCache[Abstracted.CurrentLocale .. "_" .. k] or k end

    local function upd()
        local tName = getC(c.Name)
        if c.Multi then
            local t = {}
            for _, v in ipairs(sel) do table.insert(t, getC(v)) end
            lbl.Text = tName .. " : " .. (#t == 0 and getC("None") or table.concat(t, ", "))
        else
            lbl.Text = tName .. " : " .. (sel == "" and getC("None") or getC(sel))
        end
    end
    Abstracted:RegisterLoc(lbl, c.Name, function() upd() end)
    
    Engine.ApplyTag(top, c.Tag, 10)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(top, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = dd })

    for _, opt in ipairs(c.Options) do
        local b = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = Theme.Bg, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.TextDark, Parent = lst }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
        Abstracted:RegisterLoc(b, opt)
        Engine.Connect(b.MouseButton1Click, function()
            if c.Multi then
                local f = table.find(sel, opt)
                if f then table.remove(sel, f) else table.insert(sel, opt) end
                Engine.Tween(b, { TextColor3 = table.find(sel, opt) and Theme.Accent or Theme.TextDark }, 0.2)
            else
                sel = opt; open = false; Engine.Tween(dd, { Size = UDim2.new(1, 0, 0, 35) }, 0.2)
                for _, x in ipairs(lst:GetChildren()) do if x:IsA("TextButton") then x.TextColor3 = Theme.TextDark end end
                b.TextColor3 = Theme.Accent
                task.delay(0.2, function() if not open then lst.Visible = false end end)
            end
            upd(); if c.Callback then c.Callback(sel) end
        end)
    end
    Engine.Connect(top.MouseButton1Click, function() 
        open = not open; if open then lst.Visible = true end
        Engine.Tween(dd, { Size = UDim2.new(1, 0, 0, open and (35 + (#c.Options * 27)) or 35) }, 0.2) 
        if not open then task.delay(0.2, function() if not open then lst.Visible = false end end) end
    end)
end

function SectionMethods:AddKeybind(c)
    local k, bind = c.Default or Enum.KeyCode.Unknown, false
    local kb = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Hover, Parent = self.Items }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("TextLabel", { Name = "Lbl", Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("TextButton", { Name = "Btn", Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -60, 0.5, -10), BackgroundColor3 = Theme.Bg, Text = k.Name, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Accent }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    })
    Abstracted:RegisterLoc(kb.Lbl, c.Name)
    Engine.ApplyTag(kb, c.Tag, 65)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(kb, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = kb })

    local bindLabel = nil
    local function SyncKeybindTab(keyName)
        if not bindLabel then
            bindLabel = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = self.Window.KeybindsSection.Items }, {
                Engine.Create("TextLabel", { Name = "Txt", Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left }),
                Engine.Create("TextLabel", { Name = "Key", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Text = "["..keyName.."]", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right })
            })
            Abstracted:RegisterLoc(bindLabel.Txt, c.Name)
        else bindLabel.Key.Text = "["..keyName.."]" end
    end
    if k ~= Enum.KeyCode.Unknown then SyncKeybindTab(k.Name) end

    Engine.Connect(kb.Btn.MouseButton1Click, function() kb.Btn.Text = "..."; bind = true end)
    Engine.Connect(UserInputService.InputBegan, function(i, gp)
        if bind and i.UserInputType == Enum.UserInputType.Keyboard then
            k = i.KeyCode; kb.Btn.Text = k.Name; bind = false; SyncKeybindTab(k.Name)
            if c.Callback then c.Callback(k) end
        elseif not gp and not bind and i.KeyCode == k and k ~= Enum.KeyCode.Unknown then
            if c.Callback then c.Callback(k) end
        end
    end)
end

function SectionMethods:AddColorPicker(c)
    local col, open = c.Default or Color3.new(1,1,1), false
    local cp = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 35), ClipsDescendants = true, BackgroundColor3 = Theme.Hover, Parent = self.Items }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    local top = Engine.Create("TextButton", { Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Text = "", Parent = cp })
    Engine.Create("TextLabel", { Name = "Lbl", Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    local pv = Engine.Create("Frame", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0, 5), BackgroundColor3 = col, Parent = top }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    local sls = Engine.Create("Frame", { Size = UDim2.new(1, -10, 0, 90), Position = UDim2.new(0, 5, 0, 35), BackgroundTransparency = 1, Parent = cp }, { Engine.Create("UIListLayout", { Padding = UDim.new(0, 5) }) })
    
    Abstracted:RegisterLoc(top.Lbl, c.Name)
    
    local function mkSl(txt, val, idx)
        local frm = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Parent = sls }, {
            Engine.Create("TextLabel", { Size = UDim2.new(0, 15, 1, 0), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.TextDark }),
            Engine.Create("Frame", { Name = "Bar", Size = UDim2.new(1, -25, 0, 6), Position = UDim2.new(0, 20, 0, 10), BackgroundColor3 = Theme.Bg }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Engine.Create("Frame", { Name = "Fill", Size = UDim2.new(val, 0, 1, 0), BackgroundColor3 = Theme.Accent }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) }),
            Engine.Create("TextButton", { Name = "Hit", Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = "" })
        })
        local d = false
        Engine.Connect(frm.Hit.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true end end)
        Engine.Connect(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
        Engine.Connect(game:GetService("RunService").RenderStepped, function()
            if d then
                local pct = math.clamp((UserInputService:GetMouseLocation().X - frm.Bar.AbsolutePosition.X) / frm.Bar.AbsoluteSize.X, 0, 1)
                frm.Bar.Fill.Size = UDim2.new(pct, 0, 1, 0)
                if idx == 1 then col = Color3.new(pct, col.G, col.B) elseif idx == 2 then col = Color3.new(col.R, pct, col.B) else col = Color3.new(col.R, col.G, pct) end
                pv.BackgroundColor3 = col; if c.Callback then c.Callback(col) end
            end
        end)
    end
    mkSl("R", col.R, 1); mkSl("G", col.G, 2); mkSl("B", col.B, 3)

    Engine.ApplyTag(top, c.Tag, 45)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(cp, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    table.insert(Abstracted.Elements, { Name = c.Name, Instance = cp })
    Engine.Connect(top.MouseButton1Click, function() open = not open; Engine.Tween(cp, { Size = UDim2.new(1, 0, 0, open and 130 or 35) }, 0.2) end)
end

function SectionMethods:AddStat(c)
    local st = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Parent = self.Items }, {
        Engine.Create("TextLabel", { Name = "Lbl", Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("TextLabel", { Name = "Val", Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = tostring(c.Default or ""), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right })
    })
    Abstracted:RegisterLoc(st.Lbl, c.Name)
    
    if c.Tooltip then 
        Engine.ApplyTooltip(st, function() return Abstracted:GetLocAsync(c.Tooltip) end, self.Window) 
    end
    
    return { Update = function(self, val) st.Val.Text = tostring(val) end }
end

function SectionMethods:AddProgress(c)
    local p = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.ElementBg, Parent = self.Items }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("TextLabel", { Name = "Txt", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left }),
        Engine.Create("Frame", { Name = "BarBg", Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 24), BackgroundColor3 = Theme.Bg }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Engine.Create("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) })
    })
    
    local currentPct = 0
    Abstracted:RegisterLoc(p.Txt, c.Name, function(trans) p.Txt.Text = trans .. " (" .. math.floor(currentPct * 100) .. "%)" end)
    
    return { Update = function(self, pct) 
        currentPct = math.clamp(pct, 0, 1)
        Engine.Tween(p.BarBg.Fill, { Size = UDim2.new(currentPct, 0, 1, 0) }, 0.2)
        local transName = Abstracted.TranslationCache[Abstracted.CurrentLocale .. "_" .. c.Name] or c.Name
        p.Txt.Text = transName .. " (" .. math.floor(currentPct * 100) .. "%)" 
    end }
end

function SectionMethods:AddConsole(c)
    local con = Engine.Create("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = Theme.Bg, Parent = self.Items }, {
        Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Engine.Create("ScrollingFrame", { Name = "Log", Size = UDim2.new(1, -10, 1, -35), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0) }, { Engine.Create("UIListLayout", { Name = "List", Padding = UDim.new(0, 2) }) }),
        Engine.Create("TextBox", { Name = "Inp", Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 5, 1, -30), BackgroundColor3 = Theme.Hover, Text = "", PlaceholderText = "> Command...", Font = Enum.Font.Code, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false }, { Engine.Create("UICorner", { CornerRadius = UDim.new(0, 4) }), Engine.Create("UIPadding", { PaddingLeft = UDim.new(0, 5) }) })
    })
    con.Log.List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        con.Log.CanvasSize = UDim2.new(0, 0, 0, con.Log.List.AbsoluteContentSize.Y + 5)
        con.Log.CanvasPosition = Vector2.new(0, con.Log.List.AbsoluteContentSize.Y)
    end)
    local obj = { 
        Log = function(self, txt) Engine.Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Code, TextSize = 11, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left, Parent = con.Log }) end,
        Clear = function(self) for _, v in ipairs(con.Log:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end end
    }
    Engine.Connect(con.Inp.FocusLost, function(ent) if ent and con.Inp.Text ~= "" then local t = con.Inp.Text; con.Inp.Text = ""; obj:Log("> "..t); if c.Callback then c.Callback(t, obj) end end end)
    return obj
end

function SectionMethods:AddText(c) 
    local lbl = Engine.Create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.TextDark, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = self.Items }) 
    Abstracted:RegisterLoc(lbl, c.Text)
end

function SectionMethods:AddDivider() Engine.Create("Frame", { Size = UDim2.new(1, -10, 0, 2), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Theme.Bg, Parent = self.Items }, { Engine.Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) end

function Window:Unload()
    for _, conn in ipairs(Engine.Connections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
    table.clear(Engine.Connections)
    if self.Container then self.Container:Destroy() end
    table.clear(Abstracted.Elements); table.clear(self.Tabs); table.clear(self.LocalizedObjects)
    Abstracted.CurrentWindow = nil
end

return Abstracted
