net.Receive("LoganRunSound", function()
    local soundToRun = tostring(net.ReadString())
    local soundLevel = net.ReadInt(16)
    --surface.PlaySound(tostring(soundToRun))
    LocalPlayer():EmitSound(soundToRun, soundLevel or 75)
end)

chalkMessages = {
    {pos1 = Vector(), rot = Angle(), msg = ""},
    {pos1 = Vector(), rot = Angle(), msg = ""},
    {pos1 = Vector(), rot = Angle(), msg = ""}
}

hook.Add("PostDrawOpaqueRenderables", "DrawChalkMessages", function()
    if !enableHudEffects then return end --If this is loaded but we're not on my map

    for k, v in pairs(chalkMessages) do
        local text = v.msg

        cam.Start3D2D(v.pos1, Angle(0, 0, 90) + v.rot, 0.5)
            draw.NoTexture()
            surface.SetFont("nz.display.hud.main")
            surface.SetDrawColor(255, 255, 255)
            surface.SetTextColor(255, 255, 255)
            if istable(v.msg) then
                for k, v in pairs(v.msg) do
                    surface.SetTextPos(0, 48 * (k - 1))
                    surface.DrawText(v)
                end
            else
                surface.SetTextPos(0, 0)
                surface.DrawText(text)
            end
        cam.End3D2D()
    end
end)