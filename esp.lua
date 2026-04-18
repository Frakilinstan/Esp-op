----------------------------------------------------
-- Franklinstan_scripts v1.0
-- RightShift = toggle menu
----------------------------------------------------

-- Core settings
local fov                = 120
local aimbotEnabled      = false
local espEnabled         = true
local headAimEnabled     = false
local teamCheck          = false
local aimSmoothing       = 0.2
local fovVisible         = true
local currentTarget      = nil
local currentTargetDistance = 0
local fovColor           = Color3.fromRGB(138, 80, 255)
local aimHotkey          = "MouseButton2"
local bindingAimKey      = false
local wallCheck          = false

-- ESP
local espBoxEnabled      = true
local espSkeletonEnabled = false
local espHealthEnabled   = true
local espNameEnabled     = true
local espDistEnabled     = true
local espBoxColor        = Color3.fromRGB(255, 255, 255)
local espSkeletonColor   = Color3.fromRGB(255, 255, 255)
local espHealthColor     = Color3.fromRGB(80, 220, 100)
local espNameColor       = Color3.fromRGB(255, 255, 255)
local espDistColor       = Color3.fromRGB(200, 200, 200)
local espTeamCheck       = false

-- Chams
local chamsEnabled       = false
local chamsVisColor      = Color3.fromRGB(255, 255, 255)
local chamsInvisColor    = Color3.fromRGB(255, 50,  50)
local chamsFillTrans     = 0.4
local chamsOutlineTrans  = 0.0

-- Rainbow
local rainbowESP         = false
local rainbowChams       = false
local rainbowFOV         = false
local rainbowHue         = 0

-- Crosshair
local crosshairVisible   = true
local crosshairAngle     = 0
local crosshairSize      = 10   -- arm length in px
local crosshairGap       = 3    -- gap from centre
local crosshairThick     = 1.5  -- line thickness
local crosshairSpeed     = 55   -- degrees per second
local crosshairRainbow   = false
local crosshairColor     = Color3.fromRGB(255, 255, 255)

-- Services
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local Camera             = workspace.CurrentCamera
local TweenService       = game:GetService("TweenService")
local LocalPlayer        = Players.LocalPlayer

----------------------------------------------------
-- HSV helper
----------------------------------------------------
local function hsvToRgb(h, s, v)
	local i = math.floor(h * 6) % 6
	local f = h * 6 - math.floor(h * 6)
	local p, q, t = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
	if i==0 then return Color3.new(v,t,p)
	elseif i==1 then return Color3.new(q,v,p)
	elseif i==2 then return Color3.new(p,v,t)
	elseif i==3 then return Color3.new(p,q,v)
	elseif i==4 then return Color3.new(t,p,v)
	else return Color3.new(v,p,q) end
end

----------------------------------------------------
-- ESP objects
----------------------------------------------------
local espObjects = {}
local SKEL_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function newESP(player)
	local obj = {highlight=nil, chams=nil, box={}, skeleton={}}
	for i=1,4 do
		local l=Drawing.new("Line") l.Visible=false l.Color=espBoxColor l.Thickness=1.5 l.Transparency=1
		table.insert(obj.box,l)
	end
	for i=1,#SKEL_PAIRS do
		local l=Drawing.new("Line") l.Visible=false l.Color=espSkeletonColor l.Thickness=1 l.Transparency=1
		table.insert(obj.skeleton,l)
	end
	obj.healthBg   = Drawing.new("Line") obj.healthBg.Visible=false   obj.healthBg.Color=Color3.fromRGB(0,0,0)   obj.healthBg.Thickness=4 obj.healthBg.Transparency=0.5
	obj.healthFill = Drawing.new("Line") obj.healthFill.Visible=false  obj.healthFill.Color=espHealthColor        obj.healthFill.Thickness=3 obj.healthFill.Transparency=1
	obj.nameText   = Drawing.new("Text") obj.nameText.Visible=false    obj.nameText.Color=espNameColor            obj.nameText.Size=13 obj.nameText.Font=Drawing.Fonts.UI obj.nameText.Outline=true obj.nameText.OutlineColor=Color3.fromRGB(0,0,0) obj.nameText.Center=true
	obj.distText   = Drawing.new("Text") obj.distText.Visible=false    obj.distText.Color=espDistColor            obj.distText.Size=11 obj.distText.Font=Drawing.Fonts.UI obj.distText.Outline=true obj.distText.OutlineColor=Color3.fromRGB(0,0,0) obj.distText.Center=true
	espObjects[player]=obj
end

local function removeESP(player)
	local obj=espObjects[player] if not obj then return end
	for _,l in ipairs(obj.box) do l:Remove() end
	for _,l in ipairs(obj.skeleton) do l:Remove() end
	obj.healthBg:Remove() obj.healthFill:Remove() obj.nameText:Remove() obj.distText:Remove()
	if obj.highlight and obj.highlight.Parent then obj.highlight:Destroy() end
	if obj.chams and obj.chams.Parent then obj.chams:Destroy() end
	espObjects[player]=nil
end

for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then newESP(p) end end
Players.PlayerAdded:Connect(newESP)
Players.PlayerRemoving:Connect(removeESP)

----------------------------------------------------
-- ESP render loop
----------------------------------------------------
RunService.RenderStepped:Connect(function()
	local myChar=LocalPlayer.Character
	local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myPos=myHRP and myHRP.Position or Vector3.zero
	local rbC=hsvToRgb(rainbowHue,1,1)

	for _,player in pairs(Players:GetPlayers()) do
		if player==LocalPlayer then continue end
		local obj=espObjects[player] if not obj then continue end
		local char=player.Character
		local hrp=char and char:FindFirstChild("HumanoidRootPart")
		local hum=char and char:FindFirstChild("Humanoid")
		local alive=hrp and hum and hum.Health>0
		local isTeammate=espTeamCheck and LocalPlayer.Team~=nil and player.Team==LocalPlayer.Team

		-- Highlight
		if espEnabled and alive and not isTeammate then
			if not obj.highlight or not obj.highlight.Parent then
				local hl=Instance.new("Highlight") hl.Adornee=char hl.FillColor=espBoxColor
				hl.FillTransparency=0.75 hl.OutlineColor=espBoxColor hl.OutlineTransparency=0.2 hl.Parent=char
				obj.highlight=hl
			else
				local bc=rainbowESP and rbC or espBoxColor
				obj.highlight.FillColor=bc obj.highlight.OutlineColor=bc obj.highlight.Enabled=true
			end
		elseif obj.highlight then obj.highlight.Enabled=false end

		-- Chams
		if chamsEnabled and espEnabled and alive and not isTeammate then
			local camPos=Camera.CFrame.Position
			local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances={myChar or workspace,char}
			local hit=workspace:Raycast(camPos,hrp.Position-camPos,rp)
			local vis=(hit==nil)
			local fc=rainbowChams and rbC or (vis and chamsVisColor or chamsInvisColor)
			if not obj.chams or not obj.chams.Parent then
				local ch=Instance.new("Highlight") ch.Adornee=char ch.FillColor=fc
				ch.FillTransparency=chamsFillTrans ch.OutlineColor=fc ch.OutlineTransparency=chamsOutlineTrans
				ch.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop ch.Parent=char obj.chams=ch
			else
				obj.chams.FillColor=fc obj.chams.OutlineColor=fc obj.chams.Enabled=true
			end
		elseif obj.chams then obj.chams.Enabled=false end

		local function hideAll()
			for _,l in ipairs(obj.box) do l.Visible=false end
			for _,l in ipairs(obj.skeleton) do l.Visible=false end
			obj.healthBg.Visible=false obj.healthFill.Visible=false
			obj.nameText.Visible=false obj.distText.Visible=false
		end

		if not espEnabled or not alive or isTeammate then hideAll() continue end

		local rs,onScreen=Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then hideAll() continue end

		local dist=math.floor((myPos-hrp.Position).Magnitude)
		local head=char:FindFirstChild("Head")
		local hs=head and Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
		local fs=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
		local topY=hs and hs.Y or (rs.Y-40)
		local botY=fs.Y
		local h=math.abs(botY-topY) local w=h*0.5 local cx=rs.X
		local x1,x2,y1,y2=cx-w/2,cx+w/2,topY,botY

		if espBoxEnabled then
			local bc=rainbowESP and rbC or espBoxColor
			local corners={{Vector2.new(x1,y1),Vector2.new(x2,y1)},{Vector2.new(x2,y1),Vector2.new(x2,y2)},{Vector2.new(x2,y2),Vector2.new(x1,y2)},{Vector2.new(x1,y2),Vector2.new(x1,y1)}}
			for i,l in ipairs(obj.box) do l.From=corners[i][1] l.To=corners[i][2] l.Color=bc l.Visible=true end
		else for _,l in ipairs(obj.box) do l.Visible=false end end

		if espSkeletonEnabled then
			for i,pair in ipairs(SKEL_PAIRS) do
				local pA=char:FindFirstChild(pair[1]) local pB=char:FindFirstChild(pair[2]) local l=obj.skeleton[i]
				if pA and pB then
					local sA=Camera:WorldToViewportPoint(pA.Position) local sB=Camera:WorldToViewportPoint(pB.Position)
					l.From=Vector2.new(sA.X,sA.Y) l.To=Vector2.new(sB.X,sB.Y)
					l.Color=rainbowESP and rbC or espSkeletonColor l.Visible=true
				else l.Visible=false end
			end
		else for _,l in ipairs(obj.skeleton) do l.Visible=false end end

		if espHealthEnabled then
			local ratio=math.clamp(hum.Health/(hum.MaxHealth>0 and hum.MaxHealth or 100),0,1)
			local bx=x1-6
			obj.healthBg.From=Vector2.new(bx,y1) obj.healthBg.To=Vector2.new(bx,y2) obj.healthBg.Visible=true
			obj.healthFill.From=Vector2.new(bx,y2) obj.healthFill.To=Vector2.new(bx,y2-(y2-y1)*ratio)
			obj.healthFill.Color=rainbowESP and rbC or espHealthColor obj.healthFill.Visible=true
		else obj.healthBg.Visible=false obj.healthFill.Visible=false end

		if espNameEnabled then
			obj.nameText.Text=player.DisplayName obj.nameText.Position=Vector2.new(cx,y1-16)
			obj.nameText.Color=rainbowESP and rbC or espNameColor obj.nameText.Visible=true
		else obj.nameText.Visible=false end

		if espDistEnabled then
			obj.distText.Text=dist.."m" obj.distText.Position=Vector2.new(cx,y2+2)
			obj.distText.Color=rainbowESP and rbC or espDistColor obj.distText.Visible=true
		else obj.distText.Visible=false end
	end
end)

----------------------------------------------------
-- Aimbot
----------------------------------------------------
local function canSee(part)
	local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances={LocalPlayer.Character or workspace,part.Parent}
	return workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp)==nil
end

local function getClosest()
	local closest,best=nil,math.huge
	local sc=Camera.ViewportSize/2
	local myChar=LocalPlayer.Character
	local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myPos=myHRP and myHRP.Position or Vector3.zero
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character then
			local tp=headAimEnabled and p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
			local h=p.Character:FindFirstChild("Humanoid")
			if tp and h and h.Health>0 and h:GetState()~=Enum.HumanoidStateType.Dead then
				local sp,on=Camera:WorldToViewportPoint(tp.Position)
				local d2=(Vector2.new(sp.X,sp.Y)-sc).Magnitude
				if on and d2<best and d2<=fov then
					if not teamCheck or p.Team~=LocalPlayer.Team then
						if not wallCheck or canSee(tp) then
							closest=p best=d2 currentTargetDistance=math.floor((myPos-tp.Position).Magnitude)
						end
					end
				end
			end
		end
	end
	return closest
end

local function isValid(p)
	if not p or not p.Character then return false end
	local h=p.Character:FindFirstChild("Humanoid")
	return h and h.Health>0 and h:GetState()~=Enum.HumanoidStateType.Dead
end

local function lockOn()
	if not currentTarget then return end
	if not isValid(currentTarget) then currentTarget=nil return end
	local char=currentTarget.Character
	local tp=headAimEnabled and char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not tp then currentTarget=nil return end
	local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if myHRP and (myHRP.Position.Y-tp.Position.Y)>80 then currentTarget=nil return end
	if wallCheck and not canSee(tp) then currentTarget=nil return end
	local pred=tp.Position+tp.AssemblyLinearVelocity*math.clamp(0.05+currentTargetDistance/2000,0.02,0.1)
	Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,pred),aimSmoothing)
end

RunService.RenderStepped:Connect(function()
	if not aimbotEnabled or bindingAimKey then return end
	local pressing=false
	if aimHotkey=="MouseButton2" then pressing=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	elseif aimHotkey=="MouseButton1" then pressing=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	elseif aimHotkey=="MouseButton3" then pressing=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
	else local ok,kc=pcall(function() return Enum.KeyCode[aimHotkey] end) if ok and kc then pressing=UserInputService:IsKeyDown(kc) end end
	if pressing then if not currentTarget then currentTarget=getClosest() end if currentTarget then lockOn() end
	else currentTarget=nil end
end)

----------------------------------------------------
-- FOV ring + rotating crosshair
----------------------------------------------------
local fovRing=Drawing.new("Circle") fovRing.Thickness=0.8 fovRing.Transparency=1 fovRing.Filled=false fovRing.NumSides=128

local crossLines={}
for i=1,4 do
	local l=Drawing.new("Line") l.Thickness=crosshairThick l.Transparency=1 l.Visible=true
	table.insert(crossLines,l)
end

RunService.RenderStepped:Connect(function(dt)
	local center=Camera.ViewportSize/2
	rainbowHue=(rainbowHue+dt*0.22)%1
	local rbC=hsvToRgb(rainbowHue,1,1)

	-- FOV
	local rc
	if rainbowFOV then rc=rbC
	elseif aimbotEnabled then rc=currentTarget and Color3.fromRGB(255,70,90) or Color3.fromRGB(80,230,130)
	else rc=fovColor end
	fovRing.Color=rc fovRing.Radius=fov fovRing.Position=center fovRing.Visible=fovVisible

	-- Rotating crosshair
	crosshairAngle = (crosshairAngle + dt * crosshairSpeed) % 360
	local xColor = crosshairRainbow and rbC or crosshairColor
	for i, ang in ipairs({crosshairAngle, crosshairAngle+90, crosshairAngle+180, crosshairAngle+270}) do
		local rad = math.rad(ang)
		local dx, dy = math.cos(rad), math.sin(rad)
		crossLines[i].From      = Vector2.new(center.X + dx*crosshairGap,                   center.Y + dy*crosshairGap)
		crossLines[i].To        = Vector2.new(center.X + dx*(crosshairGap+crosshairSize),    center.Y + dy*(crosshairGap+crosshairSize))
		crossLines[i].Color     = xColor
		crossLines[i].Thickness = crosshairThick
		crossLines[i].Visible   = crosshairVisible
	end
end)

----------------------------------------------------
-- GUI
----------------------------------------------------
local function createGUI()
	if game.CoreGui:FindFirstChild("RayfieldAimGUI") then
		game.CoreGui.RayfieldAimGUI:Destroy()
	end

	local W,H,SB_W,TOP_H=740,460,162,42
	local BG=Color3.fromRGB(13,13,15) local SIDEBAR=Color3.fromRGB(18,18,21)
	local PANEL=Color3.fromRGB(22,22,26) local CARD=Color3.fromRGB(28,28,33)
	local BORDER=Color3.fromRGB(40,40,50) local PURPLE=Color3.fromRGB(138,80,255)
	local WHITE=Color3.fromRGB(215,215,225) local GREY=Color3.fromRGB(100,100,120)
	local TOGON=Color3.fromRGB(138,80,255) local TOGOFF=Color3.fromRGB(45,45,55)
	local FONT=Enum.Font.Code

	local ScreenGui=Instance.new("ScreenGui")
	ScreenGui.Name="RayfieldAimGUI" ScreenGui.ResetOnSpawn=false
	ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling ScreenGui.Parent=game.CoreGui

	local Window=Instance.new("Frame",ScreenGui)
	Window.Name="Window" Window.Size=UDim2.new(0,W,0,H)
	Window.Position=UDim2.new(0.5,-W/2,0.5,-H/2) Window.BackgroundColor3=BG
	Window.BorderSizePixel=0 Window.Active=true Window.Draggable=true
	Instance.new("UICorner",Window).CornerRadius=UDim.new(0,6)
	local ws=Instance.new("UIStroke",Window) ws.Color=BORDER ws.Thickness=1

	-- Top bar
	local TopBar=Instance.new("Frame",Window)
	TopBar.Size=UDim2.new(1,0,0,TOP_H) TopBar.BackgroundColor3=SIDEBAR TopBar.BorderSizePixel=0
	Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,6)
	local tbfix=Instance.new("Frame",TopBar) tbfix.Size=UDim2.new(1,0,0,8) tbfix.Position=UDim2.new(0,0,1,-8) tbfix.BackgroundColor3=SIDEBAR tbfix.BorderSizePixel=0

	local tL=Instance.new("TextLabel",TopBar) tL.Size=UDim2.new(0,220,1,0) tL.Position=UDim2.new(0,14,0,0) tL.BackgroundTransparency=1 tL.Text="KOHAN_SCRIPTS" tL.TextColor3=WHITE tL.TextSize=15 tL.Font=FONT tL.TextXAlignment=Enum.TextXAlignment.Left
	local vL=Instance.new("TextLabel",TopBar) vL.Size=UDim2.new(0,60,1,0) vL.Position=UDim2.new(0.5,-30,0,0) vL.BackgroundTransparency=1 vL.Text="v1.0" vL.TextColor3=GREY vL.TextSize=12 vL.Font=FONT vL.TextXAlignment=Enum.TextXAlignment.Center
	local hL=Instance.new("TextLabel",TopBar) hL.Size=UDim2.new(0,120,1,0) hL.Position=UDim2.new(1,-148,0,0) hL.BackgroundTransparency=1 hL.Text="RSHIFT = HIDE" hL.TextColor3=GREY hL.TextSize=11 hL.Font=FONT hL.TextXAlignment=Enum.TextXAlignment.Right
	local cb=Instance.new("TextButton",TopBar) cb.Size=UDim2.new(0,26,0,26) cb.Position=UDim2.new(1,-34,0.5,-13) cb.BackgroundColor3=Color3.fromRGB(200,50,50) cb.BorderSizePixel=0 cb.Text="x" cb.TextColor3=WHITE cb.TextSize=14 cb.Font=FONT
	Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
	cb.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

	-- Sidebar
	local SB=Instance.new("Frame",Window)
	SB.Size=UDim2.new(0,SB_W,1,-TOP_H) SB.Position=UDim2.new(0,0,0,TOP_H) SB.BackgroundColor3=SIDEBAR SB.BorderSizePixel=0
	local sbStr=Instance.new("UIStroke",SB) sbStr.Color=BORDER sbStr.Thickness=1
	local sbLL=Instance.new("UIListLayout",SB) sbLL.Padding=UDim.new(0,2) sbLL.HorizontalAlignment=Enum.HorizontalAlignment.Center
	local sbPad=Instance.new("UIPadding",SB) sbPad.PaddingTop=UDim.new(0,10)

	-- Content
	local CT=Instance.new("Frame",Window)
	CT.Size=UDim2.new(1,-SB_W,1,-TOP_H) CT.Position=UDim2.new(0,SB_W,0,TOP_H)
	CT.BackgroundColor3=PANEL CT.BorderSizePixel=0 CT.ClipsDescendants=true

	local NAV={{n="Aimbot",i="[A]"},{n="ESP",i="[E]"},{n="Rainbow",i="[R]"},{n="Misc",i="[M]"}}
	local navBtns={} local panels={}

	local function makePanel(name)
		local sc=Instance.new("ScrollingFrame",CT)
		sc.Name=name sc.Size=UDim2.new(1,0,1,0) sc.BackgroundTransparency=1
		sc.BorderSizePixel=0 sc.ScrollBarThickness=2 sc.ScrollBarImageColor3=PURPLE
		sc.CanvasSize=UDim2.new(0,0,0,0) sc.AutomaticCanvasSize=Enum.AutomaticSize.Y
		sc.Visible=(name=="Aimbot")
		local ll=Instance.new("UIListLayout",sc) ll.Padding=UDim.new(0,6) ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
		local pad=Instance.new("UIPadding",sc) pad.PaddingTop=UDim.new(0,10) pad.PaddingBottom=UDim.new(0,10) pad.PaddingLeft=UDim.new(0,8) pad.PaddingRight=UDim.new(0,8)
		panels[name]=sc
	end
	for _,it in ipairs(NAV) do makePanel(it.n) end

	local function switchTab(name)
		for n,p in pairs(panels) do p.Visible=(n==name) end
		for n,b in pairs(navBtns) do
			local on=(n==name)
			b.BackgroundTransparency=on and 0 or 1
			b.BackgroundColor3=on and Color3.fromRGB(30,26,44) or BG
			for _,c in ipairs(b:GetChildren()) do if c:IsA("TextLabel") then c.TextColor3=on and PURPLE or GREY end end
		end
	end

	for _,it in ipairs(NAV) do
		local btn=Instance.new("TextButton",SB)
		btn.Size=UDim2.new(1,-8,0,36) btn.BackgroundTransparency=1 btn.BackgroundColor3=BG btn.BorderSizePixel=0 btn.Text=""
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
		local iL=Instance.new("TextLabel",btn) iL.Size=UDim2.new(0,28,1,0) iL.Position=UDim2.new(0,8,0,0) iL.BackgroundTransparency=1 iL.Text=it.i iL.TextColor3=GREY iL.TextSize=11 iL.Font=FONT
		local nL=Instance.new("TextLabel",btn) nL.Size=UDim2.new(1,-40,1,0) nL.Position=UDim2.new(0,38,0,0) nL.BackgroundTransparency=1 nL.Text=it.n:upper() nL.TextColor3=GREY nL.TextSize=12 nL.Font=FONT nL.TextXAlignment=Enum.TextXAlignment.Left
		b