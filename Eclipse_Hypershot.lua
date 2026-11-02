-- ECLIPSE / Hypershot client overlay v1.4 (ignore nonblocking rig roots in LOS)
-- Based on the supplied 2026-11-02 Workspace dump. Live game untested.
-- LocalScript context; no remote downloads or anti-cheat bypass.
-- RMB: hold aim | RightShift: menu | Delete: unload
local Players = game:GetService('Players')
local Run = game:GetService('RunService')
local Input = game:GetService('UserInputService')
local Http = game:GetService('HttpService')
local me = Players.LocalPlayer
assert(me, 'Run on the client')
local pg = me:WaitForChild('PlayerGui')
local previous = pg:FindFirstChild('EclipseHypershot')
if previous then
    local event = previous:FindFirstChild('Unload')
    if event and event:IsA('BindableEvent') then event:Fire() else previous:Destroy() end
end
local cfg = {esp=true, boxes=true, names=true, glow=true, aim=false,
    teams=true, bots=true, walls=false, circle=true, hard=true, takeover=false,
    activation='Hold RMB', radius=450, range=6000, speed=22, part='Head'}
local accent = Color3.fromRGB(170,115,255)
local cyan = Color3.fromRGB(85,230,220)
local muted = Color3.fromRGB(150,153,172)
local white = Color3.fromRGB(235,237,250)
local connections, visuals = {}, {}
local dead, held, locked = false, false, nil
local windowFocused = true
local controlledCamera, originalCameraType, trackedRoot, lastRootPosition
local function releaseCamera()
    if controlledCamera and controlledCamera.Parent then
        controlledCamera.CameraType=originalCameraType
    end
    controlledCamera=nil; originalCameraType=nil
    trackedRoot=nil; lastRootPosition=nil
end
local bindName = 'Eclipse_' .. Http:GenerateGUID(false)
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function round(o,n) make('UICorner',{CornerRadius=UDim.new(0,n or 10)},o) end
local function stroke(o,c,t)
    return make('UIStroke',{Color=c or accent,Thickness=t or 1,Transparency=0.25},o)
end
local gui=make('ScreenGui',{Name='EclipseHypershot',ResetOnSpawn=false,
    IgnoreGuiInset=true,DisplayOrder=80,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
local unload=make('BindableEvent',{Name='Unload'},gui)
local folder=make('Folder',{Name=bindName},workspace)
local ring=make('Frame',{AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,
    Size=UDim2.fromOffset(cfg.radius*2,cfg.radius*2)},gui)
round(ring,9999)
stroke(ring,accent,1)
local marker=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(12,12),
    BackgroundTransparency=1,Visible=false},gui)
round(marker,99)
stroke(marker,cyan,2)
local panel=make('Frame',{Position=UDim2.fromOffset(30,100),Size=UDim2.fromOffset(330,552),
    BackgroundColor3=Color3.fromRGB(17,18,28),BorderSizePixel=0,Active=true},gui)
round(panel,14)
stroke(panel,Color3.fromRGB(68,56,99))
make('UIGradient',{Color=ColorSequence.new(Color3.fromRGB(35,29,54),Color3.fromRGB(16,18,28)),Rotation=70},panel)
local header=make('TextLabel',{Text='E C L I P S E',Font=Enum.Font.GothamBold,TextSize=21,
    TextColor3=white,BackgroundTransparency=1,Size=UDim2.new(1,-30,0,46),Position=UDim2.fromOffset(16,6),
    TextXAlignment=Enum.TextXAlignment.Left,Active=true},panel)
make('TextLabel',{Text='HYPERSHOT  /  CLIENT OVERLAY',Font=Enum.Font.Gotham,TextSize=10,
    TextColor3=accent,BackgroundTransparency=1,Size=UDim2.fromOffset(285,20),
    Position=UDim2.fromOffset(17,43),TextXAlignment=Enum.TextXAlignment.Left},panel)
local body=make('ScrollingFrame',{BackgroundTransparency=1,BorderSizePixel=0,
    Position=UDim2.fromOffset(14,75),Size=UDim2.new(1,-28,1,-129),ScrollBarThickness=3,
    ScrollBarImageColor3=accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
make('UIListLayout',{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},body)
local order=0
local function row(text,height)
    order=order+1
    local r=make('Frame',{Size=UDim2.new(1,-5,0,height or 32),BackgroundColor3=Color3.fromRGB(36,36,51),
        BackgroundTransparency=.25,BorderSizePixel=0,LayoutOrder=order},body)
    round(r,7)
    make('TextLabel',{Text=text,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=white,
        BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-105,1,0),
        TextXAlignment=Enum.TextXAlignment.Left},r)
    return r
end
local function button(r,text,callback)
    local b=make('TextButton',{Text=text,Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=white,BackgroundColor3=Color3.fromRGB(60,52,83),BorderSizePixel=0,
        Position=UDim2.new(1,-93,0,4),Size=UDim2.new(0,86,1,-8)},r)
    round(b,6)
    connect(b.Activated,callback)
    return b
end
local togglePainters={}
local function toggle(label,key)
    local b
    local function paint()
        b.Text=cfg[key] and 'ON' or 'OFF'
        b.BackgroundColor3=cfg[key] and Color3.fromRGB(111,72,170) or Color3.fromRGB(48,49,65)
    end
    b=button(row(label),'',function() cfg[key]=not cfg[key]; locked=nil; paint() end)
    togglePainters[key]=paint
    paint()
end
local function cycle(label,key,values)
    local b
    b=button(row(label),tostring(cfg[key]),function()
        local i=table.find(values,cfg[key]) or 0
        cfg[key]=values[i%#values+1]; b.Text=tostring(cfg[key]); locked=nil
    end)
end
toggle('ESP enabled','esp')
toggle('2D boxes + health bars','boxes')
toggle('Names / health / distance','names')
toggle('Highlight through walls','glow')
toggle('Aimlock enabled','aim')
toggle('Instant lock','hard')
toggle('Control camera while locked','takeover')
cycle('Activation','activation',{'Auto','Hold RMB'})
toggle('Check line of sight','walls')
toggle('Exclude same team','teams')
toggle('Include bots','bots')
toggle('Show aim circle','circle')
cycle('Aim point','part',{'Head','UpperTorso','HumanoidRootPart'})
cycle('FOV radius (pixels)','radius',{100,160,220,320,450,650})
cycle('Max distance (studs)','range',{500,1000,3000,6000,10000})
cycle('Smooth speed','speed',{10,16,22,35,55})
local status=make('TextLabel',{Text='READY',Font=Enum.Font.Gotham,TextSize=10,TextColor3=muted,
    BackgroundTransparency=1,Position=UDim2.new(0,16,1,-46),Size=UDim2.new(1,-32,0,19),
    TextXAlignment=Enum.TextXAlignment.Left},panel)
make('TextLabel',{Text='F6 aim on/off   /   RSHIFT menu   /   DEL unload',Font=Enum.Font.Gotham,
    TextSize=9,TextColor3=muted,BackgroundTransparency=1,Position=UDim2.new(0,16,1,-26),
    Size=UDim2.new(1,-32,0,16),TextXAlignment=Enum.TextXAlignment.Left},panel)
local dragStart, panelStart, dragTouch
connect(header.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragStart=i.Position; panelStart=panel.Position; dragTouch=i
    end
end)
connect(Input.InputChanged,function(i)
    if dragStart and (i.UserInputType==Enum.UserInputType.MouseMovement or i==dragTouch) then
        local d=i.Position-dragStart
        panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
    end
end)
local function owner(m)
    local id=m:GetAttribute('OwnerUserId')
    if typeof(id)=='number' then return Players:GetPlayerByUserId(id) end
    return Players:GetPlayerFromCharacter(m)
end
local function selfModel(entities)
    if entities then
        for _,m in ipairs(entities:GetChildren()) do
            if m:IsA('Model') and m:GetAttribute('OwnerUserId')==me.UserId
                and not m:GetAttribute('MenuCharacter') and not m:GetAttribute('LobbyCharacter') then return m end
        end
    end
    return me.Character
end
local function health(m)
    local h=m:FindFirstChildOfClass('Humanoid')
    return tonumber(m:GetAttribute('Health')) or (h and h.Health) or 0,
        tonumber(m:GetAttribute('MaxHealth')) or (h and h.MaxHealth) or 100
end
local function eligible(m,own)
    if not m:IsA('Model') or m==own or m==me.Character or m:GetAttribute('OwnerUserId')==me.UserId then return false end
    if m:GetAttribute('MenuCharacter') or m:GetAttribute('LobbyCharacter') or m:GetAttribute('Alive')==false then return false end
    local hp=health(m)
    if hp<=0 then return false end
    local p=owner(m)
    if not cfg.bots and not p then return false end
    if cfg.teams then
        local a=own and own:GetAttribute('Team')
        local b=m:GetAttribute('Team')
        -- Snapshot uses -1 for every active entity: treat it as unassigned/FFA.
        if a~=nil and b~=nil and a~=-1 and b~=-1 and a==b then return false end
        if p and not p.Neutral and not me.Neutral and p.Team and p.Team==me.Team then return false end
    end
    return true
end
local function createVisual(m)
    local box=make('Frame',{BackgroundTransparency=1,BorderSizePixel=0,Visible=false},gui)
    local outline=stroke(box,accent,1)
    local tag=make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.GothamMedium,
        TextSize=11,TextColor3=white,TextStrokeTransparency=.35,AnchorPoint=Vector2.new(.5,1),
        Position=UDim2.fromScale(.5,0),Size=UDim2.new(0,300,0,30)},box)
    local back=make('Frame',{BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(20,20,25),
        Position=UDim2.fromOffset(-6,0),Size=UDim2.new(0,3,1,0)},box)
    local bar=make('Frame',{BorderSizePixel=0,BackgroundColor3=cyan,AnchorPoint=Vector2.new(0,1),
        Position=UDim2.fromScale(0,1),Size=UDim2.fromScale(1,1)},back)
    local hl=make('Highlight',{Adornee=m,Enabled=false,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor=accent,OutlineColor=accent,FillTransparency=.85,OutlineTransparency=.1},folder)
    local v={box=box,outline=outline,tag=tag,back=back,bar=bar,hl=hl}
    visuals[m]=v
    return v
end
local signs={-1,1}
local function bounds(camera,m)
    local cf,size=m:GetBoundingBox()
    local loX,loY,hiX,hiY=math.huge,math.huge,-math.huge,-math.huge
    for _,x in ipairs(signs) do for _,y in ipairs(signs) do for _,z in ipairs(signs) do
        local p=camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x*size.X,y*size.Y,z*size.Z)*.5))
        if p.Z<=.1 then return end
        loX=math.min(loX,p.X); loY=math.min(loY,p.Y)
        hiX=math.max(hiX,p.X); hiY=math.max(hiY,p.Y)
    end end end
    return loX,loY,hiX-loX,hiY-loY
end
local function cleanup()
    if dead then return end
    dead=true
    Run:UnbindFromRenderStep(bindName)
    Run:UnbindFromRenderStep(bindName .. '_Overlay')
    releaseCamera()
    for _,c in ipairs(connections) do c:Disconnect() end
    folder:Destroy(); gui:Destroy(); table.clear(visuals)
end
connect(unload.Event,cleanup)
connect(gui.Destroying,cleanup)
connect(Input.InputBegan,function(i,processed)
    -- FPS camera controls can consume RMB; capture it before processed filtering.
    if i.UserInputType==Enum.UserInputType.MouseButton2 then
        held=true
        return
    end
    if processed or Input:GetFocusedTextBox() then return end
    if i.KeyCode==Enum.KeyCode.RightShift then panel.Visible=not panel.Visible end
    if i.KeyCode==Enum.KeyCode.Delete then cleanup() end
    if i.KeyCode==Enum.KeyCode.F6 then
        cfg.aim=not cfg.aim; locked=nil
        togglePainters.aim()
        if not cfg.aim then releaseCamera() end
    end
    if i.UserInputType==Enum.UserInputType.MouseButton2 then held=true end
end)
connect(Input.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton2 then held=false; locked=nil end
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i==dragTouch then dragStart=nil; dragTouch=nil end
end)
connect(Input.WindowFocusReleased,function()
    windowFocused=false; held=false; locked=nil; dragStart=nil
    releaseCamera()
end)
connect(Input.WindowFocused,function() windowFocused=true end)
local elapsed=0
-- Aim after the standard camera, before later character/viewmodel updates.
Run:BindToRenderStep(bindName,Enum.RenderPriority.Camera.Value+1,function(dt)
    if dead then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local entities=workspace:FindFirstChild('Entities')
    -- Polling also handles enabling aim while RMB is already down.
    held=windowFocused and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local aiming=cfg.aim and windowFocused and (cfg.activation=='Auto' or held)
        and not Input:GetFocusedTextBox()
    local own=selfModel(entities)
    local center=camera.ViewportSize*.5
    ring.Position=UDim2.fromOffset(center.X,center.Y)
    ring.Size=UDim2.fromOffset(cfg.radius*2,cfg.radius*2)
    ring.Visible=cfg.circle and cfg.aim
    marker.Visible=false
    local ray=RaycastParams.new()
    ray.FilterType=Enum.RaycastFilterType.Exclude
    local excluded={camera,folder}
    -- Dump includes a separate first-person weapon container.
    local weaponContainer=workspace:FindFirstChild('WModel')
    if weaponContainer then table.insert(excluded,weaponContainer) end
    if own then table.insert(excluded,own) end
    if me.Character and me.Character~=own then table.insert(excluded,me.Character) end
    ray.FilterDescendantsInstances=excluded
    local function visible(part,m)
        if not cfg.walls then return true end
        -- Each target starts with its own filter; skipped roots never leak to other rays.
        local ignore=table.clone(excluded)
        local origin=camera.CFrame.Position
        local direction=part.Position-origin
        for attempt=1,16 do
            ray.FilterDescendantsInstances=ignore
            local hit=workspace:Raycast(origin,direction,ray)
            if not hit or hit.Instance:IsDescendantOf(m) then return true end
            local object=hit.Instance
            local name=string.lower(object.Name)
            local rigRoot=name=='rootpart' or name=='humanoidrootpart'
            local nonblocking=object:IsA('BasePart') and
                (not object.CanCollide or object.Transparency>=0.95)
            if rigRoot and nonblocking then
                table.insert(ignore,object)
            else
                return false,object:GetFullName()
            end
        end
        return false,'LOS FILTER LIMIT'
    end
    local best,bestPart,bestScore=nil,nil,math.huge
    local pinned,pinnedPart=nil,nil
    local count,inCircle,blocked=0,0,0
    local obstruction=nil
    local seen={}
    for _,m in ipairs(entities and entities:GetChildren() or {}) do
        if m:IsA('Model') then
            seen[m]=true
            local v=visuals[m]
            if v then v.box.Visible=false; v.hl.Enabled=false end
            if eligible(m,own) then
                local part=m:FindFirstChild(cfg.part) or m:FindFirstChild('Head') or m.PrimaryPart
                if part and part:IsA('BasePart') then
                    local distance=(part.Position-camera.CFrame.Position).Magnitude
                    if distance<=cfg.range then
                        count=count+1
                        local p,onScreen=camera:WorldToViewportPoint(part.Position)
                        if aiming and onScreen and p.Z>0 then
                            local score=(Vector2.new(p.X,p.Y)-center).Magnitude
                            if score<=cfg.radius then
                                inCircle=inCircle+1
                                local clear,blocker=visible(part,m)
                                if clear then
                                    if m==locked then pinned=m; pinnedPart=part end
                                    if score<bestScore then best=m; bestPart=part; bestScore=score end
                                else
                                    blocked=blocked+1
                                    if not obstruction then obstruction=blocker end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for m,v in pairs(visuals) do
        if not seen[m] then v.box:Destroy(); v.hl:Destroy(); visuals[m]=nil end
    end
    locked=pinned or best
    local target=pinnedPart or bestPart
    if aiming and target then
        if cfg.takeover then
            if controlledCamera~=camera then
                releaseCamera()
                controlledCamera=camera; originalCameraType=camera.CameraType
            end
            camera.CameraType=Enum.CameraType.Scriptable
            -- Keep following local movement while normal camera updates are paused.
            local root=own and (own:FindFirstChild('HumanoidRootPart') or own.PrimaryPart)
            if root and root:IsA('BasePart') then
                if root==trackedRoot and lastRootPosition then
                    camera.CFrame=camera.CFrame+(root.Position-lastRootPosition)
                end
                trackedRoot=root; lastRootPosition=root.Position
            end
        else releaseCamera() end
        local pos=camera.CFrame.Position
        if (target.Position-pos).Magnitude>.001 then
            local desired=CFrame.lookAt(pos,target.Position)
            camera.CFrame=cfg.hard and desired or camera.CFrame:Lerp(desired,1-math.exp(-cfg.speed*dt))
            camera.Focus=CFrame.new(target.Position)
            local p=camera:WorldToViewportPoint(target.Position)
            marker.Position=UDim2.fromOffset(p.X,p.Y); marker.Visible=true
        end
    else locked=nil; releaseCamera() end
    elapsed=elapsed+dt
    if elapsed>.15 then
        elapsed=0
        local state='AIM OFF'
        if cfg.aim then
            if Input:GetFocusedTextBox() then state='TEXT INPUT ACTIVE'
            elseif not windowFocused then state='WINDOW NOT FOCUSED'
            elseif cfg.activation=='Hold RMB' and not held then state='HOLD RMB TO LOCK'
            elseif locked then state='LOCK: '..locked.Name
            elseif count==0 then state='NO ELIGIBLE TARGETS'
            elseif inCircle==0 then state='NO TARGET IN FOV'
            elseif blocked>0 then state='BLOCKED: '..(obstruction or 'WORLD')
            else state='SEARCHING' end
        end
        status.Text=not entities and 'WAITING FOR Workspace.Entities' or
            string.format('%d TARGETS | %s',count,state)
    end
end)

-- Project ESP only after aim and the game's remaining render callbacks.
Run:BindToRenderStep(bindName .. '_Overlay',Enum.RenderPriority.Last.Value+2,function()
    if dead then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local entities=workspace:FindFirstChild('Entities')
    local own=selfModel(entities)
    for _,m in ipairs(entities and entities:GetChildren() or {}) do
        if m:IsA('Model') and cfg.esp and eligible(m,own) then
            local part=m:FindFirstChild(cfg.part) or m:FindFirstChild('Head') or m.PrimaryPart
            if part and part:IsA('BasePart') then
                local distance=(part.Position-camera.CFrame.Position).Magnitude
                if distance<=cfg.range then
                    local v=visuals[m] or createVisual(m)
                    v.hl.Enabled=cfg.glow
                    v.hl.OutlineColor=m==locked and cyan or accent
                    local _,onScreen=camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local x,y,w,h=bounds(camera,m)
                        if x then
                            v.box.Visible=true
                            v.box.Position=UDim2.fromOffset(x,y)
                            v.box.Size=UDim2.fromOffset(w,h)
                            v.outline.Enabled=cfg.boxes
                            v.back.Visible=cfg.boxes
                            v.tag.Visible=cfg.names
                            local hp,maxHp=health(m)
                            local ratio=math.clamp(hp/math.max(maxHp,1),0,1)
                            v.bar.Size=UDim2.fromScale(1,ratio)
                            v.bar.BackgroundColor3=Color3.fromRGB(255,75,100):Lerp(cyan,ratio)
                            v.tag.Text=string.format('%s\n%d HP  /  %d st',m.Name,math.floor(hp),math.floor(distance))
                            v.outline.Color=m==locked and cyan or accent
                        end
                    end
                end
            end
        end
    end
    marker.Visible=false
    if locked then
        local part=locked:FindFirstChild(cfg.part) or locked:FindFirstChild('Head') or locked.PrimaryPart
        if part and part:IsA('BasePart') then
            local p,onScreen=camera:WorldToViewportPoint(part.Position)
            marker.Position=UDim2.fromOffset(p.X,p.Y)
            marker.Visible=onScreen
        end
    end
end)
