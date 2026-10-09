--[[ ☀️ Sun Menu | Delta — ส่วนที่ 1/3 : แกนระบบ + UI + ฟังก์ชันทั้ง 30 ]]
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local Stats=game:GetService("Stats")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer
local function cam() return workspace.CurrentCamera end
local START=os.clock()
local GENV=(getgenv and getgenv()) or _G
if GENV.__SUNMENU_UNLOAD then pcall(GENV.__SUNMENU_UNLOAD) end -- กันหน้าต่างซ้ำ

-- ===== ค่าตั้งต้น / ล็อก / อีเวนต์ / การเชื่อมต่อ =====
local Cfg={theme=1,alpha=15,scale=100,anim=true,sound=true,rainbow=true,glow=true,stars=true,showName=true,showTime=true,showFps=true,showPing=true}
local DEF=table.clone(Cfg)
local FILE_CFG,FILE_KB="SunMenu_settings.json","SunMenu_knowledge.json"
local Log={items={},errs=0}
function Log.add(l,m)
 table.insert(Log.items,{os.clock()-START,l,tostring(m)})
 if l=="E" then Log.errs+=1 end
 if #Log.items>200 then table.remove(Log.items,1) end
end
local function safe(tag,fn,...)
 local ok,e=pcall(fn,...)
 if not ok then Log.add("E",tag..": "..tostring(e)) end
 return ok,e
end
local Ev={h={}}
function Ev.on(n,f) Ev.h[n]=Ev.h[n] or {} table.insert(Ev.h[n],f) end
function Ev.emit(n,...) for _,f in ipairs(Ev.h[n] or {}) do safe("event "..n,f,...) end end
local Conns={}
local function conn(sig,fn)
 local c=sig:Connect(function(...) safe("signal",fn,...) end)
 table.insert(Conns,c) return c
end

-- ===== ตรวจความสามารถของตัวรัน (ไม่สมมติว่ามีทุก API) =====
local Cap={file=(type(writefile)=="function" and type(readfile)=="function" and type(isfile)=="function"),gethui=(type(gethui)=="function")}
local function execName()
 if type(identifyexecutor)=="function" then
  local ok,n=pcall(identifyexecutor)
  if ok and n then return tostring(n) end
 end
 return "ไม่ทราบ"
end
local function pingNow()
 local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
 if ok and type(v)=="number" then return v end
end
Cap.ping=(pingNow()~=nil)
local function saveFile(name,tbl)
 if not Cap.file then return false,"ตัวรันนี้ไม่รองรับการบันทึกไฟล์ (writefile)" end
 local ok,e=pcall(function() writefile(name,HttpService:JSONEncode(tbl)) end)
 if not ok then Log.add("E","บันทึก "..name..": "..tostring(e)) return false,tostring(e) end
 return true
end
local function loadFile(name)
 if not Cap.file then return nil end
 local ok,d=pcall(function() if isfile(name) then return HttpService:JSONDecode(readfile(name)) end end)
 if ok then return d end
 Log.add("E","โหลด "..name..": "..tostring(d))
end

-- ===== ระบบจัดการฟังก์ชันส่วนกลาง (FM) =====
local FM={list={},by={},st={}}
local function check(d)
 if not d.avail then return true end
 local pc,ok,why=pcall(d.avail)
 if not pc then return false,tostring(ok) end
 return ok,why
end
function FM.add(d)
 d.id=#FM.list+1
 table.insert(FM.list,d) FM.by[d.id]=d
 FM.st[d.id]={on=(d.default==true),val=d.slider and d.slider.def or nil,msg=""}
 return d
end
function FM.setOn(id,on)
 local d,s=FM.by[id],FM.st[id]
 if d.kind~="toggle" then return false end
 if on then
  local ok,why=check(d)
  if not ok then
   s.on=false s.msg="ใช้ไม่ได้: "..tostring(why)
   Log.add("W",d.name.." — "..tostring(why)) Ev.emit("fn",id) Ev.emit("toast",s.msg) return false
  end
  s.on=true s.msg=""
  if d.on then safe(d.name,d.on) end
 else
  s.on=false s.msg=""
  if d.off then safe(d.name,d.off) end
 end
 Ev.emit("fn",id) return true
end
function FM.setVal(id,v)
 local d,s=FM.by[id],FM.st[id]
 s.val=v
 if d.onval then safe(d.name,d.onval,v) end
 Ev.emit("fn",id)
end
function FM.run(id)
 local d,s=FM.by[id],FM.st[id]
 local ok,why=check(d)
 if not ok then
  s.msg="ใช้ไม่ได้: "..tostring(why) Log.add("W",d.name.." — "..tostring(why))
  Ev.emit("fn",id) Ev.emit("toast",s.msg) return
 end
 local pc,r1,r2=pcall(d.action)
 if not pc then s.msg="ผิดพลาด: "..tostring(r1) Log.add("E",d.name..": "..tostring(r1))
 elseif r1==false then s.msg=r2 or "ไม่สำเร็จ" Log.add("W",d.name..": "..s.msg)
 else s.msg=r2 or "ทำแล้ว" end
 Ev.emit("fn",id) Ev.emit("toast",s.msg)
end
function FM.init()
 for _,d in ipairs(FM.list) do
  local s=FM.st[d.id]
  if d.slider and d.onval then safe(d.name,d.onval,s.val) end
  if d.kind=="toggle" and s.on then s.on=false FM.setOn(d.id,true) end
 end
end

-- ===== ธีม / ตัวช่วย UI =====
local white=Color3.new(1,1,1)
local OFFC=Color3.fromRGB(55,65,95)
local TH={
 {n="ฟ้า",acc=Color3.fromRGB(70,170,255),panel=Color3.fromRGB(22,30,52),panel2=Color3.fromRGB(30,42,72),bg=Color3.fromRGB(12,16,30),top=Color3.fromRGB(18,24,44)},
 {n="ม่วง",acc=Color3.fromRGB(165,110,255),panel=Color3.fromRGB(34,24,56),panel2=Color3.fromRGB(48,34,80),bg=Color3.fromRGB(18,12,32),top=Color3.fromRGB(28,18,48)},
 {n="เขียว",acc=Color3.fromRGB(70,220,130),panel=Color3.fromRGB(20,44,36),panel2=Color3.fromRGB(28,62,50),bg=Color3.fromRGB(10,24,20),top=Color3.fromRGB(16,36,30)},
 {n="ชมพู",acc=Color3.fromRGB(255,110,170),panel=Color3.fromRGB(54,24,40),panel2=Color3.fromRGB(76,34,58),bg=Color3.fromRGB(30,12,22),top=Color3.fromRGB(46,18,34)},
 {n="ส้มอาทิตย์",acc=Color3.fromRGB(255,170,50),panel=Color3.fromRGB(54,38,20),panel2=Color3.fromRGB(76,54,28),bg=Color3.fromRGB(30,20,10),top=Color3.fromRGB(46,32,16)},
}
local function TC(k) return TH[Cfg.theme][k] end
local themed={}
local function tr(i,p,k) table.insert(themed,{i,p,k}) i[p]=TC(k) return i end
local function applyTheme()
 for _,t in ipairs(themed) do if t[1].Parent then t[1][t[2]]=TC(t[3]) end end
 Ev.emit("theme")
end
local function new(c,p,par) local o=Instance.new(c) for k,v in pairs(p) do o[k]=v end o.Parent=par return o end
local function corner(o,r) return new("UICorner",{CornerRadius=UDim.new(0,r)},o) end
local function stroke(o,t,col) return new("UIStroke",{Thickness=t,Color=col or white,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end
local function txt(par,t,size,pos,sz,col,xa)
 return new("TextLabel",{BackgroundTransparency=1,Text=t,TextSize=size,Position=pos,Size=sz,TextColor3=col or white,
  Font=Enum.Font.GothamMedium,TextXAlignment=xa or Enum.TextXAlignment.Left,TextWrapped=true},par)
end
local function fmtTime(s) s=math.floor(s) return string.format("%02d:%02d:%02d",s//3600,(s%3600)//60,s%60) end
local glass={}
local function gl(f,off)
 table.insert(glass,{f,off or 0})
 f.BackgroundTransparency=math.clamp(Cfg.alpha/100+(off or 0),0,1) return f
end
local function applyGlass()
 for _,g in ipairs(glass) do if g[1].Parent then g[1].BackgroundTransparency=math.clamp(Cfg.alpha/100+g[2],0,1) end end
end
local RB=ColorSequence.new{
 ColorSequenceKeypoint.new(0,Color3.fromRGB(255,60,60)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,170,40)),
 ColorSequenceKeypoint.new(.34,Color3.fromRGB(255,240,70)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(70,230,110)),
 ColorSequenceKeypoint.new(.67,Color3.fromRGB(70,200,255)),ColorSequenceKeypoint.new(.84,Color3.fromRGB(170,110,255)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(255,60,60))}
local PLAIN=ColorSequence.new(Color3.fromRGB(190,205,235))
local rb={}
local function rainbow(p,sp) local g=new("UIGradient",{Color=RB},p) table.insert(rb,{g,sp or 90}) return g end
local function applyRainbow() for _,r in ipairs(rb) do r[1].Color=Cfg.rainbow and RB or PLAIN end end
local function tween(o,t,p,st)
 if not Cfg.anim then for k,v in pairs(p) do o[k]=v end return nil end
 local tw=TS:Create(o,TweenInfo.new(t,st or Enum.EasingStyle.Quad),p) tw:Play() return tw
end

-- ===== ScreenGui / เสียง / ปิดระบบ =====
local Gui=new("ScreenGui",{Name="SunMenu",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999})
pcall(function() Gui.Parent=(Cap.gethui and gethui()) or game:GetService("CoreGui") end)
if not Gui.Parent then Gui.Parent=LP:WaitForChild("PlayerGui") end
local Snd=new("Sound",{SoundId="rbxassetid://6895079853",Volume=.4},Gui)
local function click() if Cfg.sound then pcall(function() Snd:Play() end) end end
local function unload()
 pcall(function() Ev.emit("unload") end)
 for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
 Conns={}
 pcall(function() Gui:Destroy() end)
end
GENV.__SUNMENU_UNLOAD=unload

local function hum() local c=LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c=LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function thumb(id) return "rbxthumb://type=AvatarHeadShot&id="..id.."&w=150&h=150" end
local UI={}

local function drag(handle,target,onTap)
 local dragging,startIn,startPos,moved=false,nil,nil,false
 conn(handle.InputBegan,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   dragging=true moved=false startIn=i.Position startPos=target.Position
   local c
   c=i.Changed:Connect(function()
    if i.UserInputState==Enum.UserInputState.End then
     dragging=false c:Disconnect()
     if not moved and onTap then safe("tap",onTap) end
    end
   end)
  end
 end)
 conn(UIS.InputChanged,function(i)
  if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
   local d=i.Position-startIn
   if d.Magnitude>6 then moved=true end
   if moved then target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end
  end
 end)
end

-- ===== ปุ่มวงกลมลอย ☀️ (ขอบรุ้ง 4 ชั้น + แสงเรือง + ดาว 🌟) =====
local Holder=new("Frame",{Size=UDim2.fromOffset(84,84),Position=UDim2.new(0,40,.5,-42),BackgroundTransparency=1,Visible=false},Gui)
local Inner=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},Holder)
local Aura=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(98,98),BackgroundColor3=Color3.fromRGB(255,190,70),BackgroundTransparency=.7},Inner)
corner(Aura,49)
for i=1,4 do
 local sz=84-(i-1)*10
 local ring=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(sz,sz),BackgroundTransparency=1},Inner)
 corner(ring,sz/2) rainbow(stroke(ring,2.5),(i%2==0 and -1 or 1)*(60+i*28))
end
local Core=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(40,40),BackgroundColor3=Color3.fromRGB(40,24,8)},Inner)
corner(Core,20)
local Sun=new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="☀️",TextSize=26,TextColor3=white,Font=Enum.Font.Gotham},Core)
local OrbBtn=new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=5},Inner)
task.spawn(function() -- ดาว 🌟 ล้อมรอบ
 while Gui.Parent do
  task.wait(.25)
  if Holder.Visible and Cfg.stars then
   local ang=math.random()*math.pi*2
   local r=40+math.random()*10
   local s=new("TextLabel",{BackgroundTransparency=1,Text="🌟",TextSize=math.random(8,14),AnchorPoint=Vector2.new(.5,.5),
    Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(42+math.cos(ang)*r,42+math.sin(ang)*r),ZIndex=6},Inner)
   local t=TS:Create(s,TweenInfo.new(1),{TextTransparency=1,Rotation=120,
    Position=UDim2.fromOffset(42+math.cos(ang)*(r+12),42+math.sin(ang)*(r+12))})
   t:Play() t.Completed:Connect(function() s:Destroy() end)
  end
 end
end)

-- ===== หน้าต่างหลัก =====
local Win=new("Frame",{Size=UDim2.fromOffset(500,310),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Visible=false,ClipsDescendants=true},Gui)
tr(Win,"BackgroundColor3","bg") gl(Win,0) corner(Win,16)
local WS=stroke(Win,2.5) WS.Transparency=.2 rainbow(WS,60)
local WScale=new("UIScale",{Scale=1},Win)  -- แอนิเมชันเปิด/ปิด
local SScale=new("UIScale",{Scale=1},Win)  -- ขนาดที่ผู้ใช้ปรับ

local Top=new("Frame",{Size=UDim2.new(1,0,0,46)},Win)
tr(Top,"BackgroundColor3","top") gl(Top,.05) corner(Top,14)
local Av=new("ImageLabel",{Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(8,6),BackgroundColor3=OFFC,Image=thumb(LP.UserId)},Top)
corner(Av,17) stroke(Av,2,TC("acc"))
local NameL=txt(Top,LP.DisplayName.." (@"..LP.Name..")",13,UDim2.fromOffset(48,0),UDim2.new(1,-350,1,0))
NameL.TextWrapped=false NameL.TextTruncate=Enum.TextTruncate.AtEnd
local TimeL=txt(Top,"⏱ 00:00:00",12,UDim2.new(1,-296,0,0),UDim2.fromOffset(84,46),Color3.fromRGB(255,215,130))
local FpsL=txt(Top,"FPS: --",12,UDim2.new(1,-212,0,0),UDim2.fromOffset(58,46),Color3.fromRGB(120,255,170))
local PingL=txt(Top,"Ping: --",12,UDim2.new(1,-154,0,0),UDim2.fromOffset(78,46),Color3.fromRGB(120,220,255))
local Mini=new("TextButton",{Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-72,0,9),Text="▁",TextColor3=white,TextSize=14,Font=Enum.Font.GothamBold},Top)
tr(Mini,"BackgroundColor3","panel2") corner(Mini,9)
local Close=new("TextButton",{Size=UDim2.fromOffset(30,28),Position=UDim2.new(1,-38,0,9),Text="✕",TextColor3=white,TextSize=14,Font=Enum.Font.GothamBold},Top)
tr(Close,"BackgroundColor3","panel2") corner(Close,9)
drag(Top,Win)

local Side=new("Frame",{Size=UDim2.new(0,120,1,-52),Position=UDim2.fromOffset(6,50)},Win)
tr(Side,"BackgroundColor3","panel") gl(Side,.05) corner(Side,12)
new("UIListLayout",{Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Center},Side)
new("UIPadding",{PaddingTop=UDim.new(0,8)},Side)
local Content=new("Frame",{Size=UDim2.new(1,-138,1,-58),Position=UDim2.fromOffset(132,52),BackgroundTransparency=1},Win)
local P1=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},Content)   -- หน้าเมนูหลัก
local P2=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},Content) -- หน้า AI

-- แผงแสดงข้อมูล (ใช้ร่วมกันหลายฟังก์ชัน)
local Info=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(10,14,28),BackgroundTransparency=.03,Visible=false,ZIndex=20},Content)
corner(Info,12) rainbow(stroke(Info,2),70)
local InfoT=txt(Info,"",14,UDim2.fromOffset(10,6),UDim2.new(1,-50,0,24)) InfoT.Font=Enum.Font.GothamBold
local InfoX=new("TextButton",{Size=UDim2.fromOffset(28,24),Position=UDim2.new(1,-36,0,6),BackgroundColor3=OFFC,Text="✕",TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold},Info)
corner(InfoX,8)
local InfoS=new("ScrollingFrame",{Size=UDim2.new(1,-16,1,-40),Position=UDim2.fromOffset(8,34),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},Info)
local InfoB=new("TextLabel",{Size=UDim2.new(1,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextColor3=white,TextSize=12,
 Font=Enum.Font.GothamMedium,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text=""},InfoS)
UI.showInfo=function(t,b) InfoT.Text=t InfoB.Text=b InfoS.CanvasPosition=Vector2.zero Info.Visible=true end
conn(InfoX.Activated,function() click() Info.Visible=false end)

-- ข้อความแจ้งสั้นๆ
local Toast=new("TextLabel",{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-4),Size=UDim2.new(.9,0,0,26),BackgroundColor3=Color3.fromRGB(10,14,28),
 BackgroundTransparency=.1,Text="",TextColor3=white,TextSize=11,Font=Enum.Font.GothamMedium,Visible=false,ZIndex=30,TextWrapped=true},Content)
corner(Toast,8) stroke(Toast,1.5,Color3.fromRGB(255,190,70))
local toastId=0
local function toast(m)
 toastId+=1 local my=toastId
 Toast.Text=tostring(m) Toast.Visible=true
 task.delay(2.6,function() if toastId==my then Toast.Visible=false end end)
end
Ev.on("toast",toast) UI.toast=toast

-- แถบเมนูหลักด้านซ้าย
local tabBtns={}
local function selectTab(i)
 for k,b in ipairs(tabBtns) do b.BackgroundColor3=(k==i) and TC("acc") or TC("panel") end
 P1.Visible=(i==1) P2.Visible=(i==2) if UI.onTab then UI.onTab(i) end UI.tab=i Info.Visible=false
end
local function addTab(text)
 local b=new("TextButton",{Size=UDim2.new(1,-12,0,48),BackgroundColor3=TC("panel"),Text=text,TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold,TextWrapped=true},Side)
 corner(b,10) table.insert(tabBtns,b)
 local idx=#tabBtns
 conn(b.Activated,function() click() selectTab(idx) end)
end
addTab("🌟 เมนูทั่วไป/หลัก") addTab("🌐 เมนู AI")
Ev.on("theme",function() selectTab(UI.tab or 1) end)

-- ===== เปิด/ปิด/ย่อ/รีเซ็ต/แสดงผล =====
local winOpen=false
local function openWin()
 winOpen=true Win.Visible=true click()
 if Cfg.anim then WScale.Scale=.6 tween(WScale,.25,{Scale=1},Enum.EasingStyle.Back) else WScale.Scale=1 end
end
local function closeWin()
 winOpen=false click()
 if Cfg.anim then
  local tw=tween(WScale,.18,{Scale=.6})
  tw.Completed:Connect(function() if not winOpen then Win.Visible=false end end)
 else Win.Visible=false end
end
conn(Close.Activated,closeWin)
drag(OrbBtn,Holder,function() if winOpen then closeWin() else openWin() end end)
local function setCollapsed(c)
 tween(Win,.2,{Size=c and UDim2.fromOffset(500,46) or UDim2.fromOffset(500,310)})
end
conn(Mini.Activated,function() click() FM.setOn(24,not FM.st[24].on) end)
local function resetPos()
 Win.Position=UDim2.fromScale(.5,.5) Holder.Position=UDim2.new(0,40,.5,-42)
end
local function applyDisplay()
 Av.Visible=Cfg.showName NameL.Visible=Cfg.showName TimeL.Visible=Cfg.showTime
 FpsL.Visible=Cfg.showFps PingL.Visible=(Cfg.showPing and Cap.ping)
end
local function applyAll()
 applyTheme() applyGlass() applyRainbow() SScale.Scale=Cfg.scale/100 applyDisplay()
end

-- ===== ลูปหลักของ UI =====
local frames,acc=0,0
conn(RS.Heartbeat,function(dt)
 local t=os.clock()-START
 if Cfg.rainbow and Cfg.anim then for _,r in ipairs(rb) do r[1].Rotation=(r[1].Rotation+dt*r[2])%360 end end
 Aura.Visible=Cfg.glow
 if Cfg.glow then Aura.BackgroundTransparency=.62+.2*math.sin(t*3) end
 Inner.Position=Cfg.anim and UDim2.fromOffset(0,math.sin(t*2)*5) or UDim2.new()
 Sun.Rotation=Cfg.anim and (Sun.Rotation+dt*30)%360 or 0
 frames+=1 acc+=dt
 if acc>=.5 then
  UI.fpsV=math.floor(frames/acc+.5) frames=0 acc=0
  FpsL.Text="FPS: "..UI.fpsV
  local p=pingNow()
  PingL.Text=p and ("Ping: "..math.floor(p).." ms") or "Ping: --"
  TimeL.Text="⏱ "..fmtTime(t)
 end
end)

--[[ ===== ฟังก์ชันทั้ง 30 อย่าง ===== ]]
local Mod={}
function Mod.add(name,install)
 local ok,e=pcall(install)
 Log.add(ok and "I" or "E","โมดูล "..name..(ok and " พร้อมใช้งาน" or (" ผิดพลาด: "..tostring(e))))
end
local CATS={"🏃 หมวดการเคลื่อนไหว","👤 หมวดผู้เล่น","👁️ หมวดการแสดงผล","⚙️ หมวดการตั้งค่า","🛠️ หมวดเครื่องมือ"}
local function needChar() if hum() and root() then return true end return false,"ไม่พบตัวละคร" end
local function fmt1(n) return string.format("%.1f",n) end

-- ===== ระบบบันทึก/โหลดการตั้งค่า =====
local Settings={}
function Settings.collect()
 local t={cfg={},fns={}}
 for k,v in pairs(Cfg) do t.cfg[k]=v end
 for _,d in ipairs(FM.list) do
  local s=FM.st[d.id]
  t.fns[tostring(d.id)]={on=(d.kind=="toggle" and d.persist~=false) and s.on or false,val=s.val}
 end
 return t
end
function Settings.save() return saveFile(FILE_CFG,Settings.collect()) end
function Settings.load()
 local t=loadFile(FILE_CFG)
 if type(t)~="table" then return false end
 for k,v in pairs(t.cfg or {}) do if DEF[k]~=nil and type(v)==type(DEF[k]) then Cfg[k]=v end end
 for id,v in pairs(t.fns or {}) do
  local d=FM.by[tonumber(id)]
  if d and type(v)=="table" then
   local s=FM.st[d.id]
   if d.slider and type(v.val)=="number" then s.val=math.clamp(v.val,d.slider.min,d.slider.max) end
   if d.kind=="toggle" and d.persist~=false then s.on=(v.on==true) end
  end
 end
 return true
end
function FM.reset()
 for k,v in pairs(DEF) do Cfg[k]=v end
 for _,d in ipairs(FM.list) do
  local s=FM.st[d.id]
  if d.kind=="toggle" and s.on then FM.setOn(d.id,false) end
  if d.slider then s.val=d.slider.def if d.onval then safe(d.name,d.onval,s.val) end end
 end
 for _,d in ipairs(FM.list) do if d.kind=="toggle" and d.default then FM.setOn(d.id,true) end end
 applyAll()
end

-- ===== 🏃 หมวดการเคลื่อนไหว (ฟังก์ชัน 1-7) =====
Mod.add("movement",function()
 local V={fs=60,up=false,down=false}
 local FB=new("Frame",{Size=UDim2.fromOffset(56,116),Position=UDim2.new(1,-76,.5,-58),BackgroundTransparency=1,Visible=false},Gui)
 for _,def in ipairs({{"⬆",0,"up"},{"⬇",62,"down"}}) do
  local b=new("TextButton",{Size=UDim2.fromOffset(56,54),Position=UDim2.fromOffset(0,def[2]),BackgroundColor3=Color3.fromRGB(30,42,72),BackgroundTransparency=.2,
   Text=def[1],TextColor3=white,TextSize=22,Font=Enum.Font.GothamBold},FB)
  corner(b,14) stroke(b,2,TC("acc"))
  conn(b.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then V[def[3]]=true end end)
  conn(b.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then V[def[3]]=false end end)
 end
 local function stopFly()
  if V.bv then V.bv:Destroy() V.bv=nil end
  if V.bg then V.bg:Destroy() V.bg=nil end
  local h=hum() if h then h.PlatformStand=false end
  FB.Visible=false
 end
 local function controls()
  local ok,c=pcall(function()
   local ps=LP:WaitForChild("PlayerScripts",2)
   return require(ps:WaitForChild("PlayerModule",2)):GetControls()
  end)
  if ok then return c end
 end

 FM.add{cat=1,name="บิน",kind="toggle",game=true,persist=false,k={"บิน","fly"},
  desc="บินอิสระไปตามทิศที่กล้องมอง ใช้จอยเดิน/WASD ปุ่ม ⬆⬇ (หรือ Space/Shift) เพื่อขึ้นลง ปรับความเร็วได้ 1-500",
  slider={min=1,max=500,def=60,label="ความเร็วบิน"},avail=needChar,on=function() FB.Visible=true end,off=stopFly,onval=function(v) V.fs=v end}
 FM.add{cat=1,name="วิ่งเร็ว",kind="toggle",game=true,k={"วิ่งเร็ว","วิ่ง","speed"},
  desc="เพิ่มความเร็วเดินเป็น 3 เท่าของค่าเดิมของเกม",avail=needChar}
 FM.add{cat=1,name="กระโดดไม่จำกัด",kind="toggle",game=true,k={"กระโดดไม่จำกัด","กระโดด","jump"},
  desc="กระโดดกลางอากาศได้ไม่จำกัดครั้ง (ใช้ไม่ได้ขณะเปิดโหมดบิน)",avail=needChar}
 FM.add{cat=1,name="ปรับความเร็วการเดิน",kind="toggle",game=true,k={"ความเร็วการเดิน","ความเร็วเดิน","walkspeed"},
  desc="กำหนดความเร็วเดินเองด้วยสไลด์ 1-300 (ถ้าเปิดวิ่งเร็วหรือเดินช้าพร้อมกัน สองอย่างนั้นจะมีลำดับสูงกว่า)",
  slider={min=1,max=300,def=40,label="ความเร็วเดิน"},avail=needChar}
 FM.add{cat=1,name="ปรับความสูงการกระโดด",kind="toggle",game=true,k={"ความสูงการกระโดด","ความสูงกระโดด","แรงกระโดด"},
  desc="กำหนดแรงกระโดดเองด้วยสไลด์ 10-500",slider={min=10,max=500,def=100,label="แรงกระโดด"},avail=needChar}
 FM.add{cat=1,name="เดินช้า",kind="toggle",game=true,k={"เดินช้า","ช้า"},
  desc="ลดความเร็วเดินเหลือ 40% ของค่าเดิมของเกม",avail=needChar}
 FM.add{cat=1,name="ล็อก/ปลดล็อกการเคลื่อนไหว",kind="toggle",persist=false,k={"ล็อกการเคลื่อนไหว","ล็อก","ปลดล็อก"},
  desc="เปิด = ล็อกการควบคุมเดิน/กระโดดของคุณชั่วคราว ปิด = กลับมาควบคุมได้ (ทำงานผ่าน PlayerModule ของเกมเท่านั้น)",
  avail=function() if controls() then return true end return false,"ไม่พบระบบควบคุมของเกม (PlayerModule)" end,
  on=function() local c=controls() if c then c:Disable() end end,off=function() local c=controls() if c then c:Enable() end end}

 conn(UIS.JumpRequest,function()
  if FM.st[3].on and not FM.st[1].on then local h=hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
 end)
 conn(RS.Heartbeat,function()
  local h,r=hum(),root()
  if not h then return end
  local st=FM.st
  local mode=(st[2].on and 2) or (st[6].on and 6) or (st[4].on and 4) or nil
  if mode then
   if not V.ws0 then V.ws0=h.WalkSpeed end
   h.WalkSpeed=(mode==2 and V.ws0*3) or (mode==6 and V.ws0*.4) or st[4].val
  elseif V.ws0 then h.WalkSpeed=V.ws0 V.ws0=nil end
  if st[5].on then
   if not V.jp0 then V.jp0=h.JumpPower end
   h.UseJumpPower=true h.JumpPower=st[5].val
  elseif V.jp0 then h.JumpPower=V.jp0 V.jp0=nil end
  if st[1].on and r then
   if not V.bv or V.bv.Parent~=r then
    if V.bv then V.bv:Destroy() end
    if V.bg then V.bg:Destroy() end
    V.bv=new("BodyVelocity",{MaxForce=Vector3.new(1e9,1e9,1e9),Velocity=Vector3.zero},r)
    V.bg=new("BodyGyro",{MaxTorque=Vector3.new(1e9,1e9,1e9),P=1e4,D=500,CFrame=r.CFrame},r)
   end
   h.PlatformStand=true
   local cf=cam().CFrame
   local flat=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
   local d=h.MoveDirection
   local mv=Vector3.zero
   if flat.Magnitude>.001 then
    flat=flat.Unit
    if d.Magnitude>0 then mv=cf.LookVector*d:Dot(flat)+cf.RightVector*d:Dot(flat:Cross(Vector3.yAxis)) end
    V.bg.CFrame=CFrame.lookAt(r.Position,r.Position+flat)
   end
   local vy=((UIS:IsKeyDown(Enum.KeyCode.Space) or V.up) and 1 or 0)-((UIS:IsKeyDown(Enum.KeyCode.LeftShift) or V.down) and 1 or 0)
   V.bv.Velocity=(mv+Vector3.new(0,vy,0))*V.fs
  end
 end)
 Ev.on("unload",function()
  stopFly()
  local h=hum()
  if h then
   if V.ws0 then h.WalkSpeed=V.ws0 end
   if V.jp0 then h.JumpPower=V.jp0 end
  end
  if FM.st[7].on then local c=controls() if c then c:Enable() end end
 end)
end)

-- ===== 👤 หมวดผู้เล่น (ฟังก์ชัน 8-13) =====
Mod.add("player",function()
 local HUD=new("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,8),Size=UDim2.fromOffset(200,22),BackgroundColor3=Color3.fromRGB(10,14,28),BackgroundTransparency=.2,Visible=false},Gui)
 corner(HUD,11) stroke(HUD,1.5,white)
 local HFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(70,220,120)},HUD) corner(HFill,11)
 local HTxt=txt(HUD,"",12,UDim2.new(),UDim2.fromScale(1,1),white,Enum.TextXAlignment.Center)
 HTxt.TextWrapped=false
 local rstAt=0

 FM.add{cat=2,name="แสดงข้อมูลตัวละคร",kind="button",k={"ข้อมูลตัวละคร","ข้อมูลผู้เล่น"},
  desc="แสดงชื่อ รหัสผู้เล่น อายุบัญชี ทีม และตำแหน่งปัจจุบัน",
  action=function()
   local r,h=root(),hum()
   local L={"ชื่อผู้เล่น: "..LP.Name,"ชื่อที่แสดง: "..LP.DisplayName,"รหัสผู้เล่น: "..LP.UserId,"อายุบัญชี: "..LP.AccountAge.." วัน","ทีม: "..(LP.Team and LP.Team.Name or "ไม่มี")}
   if r and h then
    table.insert(L,"ตำแหน่ง: "..math.floor(r.Position.X)..", "..math.floor(r.Position.Y)..", "..math.floor(r.Position.Z))
    table.insert(L,"รูปแบบตัวละคร: "..h.RigType.Name)
   else table.insert(L,"ตัวละคร: ไม่พบ (อาจกำลังเกิดใหม่)") end
   UI.showInfo("👤 ข้อมูลตัวละคร",table.concat(L,"\n")) return true,"แสดงข้อมูลแล้ว"
  end}
 FM.add{cat=2,name="แสดงพลังชีวิต",kind="toggle",k={"พลังชีวิต","เลือด","hp","health"},
  desc="แสดงแถบพลังชีวิตของตัวละครกลางหน้าจอด้านบน อัปเดตแบบเรียลไทม์",
  on=function() HUD.Visible=true end,off=function() HUD.Visible=false end}
 FM.add{cat=2,name="แสดงสถานะตัวละคร",kind="button",k={"สถานะตัวละคร"},
  desc="แสดงสถานะ ความเร็ว แรงกระโดด และพื้นที่ยืนของตัวละครขณะนี้",avail=function() if hum() and root() then return true end return false,"ไม่พบตัวละคร" end,
  action=function()
   local h,r=hum(),root()
   local L={"สถานะ: "..h:GetState().Name,"พลังชีวิต: "..math.floor(h.Health).." / "..math.floor(h.MaxHealth),"WalkSpeed: "..fmt1(h.WalkSpeed),
    h.UseJumpPower and ("JumpPower: "..fmt1(h.JumpPower)) or ("JumpHeight: "..fmt1(h.JumpHeight)),"HipHeight: "..fmt1(h.HipHeight),
    "พื้นที่ยืน: "..h.FloorMaterial.Name,"ความเร็วจริง: "..fmt1(r.AssemblyLinearVelocity.Magnitude).." studs/s"}
   UI.showInfo("📊 สถานะตัวละคร",table.concat(L,"\n")) return true,"แสดงสถานะแล้ว"
  end}
 FM.add{cat=2,name="รีเซ็ตตัวละคร",kind="button",k={"รีเซ็ตตัวละคร","รีเซ็ต","reset"},
  desc="ทำให้ตัวละครเกิดใหม่ (กดสองครั้งเพื่อยืนยัน) ผลขึ้นกับว่าเกมอนุญาตหรือไม่",avail=needChar,
  action=function()
   if os.clock()-rstAt>4 then rstAt=os.clock() return true,"กดอีกครั้งภายใน 4 วินาทีเพื่อยืนยัน" end
   rstAt=0
   local ok,e=pcall(function() hum().Health=0 end)
   if not ok then return false,tostring(e) end
   return true,"ส่งคำสั่งรีเซ็ตแล้ว (ผลขึ้นกับเกม)"
  end}
 FM.add{cat=2,name="แสดงเวลาเล่น",kind="toggle",default=true,k={"แสดงเวลาเล่น","เวลาเล่น"},
  desc="แสดง/ซ่อนเวลาเล่นรูปแบบ ชั่วโมง:นาที:วินาที บนแถบด้านบน (นับตั้งแต่รันสคริปต์)",
  on=function() Cfg.showTime=true applyDisplay() end,off=function() Cfg.showTime=false applyDisplay() end}
 FM.add{cat=2,name="แสดงชื่อผู้เล่น",kind="toggle",default=true,k={"แสดงชื่อผู้เล่น","ชื่อผู้เล่น"},
  desc="แสดง/ซ่อนชื่อและรูปโปรไฟล์ของคุณบนแถบด้านบน",
  on=function() Cfg.showName=true applyDisplay() end,off=function() Cfg.showName=false applyDisplay() end}

 conn(RS.Heartbeat,function()
  if not FM.st[9].on then return end
  local h=hum()
  if h and h.MaxHealth>0 then
   local a=math.clamp(h.Health/h.MaxHealth,0,1)
   HFill.Size=UDim2.fromScale(a,1) HFill.BackgroundColor3=Color3.new(1-a*.6,.25+.65*a,.3)
   HTxt.Text="❤️ "..math.floor(h.Health).." / "..math.floor(h.MaxHealth)
  else HFill.Size=UDim2.fromScale(0,1) HTxt.Text="ไม่พบตัวละคร" end
 end)
end)

-- ===== 👁️ หมวดการแสดงผล (ฟังก์ชัน 14-20) =====
Mod.add("display",function()
 FM.add{cat=3,name="เปลี่ยนธีม UI",kind="button",k={"ธีม","สี"},
  desc="สลับธีมสีของ UI ทีละแบบ: ฟ้า ม่วง เขียว ชมพู ส้มอาทิตย์",
  action=function() Cfg.theme=Cfg.theme%#TH+1 applyTheme() return true,"ธีม: "..TH[Cfg.theme].n end}
 FM.add{cat=3,name="ปรับความโปร่งใส UI",kind="slider",k={"ความโปร่งใส","โปร่งแสง"},
  desc="ปรับความโปร่งแสงของหน้าต่างด้วยสไลด์ 0-80%",slider={min=0,max=80,def=15,label="ความโปร่งใส %"},
  onval=function(v) Cfg.alpha=v applyGlass() end}
 FM.add{cat=3,name="เปิด/ปิดเอฟเฟกต์แสง",kind="toggle",default=true,k={"เอฟเฟกต์แสง","แสงเรือง","แสง"},
  desc="เปิด/ปิดแสงเรืองกะพริบรอบลูกแก้ว ☀️",on=function() Cfg.glow=true end,off=function() Cfg.glow=false end}
 FM.add{cat=3,name="เปิด/ปิดดาวประดับ",kind="toggle",default=true,k={"ดาวประดับ","ดาว"},
  desc="เปิด/ปิดดาว 🌟 เล็กๆ ที่ล้อมรอบลูกแก้ว",on=function() Cfg.stars=true end,off=function() Cfg.stars=false end}
 FM.add{cat=3,name="เปิด/ปิดขอบสีรุ้ง",kind="toggle",default=true,k={"ขอบสีรุ้ง","สีรุ้ง","รุ้ง"},
  desc="เปิด/ปิดขอบสีรุ้งของลูกแก้วและหน้าต่าง (ปิดแล้วจะเป็นขอบสีเทาอ่อน)",
  on=function() Cfg.rainbow=true applyRainbow() end,off=function() Cfg.rainbow=false applyRainbow() end}
 FM.add{cat=3,name="แสดง FPS",kind="toggle",default=true,k={"แสดง fps","fps"},
  desc="แสดง/ซ่อนค่า FPS บนแถบด้านบน",on=function() Cfg.showFps=true applyDisplay() end,off=function() Cfg.showFps=false applyDisplay() end}
 FM.add{cat=3,name="แสดง Ping",kind="toggle",default=true,k={"แสดง ping","ping","พิง"},
  desc="แสดง/ซ่อนค่า Ping บนแถบด้านบน ใช้ได้เฉพาะเมื่อตัวรันอ่านค่าจาก Stats ได้",
  avail=function() if Cap.ping then return true end return false,"อ่านค่า Ping ไม่ได้ในสภาพแวดล้อมนี้" end,
  on=function() Cfg.showPing=true applyDisplay() end,off=function() Cfg.showPing=false applyDisplay() end}
end)

-- ===== ⚙️ หมวดการตั้งค่า (ฟังก์ชัน 21-27) =====
Mod.add("settings",function()
 FM.add{cat=4,name="เปิด/ปิดแอนิเมชัน UI",kind="toggle",default=true,k={"แอนิเมชัน","animation"},
  desc="เปิด/ปิดการเคลื่อนไหวของหน้าต่าง ลูกแก้ว และขอบสีรุ้ง",on=function() Cfg.anim=true end,off=function() Cfg.anim=false end}
 FM.add{cat=4,name="เปิด/ปิดเสียง UI",kind="toggle",default=true,k={"เสียง","sound"},
  desc="เปิด/ปิดเสียงคลิกของปุ่ม (เสียงต้องโหลดจากเซิร์ฟเวอร์ Roblox ได้ ถ้าโหลดไม่ได้จะไม่มีเสียง)",
  avail=function() if Snd then return true end return false,"สร้างเสียงไม่ได้" end,
  on=function() Cfg.sound=true end,off=function() Cfg.sound=false end}
 FM.add{cat=4,name="ปรับขนาดหน้าต่าง",kind="slider",k={"ขนาดหน้าต่าง","ขนาด"},
  desc="ปรับขนาดหน้าต่างด้วยสไลด์ 60-130%",slider={min=60,max=130,def=100,label="ขนาด %"},
  onval=function(v) Cfg.scale=v SScale.Scale=v/100 end}
 FM.add{cat=4,name="ย่อ/ขยายหน้าต่าง",kind="toggle",persist=false,k={"ย่อหน้าต่าง","ขยายหน้าต่าง","ย่อ"},
  desc="เปิด = ย่อเหลือแต่แถบด้านบน (กดปุ่ม ▁ บนแถบเพื่อสลับกลับได้) ปิด = ขยายเต็ม",
  on=function() setCollapsed(true) end,off=function() setCollapsed(false) end}
 FM.add{cat=4,name="รีเซ็ตตำแหน่ง UI",kind="button",k={"รีเซ็ตตำแหน่ง","ตำแหน่ง"},
  desc="ย้ายหน้าต่างกลับกลางจอ และลูกแก้วกลับตำแหน่งเดิม",
  action=function() resetPos() return true,"รีเซ็ตตำแหน่งแล้ว" end}
 FM.add{cat=4,name="บันทึกการตั้งค่า",kind="button",k={"บันทึกการตั้งค่า","บันทึก","save"},
  desc="บันทึกการตั้งค่าลงไฟล์ในเครื่อง (ต้องให้ตัวรันรองรับ writefile) ครั้งหน้าจะโหลดอัตโนมัติ",
  action=function()
   local ok,e=Settings.save()
   if ok then return true,"บันทึกแล้ว ("..FILE_CFG..")" end
   return false,tostring(e)
  end}
 FM.add{cat=4,name="คืนค่าการตั้งค่าเริ่มต้น",kind="button",k={"คืนค่า","ค่าเริ่มต้น","รีเซ็ตการตั้งค่า"},
  desc="ปิดทุกฟังก์ชันและคืนค่า UI กลับเป็นค่าเริ่มต้น (ไฟล์ที่บันทึกไว้จะยังอยู่จนกว่าจะบันทึกใหม่)",
  action=function() FM.reset() return true,"คืนค่าเริ่มต้นแล้ว" end}
 task.spawn(function()
  pcall(function() game:GetService("ContentProvider"):PreloadAsync({Snd}) end)
  if not Snd.IsLoaded and FM.st[22] then
   FM.st[22].msg="⚠️ โหลดเสียงไม่สำเร็จ (อาจไม่มีเสียง)" Log.add("W","โหลดเสียง UI ไม่สำเร็จ") Ev.emit("fn",22)
  end
 end)
end)

-- ===== 🛠️ หมวดเครื่องมือ (ฟังก์ชัน 28-30) =====
Mod.add("tools",function()
 FM.add{cat=5,name="ค้นหาฟังก์ชัน",kind="button",k={"ค้นหาฟังก์ชัน","ค้นหา"},
  desc="พาไปที่ช่องค้นหาด้านบนของเมนูหลัก พิมพ์ชื่อฟังก์ชันเพื่อกรองรายการ",
  action=function() UI.focusSearch() return true,"พิมพ์ชื่อฟังก์ชันที่ช่องค้นหา" end}
 FM.add{cat=5,name="แสดงสถานะระบบ",kind="button",k={"สถานะระบบ","ระบบ"},
  desc="แสดงตัวรัน ความสามารถที่รองรับ จำนวนฟังก์ชันที่เปิด FPS หน่วยความจำ และจำนวนข้อผิดพลาด",
  action=function()
   local on=0 for _,s in pairs(FM.st) do if s.on then on+=1 end end
   local okm,mem=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
   local L={"ตัวรัน (executor): "..execName(),"บันทึกไฟล์ (writefile): "..(Cap.file and "รองรับ" or "ไม่รองรับ"),
    "gethui: "..(Cap.gethui and "รองรับ" or "ไม่รองรับ (ใช้ CoreGui แทน)"),"อ่านค่า Ping: "..(Cap.ping and "ได้" or "ไม่ได้"),
    "ฟังก์ชันที่เปิดอยู่: "..on.." / "..#FM.list,"FPS: "..tostring(UI.fpsV or "--"),
    "หน่วยความจำ: "..(okm and fmt1(mem).." MB" or "อ่านไม่ได้"),"เวลาตั้งแต่รันสคริปต์: "..fmtTime(os.clock()-START),
    "ข้อผิดพลาดที่บันทึก: "..Log.errs,"ความรู้ใน AI: "..(UI.kbCount and UI.kbCount() or 0).." รายการ"}
   UI.showInfo("🛠️ สถานะระบบ",table.concat(L,"\n")) return true,"แสดงสถานะระบบแล้ว"
  end}
 FM.add{cat=5,name="ดูบันทึกข้อผิดพลาด",kind="button",k={"บันทึกข้อผิดพลาด","ข้อผิดพลาด","error","log"},
  desc="แสดงบันทึกล่าสุดของระบบ (I=ข้อมูล W=คำเตือน E=ข้อผิดพลาด)",
  action=function()
   if #Log.items==0 then UI.showInfo("📜 บันทึกระบบ","ยังไม่มีบันทึก") return true,"ยังไม่มีบันทึก" end
   local L={}
   for i=#Log.items,math.max(1,#Log.items-39),-1 do
    local e=Log.items[i]
    table.insert(L,"["..string.format("%02d:%02d",e[1]//60,math.floor(e[1])%60).."] "..e[2].." "..e[3])
   end
   UI.showInfo("📜 บันทึกระบบ (ล่าสุดก่อน)",table.concat(L,"\n")) return true,"แสดงบันทึกแล้ว"
  end}
end)--[[ ส่วนที่ 2/3 : รายการฟังก์ชัน + ระบบ AI + เริ่มทำงาน (วางต่อจากส่วนที่ 1) ]]
-- ===== หน้าเมนูหลัก: ช่องค้นหา + หมวด + รายการ =====
local Search=new("TextBox",{Size=UDim2.new(1,-6,0,28),PlaceholderText="🔎 ค้นหาฟังก์ชัน...",PlaceholderColor3=Color3.fromRGB(140,160,200),
 Text="",ClearTextOnFocus=false,TextColor3=white,TextSize=13,Font=Enum.Font.GothamMedium},P1)
tr(Search,"BackgroundColor3","panel2") corner(Search,8)
local Chips=new("ScrollingFrame",{Size=UDim2.new(1,-6,0,32),Position=UDim2.fromOffset(0,32),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,
 CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X},P1)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},Chips)
local List=new("ScrollingFrame",{Size=UDim2.new(1,-4,1,-68),Position=UDim2.fromOffset(0,68),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
 AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},P1)
new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},List)
local Head=txt(List,"",13,UDim2.new(),UDim2.new(1,-8,0,22),Color3.fromRGB(255,215,130))
Head.Font=Enum.Font.GothamBold Head.LayoutOrder=0
local R,chipBtns={},{}
local selCat=1
local function matches(d,q)
 q=q:lower()
 if d.name:lower():find(q,1,true) then return true end
 for _,k in ipairs(d.k or {}) do if k:lower():find(q,1,true) then return true end end
 return false
end
local function refreshList()
 local q=Search.Text:gsub("^%s+",""):gsub("%s+$","")
 local shown=0
 for _,d in ipairs(FM.list) do
  local vis=(q=="" and d.cat==selCat) or (q~="" and matches(d,q))
  if R[d.id] then R[d.id].frame.Visible=vis end
  if vis then shown+=1 end
 end
 Head.Text=(q=="") and CATS[selCat] or ("🔎 ผลการค้นหา ("..shown..")")
 for i,b in ipairs(chipBtns) do b.BackgroundColor3=(i==selCat and q=="") and TC("acc") or TC("panel2") end
end
for i,c in ipairs(CATS) do
 local b=new("TextButton",{Size=UDim2.fromOffset(0,28),AutomaticSize=Enum.AutomaticSize.X,Text="  "..c.."  ",TextColor3=white,TextSize=12,
  Font=Enum.Font.GothamBold,BackgroundColor3=TC("panel2"),LayoutOrder=i},Chips)
 corner(b,8) chipBtns[i]=b
 conn(b.Activated,function() click() selCat=i Search.Text="" refreshList() end)
end
conn(Search:GetPropertyChangedSignal("Text"),refreshList)
UI.focusSearch=function() selectTab(1) Search:CaptureFocus() end

local function buildRow(d)
 local h=(d.kind=="slider" and 54) or (d.slider and 72) or 40
 local row=new("Frame",{Size=UDim2.new(1,-8,0,h),LayoutOrder=d.id,Visible=false},List)
 tr(row,"BackgroundColor3","panel") gl(row,.1) corner(row,10)
 local wide=(d.kind=="slider") and -24 or -84
 local nameL=txt(row,d.name,13,UDim2.fromOffset(12,3),UDim2.new(1,wide,0,18))
 nameL.TextWrapped=false nameL.TextTruncate=Enum.TextTruncate.AtEnd
 local stL
 if d.kind~="slider" then
  stL=txt(row,"",10,UDim2.fromOffset(12,21),UDim2.new(1,-84,0,14),Color3.fromRGB(160,180,215))
  stL.TextWrapped=false stL.TextTruncate=Enum.TextTruncate.AtEnd
 end
 local sw,knob
 if d.kind=="toggle" then
  sw=new("TextButton",{Size=UDim2.fromOffset(46,24),Position=UDim2.new(1,-56,0,8),BackgroundColor3=OFFC,Text="",AutoButtonColor=false},row) corner(sw,12)
  knob=new("Frame",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(3,3),BackgroundColor3=white},sw) corner(knob,9)
  conn(sw.Activated,function() click() FM.setOn(d.id,not FM.st[d.id].on) end)
 elseif d.kind=="button" then
  local act=new("TextButton",{Size=UDim2.fromOffset(60,26),Position=UDim2.new(1,-70,0,7),Text="▶ ใช้",TextColor3=white,TextSize=12,Font=Enum.Font.GothamBold},row)
  tr(act,"BackgroundColor3","acc") corner(act,8)
  conn(act.Activated,function() click() FM.run(d.id) end)
 end
 local setBar
 if d.slider then
  local y=(d.kind=="slider") and 36 or 54
  local bar=new("Frame",{Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,y),BackgroundColor3=OFFC},row) corner(bar,3)
  local fill=new("Frame",{Size=UDim2.fromScale(0,1)},bar) tr(fill,"BackgroundColor3","acc") corner(fill,3)
  local kn=new("Frame",{Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),BackgroundColor3=white},bar) corner(kn,8)
  local hit=new("TextButton",{Size=UDim2.new(1,0,0,26),Position=UDim2.fromOffset(0,y-10),BackgroundTransparency=1,Text=""},row)
  local dragging=false
  local function setX(x)
   local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
   FM.setVal(d.id,math.floor(d.slider.min+(d.slider.max-d.slider.min)*a+.5))
  end
  conn(hit.InputBegan,function(i)
   if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
    dragging=true List.ScrollingEnabled=false setX(i.Position.X)
   end
  end)
  conn(UIS.InputChanged,function(i)
   if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setX(i.Position.X) end
  end)
  conn(UIS.InputEnded,function(i)
   if dragging and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then dragging=false List.ScrollingEnabled=true end
  end)
  setBar=function()
   local a=(FM.st[d.id].val-d.slider.min)/(d.slider.max-d.slider.min)
   fill.Size=UDim2.fromScale(a,1) kn.Position=UDim2.fromScale(a,.5)
  end
 end
 local function refresh()
  local s=FM.st[d.id]
  if d.kind=="toggle" then
   nameL.Text=d.slider and (d.name.."  ("..d.slider.label..": "..s.val..")") or d.name
   local base=s.on and "✅ เปิดอยู่" or "⏸ ปิดอยู่"
   stL.Text=(s.msg~="" and s.msg) or (base..((s.on and d.game) and " · ผลขึ้นกับเกม" or ""))
   tween(sw,.15,{BackgroundColor3=s.on and TC("acc") or OFFC})
   tween(knob,.15,{Position=s.on and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)})
  elseif d.kind=="button" then
   stL.Text=(s.msg~="" and s.msg) or "พร้อมใช้งาน"
  else nameL.Text=d.name..": "..s.val end
  if setBar then setBar() end
 end
 R[d.id]={frame=row,refresh=refresh}
 refresh()
end
for _,d in ipairs(FM.list) do safe("สร้างแถว "..d.name,buildRow,d) end
Ev.on("fn",function(id) if R[id] then R[id].refresh() end end)
Ev.on("theme",function() for _,r in pairs(R) do r.refresh() end refreshList() end)

-- ===== 🌐 ระบบ AI (Lua ล้วน ไม่ใช้ API Key / ไม่ต่อ AI ภายนอก) =====
local AI={taught={},mem={},teach=nil,last=nil}
local function norm(s) s=string.lower(tostring(s)) s=s:gsub("[%s%p]","") return s end
local function grams(s)
 local cp={} for _,c in utf8.codes(s) do cp[#cp+1]=c end
 local g={} for i=1,#cp-1 do local k=cp[i]*1114112+cp[i+1] g[k]=(g[k] or 0)+1 end
 return g,math.max(#cp-1,0)
end
local function dice(a,b)
 local ga,na=grams(a) local gb,nb=grams(b)
 if na==0 or nb==0 then return 0 end
 local m=0 for k,v in pairs(ga) do if gb[k] then m+=math.min(v,gb[k]) end end
 return 2*m/(na+nb)
end
local function score(nq,key,isBase)
 if nq==key then return 1 end
 local ln,lk=#nq,#key
 if (lk>=6 or isBase) and nq:find(key,1,true) then return .55+.45*math.min(1,lk/ln) end
 if not isBase and lk>=6 and ln>=6 and key:find(nq,1,true) then return .5+.4*(ln/lk) end
 return dice(nq,key)
end
local function trim(s) s=s:gsub("^%s+","") s=s:gsub("%s+$","") return s end

local BASE={
 {keys={"สวัสดี","หวัดดี","ดีครับ","ดีค่ะ","hello"},a="สวัสดีครับ ☀️ ผมคือผู้ช่วยแชทของเมนูนี้ ถามเรื่องฟังก์ชันของสคริปต์ได้ หรือสอนข้อมูลใหม่ให้ผมได้ด้วยนะ"},
 {keys={"ขอบคุณ","ขอบใจ","thank"},a="ยินดีครับ 😊"},
 {keys={"บาย","ลาก่อน","bye"},a="แล้วเจอกันครับ ☀️"},
 {keys={"คุณคือใคร","เธอคือใคร","แนะนำตัว","คุณคืออะไร"},
  a="ผมเป็นระบบแชทที่เขียนด้วย Lua อยู่ในสคริปต์นี้เอง ทำงานจากคลังความรู้ กฎการสนทนา การจับคู่ข้อความ และสิ่งที่คุณสอนไว้ ไม่ได้เชื่อมต่อ AI ภายนอก และไม่ใช่โมเดลภาษาขนาดใหญ่"},
 {keys={"ทำอะไรได้","ช่วยอะไร","ความสามารถ"},
  a="ผมช่วยได้ดังนี้:\n• อธิบายและบอกสถานะของฟังก์ชันทั้ง 30 อย่าง เช่น \"บินคืออะไร\" \"บินเปิดอยู่ไหม\"\n• จำสิ่งที่คุณสอน: สอน: คำถาม = คำตอบ\n• ค้นหาในความรู้: ค้นหา: คำ\n• จำชื่อคุณ: ฉันชื่อ ...\nผมแค่อธิบาย ไม่ได้เปิด/ปิดฟังก์ชันแทนคุณ"},
 {keys={"ข้อจำกัด","ไม่ได้อะไร","เก่งแค่ไหน","เป็นโมเดลภาษา","chatgpt","เทียบ"},
  a="ข้อจำกัดของผม: ตอบได้เฉพาะเรื่องที่อยู่ในคลังความรู้ (ฟังก์ชันของเมนูนี้ + สิ่งที่คุณสอน) จับคู่ด้วยคำสำคัญและความคล้ายของข้อความ จึงอาจเข้าใจผิดถ้าถามคลุมเครือ ผมคิดวิเคราะห์เองหรือค้นอินเทอร์เน็ตไม่ได้ และถ้าไม่รู้ผมจะบอกตรงๆ"},
 {keys={"สอนยังไง","วิธีสอน","สอนอย่างไร","สอนได้ไหม"},
  a="สอนได้ 2 วิธี:\n1) พิมพ์ \"สอน: คำถาม = คำตอบ\"\n2) กดปุ่ม 📚 สอน แล้วพิมพ์คำถาม ตามด้วยคำตอบ\nลบความรู้ที่สอน: \"ลืม: คำถาม\" (ถ้าตัวรันรองรับ writefile ความรู้จะอยู่ถาวรข้ามการรัน)"},
 {keys={"กี่โมง","เวลาเท่าไร","วันนี้วันที่","วันอะไร"},a=function() return "เวลาในเครื่องของคุณตอนนี้: "..os.date("%H:%M:%S").." วันที่ "..os.date("%d/%m/%Y") end},
 {keys={"เล่นมานานเท่าไร","เล่นมากี่นาที","เล่นมากี่ชั่วโมง"},a=function() return "คุณรันสคริปต์มาแล้ว "..fmtTime(os.clock()-START).." (ชั่วโมง:นาที:วินาที)" end},
 {keys={"กี่ฟังก์ชัน","มีกี่ฟังก์ชัน","กี่เมนู","มีกี่เมนู","ทั้งหมดกี่"},a=function() return "มี 2 เมนูหลัก (🌟 เมนูทั่วไป/หลัก และ 🌐 เมนู AI) เมนูหลักมี "..#FM.list.." ฟังก์ชัน แบ่งเป็น "..#CATS.." หมวด" end},
 {keys={"มีอะไรบ้าง","รายการฟังก์ชัน","ฟังก์ชันทั้งหมด"},a=function()
  local L={}
  for ci,c in ipairs(CATS) do
   local n={} for _,d in ipairs(FM.list) do if d.cat==ci then table.insert(n,d.name) end end
   table.insert(L,c..": "..table.concat(n,", "))
  end
  return table.concat(L,"\n")
 end},
 {keys={"ติดตั้ง","ใช้ยังไง","วิธีใช้","เริ่มใช้"},a="กดลูกแก้ว ☀️ เพื่อเปิด/ปิดหน้าต่าง (ลากเพื่อย้ายได้) เลือกหมวดด้านบน แล้วกดสวิตช์หรือปุ่ม ▶ ในแต่ละแถว ใช้ช่อง 🔎 เพื่อค้นหาฟังก์ชัน ปุ่ม ▁ บนแถบด้านบนใช้ย่อหน้าต่าง"},
}
for _,e in ipairs(BASE) do e.nk={} for _,k in ipairs(e.keys) do table.insert(e.nk,norm(k)) end end
UI.kbCount=function() return #BASE+#AI.taught end

local function loadKB()
 local t=loadFile(FILE_KB)
 if type(t)~="table" then return end
 if type(t.taught)=="table" then
  for _,e in ipairs(t.taught) do
   if type(e)=="table" and type(e[1])=="string" and type(e[2])=="string" then table.insert(AI.taught,{q=e[1],a=e[2],nk=norm(e[1])}) end
  end
 end
 if type(t.mem)=="table" then AI.mem=t.mem end
end
local function saveKB()
 local out={} for _,e in ipairs(AI.taught) do table.insert(out,{e.q,e.a}) end
 return saveFile(FILE_KB,{taught=out,mem=AI.mem})
end
local function addTaught(q,a)
 q=trim(q) a=trim(a)
 local nq=norm(q)
 if (utf8.len(nq) or 0)<2 or #a<1 then return "คำถามสั้นเกินไป หรือไม่มีคำตอบ จึงยังไม่จำครับ" end
 if #AI.taught>=300 then return "คลังที่คุณสอนเต็มแล้ว (300 รายการ) ลองใช้ \"ลืม: คำถาม\" เพื่อลบบางส่วน" end
 local upd=false
 for _,e in ipairs(AI.taught) do if e.nk==nq then e.a=a e.q=q upd=true end end
 if not upd then table.insert(AI.taught,{q=q,a=a,nk=nq}) end
 local ok,why=saveKB()
 return (upd and "อัปเดตความรู้แล้ว ✅" or "จำแล้วครับ ✅").."\nถาม: "..q.."\nตอบ: "..a..(ok and "" or ("\n(จำไว้ในเซสชันนี้เท่านั้น: "..tostring(why)..")"))
end
local function forget(q)
 local nq=norm(q) local n=0
 for i=#AI.taught,1,-1 do
  local e=AI.taught[i]
  if e.nk==nq or dice(nq,e.nk)>=.8 then table.remove(AI.taught,i) n+=1 end
 end
 if n>0 then saveKB() return "ลืมแล้ว "..n.." รายการครับ" end
 return "ไม่พบความรู้ที่คุณสอนซึ่งตรงกับ \""..q.."\""
end
local function searchKB(kw)
 local L={} local k=kw:lower()
 for _,e in ipairs(AI.taught) do
  if e.q:lower():find(k,1,true) or e.a:lower():find(k,1,true) then table.insert(L,"• [ที่สอนไว้] "..e.q.." → "..e.a) end
 end
 for _,d in ipairs(FM.list) do
  if matches(d,kw) or d.desc:lower():find(k,1,true) then table.insert(L,"• [ฟังก์ชัน] "..d.name.." — "..d.desc) end
 end
 if #L==0 then return "ไม่พบข้อมูลที่เกี่ยวกับ \""..kw.."\" ในคลังความรู้" end
 if #L>12 then local n=#L for i=n,13,-1 do L[i]=nil end table.insert(L,"... (แสดง 12 รายการแรก)") end
 return "ผลการค้นหา \""..kw.."\":\n"..table.concat(L,"\n")
end
local function findFn(nq)
 local best,bl=nil,0
 for _,d in ipairs(FM.list) do
  local keys={d.name} for _,k in ipairs(d.k or {}) do keys[#keys+1]=k end
  for _,k in ipairs(keys) do
   local nk=norm(k)
   if (utf8.len(nk) or 0)>=2 and nq:find(nk,1,true) and #nk>bl then best,bl=d,#nk end
  end
 end
 return best
end
local function fnAnswer(d,nq)
 local s=FM.st[d.id]
 AI.last=d.id
 local function ask(...) for _,w in ipairs({...}) do if nq:find(norm(w),1,true) then return true end end return false end
 local status
 if d.kind=="toggle" then
  status=s.on and "ตอนนี้เปิดอยู่" or "ตอนนี้ปิดอยู่"
  if s.msg~="" then status=status.." ("..s.msg..")" end
 end
 if ask("เปิดอยู่","เปิดไหม","สถานะ","อยู่ไหม","ปิดอยู่","เปิดรึยัง","เปิดหรือยัง") then
  return "ฟังก์ชัน \""..d.name.."\": "..(status or "เป็นปุ่มกดใช้งาน ไม่มีสถานะเปิด/ปิด")
 end
 local out="ฟังก์ชัน \""..d.name.."\" ("..CATS[d.cat]..")\n"..d.desc
 if status then out=out.."\n"..status end
 if d.game then out=out.."\n⚠️ ผลขึ้นกับเกมและตัวรันสคริปต์ ถ้าเกมควบคุมค่านี้เอง อาจไม่เห็นผล" end
 return out
end

local function answer(raw)
 local text=trim(raw)
 text=text:gsub("：",":"):gsub("＝","=")
 if AI.teach then
  if norm(text)=="ยกเลิก" then AI.teach=nil return "ยกเลิกการสอนแล้วครับ" end
  if AI.teach.s=="q" then AI.teach={s="a",q=text} return "รับทราบครับ แล้วคำตอบของ \""..text.."\" คือ? (พิมพ์ \"ยกเลิก\" เพื่อยกเลิก)" end
  local q=AI.teach.q AI.teach=nil
  return addTaught(q,text)
 end
 local q,a=text:match("^สอน%s*:%s*(.-)%s*=%s*(.+)$")
 if not q then q,a=text:match("^จำไว้ว่า%s*:?%s*(.-)%s*=%s*(.+)$") end
 if q then return addTaught(q,a) end
 local fq=text:match("^ลืม%s*:%s*(.+)$") if fq then return forget(fq) end
 local kw=text:match("^ค้นหา%s*:%s*(.+)$") if kw then return searchKB(kw) end
 local nq=norm(text)
 if nq=="ความรู้" or nq=="รายการความรู้" or nq=="ความรู้ทั้งหมด" then
  local L={"ความรู้ในตัว "..#BASE.." หมวด และที่คุณสอน "..#AI.taught.." รายการ"}
  for i,e in ipairs(AI.taught) do if i>20 then table.insert(L,"...") break end table.insert(L,i..". "..e.q) end
  return table.concat(L,"\n")
 end
 local function has(...) for _,w in ipairs({...}) do if text:find(w,1,true) then return true end end return false end
 if has("ชื่ออะไร") and has("ฉัน","ผม","เรา","หนู","ชั้น") and not has("คุณ","เธอ") then
  return AI.mem.name and ("คุณชื่อ "..AI.mem.name.." ครับ") or "ผมยังไม่ทราบชื่อคุณ บอกได้โดยพิมพ์ เช่น \"ฉันชื่อ ...\""
 end
 for _,p in ipairs({"ฉันชื่อ","ผมชื่อ","หนูชื่อ","ชั้นชื่อ","เราชื่อ"}) do
  local _,j=text:find(p,1,true)
  if j then
   local nm=trim(text:sub(j+1))
   if #nm>0 and #nm<=40 then AI.mem.name=nm saveKB() return "ยินดีที่ได้รู้จักครับ คุณ"..nm.." ☀️ ผมจำชื่อนี้ไว้แล้ว" end
  end
 end
 local fn=findFn(nq)
 if fn then return fnAnswer(fn,nq) end
 if AI.last and has("อันนี้","อันนั้น","ตัวนี้","ตัวนั้น","มัน","แล้วล่ะ") then return fnAnswer(FM.by[AI.last],nq) end
 local best,bs,bq=nil,0,nil
 for _,e in ipairs(BASE) do for _,nk in ipairs(e.nk) do local sc=score(nq,nk,true) if sc>bs then best,bs,bq=e,sc,e.keys[1] end end end
 for _,e in ipairs(AI.taught) do local sc=score(nq,e.nk,false) if sc>=bs and sc>0 then best,bs,bq=e,sc,e.q end end
 if best and bs>=.5 then return type(best.a)=="function" and best.a() or best.a end
 return "ขออภัยครับ ผมยังไม่มีข้อมูลเรื่องนี้ในคลังความรู้ จึงไม่ขอเดาคำตอบ 🙏\nถ้าคุณรู้คำตอบ สอนผมได้โดยพิมพ์: สอน: คำถาม = คำตอบ หรือกดปุ่ม 📚 สอน"
  ..((best and bs>=.3) and ("\n(ใกล้เคียงที่สุด: \""..tostring(bq).."\")") or "")
end

-- ===== หน้าจอแชท =====
local Msgs=new("ScrollingFrame",{Size=UDim2.new(1,-4,1,-74),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
 AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},P2)
new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},Msgs)
local msgLabels,order={},0
local function say(text,user)
 order+=1
 local l=new("TextLabel",{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=user and Color3.fromRGB(35,90,170) or TC("panel"),
  Text=text,TextColor3=white,TextSize=13,Font=Enum.Font.GothamMedium,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order},Msgs)
 corner(l,10) new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)},l)
 table.insert(msgLabels,l)
 if #msgLabels>80 then msgLabels[1]:Destroy() table.remove(msgLabels,1) end
 task.defer(function() task.wait(.05) Msgs.CanvasPosition=Vector2.new(0,1e6) end)
end
local function reply(t)
 local ok,res=pcall(answer,t)
 if ok then say("☀️ "..tostring(res))
 else Log.add("E","AI: "..tostring(res)) say("☀️ ขออภัยครับ ระบบตอบเกิดข้อผิดพลาด (ดูได้ที่ ดูบันทึกข้อผิดพลาด)") end
end
local function clearChat()
 for _,l in ipairs(msgLabels) do l:Destroy() end
 msgLabels={} AI.teach=nil
 say("☀️ ล้างประวัติสนทนาแล้วครับ (ความรู้ที่คุณสอนยังอยู่)")
end
local Box=new("TextBox",{Size=UDim2.new(1,-74,0,32),Position=UDim2.new(0,0,1,-34),PlaceholderText="ถามหรือสอนที่นี่...",PlaceholderColor3=Color3.fromRGB(140,160,200),
 Text="",ClearTextOnFocus=false,TextColor3=white,TextSize=13,Font=Enum.Font.GothamMedium},P2)
tr(Box,"BackgroundColor3","panel") corner(Box,10)
local Send=new("TextButton",{Size=UDim2.fromOffset(66,32),Position=UDim2.new(1,-68,1,-34),Text="ส่ง",TextColor3=white,TextSize=14,Font=Enum.Font.GothamBold},P2)
tr(Send,"BackgroundColor3","acc") corner(Send,10)
local function submit()
 local t=Box.Text Box.Text=""
 if trim(t)=="" then return end
 say("คุณ: "..t,true) reply(t)
end
conn(Send.Activated,function() click() submit() end)
conn(Box.FocusLost,function(enter) if enter then submit() end end)
local Tools=new("Frame",{Size=UDim2.new(1,-4,0,30),Position=UDim2.new(0,0,1,-70),BackgroundTransparency=1},P2)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},Tools)
local function toolBtn(i,t,fn)
 local b=new("TextButton",{Size=UDim2.new(.25,-3,1,0),Text=t,TextColor3=white,TextSize=12,Font=Enum.Font.GothamBold,LayoutOrder=i},Tools)
 tr(b,"BackgroundColor3","panel2") corner(b,8) stroke(b,1.5,TC("acc"))
 conn(b.Activated,function() click() fn() end)
end
toolBtn(1,"📚 สอน",function()
 AI.teach={s="q"} say("คุณ: 📚 สอนข้อมูลใหม่",true) say("☀️ พิมพ์ \"คำถาม\" ที่อยากให้ผมจำ (พิมพ์ \"ยกเลิก\" เพื่อยกเลิก)")
end)
toolBtn(2,"🔎 ค้นหา",function() Box.Text="ค้นหา: " Box:CaptureFocus() end)
toolBtn(3,"📋 ความรู้",function() say("คุณ: ความรู้",true) reply("ความรู้") end)
toolBtn(4,"🗑️ ล้าง",clearChat)

-- ===== เริ่มทำงาน =====
Settings.load() loadKB()
say("☀️ สวัสดีครับ ผมเป็นระบบแชทที่เขียนด้วย Lua ในสคริปต์นี้ ตอบจากคลังความรู้และสิ่งที่คุณสอนเท่านั้น ไม่ได้ต่อ AI ภายนอก และไม่ใช่โมเดลภาษาขนาดใหญ่ ถ้าไม่รู้ผมจะบอกตรงๆ\nลองพิมพ์ \"มีกี่ฟังก์ชัน\" หรือ \"บินคืออะไร\"")
applyAll()
FM.init()
for _,r in pairs(R) do r.refresh() end
selectTab(1) refreshList()
Holder.Visible=true
if #FM.list~=30 then Log.add("E","จำนวนฟังก์ชันไม่ครบ 30 (พบ "..#FM.list..")") end
Log.add("I","เริ่มระบบ Sun Menu แล้ว")--[[ ส่วนที่ 3/3 : 🙊 เมนูลับ 🌐 (วางต่อจากส่วนที่ 2 ท้ายสุดของสคริปต์) ]]
do
local SM={unlocked=false,refs={},ticks={},pages={},cat=1}
local PASS="4956"
local SOUND_ID={gun="",boom=""} -- ใส่ "rbxassetid://..." ของคุณเอง (ว่าง = ไม่มีเสียง)
local Debris=game:GetService("Debris")
local RepS=game:GetService("ReplicatedStorage")
local FILE_SM,FILE_CODE="SunMenu_secret.json","SunMenu_codes.json"
local MB1,TCH=Enum.UserInputType.MouseButton1,Enum.UserInputType.Touch
local function isPress(i) return i.UserInputType==MB1 or i.UserInputType==TCH end
local HINT=Color3.fromRGB(160,180,215)

-- ===== SettingsManager =====
SM.def={flash=true,sound=true,shell=true,boom=true,quality=3,rate=6,fcSpeed=30,fcLock=true,ringSize=160,ringAlpha=20,ringColor=1,ringRange=150,part=2}
SM.cfg=table.clone(SM.def)
do
 local t=loadFile(FILE_SM)
 if type(t)=="table" then for k,v in pairs(t) do if SM.def[k]~=nil and type(v)==type(SM.def[k]) then SM.cfg[k]=v end end end
end
local C=SM.cfg
function SM.refreshAll() for _,f in ipairs(SM.refs) do pcall(f) end end
local function run(fn,name)
 local pc,ok,m=pcall(fn)
 if not pc then Log.add("E",name..": "..tostring(ok)) UI.toast("ผิดพลาด: "..tostring(ok))
 elseif ok==false then UI.toast(tostring(m or "ไม่สำเร็จ"))
 elseif m then UI.toast(m) end
 SM.refreshAll()
end

-- ===== แท็บ + PasswordManager =====
addTab("🙊 เมนูลับ 🌐")
local TAB=#tabBtns
local P3=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},Content)
UI.onTab=function(i) P3.Visible=(i==TAB) end

local PM={buf="",fails=0,lockUntil=0}
function PM.check(code)
 if os.clock()<PM.lockUntil then return false,"รออีก "..math.ceil(PM.lockUntil-os.clock()).." วินาที" end
 if code==PASS then PM.fails=0 return true end
 PM.fails+=1
 if PM.fails>=3 then
  local w=math.min(10*2^(PM.fails-3),300)
  PM.lockUntil=os.clock()+w
  return false,"กรอกผิดหลายครั้ง ล็อก "..w.." วินาที"
 end
 return false,"รหัสไม่ถูกต้อง (เหลือ "..(3-PM.fails).." ครั้งก่อนล็อก)"
end

local G=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},P3)
local GT=txt(G,"🙊 เมนูลับ 🌐 · ใส่รหัส 4 หลัก",14,UDim2.fromOffset(0,0),UDim2.new(1,0,0,22),white,Enum.TextXAlignment.Center) GT.Font=Enum.Font.GothamBold
local GD=txt(G,"○ ○ ○ ○",22,UDim2.fromOffset(0,24),UDim2.new(1,0,0,30),Color3.fromRGB(255,215,130),Enum.TextXAlignment.Center)
local GM=txt(G,"",11,UDim2.fromOffset(0,54),UDim2.new(1,0,0,16),Color3.fromRGB(255,140,140),Enum.TextXAlignment.Center)
local pad=new("Frame",{Size=UDim2.fromOffset(170,162),AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,74),BackgroundTransparency=1},G)
new("UIGridLayout",{CellSize=UDim2.fromOffset(52,36),CellPadding=UDim2.fromOffset(7,6),SortOrder=Enum.SortOrder.LayoutOrder},pad)
local function dots()
 local s={} for i=1,4 do s[i]=(i<=#PM.buf) and "●" or "○" end
 GD.Text=table.concat(s," ")
end
local M=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},P3)
function SM.unlock() SM.unlocked=true G.Visible=false M.Visible=true UI.toast("ปลดล็อกเมนูลับแล้ว 🙊") end
function SM.lock() SM.unlocked=false PM.buf="" dots() GM.Text="" G.Visible=true M.Visible=false end
local function press(k)
 if k=="⌫" then PM.buf=PM.buf:sub(1,-2)
 elseif k=="✔" then
  local ok,why=PM.check(PM.buf) PM.buf=""
  if ok then dots() SM.unlock() return end
  GM.Text=why
 elseif #PM.buf<4 then PM.buf..=k end
 dots()
end
for n,k in ipairs({"1","2","3","4","5","6","7","8","9","⌫","0","✔"}) do
 local b=new("TextButton",{Text=k,TextColor3=white,TextSize=16,Font=Enum.Font.GothamBold,LayoutOrder=n},pad)
 tr(b,"BackgroundColor3",(k=="✔") and "acc" or "panel2") corner(b,8)
 conn(b.Activated,function() click() press(k) end)
end

-- ===== โครงหน้าหลักของเมนูลับ =====
local chipBar=new("ScrollingFrame",{Size=UDim2.new(1,-6,0,32),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.new(),
 AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X},M)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},chipBar)
local chipN,chipB=0,{}
local function chip(text,fn)
 chipN+=1
 local b=new("TextButton",{Size=UDim2.fromOffset(0,28),AutomaticSize=Enum.AutomaticSize.X,Text="  "..text.."  ",TextColor3=white,TextSize=12,
  Font=Enum.Font.GothamBold,BackgroundColor3=TC("panel2"),LayoutOrder=chipN},chipBar)
 corner(b,8) conn(b.Activated,function() click() fn() end) return b
end
local function selCat(i)
 for k,pg in ipairs(SM.pages) do pg.Visible=(k==i) end
 for k,b in ipairs(chipB) do b.BackgroundColor3=(k==i) and TC("acc") or TC("panel2") end
 SM.cat=i
end
chip("◀ หลัก",function() selectTab(1) end)
for i,c in ipairs({"👥 ผู้เล่น","🔫 ทดสอบ","🎥 กล้อง","🎯 เป้าหมาย","🧠 สอน AI"}) do chipB[i]=chip(c,function() selCat(i) end) end
chip("🔒",function() SM.lock() end)
local function mkPage()
 local p=new("ScrollingFrame",{Size=UDim2.new(1,-4,1,-36),Position=UDim2.fromOffset(0,36),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
  AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},M)
 new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},p)
 return p
end
for i=1,5 do SM.pages[i]=mkPage() end
selCat(1)
Ev.on("theme",function() SM.refreshAll() selCat(SM.cat) end)

-- ===== ตัวสร้างแถว (ใช้ร่วมกันทุกโมดูล) =====
local ord=0
local function rowFrame(p,h,o)
 ord+=1
 local r=new("Frame",{Size=UDim2.new(1,-8,0,h),LayoutOrder=o or ord},p)
 tr(r,"BackgroundColor3","panel") gl(r,.1) corner(r,10) return r
end
local function label(r,t,y,size,col)
 local l=txt(r,t,size or 13,UDim2.fromOffset(12,y),UDim2.new(1,-90,0,18),col)
 l.TextWrapped=false l.TextTruncate=Enum.TextTruncate.AtEnd return l
end
function SM.toggle(p,name,tag,state,set)
 local r=rowFrame(p,40)
 label(r,name,3)
 local st=label(r,"",21,10,HINT)
 local sw=new("TextButton",{Size=UDim2.fromOffset(46,24),Position=UDim2.new(1,-56,0,8),BackgroundColor3=OFFC,Text="",AutoButtonColor=false},r) corner(sw,12)
 local kn=new("Frame",{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(3,3),BackgroundColor3=white},sw) corner(kn,9)
 local msg=""
 local function ref()
  local on=state()
  st.Text=(msg~="" and msg) or ((on and "✅ ทำงานอยู่" or "⏸ ปิดอยู่").." · "..tag)
  tween(sw,.15,{BackgroundColor3=on and TC("acc") or OFFC})
  tween(kn,.15,{Position=on and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)})
 end
 conn(sw.Activated,function()
  click()
  local want=not state()
  local pc,ok,m=pcall(set,want)
  if not pc then Log.add("E",name..": "..tostring(ok)) ok,m=false,ok end
  if ok==false then msg="ใช้ไม่ได้: "..tostring(m) UI.toast(msg) else msg="" UI.toast(name..(want and " เปิดแล้ว" or " ปิดแล้ว")) end
  SM.refreshAll()
 end)
 table.insert(SM.refs,ref) ref()
end
function SM.btns(p,name,tag,list,w)
 local r=rowFrame(p,40)
 local nl=label(r,"",3) nl.Size=UDim2.new(1,-(#list*(w+6)+20),0,18)
 local tl=label(r,tag,21,10,HINT) tl.Size=nl.Size
 for i,b in ipairs(list) do
  local x=new("TextButton",{Size=UDim2.fromOffset(w,26),Position=UDim2.new(1,-(#list-i+1)*(w+6),0,7),Text=b[1],TextColor3=white,TextSize=12,Font=Enum.Font.GothamBold},r)
  tr(x,"BackgroundColor3","acc") corner(x,8)
  conn(x.Activated,function() click() run(b[2],name) end)
 end
 local function ref() nl.Text=(type(name)=="function") and name() or name end
 table.insert(SM.refs,ref) ref()
end
function SM.slider(p,name,min,max,get,set)
 local r=rowFrame(p,50)
 local nl=label(r,"",3) nl.Size=UDim2.new(1,-24,0,18)
 local bar=new("Frame",{Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,34),BackgroundColor3=OFFC},r) corner(bar,3)
 local fill=new("Frame",{Size=UDim2.fromScale(0,1)},bar) tr(fill,"BackgroundColor3","acc") corner(fill,3)
 local kn=new("Frame",{Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),BackgroundColor3=white},bar) corner(kn,8)
 local hit=new("TextButton",{Size=UDim2.new(1,0,0,26),Position=UDim2.fromOffset(0,24),BackgroundTransparency=1,Text=""},r)
 local dragging=false
 local function ref()
  local v=get()
  nl.Text=name..": "..v
  local a=math.clamp((v-min)/(max-min),0,1)
  fill.Size=UDim2.fromScale(a,1) kn.Position=UDim2.fromScale(a,.5)
 end
 local function setX(x)
  local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
  local ok,m=set(math.floor(min+(max-min)*a+.5))
  if ok==false then UI.toast(tostring(m)) end
  ref()
 end
 conn(hit.InputBegan,function(i) if isPress(i) then dragging=true p.ScrollingEnabled=false setX(i.Position.X) end end)
 conn(UIS.InputChanged,function(i)
  if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==TCH) then setX(i.Position.X) end
 end)
 conn(UIS.InputEnded,function(i) if dragging and isPress(i) then dragging=false p.ScrollingEnabled=true end end)
 table.insert(SM.refs,ref) ref()
end
function SM.listBox(p,o)
 local b=new("Frame",{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=o},p)
 new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},b)
 local rows={}
 local function clear() for _,r in ipairs(rows) do r:Destroy() end rows={} end
 local function add(h)
  local r=new("Frame",{Size=UDim2.new(1,0,0,h),LayoutOrder=#rows+1},b)
  tr(r,"BackgroundColor3","panel") gl(r,.1) corner(r,8) table.insert(rows,r) return r
 end
 return b,clear,add
end
local function smallBtn(par,text,x,w,fn)
 local b=new("TextButton",{Size=UDim2.fromOffset(w,26),Position=x,Text=text,TextColor3=white,TextSize=12,Font=Enum.Font.GothamBold},par)
 tr(b,"BackgroundColor3","panel2") corner(b,8)
 b.Activated:Connect(function() click() safe("ปุ่ม",fn) end)
 return b
end
local function rowText(r,t,rightPad)
 local l=txt(r,t,12,UDim2.fromOffset(10,0),UDim2.new(1,-rightPad,1,0))
 l.TextWrapped=false l.TextTruncate=Enum.TextTruncate.AtEnd return l
end

-- ===== PlayerProfile =====
Mod.add("secret:players",function()
 local pg=SM.pages[1]
 local sel
 local det=rowFrame(pg,96,0)
 local av=new("ImageLabel",{Size=UDim2.fromOffset(56,56),Position=UDim2.fromOffset(10,8),BackgroundColor3=OFFC},det) corner(av,28)
 local dt=txt(det,"",11,UDim2.fromOffset(74,6),UDim2.new(1,-84,1,-40),white) dt.TextYAlignment=Enum.TextYAlignment.Top
 local tpb=new("TextButton",{Size=UDim2.fromOffset(120,26),Position=UDim2.new(1,-130,1,-32),Text="📍 วาร์ปไปหา",TextColor3=white,TextSize=12,Font=Enum.Font.GothamBold},det)
 tr(tpb,"BackgroundColor3","acc") corner(tpb,8)
 local function detail()
  local p=sel
  if not p or not p.Parent then sel=nil av.Image="" dt.Text="เลือกผู้เล่นจากรายการด้านล่าง" return end
  av.Image=thumb(p.UserId)
  local c=p.Character
  local h=c and c:FindFirstChildOfClass("Humanoid")
  local r=c and c:FindFirstChild("HumanoidRootPart")
  local me=root()
  local d=(r and me) and (math.floor((r.Position-me.Position).Magnitude).." studs") or "—"
  dt.Text=p.DisplayName.." (@"..p.Name..")\nรหัส: "..p.UserId.." · อายุบัญชี: "..p.AccountAge.." วัน\nทีม: "..(p.Team and p.Team.Name or "ไม่มี")
   .."\nHP: "..(h and (math.floor(h.Health).."/"..math.floor(h.MaxHealth)) or "—").." · ระยะ: "..d
 end
 conn(tpb.Activated,function()
  click()
  run(function()
   if not sel or not sel.Parent then return false,"ยังไม่ได้เลือกผู้เล่น" end
   local r=sel.Character and sel.Character:FindFirstChild("HumanoidRootPart")
   local me=root()
   if not r or not me then return false,"ไม่พบตัวละคร" end
   me.CFrame=r.CFrame*CFrame.new(0,0,3)
   return true,"วาร์ปแล้ว (ผลขึ้นกับเกม)"
  end,"วาร์ป")
 end)
 local _,clear,add=SM.listBox(pg,1)
 local function rebuild()
  clear()
  for _,p in ipairs(Players:GetPlayers()) do
   local r=add(40)
   local im=new("ImageLabel",{Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(8,5),BackgroundColor3=OFFC,Image=thumb(p.UserId)},r) corner(im,15)
   local l=rowText(r,p.DisplayName.." (@"..p.Name..")"..(p==LP and " · คุณ" or ""),120) l.Position=UDim2.fromOffset(46,0)
   smallBtn(r,"เลือก",UDim2.new(1,-64,0,7),56,function() sel=p detail() end)
  end
 end
 conn(Players.PlayerAdded,function() task.defer(rebuild) end)
 conn(Players.PlayerRemoving,function(p) if sel==p then sel=nil end task.delay(.2,rebuild) end)
 SM.ticks.players=detail
 rebuild() detail()
end)

-- ===== WeaponSandbox (เอฟเฟกต์ภาพบนเครื่องเราเท่านั้น ไม่มีดาเมจ ไม่สร้างอาวุธจริง) =====
Mod.add("secret:weapon",function()
 local pg=SM.pages[2]
 local folder
 local function fxf() if not folder or not folder.Parent then folder=new("Folder",{Name="SunMenuFx"},workspace) end return folder end
 local function part(size,col,cf,ball)
  return new("Part",{Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Material=Enum.Material.Neon,Color=col,Size=size,
   Shape=ball and Enum.PartType.Ball or Enum.PartType.Block,CFrame=cf},fxf())
 end
 local function play(k)
  if not C.sound then return end
  local id=SOUND_ID[k]
  if not id or id=="" then UI.toast("ยังไม่ได้ใส่ SoundId ใน SOUND_ID (เอฟเฟกต์ภาพยังทำงาน)") return end
  local s=new("Sound",{SoundId=id,Volume=.6},Gui) s:Play() Debris:AddItem(s,4)
 end
 local function shoot(kind)
  local r=root()
  if not r then return false,"ไม่พบตัวละคร" end
  local cf=r.CFrame
  local mz=cf*CFrame.new(1,.4,-2)
  if C.flash then
   local f=part(Vector3.one*(kind=="ak" and .7 or .5),Color3.fromRGB(255,200,90),mz,true)
   new("PointLight",{Color=Color3.fromRGB(255,190,90),Range=6+C.quality*2,Brightness=3},f)
   Debris:AddItem(f,.06)
   local o,dir=mz.Position,cf.LookVector
   local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={LP.Character,fxf()}
   local hit=workspace:Raycast(o,dir*120,rp)
   local e=hit and hit.Position or (o+dir*120)
   local len=(e-o).Magnitude
   if len>1 then Debris:AddItem(part(Vector3.new(.08,.08,len),Color3.fromRGB(255,230,150),CFrame.lookAt(o,e)*CFrame.new(0,0,-len/2)),.08) end
  end
  if C.shell then
   local sp=cf*CFrame.new(1.2,.8,-.5)
   local sh=part(Vector3.new(.12,.12,.35),Color3.fromRGB(230,180,60),sp) sh.Material=Enum.Material.Metal
   TS:Create(sh,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
    {Position=sp.Position+cf.RightVector*2.2+Vector3.new(0,-2.4,0),Orientation=Vector3.new(math.random(360),math.random(360),0)}):Play()
   Debris:AddItem(sh,1.2)
  end
  play("gun")
  return true
 end
 local function explode(pos)
  local q=C.quality
  local ball=part(Vector3.one,Color3.fromRGB(255,170,60),CFrame.new(pos),true) ball.Transparency=.2
  local L=new("PointLight",{Color=Color3.fromRGB(255,180,80),Range=14+q*4,Brightness=6},ball)
  local R=10+q*4
  TS:Create(ball,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.one*R,Transparency=1}):Play()
  TS:Create(L,TweenInfo.new(.5),{Brightness=0}):Play()
  local wave=part(Vector3.one,white,CFrame.new(pos),true) wave.Transparency=.8
  TS:Create(wave,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.one*R*2,Transparency=1}):Play()
  local em=part(Vector3.one,white,CFrame.new(pos)) em.Transparency=1
  local fire=new("ParticleEmitter",{Rate=0,Lifetime=NumberRange.new(.5,1),Speed=NumberRange.new(12,28),SpreadAngle=Vector2.new(180,180),Size=NumberSequence.new(2.5,0),
   LightEmission=1,Color=ColorSequence.new(Color3.fromRGB(255,200,70),Color3.fromRGB(255,70,20))},em)
  local smoke=new("ParticleEmitter",{Rate=0,Lifetime=NumberRange.new(2,3.5),Speed=NumberRange.new(3,9),SpreadAngle=Vector2.new(180,180),Size=NumberSequence.new(5,9),
   Transparency=NumberSequence.new(.4,1),Color=ColorSequence.new(Color3.fromRGB(70,70,70))},em)
  fire:Emit(q*8) smoke:Emit(q*4)
  Debris:AddItem(em,4) Debris:AddItem(ball,1) Debris:AddItem(wave,1)
  play("boom")
  local h,me=hum(),root()
  if h and me and (me.Position-pos).Magnitude<60 and not (SM.freecamOn) then
   task.spawn(function()
    for _=1,8 do h.CameraOffset=Vector3.new((math.random()-.5)*.6,(math.random()-.5)*.6,0) task.wait(.03) end
    h.CameraOffset=Vector3.zero
   end)
  end
 end
 local busy=false
 local TAG="🎨 เอฟเฟกต์จำลอง · ไม่มีดาเมจ"
 SM.btns(pg,"🔫 ปืนพก 9 มม.",TAG,{{"ยิง",function() return shoot("pistol") end}},56)
 SM.btns(pg,"🔫 ปืน AK",TAG,{{"ยิงรัว",function()
  if busy then return false,"กำลังยิงอยู่" end
  if not root() then return false,"ไม่พบตัวละคร" end
  busy=true
  task.spawn(function()
   for _=1,math.max(1,C.rate) do safe("AK",shoot,"ak") task.wait(1/math.max(1,C.rate)) end
   busy=false
  end)
  return true,"ยิงรัว 1 วินาที ("..C.rate.." นัด)"
 end}},56)
 SM.btns(pg,"💣 ระเบิด",TAG,{{"ระเบิด",function()
  local r=root()
  if not r then return false,"ไม่พบตัวละคร" end
  local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={LP.Character,fxf()}
  local hit=workspace:Raycast(r.Position+r.CFrame.LookVector*3,r.CFrame.LookVector*30-Vector3.new(0,6,0),rp)
  explode(hit and hit.Position or (r.Position+r.CFrame.LookVector*25))
  return true,"ระเบิดเอฟเฟกต์ภาพ"
 end}},64)
 SM.toggle(pg,"เอฟเฟกต์ปากกระบอก/แสงยิง",TAG,function() return C.flash end,function(on) C.flash=on return true end)
 SM.toggle(pg,"เสียงยิง/ระเบิด","🎨 ต้องใส่ SoundId",function() return C.sound end,function(on) C.sound=on return true end)
 SM.toggle(pg,"เอฟเฟกต์ปลอกกระสุน",TAG,function() return C.shell end,function(on) C.shell=on return true end)
 SM.toggle(pg,"เอฟเฟกต์ระเบิด/ควัน/แรงกระเพื่อม",TAG,function() return C.boom end,function(on) C.boom=on return true end)
 SM.slider(pg,"คุณภาพเอฟเฟกต์ (1-5)",1,5,function() return C.quality end,function(v) C.quality=v return true end)
 SM.slider(pg,"ความถี่ยิง (นัด/วินาที)",1,15,function() return C.rate end,function(v) C.rate=v return true end)
 Ev.on("unload",function() if folder then folder:Destroy() end end)
end)

-- ===== DamageSettings (ต้องมี Script ฝั่งเซิร์ฟเวอร์ในเกมของคุณ: SunMenuDevServer) =====
Mod.add("secret:damage",function()
 local pg=SM.pages[2]
 local RE,hooked
 local D={damage=true,knock=true,resist=0,req=0}
 local function avail()
  RE=RE or RepS:FindFirstChild("SunMenuDev")
  if RE and RE:IsA("RemoteEvent") then
   if not hooked then hooked=true conn(RE.OnClientEvent,function(k,v) if D[k]~=nil then D[k]=v SM.refreshAll() end end) end
   return true
  end
  RE=nil
  return false,"ไม่พบ ReplicatedStorage.SunMenuDev (ต้องวาง Script ฝั่งเซิร์ฟเวอร์ SunMenuDevServer ในเกมของคุณ)"
 end
 local function send(k,v) local ok,w=avail() if not ok then return false,w end RE:FireServer(k,v) return true end
 local TAG="🔌 ต้องมี Script ฝั่งเซิร์ฟเวอร์"
 SM.toggle(pg,"รับความเสียหาย",TAG,function() return D.damage end,function(on) return send("damage",on) end)
 SM.toggle(pg,"รับแรงกระเด็น",TAG,function() return D.knock end,function(on) return send("knock",on) end)
 local tok=0
 SM.slider(pg,"ความต้านทานแรงกระแทก %",0,100,function() return D.req end,function(v)
  D.req=v tok+=1 local my=tok
  task.delay(.3,function() if tok==my then send("resist",v) end end)
  return true
 end)
 local st=rowFrame(pg,40)
 local sl=txt(st,"",11,UDim2.fromOffset(12,0),UDim2.new(1,-24,1,0),Color3.fromRGB(255,215,130))
 table.insert(SM.refs,function()
  local ok=avail()
  sl.Text="🛡️ "..(ok and "เซิร์ฟเวอร์เชื่อมแล้ว" or "ยังไม่พบระบบฝั่งเซิร์ฟเวอร์").." · ดาเมจ: "..(D.damage and "รับ" or "ไม่รับ")
   .." · แรงกระเด็น: "..(D.knock and "รับ" or "ไม่รับ").." · ต้านทาน "..D.resist.."%"
 end)
 SM.refreshAll()
end)

-- ===== CollisionSettings (เฉพาะ workspace.SunTestMap ของคุณ) =====
Mod.add("secret:collision",function()
 local pg=SM.pages[2]
 local orig,on,gi={},false,1
 local function map() return workspace:FindFirstChild("SunTestMap") end
 local function groups()
  local f=map() local L={{"ทั้งหมด",f}}
  if f then for _,c in ipairs(f:GetChildren()) do table.insert(L,{c.Name,c}) end end
  return L
 end
 local function restore() for p,v in pairs(orig) do if p.Parent then p.CanCollide=v end end orig={} end
 local function apply()
  restore()
  local L=groups() if gi>#L then gi=1 end
  local inst=L[gi][2] if not inst then return end
  local list=inst:GetDescendants() table.insert(list,inst)
  for _,p in ipairs(list) do if p:IsA("BasePart") then orig[p]=p.CanCollide p.CanCollide=false end end
 end
 SM.toggle(pg,"ทะลุสิ่งกีดขวาง (แผนที่ทดสอบ)","✅ ทำงานจริง · เฉพาะ SunTestMap",function() return on end,function(w)
  if w then
   if not map() then return false,"ไม่พบ Folder ชื่อ SunTestMap ใน workspace" end
   on=true apply()
  else on=false restore() end
  return true
 end)
 SM.btns(pg,function() local L=groups() if gi>#L then gi=1 end return "กลุ่มวัตถุ: "..L[gi][1] end,"เลือกกลุ่มที่ให้ผ่านได้ (ใน SunTestMap)",{{"สลับ",function()
  local L=groups() gi=gi%#L+1 if on then apply() end return true,"กลุ่ม: "..L[gi][1]
 end}},56)
 Ev.on("unload",restore)
end)

-- ===== FreeCamera =====
Mod.add("secret:freecam",function()
 local pg=SM.pages[3]
 local FC={on=false,yaw=0,pitch=0,pos=Vector3.zero,h={},look=nil,anch=nil}
 local ui=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},Gui)
 local dp=new("Frame",{Size=UDim2.fromOffset(150,150),AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,16,1,-16),BackgroundTransparency=1},ui)
 for _,d in ipairs({{"▲",50,0,"f"},{"▼",50,100,"b"},{"◀",0,50,"l"},{"▶",100,50,"r"},{"⬆",100,0,"u"},{"⬇",0,100,"d"}}) do
  local b=new("TextButton",{Size=UDim2.fromOffset(50,50),Position=UDim2.fromOffset(d[2],d[3]),BackgroundColor3=Color3.fromRGB(30,42,72),BackgroundTransparency=.25,
   Text=d[1],TextColor3=white,TextSize=20,Font=Enum.Font.GothamBold},dp)
  corner(b,12) stroke(b,2,TC("acc"))
  conn(b.InputBegan,function(i) if isPress(i) then FC.h[d[4]]=true end end)
  conn(b.InputEnded,function(i) if isPress(i) then FC.h[d[4]]=false end end)
 end
 local lp=new("TextLabel",{Size=UDim2.fromOffset(150,150),AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),BackgroundColor3=Color3.fromRGB(30,42,72),
  BackgroundTransparency=.6,Text="ลากเพื่อหมุนกล้อง",TextColor3=white,TextSize=12,Font=Enum.Font.GothamMedium},ui)
 corner(lp,12) stroke(lp,2,TC("acc"))
 conn(lp.InputBegan,function(i) if isPress(i) then FC.look=i end end)
 conn(UIS.InputChanged,function(i)
  if not FC.on or not FC.look then return end
  if i==FC.look or (FC.look.UserInputType==MB1 and i.UserInputType==Enum.UserInputType.MouseMovement) then
   FC.yaw-=i.Delta.X*.005 FC.pitch=math.clamp(FC.pitch-i.Delta.Y*.005,-1.5,1.5)
  end
 end)
 conn(UIS.InputEnded,function(i) if i==FC.look or (FC.look and FC.look.UserInputType==MB1 and i.UserInputType==MB1) then FC.look=nil end end)
 local function key(c) return C.fcLock and UIS:IsKeyDown(c) and not UIS:GetFocusedTextBox() end
 local function step(dt)
  local cm=cam()
  if cm.CameraType~=Enum.CameraType.Scriptable then cm.CameraType=Enum.CameraType.Scriptable end
  local rot=CFrame.fromOrientation(FC.pitch,FC.yaw,0)
  local f=((FC.h.f or key(Enum.KeyCode.W)) and 1 or 0)-((FC.h.b or key(Enum.KeyCode.S)) and 1 or 0)
  local s=((FC.h.r or key(Enum.KeyCode.D)) and 1 or 0)-((FC.h.l or key(Enum.KeyCode.A)) and 1 or 0)
  local u=((FC.h.u or key(Enum.KeyCode.E)) and 1 or 0)-((FC.h.d or key(Enum.KeyCode.Q)) and 1 or 0)
  FC.pos+=(rot.LookVector*f+rot.RightVector*s+Vector3.yAxis*u)*C.fcSpeed*dt
  cm.CFrame=CFrame.new(FC.pos)*rot
 end
 local function disable()
  pcall(function() RS:UnbindFromRenderStep("SunFreeCam") end)
  local r=root() if r and FC.anch~=nil then r.Anchored=FC.anch end
  FC.anch=nil
  local cm=cam() cm.CameraType=Enum.CameraType.Custom
  local h=hum() if h then cm.CameraSubject=h end
  FC.on=false SM.freecamOn=false ui.Visible=false FC.h={} FC.look=nil
 end
 local function enable()
  local r=root()
  if not r then return false,"ไม่พบตัวละคร" end
  local cm=cam()
  local rx,ry=cm.CFrame:ToOrientation()
  FC.pitch=rx FC.yaw=ry FC.pos=cm.CFrame.Position
  if C.fcLock then FC.anch=r.Anchored r.Anchored=true end
  cm.CameraType=Enum.CameraType.Scriptable
  RS:BindToRenderStep("SunFreeCam",Enum.RenderPriority.Camera.Value+1,function(dt) safe("freecam",step,dt) end)
  FC.on=true SM.freecamOn=true ui.Visible=true
  return true
 end
 local TAG="✅ ทำงานจริง (ฝั่งเรา)"
 SM.toggle(pg,"กล้องอิสระ (Free Camera)",TAG,function() return FC.on end,function(w) if w then return enable() end disable() return true end)
 SM.toggle(pg,"ล็อกตำแหน่งตัวละครขณะใช้กล้อง",TAG,function() return C.fcLock end,function(w)
  C.fcLock=w
  local r=root()
  if FC.on and r then
   if w then FC.anch=r.Anchored r.Anchored=true elseif FC.anch~=nil then r.Anchored=FC.anch FC.anch=nil end
  end
  return true
 end)
 SM.slider(pg,"ความเร็วกล้องอิสระ",1,200,function() return C.fcSpeed end,function(v) C.fcSpeed=v return true end)
 conn(LP.CharacterAdded,function() if FC.on then FC.anch=nil disable() SM.refreshAll() end end)
 Ev.on("unload",disable)
end)

-- ===== ZoomController (แยกจากความเร็วกล้องอิสระ) =====
Mod.add("secret:zoom",function()
 local pg=SM.pages[3]
 local Z={v=nil,orig=nil}
 local function apply(v)
  if LP.CameraMode==Enum.CameraMode.LockFirstPerson then return false,"เกมล็อกมุมมองบุคคลที่หนึ่ง" end
  v=math.clamp(math.floor(v),1,999)
  if not Z.orig then Z.orig={max=LP.CameraMaxZoomDistance,min=LP.CameraMinZoomDistance} end
  Z.v=v
  LP.CameraMinZoomDistance=math.min(LP.CameraMinZoomDistance,v)
  LP.CameraMaxZoomDistance=v
  LP.CameraMinZoomDistance=v -- ดันกล้องไปที่ระยะนี้ทันที แล้วคืนค่าต่ำสุดเพื่อให้ยังเลื่อนเข้าได้
  task.delay(.4,function() if Z.v==v and Z.orig then LP.CameraMinZoomDistance=math.min(Z.orig.min,v) end end)
  return true
 end
 local function cur() return Z.v or math.clamp(math.floor(LP.CameraMaxZoomDistance),1,999) end
 local function reset()
  if Z.orig then LP.CameraMaxZoomDistance=Z.orig.max LP.CameraMinZoomDistance=Z.orig.min end
  Z.v=nil Z.orig=nil
 end
 SM.slider(pg,"ระยะกล้อง (1-999)",1,999,cur,apply)
 SM.btns(pg,function() return "ระยะกล้องปัจจุบัน: "..cur() end,"✅ ทำงานจริง · เกมอาจจำกัดเอง",{
  {"−10",function() return apply(cur()-10) end},{"+10",function() return apply(cur()+10) end},{"รีเซ็ต",function() reset() return true,"คืนระยะกล้องเดิมแล้ว" end}},50)
 Ev.on("unload",reset)
end)

-- ===== TargetSelector (เลือกเป้าหมาย/แสดงผลเท่านั้น ไม่มีการเล็งหรือล็อกกล้องอัตโนมัติ) =====
Mod.add("secret:target",function()
 local pg=SM.pages[4]
 local T={on=false,sel=nil,key=""}
 local COLS={Color3.fromRGB(255,255,255),Color3.fromRGB(255,90,90),Color3.fromRGB(90,255,140),Color3.fromRGB(90,180,255),Color3.fromRGB(255,215,90)}
 local CN={"ขาว","แดง","เขียว","ฟ้า","เหลือง"}
 local PN={{"ขา",{"RightLowerLeg","Right Leg","LeftLowerLeg","Left Leg"}},{"ลำตัว",{"UpperTorso","Torso"}},{"ศีรษะ",{"Head"}}}
 local ring=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1,Visible=false},Gui)
 new("UICorner",{CornerRadius=UDim.new(.5,0)},ring)
 local rs=new("UIStroke",{Thickness=3},ring)
 local function style()
  ring.Size=UDim2.fromOffset(C.ringSize,C.ringSize) rs.Transparency=C.ringAlpha/100 rs.Color=COLS[C.ringColor] or white
  ring.Visible=T.on
 end
 function SM.getTargetPart() -- ให้ระบบในเกมของคุณเรียกใช้ได้
  local p=T.sel
  if not (p and p.Parent and p.Character) then return nil end
  for _,n in ipairs(PN[C.part][2]) do local x=p.Character:FindFirstChild(n) if x then return x end end
 end
 local TAG="✅ ทำงานจริง · เลือก/แสดงผลเท่านั้น"
 SM.toggle(pg,"วงกลมกลางหน้าจอ",TAG,function() return T.on end,function(w) T.on=w style() return true end)
 SM.slider(pg,"ขนาดวงกลม",60,400,function() return C.ringSize end,function(v) C.ringSize=v style() return true end)
 SM.slider(pg,"ความโปร่งใสวงกลม %",0,90,function() return C.ringAlpha end,function(v) C.ringAlpha=v style() return true end)
 SM.slider(pg,"ระยะค้นหา (studs)",20,500,function() return C.ringRange end,function(v) C.ringRange=v return true end)
 SM.btns(pg,function() return "สีวงกลม: "..CN[C.ringColor] end,"สลับสีวงกลม",{{"สลับสี",function() C.ringColor=C.ringColor%#COLS+1 style() return true end}},60)
 SM.btns(pg,function() return "ตำแหน่งร่างกาย: "..PN[C.part][1] end,"ใช้เลือกส่วนของเป้าหมาย",{
  {"ขา",function() C.part=1 return true end},{"ลำตัว",function() C.part=2 return true end},{"ศีรษะ",function() C.part=3 return true end}},52)
 local info=rowFrame(pg,40)
 local il=txt(info,"",11,UDim2.fromOffset(12,0),UDim2.new(1,-100,1,0),Color3.fromRGB(255,215,130))
 smallBtn(info,"ยกเลิก",UDim2.new(1,-76,0,7),68,function() T.sel=nil SM.refreshAll() UI.toast("ยกเลิกเป้าหมายแล้ว") end)
 table.insert(SM.refs,function()
  local p=T.sel
  if p and not p.Parent then T.sel=nil p=nil end
  il.Text=p and ("🎯 เป้าหมาย: "..p.DisplayName.." · ส่วน: "..PN[C.part][1]) or "🎯 ยังไม่ได้เลือกเป้าหมาย"
 end)
 local _,clear,add=SM.listBox(pg,50)
 local function scan()
  local L,key={},{}
  if T.on then
   local c=cam() local ctr=c.ViewportSize/2
   for _,p in ipairs(Players:GetPlayers()) do
    local hrp=p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp.Position-c.CFrame.Position).Magnitude<=C.ringRange then
     local v,onScr=c:WorldToViewportPoint(hrp.Position)
     if onScr and (Vector2.new(v.X,v.Y)-ctr).Magnitude<=C.ringSize/2 then table.insert(L,p) table.insert(key,p.UserId) end
    end
   end
  end
  local k=table.concat(key,",")..(T.on and "1" or "0")
  if k==T.key then SM.refreshAll() return end
  T.key=k clear()
  if #L==0 then
   local r=add(30) rowText(r,T.on and "ไม่มีเป้าหมายในวงกลม" or "เปิดวงกลมเพื่อดูรายชื่อเป้าหมายในระยะ",20)
  end
  for _,p in ipairs(L) do
   local r=add(36) rowText(r,p.DisplayName.." (@"..p.Name..")",84)
   smallBtn(r,"เลือก",UDim2.new(1,-64,0,5),56,function() T.sel=p SM.refreshAll() UI.toast("เลือก "..p.DisplayName) end)
  end
 end
 SM.ticks.target=scan
 style()
 Ev.on("unload",function() ring:Destroy() end)
end)

-- ===== AIKnowledge (ต่อยอดระบบ AI เดิม: คลังความรู้ + คลังโค้ด ไม่รันโค้ดที่สอน) =====
Mod.add("secret:ai",function()
 local pg=SM.pages[5]
 SM.codes={}
 local function loadCodes()
  local t=loadFile(FILE_CODE)
  if type(t)=="table" then
   for _,e in ipairs(t) do
    if type(e)=="table" and type(e[1])=="string" and type(e[2])=="string" then table.insert(SM.codes,{title=e[1],code=e[2],nk=norm(e[1])}) end
   end
  end
 end
 local function saveCodes() local out={} for _,c in ipairs(SM.codes) do table.insert(out,{c.title,c.code}) end return saveFile(FILE_CODE,out) end
 local function syncBase() -- ให้แชทตอบเรื่องโค้ดที่บันทึกได้ (แค่แสดงเป็นข้อความ)
  for i=#BASE,1,-1 do if BASE[i].isCode then table.remove(BASE,i) end end
  for _,c in ipairs(SM.codes) do
   table.insert(BASE,{isCode=true,keys={c.title},nk={norm(c.title)},a="โค้ด Lua ที่บันทึกไว้ \""..c.title.."\" (เก็บเป็นข้อมูล ไม่ได้รันให้):\n"..c.code})
  end
 end
 local function addInfo(keys,a) local e={keys=keys,a=a,nk={}} for _,k in ipairs(keys) do table.insert(e.nk,norm(k)) end table.insert(BASE,e) end
 addInfo({"เมนูลับ","secret menu"},"เมนู 🙊 เมนูลับ 🌐 ต้องใส่รหัส 4 หลักก่อนเข้า มี 7 ฟังก์ชัน: ผู้เล่น/วาร์ป, ทดลองเอฟเฟกต์อาวุธ, ความเสียหาย, การชน, กล้องอิสระ, ซูม, วงกลมเลือกเป้าหมาย แต่ละแถวมีป้ายบอกว่า ✅ ทำงานจริง / 🎨 เอฟเฟกต์จำลอง / 🔌 ต้องมี Script ฝั่งเซิร์ฟเวอร์")
 addInfo({"free camera","กล้องอิสระ"},"Free Camera คือระบบกล้องอิสระสำหรับถ่ายภาพ/วิดีโอในเกม เปิดแล้วใช้ปุ่มบนจอ (หรือ WASD+Q/E) เลื่อนกล้อง ลากช่องขวาเพื่อหมุน ปรับความเร็วได้ 1-200 ปิดแล้วกล้องกลับสู่โหมดปกติ")
 addInfo({"extended zoom","ซูมกล้อง","ระยะกล้อง"},"Extended Zoom ปรับระยะกล้องออกได้ 1-999 ด้วยแถบเลื่อนและปุ่ม −10/+10/รีเซ็ต เกมบางเกมอาจจำกัดระยะเอง")
 addInfo({"target ring","วงกลมเลือกเป้าหมาย","เลือกเป้าหมาย"},"Target Ring แสดงวงกลมกลางจอ ปรับขนาด/สี/ความโปร่งใสได้ แสดงรายชื่อผู้เล่นที่อยู่ในวงและระยะ เลือกส่วนร่างกายได้ (ขา/ลำตัว/ศีรษะ) เป็นการเลือกและแสดงผลเท่านั้น ไม่ได้เล็งให้")
 addInfo({"player profile","รายชื่อผู้เล่น","วาร์ป","teleport"},"Player Profile แสดงผู้เล่นในเซิร์ฟเวอร์ เลือกดูข้อมูล และกด 📍 วาร์ปไปหา (ผลขึ้นกับเกม)")
 addInfo({"weapon sandbox","ทดลองอาวุธ","เอฟเฟกต์อาวุธ"},"Weapon & Effect Sandbox เป็นเอฟเฟกต์ภาพบนเครื่องคุณเท่านั้น (แสงปากกระบอก เส้นกระสุน ปลอกกระสุน ระเบิด ควัน) ไม่สร้างอาวุธจริงและไม่ทำดาเมจ เสียงต้องใส่ SoundId เอง")
 addInfo({"damage settings","ความเสียหาย","แรงกระเด็น"},"Damage & Knockback ต้องมี Script SunMenuDevServer ในเกมของคุณ เซิร์ฟเวอร์เป็นผู้ตรวจและบังคับค่า ถ้าไม่พบ จะแจ้งว่าใช้ไม่ได้")
 addInfo({"collision settings","การชน","ทะลุสิ่งกีดขวาง"},"Collision Settings ใช้กับ Folder ชื่อ SunTestMap ใน workspace เท่านั้น เลือกกลุ่มวัตถุที่ให้ผ่านได้ และคืนค่าเดิมเมื่อปิด")

 local mode="k"
 local form=rowFrame(pg,184,0)
 local function box(h,y,ph,multi)
  local b=new("TextBox",{Size=UDim2.new(1,-20,0,h),Position=UDim2.fromOffset(10,y),PlaceholderText=ph,PlaceholderColor3=Color3.fromRGB(140,160,200),Text="",
   ClearTextOnFocus=false,TextColor3=white,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,MultiLine=multi,TextWrapped=multi,
   TextYAlignment=multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center},form)
  tr(b,"BackgroundColor3","panel2") corner(b,8) return b
 end
 local tbT=box(26,8,"หัวข้อ / คำถาม",false)
 local tbB=box(96,38,"คำตอบ / เนื้อหา / โค้ด Lua (โค้ดจะถูกเก็บเป็นข้อความ ไม่ถูกรัน)",true)
 local function parse(title,body)
  title,body=trim(title),trim(body)
  local kind=mode
  if title=="" then
   local t=body:match("หัวข้อ%s*:%s*([^\n]+)")
   local c=body:match("เนื้อหา%s*:%s*(.+)$")
   if t and c then
    local ty=body:match("ประเภท%s*:%s*([^\n]+)")
    if ty and (ty:find("โค้ด") or ty:lower():find("code")) then kind="c" end
    return kind,trim(t),trim(c)
   end
   local q,a=body:match("คำถาม%s*:%s*([^\n]+)%s*\n%s*คำตอบ%s*:%s*(.+)$")
   if q then return kind,trim(q),trim(a) end
   if kind=="k" then
    local q2,a2=body:match("^(.-)%s*=%s*(.+)$")
    if q2 and q2~="" then return kind,trim(q2),trim(a2) end
   end
  end
  return kind,title,body
 end
 local function validate(kind,t,b)
  if (utf8.len(norm(t)) or 0)<2 then return false,"หัวข้อ/คำถามสั้นเกินไป" end
  if #t>80 then return false,"หัวข้อยาวเกิน 80 ตัวอักษร" end
  if #b<1 then return false,"ยังไม่มีเนื้อหา/คำตอบ" end
  if kind=="k" then
   if #b>1500 then return false,"คำตอบยาวเกิน 1500 ตัวอักษร" end
   return true,"รูปแบบถูกต้อง (ความรู้)"
  end
  if #b>8000 then return false,"โค้ดยาวเกิน 8000 ตัวอักษร" end
  local ls=(type(loadstring)=="function" and loadstring) or (type(load)=="function" and load)
  if ls then
   local pc,f,err=pcall(ls,b,"=kb") -- คอมไพล์เพื่อตรวจไวยากรณ์เท่านั้น ไม่เรียกใช้ฟังก์ชัน
   if pc and not f then return false,"ไวยากรณ์ Lua ผิด: "..tostring(err) end
   if pc then return true,"ไวยากรณ์ถูกต้อง (ตรวจอย่างเดียว ไม่ได้รัน)" end
  end
  return true,"รูปแบบถูกต้อง (ตัวรันนี้ตรวจไวยากรณ์ไม่ได้)"
 end
 local box2,clear,add=SM.listBox(pg,5)
 local sb
 local function items()
  local q=trim(sb.Text):lower() local L={}
  for _,e in ipairs(AI.taught) do if q=="" or e.q:lower():find(q,1,true) or e.a:lower():find(q,1,true) then table.insert(L,{k="k",t=e.q,v=e.a,nk=e.nk}) end end
  for _,c in ipairs(SM.codes) do if q=="" or c.title:lower():find(q,1,true) or c.code:lower():find(q,1,true) then table.insert(L,{k="c",t=c.title,v=c.code,nk=c.nk}) end end
  return L
 end
 local setMode
 local function refreshList()
  clear()
  local L=items()
  if #L==0 then rowText(add(30),"ยังไม่มีรายการ",20) end
  for _,it in ipairs(L) do
   local r=add(38)
   rowText(r,(it.k=="k" and "📖 " or "💻 ")..it.t,124)
   smallBtn(r,"👁",UDim2.new(1,-102,0,6),30,function() UI.showInfo((it.k=="k" and "📖 " or "💻 ")..it.t,it.v) end)
   smallBtn(r,"✏️",UDim2.new(1,-68,0,6),30,function() setMode(it.k) tbT.Text=it.t tbB.Text=it.v UI.toast("โหลดเข้าฟอร์มแล้ว แก้แล้วกดบันทึก") end)
   smallBtn(r,"🗑",UDim2.new(1,-34,0,6),30,function()
    if it.k=="k" then
     for i=#AI.taught,1,-1 do if AI.taught[i].nk==it.nk then table.remove(AI.taught,i) end end
     saveKB()
    else
     for i=#SM.codes,1,-1 do if SM.codes[i].nk==it.nk then table.remove(SM.codes,i) end end
     saveCodes() syncBase()
    end
    UI.toast("ลบแล้ว") refreshList()
   end)
  end
 end
 local mb
 function setMode(m) mode=m if mb then mb.Text=(m=="k") and "📖 ความรู้" or "💻 โค้ด" end end
 local function doSave()
  local kind,t,b=parse(tbT.Text,tbB.Text)
  local ok,msg=validate(kind,t,b)
  if not ok then return false,msg end
  if kind=="k" then
   local res=addTaught(t,b)
   refreshList()
   return true,res:match("^[^\n]+")
  end
  local nk,upd=norm(t),false
  for _,c in ipairs(SM.codes) do if c.nk==nk then c.code=b c.title=t upd=true end end
  if not upd then
   if #SM.codes>=100 then return false,"คลังโค้ดเต็ม 100 รายการ" end
   table.insert(SM.codes,{title=t,code=b,nk=nk})
  end
  local sv=saveCodes() syncBase() refreshList()
  return true,(upd and "อัปเดตโค้ดแล้ว ✅" or "บันทึกโค้ดแล้ว ✅")..(sv and "" or " (เก็บในเซสชันนี้เท่านั้น)")
 end
 mb=smallBtn(form,"📖 ความรู้",UDim2.fromOffset(10,148),80,function() setMode(mode=="k" and "c" or "k") end)
 smallBtn(form,"✔ ตรวจ",UDim2.fromOffset(96,148),72,function()
  local kind,t,b=parse(tbT.Text,tbB.Text) local ok,msg=validate(kind,t,b) UI.toast((ok and "✅ " or "❌ ")..msg)
 end)
 smallBtn(form,"💾 บันทึก",UDim2.fromOffset(174,148),84,function() local _,m=doSave() UI.toast(m) end)
 smallBtn(form,"ล้าง",UDim2.fromOffset(264,148),60,function() tbT.Text="" tbB.Text="" end)
 local srow=rowFrame(pg,34,4)
 sb=new("TextBox",{Size=UDim2.new(1,-20,0,26),Position=UDim2.fromOffset(10,4),PlaceholderText="🔎 ค้นหาความรู้/โค้ดที่สอนไว้",PlaceholderColor3=Color3.fromRGB(140,160,200),
  Text="",ClearTextOnFocus=false,TextColor3=white,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},srow)
 tr(sb,"BackgroundColor3","panel2") corner(sb,8)
 conn(sb:GetPropertyChangedSignal("Text"),refreshList)
 local setRow=SM.btns(pg,"ตั้งค่าเมนูลับ","บันทึกค่าที่ปรับไว้ลงไฟล์ (ถ้าตัวรันรองรับ)",{{"💾 บันทึก",function()
  local ok,e=saveFile(FILE_SM,SM.cfg) if ok then return true,"บันทึกแล้ว" end return false,tostring(e)
 end}},70)
 loadCodes() syncBase() refreshList()
end)

-- ===== ลูปเมนูลับ: ล็อกเมื่อปิดหน้าต่าง + อัปเดตข้อมูลเป็นระยะ =====
local acc4=0
conn(RS.Heartbeat,function(dt)
 if SM.unlocked and not winOpen then SM.lock() end
 acc4+=dt
 if acc4<.4 then return end
 acc4=0
 if SM.unlocked and P3.Visible then for k,f in pairs(SM.ticks) do safe("tick "..k,f) end end
end)
Log.add("I","โมดูลเมนูลับ โหลดแล้ว")
end
