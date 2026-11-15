--!strict
-- Starfall Studio Kit / responsive client UI
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- All currency and progress are controlled by the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("StarfallNetwork") :: RemoteEvent
local gui = Instance.new("ScreenGui")
gui.Name = "StarfallHUD"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local C = {
    background = Color3.fromRGB(15, 18, 34),
    surface = Color3.fromRGB(27, 32, 56),
    card = Color3.fromRGB(37, 44, 75),
    text = Color3.fromRGB(247, 248, 255),
    muted = Color3.fromRGB(175, 190, 218),
    violet = Color3.fromRGB(147, 117, 255),
    mint = Color3.fromRGB(91, 241, 189),
    amber = Color3.fromRGB(255, 204, 96),
    red = Color3.fromRGB(255, 126, 142),
}

local function new(class: string, props: {[string]: any}, parent: Instance?): Instance
    local item = Instance.new(class)
    for property, value in pairs(props) do
        (item :: any)[property] = value
    end
    if parent then item.Parent = parent end
    return item
end
local function corner(parent: Instance, radius: number)
    new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end
local function stroke(parent: Instance, color: Color3, transparency: number)
    new("UIStroke", { Color = color, Transparency = transparency, Thickness = 1 }, parent)
end
local function text(parent: Instance, value: string, size: number, color: Color3, bold: boolean?): TextLabel
    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = color,
        TextSize = size,
        Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, size + 13),
    }, parent)
    return label :: TextLabel
end
local function button(parent: Instance, value: string, color: Color3, onClick: () -> (), width: number?): TextButton
    local b = new("TextButton", {
        Name = "ActionButton",
        Size = UDim2.fromOffset(width or 146, 39),
        BackgroundColor3 = color,
        Text = value,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.background,
        AutoButtonColor = true,
    }, parent) :: TextButton
    corner(b, 11)
    b.Activated:Connect(onClick)
    return b
end

local hud = new("Frame", {
    Name = "ProgressBar",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 52),
    Size = UDim2.fromOffset(282, 78),
    BackgroundColor3 = C.background,
    BackgroundTransparency = 0.08,
}, gui) :: Frame
corner(hud, 15)
stroke(hud, C.violet, 0.65)

local creditsLabel = text(hud, "CREDITS  --", 13, C.amber, true)
creditsLabel.Position = UDim2.fromOffset(15, 8)
creditsLabel.Size = UDim2.new(1, -25, 0, 24)
local energyLabel = text(hud, "ENERGY  -- / --", 13, C.mint, true)
energyLabel.Position = UDim2.fromOffset(15, 35)
energyLabel.Size = UDim2.new(1, -25, 0, 24)

local menuButton = button(gui, "STARFALL  /  MENU", C.violet, function() end, 174)
menuButton.Name = "OpenMenu"
menuButton.Position = UDim2.fromOffset(14, 63)
menuButton.TextSize = 11

local dimmer = new("Frame", {
    Name = "Dimmer",
    BackgroundColor3 = C.background,
    BackgroundTransparency = 0.22,
    Size = UDim2.fromScale(1, 1),
    Visible = false,
}, gui) :: Frame
local panel = new("Frame", {
    Name = "MenuPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(610, 458),
    BackgroundColor3 = C.background,
}, dimmer) :: Frame
corner(panel, 21)
stroke(panel, C.violet, 0.5)
new("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, panel)
local head = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, panel) :: Frame
local title = text(head, "STARFALL  /  STUDIO KIT", 19, C.text, true)
title.Size = UDim2.new(1, -60, 1, 0)
local close = button(head, "X", C.card, function() dimmer.Visible = false end, 38)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, 0, 0, 0)
close.TextColor3 = C.text

local tabs = new("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1 }, panel) :: Frame
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8) }, tabs)
local content = new("ScrollingFrame", {
    Name = "Content",
    Position = UDim2.fromOffset(0, 99),
    Size = UDim2.new(1, 0, 1, -135),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.violet,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, panel) :: ScrollingFrame
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 10) }, content)

local bottom = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -24),
    Size = UDim2.fromOffset(350, 53),
    BackgroundColor3 = C.surface,
    Visible = false,
}, gui) :: Frame
corner(bottom, 14)
stroke(bottom, C.violet, 0.4)
local toastText = text(bottom, "", 12, C.text, true)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.Size = UDim2.new(1, -20, 1, 0)
toastText.Position = UDim2.fromOffset(10, 0)

local snapshot: {[string]: any}? = nil
local activeTab = "Guide"
local toastIndex = 0
local renderTab: () -> ()

local function stack(parent: Instance, gap: number): Frame
    local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, parent)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap) }, frame)
    return frame :: Frame
end

local function makeCard(parent: Instance, height: number): Frame
    local frame = new("Frame", { Size = UDim2.new(1, -3, 0, height), BackgroundColor3 = C.surface }, parent)
    corner(frame, 13)
    stroke(frame, C.card, 0.2)
    return frame :: Frame
end

local function makeRow(parent: Instance, heading: string, detail: string, label: string?, onClick: (() -> ())?, tint: Color3?): Frame
    local compact = workspace.CurrentCamera ~= nil and workspace.CurrentCamera.ViewportSize.X < 600 and label ~= nil and onClick ~= nil
    local frame = makeCard(parent, if compact then 139 else 91)
    local h = text(frame, heading, 15, C.text, true)
    h.Position = UDim2.fromOffset(14, 9)
    h.Size = UDim2.new(1, if compact then -28 else -180, 0, 29)
    local d = text(frame, detail, 12, C.muted)
    d.Position = UDim2.fromOffset(14, 38)
    d.Size = UDim2.new(1, -30, 0, if compact then 50 else 38)
    if label and onClick then
        local b = button(frame, label, tint or C.violet, onClick, 142)
        b.Position = if compact then UDim2.new(0, 14, 0, 94) else UDim2.new(1, -155, 0, 10)
    end
    return frame
end

local function clear(parent: Instance)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") or child:IsA("UIListLayout") then child:Destroy() end
    end
end

renderTab = function()
    clear(content)
    local list = stack(content, 10)
    if not snapshot then
        makeRow(list, "Connecting...", "Waiting for the game server to send progress.")
        return
    end
    if activeTab == "Shop" then
        local intro = text(list, "UPGRADE YOUR ADVENTURE", 13, C.violet, true)
        intro.Size = UDim2.new(1, -5, 0, 33)
        for _, item in ipairs(snapshot.shop) do
            local detail = "Level " .. item.level .. " / " .. item.max
            if item.id == "pack" then detail ..= "  |  +20 capacity each level" end
            if item.id == "power" then detail ..= "  |  +1 energy per crystal" end
            if item.id == "boots" then detail ..= "  |  +2 walk speed each level" end
            if item.cost then detail ..= "  |  Cost: " .. item.cost .. " credits" end
            makeRow(list, item.title, detail,
                if item.cost then "BUY  /  " .. item.cost else "MAXED",
                if item.cost then function() remote:FireServer("buy", item.id) end else nil,
                C.mint)
        end
        makeRow(list, "How credits work", "Collect crystals in any of the three zones. Sell energy at the green town kiosk to earn credits.")
    elseif activeTab == "Quests" then
        local intro = text(list, "DAILY QUESTS  /  RESET AT 00:00 UTC", 12, C.violet, true)
        intro.Size = UDim2.new(1, -5, 0, 33)
        for _, quest in ipairs(snapshot.quests) do
            local status = quest.progress .. " / " .. quest.target .. "  |  Reward: " .. quest.reward .. " credits"
            local claimable = not quest.claimed and quest.progress >= quest.target
            local label = if quest.claimed then "CLAIMED" else if claimable then "CLAIM REWARD" else nil
            makeRow(list, quest.title, quest.detail .. "  |  " .. status, label,
                if claimable then function() remote:FireServer("quest", quest.id) end else nil,
                C.amber)
        end
    elseif activeTab == "Daily" then
        makeRow(list, "Daily check-in", "Collect " .. snapshot.dailyReward .. " free credits once per UTC day.",
            if snapshot.dailyClaimed then "COLLECTED" else "CLAIM +" .. snapshot.dailyReward,
            if snapshot.dailyClaimed then nil else function() remote:FireServer("daily") end,
            C.amber)
        makeRow(list, "Return tomorrow", "Your progress saves in published test experiences with Studio API access enabled.")
    else
        makeRow(list, "01  /  GATHER", "Visit the mint, amber, or purple crystal zones and press E to gather energy. Mobile players use the interaction prompt.")
        makeRow(list, "02  /  SELL", "Return to the green SELL ENERGY kiosk near the spawn and press E to turn energy into credits.")
        makeRow(list, "03  /  UPGRADE", "Spend credits on backpack capacity, crystal power, and walk speed. Every purchase is checked by the server.")
        makeRow(list, "04  /  QUESTS", "Complete three daily challenges and claim rewards. Check in daily for extra credits.")
        local saveNote = if snapshot.savingAvailable then "Saving is active for this session." else "Unsaved demo session: publish a private test place and enable Studio API access to test saves."
        makeRow(list, "SAVE STATUS", saveNote)
    end
end

local function openTab(name: string)
    activeTab = name
    dimmer.Visible = true
    renderTab()
end

local function makeTab(name: string)
    local b = button(tabs, name:upper(), C.surface, function()
        openTab(name)
    end, 105)
    b.TextColor3 = C.text
end
for _, name in ipairs({ "Guide", "Shop", "Quests", "Daily" }) do makeTab(name) end
menuButton.Activated:Connect(function() openTab("Guide") end)

local function showToast(message: string)
    toastIndex += 1
    local id = toastIndex
    bottom.Visible = true
    toastText.Text = message
    bottom.BackgroundTransparency = 0
    task.delay(3.5, function()
        if id ~= toastIndex then return end
        local tween = TweenService:Create(bottom, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        if id == toastIndex then bottom.Visible = false end
    end)
end

local function updateSize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local view = camera.ViewportSize
    panel.Size = UDim2.fromOffset(math.min(610, math.max(302, view.X - 24)), math.min(458, math.max(285, view.Y - 95)))
    if view.X < 590 then
        hud.Size = UDim2.fromOffset(190, 75)
        menuButton.Size = UDim2.fromOffset(145, 39)
        menuButton.Text = "STARFALL / MENU"
        bottom.Size = UDim2.fromOffset(math.min(350, view.X - 30), 53)
        for _, child in ipairs(tabs:GetChildren()) do
            if child:IsA("TextButton") then child.Size = UDim2.fromOffset(58, 39) end
        end
    else
        hud.Size = UDim2.fromOffset(282, 78)
        menuButton.Size = UDim2.fromOffset(174, 39)
        bottom.Size = UDim2.fromOffset(350, 53)
        for _, child in ipairs(tabs:GetChildren()) do
            if child:IsA("TextButton") then child.Size = UDim2.fromOffset(105, 39) end
        end
    end
end

local function installCameraListener()
    local camera = workspace.CurrentCamera
    if not camera then return end
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
    updateSize()
end
installCameraListener()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(installCameraListener)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        if dimmer.Visible then dimmer.Visible = false else openTab("Guide") end
    end
end)

remote.OnClientEvent:Connect(function(kind: string, value: any)
    if kind == "Snapshot" and typeof(value) == "table" then
        snapshot = value
        creditsLabel.Text = "CREDITS  " .. tostring(value.coins)
        energyLabel.Text = "ENERGY  " .. tostring(value.energy) .. " / " .. tostring(value.capacity)
        if dimmer.Visible then renderTab() end
    elseif kind == "Toast" and typeof(value) == "string" then
        showToast(value)
    elseif kind == "Open" and typeof(value) == "string" then
        if value == "Shop" or value == "Quests" or value == "Daily" then openTab(value) end
    end
end)
remote:FireServer("hello")
showToast("Welcome to Starfall! Open MENU for the guide.")
