--\ services \--

rs = game:GetService("RunService")
uis = game:GetService("UserInputService")
tw = game:GetService("TweenService")
cas = game:GetService("ContextActionService")

--\ locals \--

local drawing = Drawing.new;
local vec = Vector2.new;
local fromRGB = Color3.fromRGB;
local camera = game:GetService("Workspace").CurrentCamera;
local mouse = game:GetService("Players").LocalPlayer:GetMouse();

local library = {
    flags = {},
    folderName = "sinister",
    extensionName = ".esp",
    theme = Color3.fromRGB(17, 209, 136), --208, 41, 79
    title = "sinister",
    open = true,
    uiBind = "RightShift",
    isDropDown = false,
    isClrPickerOpen = false,
    isTextBoxFocused = false,
    instances = {},
    options = {},
    themeObjs = {},
    disabledObjs = {},
    unsafeObjs = {}
}

getgenv().library = library

--\ functions \--
local function isHovering(mouse, size, object)
    return ((mouse.Y > object.Y and mouse.Y < (object.Y + size.Y)) and (mouse.X > object.X and mouse.X < (object.X + size.X)))
end

function library:Draw(shape, properties)
    properties = properties or {}

    local item = drawing(shape)

    for property, value in next, properties do
        item[property] = value
    end

    if shape ~= 'Triangle' then
        table.insert(self.instances, item)
    end

    return item
end

function library:Draw2(shape, properties)
    properties = properties or {}

    local item = drawing(shape)

    for property, value in next, properties do
        item[property] = value
    end

    return item
end

function library:refreshCursor()
    local mse = uis:GetMouseLocation()
    local mousePos = vec(mse.X, mse.Y)

    local c1 = self:Draw('Triangle', {
        Transparency = .6, Color = fromRGB(180,180,180)
    })

    local c2 = self:Draw('Triangle', {
        Transparency = .6, Color = fromRGB(215,215,215)
    })

    mouse.Move:Connect(function()
        if self.open == true then
            local mse = uis:GetMouseLocation()
            local mousePos = vec(mse.X, mse.Y)
            c1.Visible = true
            c2.Visible = true

            c1.PointA =  mousePos
            c1.PointB =  mousePos + vec(12,12)
            c1.PointC =  mousePos + vec(12,12)

            c2.PointA =  mousePos
            c2.PointB =  mousePos + vec(11,11)
            c2.PointC =  mousePos + vec(11,11)
        else
            c1.Visible = false
            c2.Visible = false
        end
    end)
    uis.InputBegan:Connect(function(input)
        if input.KeyCode.Name == library.uiBind then
            if self.open and self.isTextBoxFocused == false then
                c1.Visible = false
                c2.Visible = false
            else
                c1.Visible = true
                c2.Visible = true
            end
        end
    end)
end

function library:SaveConfig(name)
    local cfg = {}

    for i, option in next, self.options do
        if option.Type ~= "Button" and option.Flag then
            if option.Type == "Toggle" then
                cfg[option.Flag] = option.State
            elseif option.Type == "Slider" then
                cfg[option.Flag] = option.Value
            elseif option.Type == "Textbox" then
                cfg[option.Flag] = option.Value
            elseif option.Type == "ColorPicker" then
                cfg[option.Flag] = option.Value
                if option.trans then
                    cfg[option.Flag .. " Transparency"] = option.trans
                end
            elseif option.Type == "Dropdown" then
                cfg[option.Flag] = option.Value
            end
        end
    end

    if isfolder(self.folderName) == false then
        makefolder(self.folderName)
        wait(1)
        writefile(self.folderName .. "\\" .. name .. self.extensionName, game:GetService"HttpService":JSONEncode(cfg))
    else
        writefile(self.folderName .. "\\" .. name .. self.extensionName, game:GetService"HttpService":JSONEncode(cfg))
    end
end

function library:LoadConfig(name)
    local cfg = game:GetService"HttpService":JSONDecode(readfile(self.folderName .. "\\" .. name .. self.extensionName))

    for i, option in next, self.options do
        if option.Flag then
            if option.Type == "Toggle" then
                option:SetState(cfg[option.Flag])
            elseif option.Type == "Slider" then
                option:SetValue(cfg[option.Flag])
            elseif option.Type == "Textbox" then
                option:SetText(cfg[option.Flag])
            elseif option.Type == "ColorPicker" then
                option:SetValue(cfg[option.Flag])
                option:SetTransparency(cfg[option.Flag .. " Transparency"])
            elseif option.Type == "Dropdown" then
                option:SetValue(cfg[option.Flag])
            end
        end
    end
end

library.round = function(num, bracket)
	bracket = bracket or 1
	local a
	if typeof(num) == "Vector2" then
		a = Vector2.new(library.round(num.X), library.round(num.Y))
	elseif typeof(num) == "Color3" then
		return library.round(num.r * 255), library.round(num.g * 255), library.round(num.b * 255)
	else
		a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
		if a < 0 then
			a = a + bracket
		end
		return a
	end
	return a
end

function library:Window()
    local Window = {
        dragging = false,
        Tabs = {},
        currentTab = 0,
        tabIndentation = 0,
        tabButtons = {}
    }

    local sgui = Instance.new("ScreenGui")
    syn.protect_gui(sgui)
    sgui.Parent = game:GetService("CoreGui")
    sgui.ResetOnSpawn = false
    local mod = Instance.new("TextButton", sgui)
    mod.BackgroundTransparency = 1
    mod.Text = ""
    mod.Size = UDim2.fromOffset(560,625)
    mod.Modal = true
    mod.Visible = true

    local copiedColor = nil

    Window.curtab = Instance.new('IntValue', sgui)
    Window.curtab.Value = Window.currentTab
    --560, 625
    Window.outer = library:Draw('Square', {
        Size = vec(420, 525), Position = vec(camera.ViewportSize.X / 2 - (420 / 2), camera.ViewportSize.Y / 2 - (525 / 2)), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
    })

    amountofdrawings = library:Draw('Text', {
        Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = "", Position = vec(1,1)
    })
    
    rs.RenderStepped:Connect(function()
        amountofdrawings.Text = "" .. tostring(#library.instances)
        amountofdrawings.Position = vec(amountofdrawings.TextBounds.X, 1)
    end)

    mod.Position = UDim2.fromOffset(Window.outer.Position.X, Window.outer.Position.Y)

    Window.borderclr = library:Draw('Square', {
        Size = vec(Window.outer.Size.X - 2, Window.outer.Size.Y - 2), Position = vec(Window.outer.Position.X + 1, Window.outer.Position.Y + 1), Color = library.theme, Visible = true, Thickness = 0, Filled = true
    })
    table.insert(library.themeObjs, Window.borderclr)
    Window.border = library:Draw('Square', {
        Size = vec(Window.borderclr.Size.X - 2, Window.borderclr.Size.Y - 2), Position = vec(Window.borderclr.Position.X + 1, Window.borderclr.Position.Y + 1), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
    })
    Window.innerborder = library:Draw('Square', {
        Size = vec(Window.border.Size.X - 2, Window.border.Size.Y - 2), Position = vec(Window.border.Position.X + 1, Window.border.Position.Y + 1), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
    })
    Window.inner = library:Draw('Square', {
        Size = vec(Window.innerborder.Size.X - 2, Window.innerborder.Size.Y - 2), Position = vec(Window.innerborder.Position.X + 1, Window.innerborder.Position.Y + 1), Color = fromRGB(30,30,30), Visible = true, Thickness = 0, Filled = true
    })
    Window.drag = library:Draw('Square', {
        Size = vec(Window.innerborder.Size.X - 2, 22), Position = vec(Window.innerborder.Position.X + 1, Window.innerborder.Position.Y + 1), Color = fromRGB(255,255,255), Visible = false, Thickness = 0, Filled = true
    })
    Window.text = library:Draw('Text', {
        Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = library.title, Position = vec(Window.outer.Position.X + (Window.outer.Size.X / 2), Window.outer.Position.Y + 8)
    })
    Window.mainouter = library:Draw('Square', {
        Size = vec(Window.inner.Size.X - 8, Window.inner.Size.Y - 26), Position = vec(Window.inner.Position.X + 4, Window.inner.Position.Y + 22), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
    })
    Window.mainborder = library:Draw('Square', {
        Size = vec(Window.mainouter.Size.X - 2, Window.mainouter.Size.Y - 2), Position = vec(Window.mainouter.Position.X + 1, Window.mainouter.Position.Y + 1), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
    })
    Window.maininner = library:Draw('Square', {
        Size = vec(Window.mainborder.Size.X - 2, Window.mainborder.Size.Y - 2), Position = vec(Window.mainborder.Position.X + 1, Window.mainborder.Position.Y + 1), Color = fromRGB(25,25,25), Visible = true, Thickness = 0, Filled = true
    })

    local startPosObj = {}
    local dragStart, startPos

    local function update(input)
        pcall(function()
            local delta = input.Position - dragStart
            Window.outer.Position = vec(startPos.X + delta.X, startPos.Y + delta.Y)
            mod.Position = UDim2.fromOffset(Window.outer.Position.X, Window.outer.Position.Y)

            for _, v in next, library.instances do
                if v == nil then return end

                local delta = input.Position - dragStart
                v.Position = vec(startPosObj[v].X + delta.X, startPosObj[v].Y + delta.Y)
            end
        end)
    end

    uis.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if library.open and library.isTextBoxFocused == false then
                local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                if isHovering(mpos, Window.drag.Size, Window.drag.Position) then
                    Window.dragging = true
                    dragStart = input.Position
                    startPos = Window.outer.Position
                    for _, v in next, library.instances do
                        startPosObj[v] = v.Position
                    end
                end
            end
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window.dragging = false
        end
    end)

    uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and Window.dragging then
            update(input)
        end
    end)

    Window.otherinner = library:Draw('Square', {
        Size = vec(Window.maininner.Size.X - 8, Window.maininner.Size.Y - 28), Position = vec(Window.maininner.Position.X + 4, Window.maininner.Position.Y + 24), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
    })
    Window.innerinner = library:Draw('Square', {
        Size = vec(Window.otherinner.Size.X - 2, Window.otherinner.Size.Y - 2), Position = vec(Window.otherinner.Position.X + 1, Window.otherinner.Position.Y + 1), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
    })
    Window.frontinner = library:Draw('Square', {
        Size = vec(Window.innerinner.Size.X - 2, Window.innerinner.Size.Y - 2), Position = vec(Window.innerinner.Position.X + 1, Window.innerinner.Position.Y + 1), Color = fromRGB(30,30,30), Visible = true, Thickness = 0, Filled = true
    })

    library:refreshCursor()

    uis.InputBegan:Connect(function(input)
        if input.KeyCode.Name == library.uiBind then
            if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                for i=1,0,-.25 do
                    wait()
                    library.open = false
                    mod.Visible = false
                    Window.dragging = false
                    Window.outer.Transparency = i
                    Window.borderclr.Transparency = i
                    Window.border.Transparency = i
                    Window.innerborder.Transparency = i
                    Window.inner.Transparency = i
                    Window.text.Transparency = i
                    Window.mainouter.Transparency = i
                    Window.mainborder.Transparency = i
                    Window.maininner.Transparency = i
                    Window.otherinner.Transparency = i
                    Window.innerinner.Transparency = i
                    Window.frontinner.Transparency = i
                end
            elseif library.isDropDown == false then
                for i=0,1,.25 do
                    wait()
                    library.open = true
                    mod.Visible = true
                    Window.outer.Transparency = i
                    Window.borderclr.Transparency = i
                    Window.border.Transparency = i
                    Window.innerborder.Transparency = i
                    Window.inner.Transparency = i
                    Window.text.Transparency = i
                    Window.mainouter.Transparency = i
                    Window.mainborder.Transparency = i
                    Window.maininner.Transparency = i
                    Window.otherinner.Transparency = i
                    Window.innerinner.Transparency = i
                    Window.frontinner.Transparency = i
                end
            end
        end
    end)

    function Window:SelectTab(tab)
        Window.currentTab = tab - 1
        Window.curtab.Value = tab - 1
    end

    function Window:DisableAll(option)
        if option == "Disabled" then
            for i,v in next, library.disabledObjs do
                v:Disable()
            end
        elseif option == "Unsafe" then
            for i,v in next, library.unsafeObjs do
                v:Disable()
            end
        end
    end

    function Window:EnableAll(option)
        if option == "Disabled" then
            for i,v in next, library.disabledObjs do
                v:Enable()
            end
        elseif option == "Unsafe" then
            for i,v in next, library.unsafeObjs do
                v:Enable()
            end
        end
    end

    local lastNotif = nil
    local tabSize = Window.otherinner.Position.X
    local nestedTabSize = Window.otherinner.Position.X + 8

    function Window:Notify(options)
        local Noti = {
            Title = options.text,
            Time = options.length,
            TextColor = options.textcolor
        }

        Noti.outer = library:Draw2('Square', {
            Transparency = 0, Size = vec(0, 24), Position = vec(10, 10), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
        })

        if lastNotif == nil then
            Noti.outer.Position = vec(10,10)
        else
            Noti.outer.Position = vec(10, lastNotif.Position.Y + 26)
        end

        lastNotif = Noti.outer

        Noti.borderclr = library:Draw2('Square', {
            Transparency = 0, Size = vec(Noti.outer.Size.X - 2, Noti.outer.Size.Y - 2), Position = vec(Noti.outer.Position.X + 1, Noti.outer.Position.Y + 1), Color = library.theme, Visible = true, Thickness = 0, Filled = true
        })
        Noti.border = library:Draw2('Square', {
            Transparency = 0, Size = vec(Noti.borderclr.Size.X - 2, Noti.borderclr.Size.Y - 2), Position = vec(Noti.borderclr.Position.X + 1, Noti.borderclr.Position.Y + 1), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
        })
        Noti.innerborder = library:Draw2('Square', {
            Transparency = 0, Size = vec(Noti.border.Size.X - 2, Noti.border.Size.Y - 2), Position = vec(Noti.border.Position.X + 1, Noti.border.Position.Y + 1), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
        })
        Noti.inner = library:Draw2('Square', {
            Transparency = 0, Size = vec(Noti.innerborder.Size.X - 2, Noti.innerborder.Size.Y - 2), Position = vec(Noti.innerborder.Position.X + 1, Noti.innerborder.Position.Y + 1), Color = fromRGB(30,30,30), Visible = true, Thickness = 0, Filled = true
        })
        Noti.label = library:Draw2('Text', {
            Transparency = 0, Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = Noti.Title, Position = vec(Noti.inner.Position.X + 2, Noti.inner.Position.Y + 1)
        })

        if Noti.TextColor ~= nil then
            Noti.label.Color = Noti.TextColor
        end

        Noti.outer.Size = vec(Noti.label.TextBounds.X + 12, 24)
        Noti.borderclr.Size = vec(Noti.outer.Size.X - 2, Noti.outer.Size.Y - 2)
        Noti.border.Size = vec(Noti.borderclr.Size.X - 2, Noti.borderclr.Size.Y - 2)
        Noti.innerborder.Size = vec(Noti.border.Size.X - 2, Noti.border.Size.Y - 2)
        Noti.inner.Size = vec(Noti.innerborder.Size.X - 2, Noti.innerborder.Size.Y - 2)

        for i=0, 1, .25 do
            wait()
            Noti.outer.Transparency = i
            Noti.borderclr.Transparency = i
            Noti.border.Transparency = i
            Noti.innerborder.Transparency = i
            Noti.inner.Transparency = i
            Noti.label.Transparency = i
        end

        wait(Noti.Time)

        for i=1, 0, -.25 do
            wait()
            Noti.outer.Position = Noti.outer.Position - vec(0, 2)
            Noti.borderclr.Position = vec(Noti.outer.Position.X + 1, Noti.outer.Position.Y + 1)
            Noti.border.Position = vec(Noti.borderclr.Position.X + 1, Noti.borderclr.Position.Y + 1)
            Noti.innerborder.Position = vec(Noti.border.Position.X + 1, Noti.border.Position.Y + 1)
            Noti.inner.Position = vec(Noti.innerborder.Position.X + 1, Noti.innerborder.Position.Y + 1)
            Noti.label.Position = vec(Noti.inner.Position.X + 2, Noti.inner.Position.Y + 1)

            Noti.outer.Transparency = i
            Noti.borderclr.Transparency = i
            Noti.border.Transparency = i
            Noti.innerborder.Transparency = i
            Noti.inner.Transparency = i
            Noti.label.Transparency = i

            if i == 0 then
                lastNotif = nil
                Noti.outer:Remove()
                Noti.borderclr:Remove()
                Noti.border:Remove()
                Noti.innerborder:Remove()
                Noti.inner:Remove()
                Noti.label:Remove()
            end
        end

        library:refreshCursor()
    end

    function Window:ChangeTheme(newcolor)
        library.theme = newcolor
        for i,v in next, library.themeObjs do
            v.Color = newcolor
        end
    end

    function Window:Tab(name)
        local Tab = {
            Identifier = name,
            Index = #self.Tabs,
            Indent = self.tabIndentation,
            Sections = {},
            leftLast = nil,
            rightLast = nil,
            hasNested = false,
            nestedTabs = {},
            currentNestedTab = 0,
            nestedTabIndentation = 0
        }

        Tab.Sections.Left = {}
        Tab.Sections.Right = {}

        self.tabIndentation = self.tabIndentation + 1
        table.insert(self.Tabs, Tab)

        Tab.currentNestedVal = Instance.new('IntValue', sgui)
        Tab.currentNestedVal.Value = Tab.currentNestedTab

        Tab.outer = library:Draw('Square', {
            Size = vec(Window.otherinner.Size.X / #self.Tabs, 20), Position = vec(tabSize, Window.otherinner.Position.Y - 20), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
        })

        Tab.border = library:Draw('Square', {
            Size = vec(Tab.outer.Size.X - 2, Tab.outer.Size.Y), Position = vec(Tab.outer.Position.X + 1, Tab.outer.Position.Y + 1), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
        })
        Tab.inner = library:Draw('Square', {
            Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y - 1), Position = vec(Tab.border.Position.X + 1, Tab.border.Position.Y + 1), Color = fromRGB(23,23,23), Visible = true, Thickness = 0, Filled = true
        })
        Tab.label = library:Draw('Text', {
            Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(185,185,185), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(name), Position = vec(Tab.inner.Position.X + (Tab.inner.Size.X / 2), Tab.inner.Position.Y + 2)
        })
        Tab.frame = library:Draw('Square', {
            Size = vec(Window.frontinner.Size.X, Window.frontinner.Size.Y), Position = vec(Window.frontinner.Position.X, Window.frontinner.Position.Y), Color = fromRGB(30,30,30), Visible = false, Thickness = 0, Filled = true
        })
        
        for i,v in next, self.Tabs do
            v.outer.Size = vec((Window.otherinner.Size.X / #self.Tabs) - (#self.Tabs - 1), 20)
            v.outer.Position = vec((Window.otherinner.Position.X + ((v.outer.Size.X + #self.Tabs) * v.Index)), Window.otherinner.Position.Y - 20)

            if Window.currentTab == v.Index then
                v.outer.Position = vec((Window.otherinner.Position.X + (v.outer.Size.X * v.Index)), Window.otherinner.Position.Y - 20)
            end

            v.border.Size = vec(v.outer.Size.X - 2, v.outer.Size.Y)
            v.border.Position = vec(v.outer.Position.X + 1, v.outer.Position.Y + 1)

            v.inner.Size = vec(v.border.Size.X - 2, v.border.Size.Y - 1)
            v.inner.Position = vec(v.border.Position.X + 1, v.border.Position.Y + 1)

            v.label.Position = vec(v.inner.Position.X + (v.inner.Size.X / 2), v.inner.Position.Y + 2)

            if Window.currentTab == v.Index then
                v.inner.Size = vec(v.border.Size.X - 2, v.border.Size.Y)
                v.inner.Color = fromRGB(30,30,30)
                v.label.Color = fromRGB(255,255,255)
                v.frame.Visible = true
            end
        end

        tabSize = tabSize + Tab.outer.Size.X

        if Window.currentTab == Tab.Index then
            Tab.inner.Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y)
            Tab.inner.Color = fromRGB(30,30,30)
            Tab.label.Color = fromRGB(255,255,255)
            Tab.frame.Visible = true
        end

        uis.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if library.open and library.isTextBoxFocused == false then
                    local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                    if isHovering(mpos, Tab.border.Size, Tab.border.Position) then
                        for i, v in next, self.tabButtons do
                            v.label.Color = fromRGB(185,185,185)
                            v.inner.Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y - 1)
                            v.inner.Color = fromRGB(23,23,23)
                            v.frame.Visible = false
                        end

                        Window.currentTab = Tab.Index
                        Window.curtab.Value = Tab.Index
                        Tab.inner.Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y)
                        Tab.inner.Color = fromRGB(30,30,30)
                        Tab.label.Color = fromRGB(255,255,255)
                        Tab.frame.Visible = true
                    end
                end
            end
        end)

        Window.curtab.Changed:Connect(function(val)
            if val == Tab.Index then
                Tab.inner.Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y)
                Tab.inner.Color = fromRGB(30,30,30)
                Tab.label.Color = fromRGB(255,255,255)
                Tab.frame.Visible = true
            else
                Tab.inner.Size = vec(Tab.border.Size.X - 2, Tab.border.Size.Y - 1)
                Tab.inner.Color = fromRGB(23,23,23)
                Tab.label.Color = fromRGB(185,185,185)
                Tab.frame.Visible = false
            end
        end)

        uis.InputBegan:Connect(function(input)
            if input.KeyCode.Name == library.uiBind then
                if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                    for i=1,0,-.25 do
                        wait()
                        Tab.outer.Transparency = i
                        Tab.border.Transparency = i
                        Tab.inner.Transparency = i
                        Tab.label.Transparency = i
                        Tab.frame.Transparency = i
                    end
                elseif library.isDropDown == false then
                    for i=0,1,.25 do
                        wait()
                        Tab.outer.Transparency = i
                        Tab.border.Transparency = i
                        Tab.inner.Transparency = i
                        Tab.label.Transparency = i
                        Tab.frame.Transparency = i
                    end
                end
            end
        end)

        function Tab:Section(properties)
            --if Tab.hasNested == true then return end
            local Section = {
                Side = properties.column,
                SizeY = properties.sizeY,
                Title = properties.text,
                lastItem = nil
            }

            Section.outer = library:Draw('Square', {
                Size = vec((Tab.frame.Size.X / 2) - 12, Section.SizeY), Color = fromRGB(50,50,50), Visible = false, Filled = true
            })

            if Section.Side == 1 then
                if Tab.leftLast == nil then
                    Section.outer.Position = vec(Tab.frame.Position.X + 8, Tab.frame.Position.Y + 8)
                else
                    Section.outer.Position = vec(Tab.frame.Position.X + 8, Tab.leftLast.Position.Y + Tab.leftLast.Size.Y + 8)
                end
                Tab.leftLast = Section.outer
            else
                if Tab.rightLast == nil then
                    Section.outer.Position = vec((Tab.frame.Position.X + Section.outer.Size.X) + 16, Tab.frame.Position.Y + 8)
                else
                    Section.outer.Position = vec((Tab.frame.Position.X + Section.outer.Size.X) + 16, Tab.rightLast.Position.Y + Tab.rightLast.Size.Y + 8)
                end
                Tab.rightLast = Section.outer
            end

            Section.border = library:Draw('Square', {
                Size = vec(Section.outer.Size.X - 2, Section.outer.Size.Y - 2), Position = vec(Section.outer.Position.X + 1, Section.outer.Position.Y + 1), Color = fromRGB(15,15,15), Visible = false, Filled = true
            })
            Section.inner = library:Draw('Square', {
                Size = vec(Section.border.Size.X - 2, Section.border.Size.Y - 2), Position = vec(Section.border.Position.X + 1, Section.border.Position.Y + 1), Color = fromRGB(23,23,23), Visible = false, Filled = true
            })
            Section.bar = library:Draw('Square', {
                Size = vec(Section.inner.Size.X - 2, 1), Position = vec(Section.border.Position.X + 2, Section.border.Position.Y + 2), Color = library.theme, Visible = false, Filled = true
            })
            table.insert(library.themeObjs, Section.bar)
            Section.label = library:Draw('Text', {
                Size = 13, Font = Drawing.Fonts["Plex"], Visible = false, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Section.Title), Position = vec(Section.inner.Position.X + 4, Section.inner.Position.Y + 4)
            })

            Window.curtab.Changed:Connect(function(val)
                if val == Tab.Index then
                    Section.outer.Visible = true
                    Section.border.Visible = true
                    Section.inner.Visible = true
                    Section.bar.Visible = true
                    Section.label.Visible = true
                else
                    Section.outer.Visible = false
                    Section.border.Visible = false
                    Section.inner.Visible = false
                    Section.bar.Visible = false
                    Section.label.Visible = false
                end
            end)

            if Window.currentTab == Tab.Index then
                Section.outer.Visible = true
                Section.border.Visible = true
                Section.inner.Visible = true
                Section.bar.Visible = true
                Section.label.Visible = true
            else
                Section.outer.Visible = false
                Section.border.Visible = false
                Section.inner.Visible = false
                Section.bar.Visible = false
                Section.label.Visible = false
            end

            uis.InputBegan:Connect(function(input)
                if input.KeyCode.Name == library.uiBind then
                    if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                        for i=1,0,-.25 do
                            wait()
                            Section.outer.Transparency = i
                            Section.border.Transparency = i
                            Section.inner.Transparency = i
                            Section.bar.Transparency = i
                            Section.label.Transparency = i
                        end
                    elseif library.isDropDown == false then
                        for i=0,1,.25 do
                            wait()
                            Section.outer.Transparency = i
                            Section.border.Transparency = i
                            Section.inner.Transparency = i
                            Section.bar.Transparency = i
                            Section.label.Transparency = i
                        end
                    end
                end
            end)

            --\ elements \--

            function Section:Button(options)
                local Button = {
                    Title = options.text,
                    Callback = options.callback or function() end,
                    Unsafe = options.unsafe,
                    Disabled = options.disabled
                }
                Button.Type = "Button"

                Button.outer = library:Draw('Square', {
                    Size = vec(self.inner.Size.X - 8, 20), Position = vec(0,0), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })

                if Section.lastItem == nil then
                    Button.outer.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 20)
                else
                    Button.outer.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 4)
                end

                self.lastItem = Button.outer

                Button.inner = library:Draw('Square', {
                    Size = vec(Button.outer.Size.X - 2, Button.outer.Size.Y - 2), Position = vec(Button.outer.Position.X + 1, Button.outer.Position.Y + 1), Color = fromRGB(27,27,27), Visible = true, Filled = true
                })
                Button.border1 = library:Draw('Square', {
                    Size = vec(1, Button.inner.Size.Y - 2), Position = vec(Button.inner.Position.X, Button.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Button.border2 = library:Draw('Square', {
                    Size = vec(1, Button.inner.Size.Y - 2), Position = vec(Button.inner.Position.X + Button.inner.Size.X - 1, Button.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Button.border3 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X, 1), Position = vec(Button.inner.Position.X, Button.inner.Position.Y), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Button.border4 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X, 1), Position = vec(Button.inner.Position.X, Button.inner.Position.Y + Button.inner.Size.Y - 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })

                Button.fade1 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X - 2, 2), Transparency = 0.3, Position = vec(Button.inner.Position.X + 1, Button.inner.Position.Y + 1), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Button.fade2 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X - 2, 2), Transparency = 0.25, Position = vec(Button.inner.Position.X + 1, Button.inner.Position.Y + 3), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Button.fade3 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X - 2, 2), Transparency = 0.2, Position = vec(Button.inner.Position.X + 1, Button.inner.Position.Y + 5), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Button.fade4 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X - 2, 2), Transparency = 0.15, Position = vec(Button.inner.Position.X + 1, Button.inner.Position.Y + 7), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Button.fade5 = library:Draw('Square', {
                    Size = vec(Button.inner.Size.X - 2, 2), Transparency = 0.1, Position = vec(Button.inner.Position.X + 1, Button.inner.Position.Y + 9), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })

                Button.label = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Button.Title), Position = vec(Button.inner.Position.X + (Button.inner.Size.X / 2), Button.inner.Position.Y + 2)
                })

                if Button.Unsafe == true then
                    table.insert(library.unsafeObjs, Button)
                    if Button.Disabled == true then
                        table.insert(library.disabledObjs, Button)
                        Button.label.Color = fromRGB(179, 174, 70)
                    else
                        Button.label.Color = fromRGB(245, 239, 120)
                    end
                else
                    if Button.Disabled == true then
                        table.insert(library.disabledObjs, Button)
                        Button.label.Color = fromRGB(165,165,165)
                    else
                        Button.label.Color = fromRGB(255,255,255)
                    end
                end

                local down = false

                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and library.isDropDown == false and Button.Disabled ~= true then
                            local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                            if isHovering(mpos, Button.inner.Size, Button.inner.Position) then
                                Button.outer.Color = library.theme
                                down = true
                            end
                        end
                    end
                end)

                uis.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and Button.Disabled ~= true then
                            if down == true then
                                Button.outer.Color = fromRGB(15,15,15)
                                down = false
                                Button.Callback()
                            end
                        end
                    end
                end)

                function Button:SimulateClick()
                    if Button.Disabled == true then return end
                    Button.Callback()
                end
                --hiding menu
                if Window.currentTab ~= Tab.Index then
                    Button.outer.Visible = false
                    Button.inner.Visible = false
                    Button.border1.Visible = false
                    Button.border2.Visible = false
                    Button.border3.Visible = false
                    Button.border4.Visible = false
                    Button.fade1.Visible = false
                    Button.fade2.Visible = false
                    Button.fade3.Visible = false
                    Button.fade4.Visible = false
                    Button.fade5.Visible = false
                    Button.label.Visible = false
                end
                --hiding menu
                Window.curtab.Changed:Connect(function(val)
                    if val == Tab.Index then
                        Button.outer.Visible = true
                        Button.inner.Visible = true
                        Button.border1.Visible = true
                        Button.border2.Visible = true
                        Button.border3.Visible = true
                        Button.border4.Visible = true
                        Button.fade1.Visible = true
                        Button.fade2.Visible = true
                        Button.fade3.Visible = true
                        Button.fade4.Visible = true
                        Button.fade5.Visible = true
                        Button.label.Visible = true
                    else
                        Button.outer.Visible = false
                        Button.inner.Visible = false
                        Button.border1.Visible = false
                        Button.border2.Visible = false
                        Button.border3.Visible = false
                        Button.border4.Visible = false
                        Button.fade1.Visible = false
                        Button.fade2.Visible = false
                        Button.fade3.Visible = false
                        Button.fade4.Visible = false
                        Button.fade5.Visible = false
                        Button.label.Visible = false
                    end
                end)
                --hiding menu
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == library.uiBind then
                        if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                            for i=1,0,-.25 do
                                wait()
                                Button.outer.Transparency = i
                                Button.inner.Transparency = i
                                Button.border1.Transparency = 0
                                Button.border2.Transparency = 0
                                Button.border3.Transparency = 0
                                Button.border4.Transparency = 0
                                Button.fade1.Transparency = 0
                                Button.fade2.Transparency = 0
                                Button.fade3.Transparency = 0
                                Button.fade4.Transparency = 0
                                Button.fade5.Transparency = 0
                                Button.label.Transparency = 0
                            end
                        elseif library.isDropDown == false then
                            for i=0,1,.25 do
                                wait()
                                Button.outer.Transparency = i
                                Button.inner.Transparency = i
                                Button.border1.Transparency = 0.1
                                Button.border2.Transparency = 0.1
                                Button.border3.Transparency = 0.1
                                Button.border4.Transparency = 0.1
                                Button.fade1.Transparency = .3
                                Button.fade2.Transparency = .25
                                Button.fade3.Transparency = .2
                                Button.fade4.Transparency = .15
                                Button.fade5.Transparency = .1
                                Button.label.Transparency = i
                            end
                        end
                    end
                end)

                function Button:Disable()
                    Button.Disabled = true
                    table.insert(library.disabledObjs, Button)
                    if Button.Unsafe == true then
                        Button.label.Color = fromRGB(179, 174, 70)
                    else
                        Button.label.Color = fromRGB(165,165,165)
                    end
                end

                function Button:Enable()
                    Button.Disabled = false
                    table.remove(library.disabledObjs, table.find(library.disabledObjs, Button))
                    if Button.Unsafe == true then
                        Button.label.Color = fromRGB(245, 239, 120)
                    else
                        Button.label.Color = fromRGB(255,255,255)
                    end
                end

                function Button:Check(option)
                    if option == "Disabled" then
                        return Button.Disabled
                    elseif option == "Unsafe" then
                        return Button.Unsafe
                    end
                end

                table.insert(library.options, Button)

                library:refreshCursor()
                return Button
            end

            function Section:Toggle(options)
                local Toggle = {
                    Title = options.text,
                    Unsafe = options.unsafe,
                    Disabled = options.disabled
                }
                Toggle.Type = "Toggle"
                Toggle.State = options.state
                Toggle.lastPckr = nil

                if options.flag == nil then
                    library.flags[options.text] = options.state
                    Toggle.Flag = options.text
                else
                    library.flags[options.flag] = options.state
                    Toggle.Flag = options.flag
                end

                Toggle.Callback = options.callback or function() end

                Toggle.box = library:Draw('Square', {
                    Size = vec(12,12), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })

                if Section.lastItem == nil then
                    Toggle.box.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 20)
                else
                    Toggle.box.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 4)
                end

                Section.lastItem = Toggle.box

                Toggle.invis = library:Draw('Square', {
                    Size = vec(Section.inner.Size.X - 8, 16), Position = vec(Section.inner.Position.X + 4, Toggle.box.Position.Y - 2), Transparency = 0, Visible = true, Filled = true
                })

                Toggle.inner = library:Draw('Square', {
                    Size = vec(Toggle.box.Size.X - 2, Toggle.box.Size.Y - 2),  Position = vec(Toggle.box.Position.X + 1, Toggle.box.Position.Y + 1), Visible = true, Filled = true
                })

                if Toggle.State == true then
                    Toggle.inner.Color = library.theme
                    table.insert(library.themeObjs, Toggle.inner)
                else
                    Toggle.inner.Color = fromRGB(30,30,30)
                end

                Toggle.border1 = library:Draw('Square', {
                    Size = vec(1, Toggle.inner.Size.Y - 2), Position = vec(Toggle.inner.Position.X, Toggle.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Toggle.border2 = library:Draw('Square', {
                    Size = vec(1, Toggle.inner.Size.Y - 2), Position = vec(Toggle.inner.Position.X + Toggle.inner.Size.X - 1, Toggle.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Toggle.border3 = library:Draw('Square', {
                    Size = vec(Toggle.inner.Size.X, 1), Position = vec(Toggle.inner.Position.X, Toggle.inner.Position.Y), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Toggle.border4 = library:Draw('Square', {
                    Size = vec(Toggle.inner.Size.X, 1), Position = vec(Toggle.inner.Position.X, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })

                Toggle.fade1 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 3), Size = vec(Toggle.inner.Size.X - 2, 2), Color = fromRGB(0,0,0), Transparency = 0.3, Visible = true, Filled = true
                })
                Toggle.fade2 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 4), Size = vec(Toggle.inner.Size.X - 2, 1), Color = fromRGB(0,0,0), Transparency = 0.25, Visible = true, Filled = true
                })
                Toggle.fade3 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 5), Size = vec(Toggle.inner.Size.X - 2, 1), Color = fromRGB(0,0,0), Transparency = 0.2, Visible = true, Filled = true
                })
                Toggle.fade4 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 6), Size = vec(Toggle.inner.Size.X - 2, 1), Color = fromRGB(0,0,0), Transparency = 0.15, Visible = true, Filled = true
                })
                Toggle.fade5 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 7), Size = vec(Toggle.inner.Size.X - 2, 1), Color = fromRGB(0,0,0), Transparency = 0.1, Visible = true, Filled = true
                })
                Toggle.fade6 = library:Draw('Square', {
                    Position = vec(Toggle.inner.Position.X + 1, Toggle.inner.Position.Y + Toggle.inner.Size.Y - 8), Size = vec(Toggle.inner.Size.X - 2, 1), Color = fromRGB(0,0,0), Transparency = 0.05, Visible = true, Filled = true
                })
                Toggle.label = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Toggle.Title), Position = vec(Toggle.box.Position.X + Toggle.box.Size.X + 4, Toggle.box.Position.Y - 1)
                })

                if Toggle.Unsafe == true then
                    table.insert(library.unsafeObjs, Toggle)
                    if Toggle.Disabled == true then
                        table.insert(library.disabledObjs, Toggle)
                        Toggle.label.Color = fromRGB(179, 174, 70)
                    else
                        Toggle.label.Color = fromRGB(245, 239, 120)
                    end
                else
                    if Toggle.Disabled == true then
                        table.insert(library.disabledObjs, Toggle)
                        Toggle.label.Color = fromRGB(165,165,165)
                    else
                        Toggle.label.Color = fromRGB(255,255,255)
                    end
                end
                --hiding menu
                if Window.currentTab ~= Tab.Index then
                    Toggle.box.Visible = false
                    Toggle.inner.Visible = false
                    Toggle.invis.Visible = false
                    Toggle.border1.Visible = false
                    Toggle.border2.Visible = false
                    Toggle.border3.Visible = false
                    Toggle.border4.Visible = false
                    Toggle.fade1.Visible = false
                    Toggle.fade2.Visible = false
                    Toggle.fade3.Visible = false
                    Toggle.fade4.Visible = false
                    Toggle.fade5.Visible = false
                    Toggle.fade6.Visible = false
                    Toggle.label.Visible = false
                end
                --hiding menu
                Window.curtab.Changed:Connect(function(val)
                    if val == Tab.Index then
                        Toggle.box.Visible = true
                        Toggle.invis.Visible = true
                        Toggle.inner.Visible = true
                        Toggle.border1.Visible = true
                        Toggle.border2.Visible = true
                        Toggle.border3.Visible = true
                        Toggle.border4.Visible = true
                        Toggle.fade1.Visible = true
                        Toggle.fade2.Visible = true
                        Toggle.fade3.Visible = true
                        Toggle.fade4.Visible = true
                        Toggle.fade5.Visible = true
                        Toggle.fade6.Visible = true
                        Toggle.label.Visible = true
                    else
                        Toggle.box.Visible = false
                        Toggle.invis.Visible = false
                        Toggle.inner.Visible = false
                        Toggle.border1.Visible = false
                        Toggle.border2.Visible = false
                        Toggle.border3.Visible = false
                        Toggle.border4.Visible = false
                        Toggle.fade1.Visible = false
                        Toggle.fade2.Visible = false
                        Toggle.fade3.Visible = false
                        Toggle.fade4.Visible = false
                        Toggle.fade5.Visible = false
                        Toggle.fade6.Visible = false
                        Toggle.label.Visible = false
                    end
                end)
                --hiding menu
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == library.uiBind then
                        if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                            for i=1,0,-.25 do
                                wait()
                                Toggle.box.Transparency = i
                                Toggle.border1.Transparency = 0
                                Toggle.inner.Transparency = i
                                Toggle.border2.Transparency = 0
                                Toggle.border3.Transparency = 0
                                Toggle.border4.Transparency = 0
                                Toggle.fade1.Transparency = 0
                                Toggle.fade2.Transparency = 0
                                Toggle.fade3.Transparency = 0
                                Toggle.fade4.Transparency = 0
                                Toggle.fade5.Transparency = 0
                                Toggle.fade6.Transparency = 0
                                Toggle.label.Transparency = i
                            end
                        elseif library.isDropDown == false then
                            for i=0,1,.25 do
                                wait()
                                Toggle.box.Transparency = i
                                Toggle.inner.Transparency = i
                                Toggle.border1.Transparency = 0.1
                                Toggle.border2.Transparency = 0.1
                                Toggle.border3.Transparency = 0.1
                                Toggle.border4.Transparency = 0.1
                                Toggle.fade1.Transparency = 0.3
                                Toggle.fade2.Transparency = 0.25
                                Toggle.fade3.Transparency = 0.2
                                Toggle.fade4.Transparency = 0.15
                                Toggle.fade5.Transparency = 0.1
                                Toggle.fade6.Transparency = 0.05
                                Toggle.label.Transparency = i
                            end
                        end
                    end
                end)

                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and library.isDropDown == false and Toggle.Disabled ~= true then
                            local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                            if isHovering(mpos, Toggle.invis.Size, Toggle.invis.Position) then
                                if Toggle.State == true then
                                    Toggle.inner.Color = fromRGB(30,30,30)
                                    table.remove(library.themeObjs, table.find(library.themeObjs, Toggle.inner))
                                else
                                    Toggle.inner.Color = library.theme
                                    table.insert(library.themeObjs, Toggle.inner)
                                end
                                Toggle.State = not Toggle.State
                                if options.flag == nil then
                                    library.flags[options.text] = Toggle.State
                                    Toggle.Flag = options.text
                                else
                                    library.flags[options.flag] = Toggle.State
                                    Toggle.Flag = options.flag
                                end
                                Toggle.Callback(Toggle.State)
                            end
                        end
                    end
                end)

                function Toggle:SetState(state)
                    if state == true then
                        Toggle.inner.Color = library.theme
                        table.insert(library.themeObjs, Toggle.inner)
                    else
                        Toggle.inner.Color = fromRGB(30,30,30)
                        table.remove(library.themeObjs, table.find(library.themeObjs, Toggle.inner))
                    end
                    Toggle.State = state
                    if options.flag == nil then
                        library.flags[options.text] = Toggle.State
                        Toggle.Flag = options.text
                    else
                        library.flags[options.flag] = Toggle.State
                        Toggle.Flag = options.flag
                    end
                    Toggle.Callback(state)
                end

                function Toggle:Disable()
                    Toggle.Disabled = true
                    table.insert(library.disabledObjs, Toggle)
                    if Toggle.Unsafe == true then
                        Toggle.label.Color = fromRGB(179, 174, 70)
                    else
                        Toggle.label.Color = fromRGB(165,165,165)
                    end
                end

                function Toggle:Enable()
                    Toggle.Disabled = false
                    table.remove(library.disabledObjs, table.find(library.disabledObjs, Toggle))
                    if Toggle.Unsafe == true then
                        Toggle.label.Color = fromRGB(245, 239, 120)
                    else
                        Toggle.label.Color = fromRGB(255,255,255)
                    end
                end

                function Toggle:Check(option)
                    if option == "Disabled" then
                        return Toggle.Disabled
                    elseif option == "Unsafe" then
                        return Toggle.Unsafe
                    end
                end

                table.insert(library.options, Toggle)

                library:refreshCursor()
                return Toggle
            end

            function Section:Slider(options)
                local Slider = {
                    Type = "Slider",
                    Title = options.text,
                    Minimum = options.min or 0,
                    Maximum = options.max or 100,
                    Suffix = options.suffix or "",
                    Accurate = options.rounded or true,
                    Unsafe = options.unsafe,
                    Disabled = options.disabled
                }
                Slider.Value = options.value
                if options.flag == nil then
                    library.flags[options.text] = Slider.Value
                    Slider.Flag = options.text
                else
                    library.flags[options.flag] = Slider.Value
                    Slider.Flag = options.flag
                end
                Slider.Callback = options.callback or function() end

                Slider.outer = library:Draw('Square', {
                    Size = vec(self.inner.Size.X - 8, 12), Position = vec(0,0), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })

                if Section.lastItem == nil then
                    Slider.outer.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 32)
                else
                    Slider.outer.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 16)
                end

                self.lastItem = Slider.outer

                Slider.inner = library:Draw('Square', {
                    Size = vec(Slider.outer.Size.X - 2, Slider.outer.Size.Y - 2), Position = vec(Slider.outer.Position.X + 1, Slider.outer.Position.Y + 1), Color = fromRGB(27,27,27), Visible = true, Filled = true
                })
                Slider.border1 = library:Draw('Square', {
                    Size = vec(1, Slider.inner.Size.Y - 2), Position = vec(Slider.inner.Position.X, Slider.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Slider.border2 = library:Draw('Square', {
                    Size = vec(1, Slider.inner.Size.Y - 2), Position = vec(Slider.inner.Position.X + Slider.inner.Size.X - 1, Slider.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Slider.border3 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X, 1), Position = vec(Slider.inner.Position.X, Slider.inner.Position.Y), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Slider.border4 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X, 1), Position = vec(Slider.inner.Position.X, Slider.inner.Position.Y + Slider.inner.Size.Y - 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Slider.indicator = library:Draw('Square', {
                    Size = vec(0, Slider.outer.Size.Y - 2), Position = vec(Slider.outer.Position.X + 1, Slider.outer.Position.Y + 1), Color = library.theme, Visible = true, Filled = true
                })
                table.insert(library.themeObjs, Slider.indicator)
                Slider.fade1 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0.3, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 1), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Slider.fade2 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0.25, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 3), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Slider.fade3 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0.2, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 5), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Slider.fade4 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0.15, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 7), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Slider.fade5 = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0.1, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 9), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })

                if Slider.Value > Slider.Maximum then
                    Slider.Value = Slider.Maximum
                elseif Slider.Value < Slider.Minimum then
                    Slider.Value = Slider.Minimum
                end

                Slider.valLabel = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Slider.Value) .. Slider.Suffix, Position = vec(Slider.inner.Position.X + (Slider.inner.Size.X / 2), Slider.inner.Position.Y - 2)
                })
                Slider.label = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Slider.Title), Position = vec(Slider.inner.Position.X, Slider.inner.Position.Y - 15)
                })
                Slider.invis = library:Draw('Square', {
                    Size = vec(Slider.inner.Size.X - 2, 2), Transparency = 0, Position = vec(Slider.inner.Position.X + 1, Slider.inner.Position.Y + 9), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })

                if Slider.Unsafe == true then
                    table.insert(library.unsafeObjs, Slider)
                    if Slider.Disabled == true then
                        table.insert(library.disabledObjs, Slider)
                        Slider.label.Color = fromRGB(179, 174, 70)
                        Slider.valLabel.Color = fromRGB(179, 174, 70)
                    else
                        Slider.label.Color = fromRGB(245, 239, 120)
                        Slider.valLabel.Color = fromRGB(245, 239, 120)
                    end
                else
                    if Slider.Disabled == true then
                        table.insert(library.disabledObjs, Slider)
                        Slider.label.Color = fromRGB(165,165,165)
                        Slider.valLabel.Color = fromRGB(165,165,165)
                    else
                        Slider.label.Color = fromRGB(255,255,255)
                        Slider.valLabel.Color = fromRGB(255,255,255)
                    end
                end

                Slider.indicator.Size = vec((Slider.inner.Size.X) * ((Slider.Value - Slider.Minimum) / (Slider.Maximum - Slider.Minimum)), Slider.inner.Size.Y)

                local sliding = false
                local insideBox = false

                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and library.isDropDown == false and Slider.Disabled ~= true then
                            local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                            if isHovering(mpos, Slider.outer.Size, Slider.outer.Position) then
                                sliding = true
                                Slider.outer.Color = library.theme
                            end
                        end
                    end
                end)
                uis.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and sliding then
                            sliding = false
                            Slider.outer.Color = fromRGB(15,15,15)
                        end
                    end
                end)
                --[[
                local function SlideFunc()
                    local newval = (mouse.X - Slider.outer.Position.X) / Slider.outer.Size.X

                    newval = math.clamp(newval, 0, 1)
                    local value
                    if Slider.Accurate == true then
                        value = math.floor(Slider.Minimum + (Slider.Maximum - Slider.Minimum) * newval)
                    else
                        local xval = Slider.Minimum + (Slider.Maximum - Slider.Minimum) * newval
                        value = math.floor(xval * 10)/10
                    end
                    Slider.valLabel.Text = tostring(value) .. Slider.Suffix

                    Slider.indicator.Size = vec(newval * Slider.inner.Size.X, Slider.inner.Size.Y)

                    Slider.Value = value
                    library.flags[options.flag] = value
                    Slider.Callback(value)
                end]]

                if options.flag == nil then
                    library.flags[options.text] = Slider.Value
                else
                    library.flags[options.flag] = Slider.Value
                end

                Slider.Callback(Slider.Value)

                uis.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and Window.currentTab == Tab.Index and sliding and library.open then
                        Slider.outer.Color = library.theme
                        --SlideFunc()
                        Slider:SetValue(options.min + ((input.Position.X - Slider.inner.Position.X) / Slider.inner.Size.X) * (options.max - options.min))
                    end
                end)
                --[[
                function Slider:SetValue(val)
                    if val > Slider.Maximum then
                        val = Slider.Maximum
                    elseif val < Slider.Minimum then
                        val = Slider.Minimum
                    end

                    Slider.Value = val

                    Slider.valLabel.Text = tostring(val) .. Slider.Suffix
                    Slider.indicator.Size = vec((Slider.inner.Size.X) * ((Slider.Value - Slider.Minimum) / (Slider.Maximum - Slider.Minimum)), Slider.inner.Size.Y)

                    library.flags[options.flag] = val
                    Slider.Callback(val)
                end]]

                function Slider:SetValue(val)
                    val = library.round(val, options.float)
                    val = math.clamp(val, options.min, options.max)
                    Slider.indicator.Size = vec((Slider.inner.Size.X) * ((val - options.min) / (options.max - options.min)), Slider.outer.Size.Y - 2)
                    library.flags[options.flag] = val
                    Slider.Value = val
                    Slider.Callback(val)
                    Slider.valLabel.Text = tostring(val) .. Slider.Suffix
                end

                local focused = false
                local oldVal

                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton2 and Window.currentTab == Tab.Index and library.open then
                        local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                        if isHovering(mpos, Slider.outer.Size, Slider.outer.Position) then
                            Slider.outer.Color = library.theme
                            focused = true
                            oldVal = string.gsub(Slider.valLabel.Text, Slider.Suffix, "")
                            Slider.valLabel.Text = "..."
                        end
                    end
                end)

                --when enter is pressed
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "Return" then
                        if focused == true then
                            if Slider.valLabel.Text == "..." or Slider.valLabel.Text == "" then
                                focused = false
                                Slider.valLabel.Text = oldVal
                                oldVal = nil
                            else
                                focused = false
                                Slider.Callback(Slider.valLabel.Text)
                                library.flags[options.text] = Slider.valLabel.Text
                                Slider:SetValue(Slider.valLabel.Text)
                                Slider.valLabel.Text = Slider.valLabel.Text .. Slider.Suffix
                            end
                            Slider.outer.Color = fromRGB(15,15,15)
                        end
                    end
                end)

                --when backspace is pressed
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "Backspace" then
                        if focused == true then
                            if Slider.valLabel.Text ~= "..." then
                                Slider.valLabel.Text = Slider.valLabel.Text:sub(1, -2)
                            end
                        end
                    end
                end)

                --custom key functions
                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if focused == true then
                            if input.KeyCode.Name == 'One' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "1"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "1"
                                end
                            elseif input.KeyCode.Name == 'Two' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "2"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "2"
                                end
                            elseif input.KeyCode.Name == 'Three' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "3"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "3"
                                end
                            elseif input.KeyCode.Name == 'Four' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "4"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "4"
                                end
                            elseif input.KeyCode.Name == 'Five' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "5"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "5"
                                end
                            elseif input.KeyCode.Name == 'Six' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "6"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "6"
                                end
                            elseif input.KeyCode.Name == 'Seven' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "7"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "7"
                                end
                            elseif input.KeyCode.Name == 'Eight' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "8"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "8"
                                end
                            elseif input.KeyCode.Name == 'Nine' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "9"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "9"
                                end
                            elseif input.KeyCode.Name == 'Zero' then
                                if Slider.valLabel.Text == "..." then
                                    Slider.valLabel.Text = "0"
                                else
                                    Slider.valLabel.Text = Slider.valLabel.Text .. "0"
                                end
                            end
                        end
                    end
                end)

                --hiding menu
                if Window.currentTab ~= Tab.Index then
                    Slider.outer.Visible = false
                    Slider.inner.Visible = false
                    Slider.border1.Visible = false
                    Slider.border2.Visible = false
                    Slider.border3.Visible = false
                    Slider.border4.Visible = false
                    Slider.fade1.Visible = false
                    Slider.fade2.Visible = false
                    Slider.fade3.Visible = false
                    Slider.fade4.Visible = false
                    Slider.fade5.Visible = false
                    Slider.label.Visible = false
                    Slider.indicator.Visible = false
                    Slider.valLabel.Visible = false
                    Slider.invis.Visible = false
                end
                --hiding menu
                Window.curtab.Changed:Connect(function(val)
                    if val == Tab.Index then
                        Slider.outer.Visible = true
                        Slider.inner.Visible = true
                        Slider.border1.Visible = true
                        Slider.border2.Visible = true
                        Slider.border3.Visible = true
                        Slider.border4.Visible = true
                        Slider.fade1.Visible = true
                        Slider.fade2.Visible = true
                        Slider.fade3.Visible = true
                        Slider.fade4.Visible = true
                        Slider.fade5.Visible = true
                        Slider.label.Visible = true
                        Slider.indicator.Visible = true
                        Slider.valLabel.Visible = true
                        Slider.invis.Visible = true
                    else
                        Slider.outer.Visible = false
                        Slider.inner.Visible = false
                        Slider.border1.Visible = false
                        Slider.border2.Visible = false
                        Slider.border3.Visible = false
                        Slider.border4.Visible = false
                        Slider.fade1.Visible = false
                        Slider.fade2.Visible = false
                        Slider.fade3.Visible = false
                        Slider.fade4.Visible = false
                        Slider.fade5.Visible = false
                        Slider.label.Visible = false
                        Slider.indicator.Visible = false
                        Slider.valLabel.Visible = false
                        Slider.invis.Visible = false
                    end
                end)
                --hiding menu
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == library.uiBind then
                        if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                            for i=1,0,-.25 do
                                wait()
                                Slider.outer.Transparency = i
                                Slider.inner.Transparency = i
                                Slider.border1.Transparency = 0
                                Slider.border2.Transparency = 0
                                Slider.border3.Transparency = 0
                                Slider.border4.Transparency = 0
                                Slider.fade1.Transparency = 0
                                Slider.fade2.Transparency = 0
                                Slider.fade3.Transparency = 0
                                Slider.fade4.Transparency = 0
                                Slider.fade5.Transparency = 0
                                Slider.label.Transparency = 0
                                Slider.indicator.Transparency = i
                                Slider.valLabel.Transparency = i
                            end
                        elseif library.isDropDown == false then
                            for i=0,1,.25 do
                                wait()
                                Slider.outer.Transparency = i
                                Slider.inner.Transparency = i
                                Slider.border1.Transparency = 0.1
                                Slider.border2.Transparency = 0.1
                                Slider.border3.Transparency = 0.1
                                Slider.border4.Transparency = 0.1
                                Slider.fade1.Transparency = .3
                                Slider.fade2.Transparency = .25
                                Slider.fade3.Transparency = .2
                                Slider.fade4.Transparency = .15
                                Slider.fade5.Transparency = .1
                                Slider.label.Transparency = i
                                Slider.indicator.Transparency = i
                                Slider.valLabel.Transparency = i
                            end
                        end
                    end
                end)

                function Slider:Disable()
                    table.insert(library.disabledObjs, Slider)
                    Slider.Disabled = true
                    if Slider.Unsafe == true then
                        Slider.label.Color = fromRGB(179, 174, 70)
                    else
                        Slider.label.Color = fromRGB(165,165,165)
                    end
                end

                function Slider:Enable()
                    table.remove(library.disabledObjs, table.find(library.disabledObjs, Slider))
                    Slider.Disabled = false
                    if Slider.Unsafe == true then
                        Slider.label.Color = fromRGB(245, 239, 120)
                    else
                        Slider.label.Color = fromRGB(255,255,255)
                    end
                end

                function Slider:Check(option)
                    if option == "Disabled" then
                        return Slider.Disabled
                    elseif option == "Unsafe" then
                        return Slider.Unsafe
                    end
                end

                table.insert(library.options, Slider)

                library:refreshCursor()
                return Slider
            end
            
            function Section:Divider(options)
                local Divider = {}

                Divider.outer = library:Draw('Square', {
                    Size = vec(self.inner.Size.X - 8, 14), Position = vec(0,0), Color = fromRGB(15,15,15), Visible = true, Filled = true, Transparency = 0
                })

                if Section.lastItem == nil then
                    Divider.outer.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 20)
                else
                    Divider.outer.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 4)
                end

                self.lastItem = Divider.outer

                Divider.outerbar = library:Draw('Square', {
                    Size = vec(Divider.outer.Size.X, 3), Position = vec(Divider.outer.Position.X, Divider.outer.Position.Y + (Divider.outer.Size.Y / 2)), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })
                Divider.innerbar = library:Draw('Square', {
                    Size = vec(Divider.outerbar.Size.X - 2, 1), Position = vec(Divider.outerbar.Position.X + 1, Divider.outerbar.Position.Y + 1), Color = library.theme, Visible = true, Filled = true
                })
                table.insert(library.themeObjs, Divider.innerbar)

                if options.text ~= nil then
                    Divider.invis = library:Draw('Square', {
                        Size = vec(0,0), Position = vec(0,0), Color = fromRGB(23,23,23), Visible = true, Filled = true
                    })
                    Divider.label = library:Draw('Text', {
                        Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(options.text), Position = vec(Divider.outerbar.Position.X + (Divider.outerbar.Size.X / 2), Divider.outerbar.Position.Y - 6)
                    })
                    Divider.invis.Size = vec(Divider.label.TextBounds.X + 8, 5)
                    Divider.invis.Position = vec(Divider.label.Position.X - (Divider.invis.Size.X / 2), Divider.outerbar.Position.Y - 1)

                    if Window.currentTab ~= Tab.Index then
                        Divider.outer.Visible = false
                        Divider.outerbar.Visible = false
                        Divider.innerbar.Visible = false
                        Divider.invis.Visible = false
                        Divider.label.Visible = false
                    end
    
                    Window.curtab.Changed:Connect(function(val)
                        if val == Tab.Index then
                            Divider.outer.Visible = true
                            Divider.outerbar.Visible = true
                            Divider.innerbar.Visible = true
                            Divider.invis.Visible = true
                            Divider.label.Visible = true
                        else
                            Divider.outer.Visible = false
                            Divider.outerbar.Visible = false
                            Divider.innerbar.Visible = false
                            Divider.invis.Visible = false
                            Divider.label.Visible = false
                        end
                    end)
    
                    uis.InputBegan:Connect(function(input)
                        if input.KeyCode.Name == library.uiBind and library.isDropDown == false then
                            if library.open and library.isTextBoxFocused == false then
                                for i=1,0,-.25 do
                                    wait()
                                    Divider.outerbar.Transparency = i
                                    Divider.innerbar.Transparency = i
                                    Divider.invis.Transparency = i
                                    Divider.label.Transparency = i
                                end
                            else
                                for i=0,1,.25 do
                                    wait()
                                    Divider.outerbar.Transparency = i
                                    Divider.innerbar.Transparency = i
                                    Divider.invis.Transparency = i
                                    Divider.label.Transparency = i
                                end
                            end
                        end
                    end)
                else
                    if Window.currentTab ~= Tab.Index then
                        Divider.outer.Visible = false
                        Divider.outerbar.Visible = false
                        Divider.innerbar.Visible = false
                    end
    
                    Window.curtab.Changed:Connect(function(val)
                        if val == Tab.Index then
                            Divider.outer.Visible = true
                            Divider.outerbar.Visible = true
                            Divider.innerbar.Visible = true
                        else
                            Divider.outer.Visible = false
                            Divider.outerbar.Visible = false
                            Divider.innerbar.Visible = false
                        end
                    end)
    
                    uis.InputBegan:Connect(function(input)
                        if input.KeyCode.Name == library.uiBind then
                            if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                                for i=1,0,-.25 do
                                    wait()
                                    Divider.outerbar.Transparency = i
                                    Divider.innerbar.Transparency = i
                                end
                            elseif library.isDropDown == false then
                                for i=0,1,.25 do
                                    wait()
                                    Divider.outerbar.Transparency = i
                                    Divider.innerbar.Transparency = i
                                end
                            end
                        end
                    end)
                end


                library:refreshCursor()
                return Divider
            end

            function Section:Textbox(options)
                local Textbox = {
                    Value = options.text,
                    Callback = options.callback or function() end,
                    Unsafe = options.unsafe,
                    Disabled = options.disabled,
                    Flag = nil
                }
                Textbox.Type = "Textbox"


                local text1 = options.text

                if options.flag == nil then
                    library.flags[options.text] = options.text
                    Textbox.Flag = options.text
                else
                    library.flags[options.flag] = options.text
                    Textbox.Flag = options.flag
                end

                Textbox.outer = library:Draw('Square', {
                    Size = vec(self.inner.Size.X - 8, 20), Position = vec(0,0), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })

                if Section.lastItem == nil then
                    Textbox.outer.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 20)
                else
                    Textbox.outer.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 4)
                end

                self.lastItem = Textbox.outer
                
                Textbox.inner = library:Draw('Square', {
                    Size = vec(Textbox.outer.Size.X - 2, Textbox.outer.Size.Y - 2), Position = vec(Textbox.outer.Position.X + 1, Textbox.outer.Position.Y + 1), Color = fromRGB(27,27,27), Visible = true, Filled = true
                })
                Textbox.border1 = library:Draw('Square', {
                    Size = vec(1, Textbox.inner.Size.Y - 2), Position = vec(Textbox.inner.Position.X, Textbox.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Textbox.border2 = library:Draw('Square', {
                    Size = vec(1, Textbox.inner.Size.Y - 2), Position = vec(Textbox.inner.Position.X + Textbox.inner.Size.X - 1, Textbox.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Textbox.border3 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X, 1), Position = vec(Textbox.inner.Position.X, Textbox.inner.Position.Y), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Textbox.border4 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X, 1), Position = vec(Textbox.inner.Position.X, Textbox.inner.Position.Y + Textbox.inner.Size.Y - 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                
                Textbox.fade1 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X - 2, 2), Transparency = 0.3, Position = vec(Textbox.inner.Position.X + 1, Textbox.inner.Position.Y + 1), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Textbox.fade2 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X - 2, 2), Transparency = 0.25, Position = vec(Textbox.inner.Position.X + 1, Textbox.inner.Position.Y + 3), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Textbox.fade3 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X - 2, 2), Transparency = 0.2, Position = vec(Textbox.inner.Position.X + 1, Textbox.inner.Position.Y + 5), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Textbox.fade4 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X - 2, 2), Transparency = 0.15, Position = vec(Textbox.inner.Position.X + 1, Textbox.inner.Position.Y + 7), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Textbox.fade5 = library:Draw('Square', {
                    Size = vec(Textbox.inner.Size.X - 2, 2), Transparency = 0.1, Position = vec(Textbox.inner.Position.X + 1, Textbox.inner.Position.Y + 9), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })

                Textbox.label = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(options.text or ""), Position = vec(Textbox.inner.Position.X + 2, Textbox.inner.Position.Y + 2)
                })

                if Textbox.Unsafe == true then
                    table.insert(library.unsafeObjs, Textbox)
                    if Textbox.Disabled == true then
                        table.insert(library.disabledObjs, Textbox)
                        Textbox.label.Color = fromRGB(179, 174, 70)
                    else
                        Textbox.label.Color = fromRGB(245, 239, 120)
                    end
                else
                    if Textbox.Disabled == true then
                        table.insert(library.disabledObjs, Textbox)
                        Textbox.label.Color = fromRGB(165,165,165)
                    else
                        Textbox.label.Color = fromRGB(255,255,255)
                    end
                end

                local focused, holdingShift, capsLockToggled = false
                --detecting shift state
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "LeftShift" then
                        holdingShift = true
                    end
                end)
                --detecing shift state
                uis.InputEnded:Connect(function(input)
                    if input.KeyCode.Name == "LeftShift" then
                        holdingShift = false
                    end
                end)
                --focusing textbox
                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if library.open and Window.currentTab == Tab.Index and library.isDropDown == false and Textbox.Disabled ~= true then
                            local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                            if isHovering(mpos, Textbox.inner.Size, Textbox.inner.Position) then
                                Textbox.outer.Color = library.theme
                                focused = true
                                Textbox.label.Text = Textbox.label.Text .. "|"
                            end
                        end
                    end
                end)
                --when enter is pressed
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "Return" then
                        if focused == true then
                            focused = false
                            Textbox.outer.Color = fromRGB(15,15,15)
                            Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                            Textbox.Callback(Textbox.label.Text)
                            library.flags[options.text] = Textbox.label.Text
                            Textbox.Value = Textbox.label.Text
                        end
                    end
                end)
                --when backspace is pressed
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "Backspace" then
                        if focused == true then
                            if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                Textbox.label.Text = text1:sub(1, -3)
                            else
                                Textbox.label.Text = Textbox.label.Text:sub(1, -3)
                                text1 = Textbox.label.Text
                                Textbox.label.Text = Textbox.label.Text .. "|"
                            end
                        end
                    end
                end)
                --detect capslock state
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == "CapsLock" then
                        capsLockToggled = not capsLockToggled
                    end
                end)
                --custom key functions
                uis.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if focused == true then
                            if input.KeyCode.Value >= 97 and input.KeyCode.Value <= 122 then
                                if holdingShift == true or capsLockToggled == true then
                                    Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                    Textbox.label.Text = Textbox.label.Text .. input.KeyCode.Name
                                    text1 = text1 .. input.KeyCode.Name
                                    Textbox.label.Text = Textbox.label.Text .. "|"
                                    if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                        Textbox.label.Text = Textbox.label.Text:sub(2)
                                    end
                                else
                                    Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                    Textbox.label.Text = Textbox.label.Text .. string.lower(input.KeyCode.Name)
                                    text1 = text1 .. input.KeyCode.Name
                                    Textbox.label.Text = Textbox.label.Text .. "|"
                                    if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                        Textbox.label.Text = Textbox.label.Text:sub(2)
                                    end
                                end
                            elseif input.KeyCode.Name == 'One' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "1"
                                text1 = text1 .. "1"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Two' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "2"
                                text1 = text1 .. "2"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Three' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "3"
                                text1 = text1 .. "3"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Four' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "4"
                                text1 = text1 .. "4"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Five' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "5"
                                text1 = text1 .. "5"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Six' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "6"
                                text1 = text1 .. "6"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Seven' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "7"
                                text1 = text1 .. "7"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Eight' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "8"
                                text1 = text1 .. "8"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Nine' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "9"
                                text1 = text1 .. "9"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Zero' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. "0"
                                text1 = text1 .. "0"
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            elseif input.KeyCode.Name == 'Space' then
                                Textbox.label.Text = Textbox.label.Text:sub(1, -2)
                                Textbox.label.Text = Textbox.label.Text .. " "
                                text1 = text1 .. " "
                                Textbox.label.Text = Textbox.label.Text .. "|"
                                if Textbox.label.TextBounds.X - 4 > Textbox.inner.Size.X then
                                    Textbox.label.Text = Textbox.label.Text:sub(2)
                                end
                            end
                        end
                    end
                end)

                if Window.currentTab ~= Tab.Index then
                    Textbox.outer.Visible = false
                    Textbox.inner.Visible = false
                    Textbox.border1.Visible = false
                    Textbox.border2.Visible = false
                    Textbox.border3.Visible = false
                    Textbox.border4.Visible = false
                    Textbox.fade1.Visible = false
                    Textbox.fade2.Visible = false
                    Textbox.fade3.Visible = false
                    Textbox.fade4.Visible = false
                    Textbox.fade5.Visible = false
                    Textbox.label.Visible = false
                end

                Window.curtab.Changed:Connect(function(val)
                    if val == Tab.Index then
                        Textbox.outer.Visible = true
                        Textbox.inner.Visible = true
                        Textbox.border1.Visible = true
                        Textbox.border2.Visible = true
                        Textbox.border3.Visible = true
                        Textbox.border4.Visible = true
                        Textbox.fade1.Visible = true
                        Textbox.fade2.Visible = true
                        Textbox.fade3.Visible = true
                        Textbox.fade4.Visible = true
                        Textbox.fade5.Visible = true
                        Textbox.label.Visible = true
                    else
                        Textbox.outer.Visible = false
                        Textbox.inner.Visible = false
                        Textbox.border1.Visible = false
                        Textbox.border2.Visible = false
                        Textbox.border3.Visible = false
                        Textbox.border4.Visible = false
                        Textbox.fade1.Visible = false
                        Textbox.fade2.Visible = false
                        Textbox.fade3.Visible = false
                        Textbox.fade4.Visible = false
                        Textbox.fade5.Visible = false
                        Textbox.label.Visible = false
                    end
                end)
                --hiding menu
                uis.InputBegan:Connect(function(input)
                    if input.KeyCode.Name == library.uiBind then
                        if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                            for i=1,0,-.25 do
                                wait()
                                Textbox.outer.Transparency = i
                                Textbox.inner.Transparency = i
                                Textbox.border1.Transparency = 0
                                Textbox.border2.Transparency = 0
                                Textbox.border3.Transparency = 0
                                Textbox.border4.Transparency = 0
                                Textbox.fade1.Transparency = 0
                                Textbox.fade2.Transparency = 0
                                Textbox.fade3.Transparency = 0
                                Textbox.fade4.Transparency = 0
                                Textbox.fade5.Transparency = 0
                                Textbox.label.Transparency = 0
                            end
                        elseif library.isDropDown == false then
                            for i=0,1,.25 do
                                wait()
                                Textbox.outer.Transparency = i
                                Textbox.inner.Transparency = i
                                Textbox.border1.Transparency = 0.1
                                Textbox.border2.Transparency = 0.1
                                Textbox.border3.Transparency = 0.1
                                Textbox.border4.Transparency = 0.1
                                Textbox.fade1.Transparency = .3
                                Textbox.fade2.Transparency = .25
                                Textbox.fade3.Transparency = .2
                                Textbox.fade4.Transparency = .15
                                Textbox.fade5.Transparency = .1
                                Textbox.label.Transparency = i
                            end
                        end
                    end
                end)

                function Textbox:Disable()
                    Textbox.Disabled = true
                    table.insert(library.disabledObjs, Textbox)
                    if Textbox.Unsafe == true then
                        Textbox.label.Color = fromRGB(179, 174, 70)
                    else
                        Textbox.label.Color = fromRGB(165,165,165)
                    end
                end

                function Textbox:Enable()
                    Textbox.Disabled = false
                    table.remove(library.disabledObjs, table.find(library.disabledObjs, Textbox))
                    if Textbox.Unsafe == true then
                        Textbox.label.Color = fromRGB(245, 239, 120)
                    else
                        Textbox.label.Color = fromRGB(255,255,255)
                    end
                end

                function Textbox:Check(option)
                    if option == "Disabled" then
                        return Textbox.Disabled
                    elseif option == "Unsafe" then
                        return Textbox.Unsafe
                    end
                end

                function Textbox:SetText(text)
                    if options.flag == nil then
                        library.flags[options.text] = text
                    else
                        library.flags[options.flag] = text
                    end
                    text1 = text
                    Textbox.label.Text = text
                end

                function Textbox:Focus()
                    focused = true
                    Textbox.outer.Color = library.theme
                    Textbox.label.Text = Textbox.label.Text .. "|"
                    library.isTextBoxFocused = true
                end

                function Textbox:LoseFocus()
                    focused = false
                    Textbox.outer.Color = fromRGB(15,15,15)
                    Textbox.label.Text = Textbox.label.Text:sub(1, -2)

                    Textbox.Callback(Textbox.label.Text)
                    library.flags[options.text] = Textbox.label.Text
                    Textbox.Value = Textbox.label.Text
                    library.isTextBoxFocused = false
                end

                table.insert(library.options, Textbox)

                return Textbox
            end

            function Section:Dropdown(options)
                local Dropdown = {
                    Title = options.text,
                    Callback = options.callback or function() end,
                    Value = options.value,
                    Unsafe = options.unsafe,
                    Disabled = options.disabled
                }
                Dropdown.Type = "Dropdown"

                Dropdown.outer = library:Draw('Square', {
                    Size = vec(self.inner.Size.X - 8, 20), Position = vec(0,0), Color = fromRGB(15,15,15), Visible = true, Filled = true
                })

                if Section.lastItem == nil then
                    Dropdown.outer.Position = vec(self.inner.Position.X + 4, self.inner.Position.Y + 32)
                else
                    Dropdown.outer.Position = vec(self.inner.Position.X + 4, self.lastItem.Position.Y + self.lastItem.Size.Y + 16)
                end

                self.lastItem = Dropdown.outer

                Dropdown.inner = library:Draw('Square', {
                    Size = vec(Dropdown.outer.Size.X - 2, Dropdown.outer.Size.Y - 2), Position = vec(Dropdown.outer.Position.X + 1, Dropdown.outer.Position.Y + 1), Color = fromRGB(27,27,27), Visible = true, Filled = true
                })
                Dropdown.border1 = library:Draw('Square', {
                    Size = vec(1, Dropdown.inner.Size.Y - 2), Position = vec(Dropdown.inner.Position.X, Dropdown.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Dropdown.border2 = library:Draw('Square', {
                    Size = vec(1, Dropdown.inner.Size.Y - 2), Position = vec(Dropdown.inner.Position.X + Dropdown.inner.Size.X - 1, Dropdown.inner.Position.Y + 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Dropdown.border3 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X, 1), Position = vec(Dropdown.inner.Position.X, Dropdown.inner.Position.Y), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })
                Dropdown.border4 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X, 1), Position = vec(Dropdown.inner.Position.X, Dropdown.inner.Position.Y + Dropdown.inner.Size.Y - 1), Color = fromRGB(255,255,255), Transparency = 0.1, Visible = true, Filled = true
                })

                Dropdown.fade1 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X - 2, 2), Transparency = 0.3, Position = vec(Dropdown.inner.Position.X + 1, Dropdown.inner.Position.Y + 1), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Dropdown.fade2 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X - 2, 2), Transparency = 0.25, Position = vec(Dropdown.inner.Position.X + 1, Dropdown.inner.Position.Y + 3), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Dropdown.fade3 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X - 2, 2), Transparency = 0.2, Position = vec(Dropdown.inner.Position.X + 1, Dropdown.inner.Position.Y + 5), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Dropdown.fade4 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X - 2, 2), Transparency = 0.15, Position = vec(Dropdown.inner.Position.X + 1, Dropdown.inner.Position.Y + 7), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })
                Dropdown.fade5 = library:Draw('Square', {
                    Size = vec(Dropdown.inner.Size.X - 2, 2), Transparency = 0.1, Position = vec(Dropdown.inner.Position.X + 1, Dropdown.inner.Position.Y + 9), Color = fromRGB(12,12,12), Visible = true, Filled = true
                })

                Dropdown.label = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(Dropdown.Title), Position = vec(Dropdown.outer.Position.X, Dropdown.outer.Position.Y - 14)
                })
                Dropdown.sign = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = "-", Position = vec(Dropdown.outer.Position.X + Dropdown.outer.Size.X - 14, Dropdown.outer.Position.Y + 3)
                })
                Dropdown.valLabel = library:Draw('Text', {
                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = (typeof(options.value) == "string" and options.value or getMultiText()), Position = vec(Dropdown.outer.Position.X + 3, Dropdown.outer.Position.Y + 3)
                })

                local dropped

                local buttons = {}
                local labels = {}

                function Dropdown:SetValue(val)
                    Dropdown.Value = typeof(val) == "table" and val or tostring(table.find(options.values, val) and val or options.values[1])
                    library.flags[options.flag] = Dropdown.Value
                    Dropdown.valLabel.Text = Dropdown.Value

                    for i,v in next, labels do
                        if v.Text == val then
                            v.Color = library.theme
                        else
                            v.Color = fromRGB(255,255,255)
                        end
                    end

                    Dropdown.Callback(Dropdown.Value)
                end

                --scuffed as FUCK
                uis.InputBegan:Connect(function(input)
                    pcall(function()
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if library.open and Window.currentTab == Tab.Index and not library.isDropDown and not Dropdown.Disabled then
                                local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                                if isHovering(mpos, Dropdown.inner.Size, Dropdown.inner.Position) then
                                    library.isDropDown = true
                                    dropped = true

                                        Dropdown.dropOuter = library:Draw('Square', {
                                            Size = vec(Dropdown.outer.Size.X, 4), Position = vec(Dropdown.outer.Position.X, Dropdown.outer.Position.Y + Dropdown.outer.Size.Y), Color = fromRGB(15,15,15), Visible = true, Filled = true
                                        })

                                        for i,v in next, options.values do
                                            Dropdown.dropOuter.Size = Dropdown.dropOuter.Size + vec(0, 18)
                                        end

                                        Dropdown.dropInner = library:Draw('Square', {
                                            Size = vec(Dropdown.dropOuter.Size.X - 2, Dropdown.dropOuter.Size.Y - 1), Position = vec(Dropdown.dropOuter.Position.X + 1, Dropdown.dropOuter.Position.Y), Color = fromRGB(40,40,40), Visible = true, Filled = true
                                        })

                                        for i,v in next, options.values do
                                            Dropdown.but = library:Draw('Square', {
                                                Size = vec(Dropdown.dropInner.Size.X, 18), Position = vec(Dropdown.dropInner.Position.X, Dropdown.dropOuter.Position.Y + (18 * (i - 1))), Color = fromRGB(255,0,0), Transparency = 0, Visible = true, Filled = true
                                            })
                                            buttons[i] = Dropdown.but

                                            if v == Dropdown.Value then
                                                Dropdown.label2 = library:Draw('Text', {
                                                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = library.theme, Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = v, Position = vec(Dropdown.dropOuter.Position.X + 3, Dropdown.dropOuter.Position.Y + 3 + (18 * (i - 1)))
                                                })
                                                labels[i] = Dropdown.label2
                                            else
                                                Dropdown.label2 = library:Draw('Text', {
                                                    Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(255,255,255), Center = false, Outline = true, OutlineColor = fromRGB(0,0,0), Text = v, Position = vec(Dropdown.dropOuter.Position.X + 3, Dropdown.dropOuter.Position.Y + 3 + (18 * (i - 1)))
                                                })
                                                labels[i] = Dropdown.label2
                                            end
                                    end

                                    uis.InputBegan:Connect(function(input)
                                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                            if library.open and Window.currentTab == Tab.Index and library.isDropDown == true and Dropdown.Disabled ~= true then
                                                local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                                                if library.isDropDown == true and not isHovering(mpos, Dropdown.dropInner.Size, Dropdown.dropInner.Position) then
                                                    for i,v in next, labels do
                                                        table.remove(library.instances, table.find(library.instances, v))
                                                        v:Remove()
                                                    end
                                                    for i,v in next, buttons do
                                                        table.remove(library.instances, table.find(library.instances, v))
                                                        v.Visible = false
                                                        v:Remove()
                                                    end
                                                    table.remove(library.instances, table.find(library.instances, Dropdown.dropInner))
                                                    Dropdown.dropInner:Remove()
                                                    table.remove(library.instances, table.find(library.instances, Dropdown.dropOuter))
                                                    Dropdown.dropOuter:Remove()
                                                    library.isDropDown = false
                                                    dropped = false
                                                    buttons = {}
                                                    labels = {}
                                                end
                                            end
                                        end
                                    end)

                                    library:refreshCursor()
                                end
                            end
                        end
                    end)
                end)

                uis.InputBegan:Connect(function(input)
                    for i,v in next, options.values do
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if library.open and Window.currentTab == Tab.Index and library.isDropDown == true and Dropdown.Disabled ~= true then
                                local mpos = camera:WorldToViewportPoint(mouse.Hit.p)
                                if isHovering(mpos, buttons[i].Size, buttons[i].Position) and buttons[i].Visible == true then
                                    Dropdown:SetValue(labels[i].Text)
                                end
                            end
                        end
                    end
                end)

                --hiding menu
                if Window.currentTab ~= Tab.Index then
                                    Dropdown.outer.Visible = false
                                    Dropdown.inner.Visible = false
                                    Dropdown.border1.Visible = false
                                    Dropdown.border2.Visible = false
                                    Dropdown.border3.Visible = false
                                    Dropdown.border4.Visible = false
                                    Dropdown.fade1.Visible = false
                                    Dropdown.fade2.Visible = false
                                    Dropdown.fade3.Visible = false
                                    Dropdown.fade4.Visible = false
                                    Dropdown.fade5.Visible = false
                                    Dropdown.label.Visible = false
                                    Dropdown.valLabel.Visible = false
                                    Dropdown.sign.Visible = false
                end
                --hiding menu
                Window.curtab.Changed:Connect(function(val)
                                    if val == Tab.Index then
                                        Dropdown.outer.Visible = true
                                        Dropdown.inner.Visible = true
                                        Dropdown.border1.Visible = true
                                        Dropdown.border2.Visible = true
                                        Dropdown.border3.Visible = true
                                        Dropdown.border4.Visible = true
                                        Dropdown.fade1.Visible = true
                                        Dropdown.fade2.Visible = true
                                        Dropdown.fade3.Visible = true
                                        Dropdown.fade4.Visible = true
                                        Dropdown.fade5.Visible = true
                                        Dropdown.label.Visible = true
                                        Dropdown.valLabel.Visible = true
                                        Dropdown.sign.Visible = true
                                    else
                                        Dropdown.outer.Visible = false
                                        Dropdown.inner.Visible = false
                                        Dropdown.border1.Visible = false
                                        Dropdown.border2.Visible = false
                                        Dropdown.border3.Visible = false
                                        Dropdown.border4.Visible = false
                                        Dropdown.fade1.Visible = false
                                        Dropdown.fade2.Visible = false
                                        Dropdown.fade3.Visible = false
                                        Dropdown.fade4.Visible = false
                                        Dropdown.fade5.Visible = false
                                        Dropdown.label.Visible = false
                                        Dropdown.valLabel.Visible = false
                                        Dropdown.sign.Visible = false
                                    end
                end)

                --hiding menu
                uis.InputBegan:Connect(function(input)
                                    if input.KeyCode.Name == library.uiBind then
                                        if library.open and library.isTextBoxFocused == false and library.isDropDown == false then
                                            for i=1,0,-.25 do
                                                wait()
                                                Dropdown.outer.Transparency = i
                                                Dropdown.inner.Transparency = i
                                                Dropdown.border1.Transparency = 0
                                                Dropdown.border2.Transparency = 0
                                                Dropdown.border3.Transparency = 0
                                                Dropdown.border4.Transparency = 0
                                                Dropdown.fade1.Transparency = 0
                                                Dropdown.fade2.Transparency = 0
                                                Dropdown.fade3.Transparency = 0
                                                Dropdown.fade4.Transparency = 0
                                                Dropdown.fade5.Transparency = 0
                                                Dropdown.label.Transparency = 0
                                                Dropdown.sign.Transparency = 0
                                                Dropdown.valLabel.Transparency = 0
                                            end
                                        elseif library.isDropDown == false then
                                            for i=0,1,.25 do
                                                wait()
                                                Dropdown.outer.Transparency = i
                                                Dropdown.inner.Transparency = i
                                                Dropdown.border1.Transparency = 0.1
                                                Dropdown.border2.Transparency = 0.1
                                                Dropdown.border3.Transparency = 0.1
                                                Dropdown.border4.Transparency = 0.1
                                                Dropdown.fade1.Transparency = .3
                                                Dropdown.fade2.Transparency = .25
                                                Dropdown.fade3.Transparency = .2
                                                Dropdown.fade4.Transparency = .15
                                                Dropdown.fade5.Transparency = .1
                                                Dropdown.label.Transparency = i
                                                Dropdown.sign.Transparency = i
                                                Dropdown.valLabel.Transparency = i
                                            end
                                        end
                                    end
                end)

                table.insert(library.options, Dropdown)

                return Dropdown
            end

            library.Window[name][properties.text] = Section

            library:refreshCursor()
            return Section
        end
        --[[
        function Tab:NestedTab(name)
            
            local NestedTab = {
                Sections = {},
                leftLast = nil,
                rightLast = nil,
                Identifier = name,
                Index = #self.nestedTabs,
                Indent = self.nestedTabIndentation
            }

            NestedTab.Sections.Left = {}
            NestedTab.Sections.Right = {}

            self.nestedTabIndentation = self.nestedTabIndentation + 1
            table.insert(self.nestedTabs, NestedTab)

            if Tab.hasNested == false then
                NestedTab.bg = library:Draw('Square', {
                    Size = vec(Window.frontinner.Size.X - 16, 22), Position = vec(Window.frontinner.Position.X + 8, Window.frontinner.Position.Y + 8), Color = fromRGB(50,50,50), Visible = true, Thickness = 0, Filled = true
                })
            end

            NestedTab.outer = library:Draw('Square', {
                Size = vec(NestedTab.bg.Size.X / #self.nestedTabs, 20), Position = vec(NestedTab.bg.Position.X + 1, NestedTab.bg.Position.Y + 1), Color = fromRGB(15,15,15), Visible = true, Thickness = 0, Filled = true
            })
            NestedTab.inner = library:Draw('Square', {
                Size = vec(NestedTab.outer.Size.X - 2, NestedTab.outer.Size.Y - 2), Position = vec(NestedTab.outer.Position.X + 1, NestedTab.outer.Position.Y + 1), Color = fromRGB(25,25,25), Visible = true, Thickness = 0, Filled = true
            })
            NestedTab.label = library:Draw('Text', {
                Size = 13, Font = Drawing.Fonts["Plex"], Visible = true, Color = fromRGB(185,185,185), Center = true, Outline = true, OutlineColor = fromRGB(0,0,0), Text = tostring(name), Position = vec(NestedTab.inner.Position.X + (NestedTab.inner.Size.X / 2), NestedTab.inner.Position.Y + 2)
            })
            NestedTab.bar = library:Draw('Square', {
                Size = vec(NestedTab.inner.Size.X, 1), Position = vec(NestedTab.inner.Position.X, NestedTab.inner.Position.Y), Color = library.theme, Visible = false, Thickness = 0, Filled = true
            })
            table.insert(library.themeObjs, NestedTab.bar)
            NestedTab.frame = library:Draw('Square', {
                Size = vec(Window.frontinner.Size.X - 16, Window.frontinner.Size.Y - 48), Position = vec(Window.frontinner.Position.X + 8, Window.frontinner.Position.Y + 40), Color = fromRGB(30,30,30), Visible = false, Thickness = 0, Filled = true
            })

            for i,v in next, self.nestedTabs do
                
            end
    
            nestedTabSize = nestedTabSize + NestedTab.outer.Size.X

            Tab.hasNested = true
            return NestedTab
        end
        ]]
        library:refreshCursor()

        library.Window[name] = Tab
        return Tab
    end

    library.Window = Window

    return Window
end

return library
