include('shared.lua')

local matBeam		 		= Material("egon/egon_middlebeam")
local matLight 				= Material("egon/muzzlelight")
local matRefraction			= Material("egon/egon_ringbeam")
local matRefractRing		= Material("egon/refract_ring")

function ENT:Initialize()
	self.Size = 0
end

function ENT:Think()
	self.Entity:SetRenderBoundsWS(self:GetEndPos(),self.Entity:GetPos(),Vector()*8)
	self.Size = math.Approach(self.Size,1,10*FrameTime())
end

function ENT:DrawMainBeam(StartPos,EndPos)
	local TexOffset = CurTime()*-2.0
	render.SetMaterial(matBeam)
	render.DrawBeam(StartPos,EndPos,32,TexOffset*-0.4,TexOffset*-0.4+StartPos:Distance(EndPos)/256,col_white)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()
	render.DrawBeam(StartPos,EndPos,32,TexOffset*0.5,TexOffset*0.5+StartPos:Distance(EndPos)/1024,col_white)
end

function ENT:DrawCurlyBeam(StartPos,EndPos,Angle)
	local TexOffset = CurTime()*0.5
	local Forward	= Angle:Forward()
	local Right 	= Angle:Right()
	local Up 		= Angle:Up()
	local Distance = StartPos:Distance(EndPos)
	local StepSize = 16
	local RingTightness = 0.05
	local LastPos
	render.SetMaterial(matBeam)
	for i=0, Distance, StepSize do
		local sin = math.sin(CurTime()*-30+i*RingTightness)
		local cos = math.cos(CurTime()*-30+i*RingTightness)
		local Pos = StartPos+(Forward*i)+(Up*sin*16)+(Right*cos*16)
		if LastPos then
			render.DrawBeam(LastPos,Pos,(math.sin(i*0.02)+1)*4,TexOffset+i,TexOffset+Distance/128+i,col_white)
		end
		LastPos = Pos
	end
end

function ENT:Draw()
	local Owner = self.Entity:GetOwner()
	if !Owner or Owner == NULL then return end
	local StartPos 		= self.Entity:GetPos()
	local EndPos 		= self:GetEndPos()
	local ViewModel 	= Owner == LocalPlayer()
	local Angle = Owner:EyeAngles()
	local st
	if ViewModel then
		local vm = Owner:GetViewModel()
		if !vm or vm == NULL then return end
		local attachment = vm:GetAttachment(1)
		StartPos = attachment.Pos
		st = Owner:EyePos()
	elseif !Owner:IsPlayer() then
		StartPos = Owner:GetPos()
		st = StartPos
	else
		local vm = Owner:GetActiveWeapon()
		if (!vm || vm == NULL) then return end
		local attachment = vm:GetAttachment( 1 )
		StartPos = attachment.Pos
		st = StartPos
	end
	if Owner:IsPlayer() then
		en = st+(Owner:EyeAngles():Forward()*4096)
		fl = {Owner,Owner:GetActiveWeapon()}
	else
		en = st+(Owner:GetAngles():Up()*4096)
		fl = {Owner}
	end
	local tr = Egon_GetTraceData(st,en,fl)
	EndPos = tr.HitPos
	local TexOffset = CurTime()*-2
	local Distance = EndPos:Distance(StartPos)*self.Size
	Angle = (EndPos-StartPos):Angle()
	local Normal = Angle:Forward()
	render.SetMaterial(matLight)
	render.DrawQuadEasy(EndPos+tr.HitNormal,tr.HitNormal,64*self.Size,64*self.Size,color_white)
	render.DrawQuadEasy(EndPos+tr.HitNormal,tr.HitNormal,math.Rand(32,128)*self.Size,math.Rand(32,128)*self.Size,color_white)
	render.DrawSprite(EndPos+tr.HitNormal,64,64,Color(150,150,255,self.Size*255))
	self:DrawMainBeam(StartPos,StartPos+Normal*Distance)
	self:DrawCurlyBeam(StartPos,StartPos+Normal*Distance,Angle)
	render.SetMaterial(matLight)
	render.DrawSprite(StartPos,30,30,Color(150,150,255,255*self.Size))
	render.DrawSprite(StartPos+Normal*32,64,64,Color(150,150,255,255*self.Size))
	if !self.LastDecal or self.LastDecal < CurTime() then
		util.Decal("EgonBurn",StartPos,StartPos+Normal*Distance*1.1)
		self.LastDecal = CurTime()+0.05
	end
end

function ENT:IsTranslucent()
	return true
end
