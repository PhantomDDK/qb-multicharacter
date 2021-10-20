QBCore = nil

Config = {
    PedCoords = {x = -813.97, y = 176.22, z = 76.74, h = -7.5, r = 1.0}, 
    HiddenCoords = {x = -1401.42, y = -986.58, z = 20.38, h = 19.38, r = 1.0},
    CamCoords = {x = -1401.42, y = -986.58, z = 20.38, h = 19.38, r = 1.0}, 

    spawns = {
        [1] = {
            coords = vector3(-1411.27, -990.08, 19.38),
            heading = 287.19
        },

        [2] = {
            coords = vector3(-1410.58, -991.65, 19.38),
            heading = 295.05
        },

        [3] = {
            coords = vector3(-1409.56, -993.45, 19.38),
            heading = 304.64
        },

        [4] = {
            coords = vector3(-1408.29, -995.08, 19.38),
            heading = 311.96
        },

        [5] = {
            coords = vector3(-1406.93, -996.25, 19.38),
            heading = 328.67
        }
    }
}

local charPed = nil
local createdChars = {}
local currentChar = nil
local choosingCharacter = false
local currentMarker = nil
local cam = nil

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(10)
        if QBCore == nil then
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)    
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
        if NetworkIsSessionStarted() then
            TriggerEvent('qb-multicharacter:client:chooseChar')
            TriggerServerEvent('mumble:infinity:server:mutePlayer')
			return
		end
	end
end)

function openCharMenu(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "ui",
        toggle = bool,
    })
    choosingCharacter = bool

    if bool == true then
        DoScreenFadeIn(3000)
        createCamera('create')
        Wait(1500)

        local html = ""
        for k, v in ipairs(createdChars) do
            local pedCoords = GetPedBoneCoords(v.ped, 0x2e28, 0.0, 0.0, 0.0)
            local onScreen, xxx, yyy = GetHudScreenPositionFromWorldPosition(pedCoords.x, pedCoords.y, pedCoords.z + 0.3)
            if v.isreg then
                html = html .. "<div id=\"" .. v.key .. "\" onmouseover=\"update_char_marker(this.id)\" onClick=\"select_character(this.id)\"><p style=\"left: ".. xxx * 100 .."%;top: ".. yyy * 90 .."%;-webkit-transform: translate(-50%, 0%);max-width: 100%; position: absolute; padding-top: 170px; padding-right: 30px; padding-bottom: 100px; padding-left: 80px;;\"></p></div>"
            else
                html = html .. "<div id=\"" .. v.key .. "\" onmouseover=\"update_char_marker(this.id)\" onClick=\"create_character(this.id)\"><p style=\"left: ".. xxx * 100 .."%;top: ".. yyy * 90 .."%;-webkit-transform: translate(-50%, 0%);max-width: 100%; position: absolute; padding-top: 170px; padding-right: 30px; padding-bottom: 100px; padding-left: 80px;;\"></p><p style=\"left: ".. xxx * 100 .."%;top: ".. yyy * 100 .."%;;text-shadow: 1px 0px 5px #000000FF, -1px 0px 0px #000000FF, 0px -1px 0px #000000FF, 0px 1px 5px #000000FF;-webkit-transform: translate(-50%, 0%);max-width: 100%;position: fixed;text-align: center;color: #FFFFFF; font-family:Heebo;font-size: 20px;\"><img \" width=\"30px\" height=\"30px\" src=\"plus.png\"></img></span></p></div>"
            end
        end

        SendNUIMessage({
            action = "setinfo",
            data = html,
        })
    else
        createCamera('exit')
    end
end

RegisterNetEvent('qb-multicharacter:client:closeNUI')
AddEventHandler('qb-multicharacter:client:closeNUI', function()
    SetNuiFocus(false, false)
end)

local Countdown = 1
function deletePeds()
    for _, v in pairs(createdChars) do
        SetEntityAsMissionEntity(v.ped, true, true)
        DeleteEntity(v.ped)
    end
    createdChars = {}
end

function CreatePeds()
    QBCore.Functions.TriggerCallback('qb-multicharacter:server:GetUserCharacters', function(res)
        local result = res
        local html = ""
        local dontHasStuff = {}
        
        for i = 1, 5, 1 do
            local has = false
            for k, v in ipairs(result) do
                if v.cid == i then
                    has = true
                    break
                end
            end
            if not has then
                table.insert(dontHasStuff, i)
            end
        end

        for k, v in ipairs(dontHasStuff) do
            Citizen.CreateThread(function()
                local randommodels = {
                    "mp_m_freemode_01",
                    "mp_f_freemode_01",
                }
                local model = GetHashKey(randommodels[math.random(1, #randommodels)])
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Citizen.Wait(0)
                end
                local charPed = CreatePed(3, model, Config.spawns[v].coords.x, Config.spawns[v].coords.y, Config.spawns[v].coords.z - 0.98, Config.spawns[v].heading, false, true)
                SetEntityAlpha(charPed, 100)
                SetPedComponentVariation(charPed, 0, 0, 0, 2)
                FreezeEntityPosition(charPed, false)
                SetEntityInvincible(charPed, true)
                PlaceObjectOnGroundProperly(charPed)
                SetBlockingOfNonTemporaryEvents(charPed, true)
                table.insert(createdChars, {key = v, ped = charPed, isreg = false})
            end)
        end

        for k, v in ipairs(result) do
            QBCore.Functions.TriggerCallback('qb-multicharacter:server:getSkin', function(model, data, inf)
                Wait(500)
                local citizenid, cid, name = inf[1], inf[2], inf[3]
                local model = model ~= nil and tonumber(model) or false
                if model ~= nil then
                    CreateThread(function()
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Citizen.Wait(0)
                        end
        
                        local charPed = CreatePed(3, model, Config.spawns[cid].coords.x, Config.spawns[cid].coords.y, Config.spawns[cid].coords.z - 0.98, Config.spawns[cid].heading, false, true)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        FreezeEntityPosition(charPed, false)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        data = json.decode(data)
                        TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
                        table.insert(createdChars, {key = cid, ped = charPed, dat = inf,isreg = true})
                    end)
                else
                    Citizen.CreateThread(function()
                        local randommodels = {
                            "mp_m_freemode_01",
                            "mp_f_freemode_01",
                        }
                        local model = GetHashKey(randommodels[math.random(1, #randommodels)])
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Citizen.Wait(0)
                        end
                        local charPed = CreatePed(3, model, Config.spawns[cid].coords.x, Config.spawns[cid].coords.y, Config.spawns[cid].coords.z - 0.98, Config.spawns[cid].heading, false, true)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        FreezeEntityPosition(charPed, false)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        table.insert(createdChars, {key = cid, ped = charPed, dat = inf,isreg = true})
                    end)
                end
            end, v.citizenid, {v.citizenid, v.cid, json.decode(v.charinfo).firstname .. ' ' .. json.decode(v.charinfo).lastname})
        end
    end)
end


function selectChar()
    openCharMenu(true)
end

function getPedFromCharID(id)
    for k, v in pairs(createdChars) do
        if v.key == id then
            if not v.isreg then
                SetEntityAlpha(v.ped, 255)
            end
            return v
        end
    end
    return nil
end

RegisterNUICallback('setupCharacters', function()
    QBCore.Functions.TriggerCallback("test:yeet", function(result)
        SendNUIMessage({
            action = "setupCharacters",
            characters = result
        })
    end)
end)

RegisterNUICallback('closeUI', function()
    openCharMenu(false)
end)

RegisterNUICallback('disconnectButton', function()
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    TriggerServerEvent('qb-multicharacter:server:disconnect')
end)

RegisterNUICallback('selectCharacter', function()
    deletePeds()
    DoScreenFadeOut(10)
    TriggerServerEvent('qb-multicharacter:server:loadUserData', currentChar)
    openCharMenu(false)
end)

RegisterNUICallback('getCloserToCharacter', function(data)
    local pedData = getPedFromCharID(tonumber(data.charid))
    currentChar = pedData
    createCamera('char', pedData.ped)

    if currentChar.isreg then
        SendNUIMessage({
            action = "setCharData",
            name = currentChar.dat[3],
            cid = currentChar.dat[1],
        })
    end
    currentMarker = nil
end)

RegisterNUICallback('updateCharMarker', function(data)
    if data.charid ~= false then
        local pedData = getPedFromCharID(tonumber(data.charid))
        currentMarker = GetEntityCoords(pedData.ped)
        if not pedData.isreg then
            SetEntityAlpha(pedData.ped, 100)
        end
    else
        currentMarker = nil
    end
end)

Citizen.CreateThread(function ()
    while true do
        if currentMarker ~= nil then
            DrawMarker(0, currentMarker.x, currentMarker.y, currentMarker.z + 1.2 , 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.1, 255, 3, 53, 255, 0, 0, 0, 1, 0, 0, 0)
        end
        Wait(3)
    end
end)

RegisterNUICallback('getOffChar', function()
    createCamera('create')
    if not currentChar.isreg then
        SetEntityAlpha(currentChar.ped, 100)
    end
    currentChar = nil
    currentMarker = nil
end)

RegisterNUICallback('createNewCharacter', function(data)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "man" then
        cData.gender = 0
    elseif cData.gender == "woman" then
        cData.gender = 1
    end

    TriggerServerEvent('qb-multicharacter:server:createCharacter', cData, currentChar.key)
    TriggerServerEvent('qb-multicharacter:server:GiveStarterItems')
    deletePeds()
    openCharMenu(false)
    Citizen.Wait(500)
end)

RegisterNetEvent('qb-multicharacter:refreshPeds')
AddEventHandler('qb-multicharacter:refreshPeds', function()
    
    deletePeds()
    currentChar = nil
    openCharMenu(false)
    CreatePeds()
    openCharMenu(true)
end)

RegisterNUICallback('removeCharacter', function()
    TriggerServerEvent('qb-multicharacter:server:deleteCharacter', currentChar.dat[1])
    DoScreenFadeOut(750)
    Wait(1500)
    TriggerEvent('qb-multicharacter:refreshPeds')
end)

RegisterNUICallback('removeBlur', function()
    SetTimecycleModifier('default')
end)

RegisterNUICallback('setBlur', function()
    SetTimecycleModifier('hud_def_blur')
end)

function createCamera(typ, pedData)
    SetRainFxIntensity(0.0)
    TriggerEvent('qb-weathersync:client:DisableSync')
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(12, 0, 0)

    if typ == 'create' then
        DoScreenFadeIn(1000)
        SetTimecycleModifierStrength(1.0)
        FreezeEntityPosition(GetPlayerPed(-1), false)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", -1402.69, -988.66, 20.18, -7.0, 0.0, 123.86, 50.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    elseif typ == 'exit' then
        SetTimecycleModifier('default')
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(GetPlayerPed(-1), false)
    elseif typ == 'char' then
        local coords = GetOffsetFromEntityInWorldCoords(pedData, 0, 2.0, 0)
        RenderScriptCams(false, false, 0, 1, 0)
        DestroyCam(cam, false)
        if(not DoesCamExist(cam)) then
            cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
            SetCamActive(cam, true)
            RenderScriptCams(true, false, 0, true, true)
            SetCamCoord(cam, coords.x, coords.y, coords.z + 0.5)
            SetCamRot(cam, 0.0, 0.0, GetEntityHeading(pedData) + 180)
        end
    end
end


-- Gta V Switch
local cloudOpacity = 0.01
local muteSound = true

function ToggleSound(state)
    if state then
        StartAudioScene("MP_LEADERBOARD_SCENE");
    else
        StopAudioScene("MP_LEADERBOARD_SCENE");
    end
end

function InitialSetup()
    ToggleSound(muteSound)
    if not IsPlayerSwitchInProgress() then
        SwitchOutPlayer(PlayerPedId(), 1, 1)
    end
end

function ClearScreen()
    SetCloudHatOpacity(cloudOpacity)
    HideHudAndRadarThisFrame()
    SetDrawOrigin(0.0, 0.0, 0.0, 0)
end

RegisterNetEvent('qb-multicharacter:client:chooseChar')
AddEventHandler('qb-multicharacter:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(0)

    ToggleSound(muteSound)
    if not IsPlayerSwitchInProgress() then
        SwitchOutPlayer(PlayerPedId(), 1, 1)
    end
    while GetPlayerSwitchState() ~= 5 do
        Citizen.Wait(0)
        ClearScreen()
    end

    ClearScreen()
    Citizen.Wait(0)
    
    local timer = GetGameTimer()
    ToggleSound(false)

    CreatePeds()
    ShutdownLoadingScreenNui()
    SetEntityCoords(GetPlayerPed(-1), vector3(-1401.42, -986.58, 20.38))
    SetEntityVisible(GetPlayerPed(-1), false, false)
    FreezeEntityPosition(GetPlayerPed(-1), true)
    Citizen.CreateThread(function()
        RequestCollisionAtCoord(Config.spawns[1].coords)
        while not HasCollisionLoadedAroundEntity(GetPlayerPed(-1)) do
            print('[qb-multicharacter] Loading spawn collision.')
            Wait(0)
        end
    end)

    DoScreenFadeIn(250)
    while true do
        ClearScreen()
        Citizen.Wait(0)
        if GetGameTimer() - timer > 5000 then
            SwitchInPlayer(PlayerPedId())
            ClearScreen()
            CreateThread(function()
                Wait(4000)
                DoScreenFadeOut(350)
            end)

            while GetPlayerSwitchState() ~= 12 do
                Citizen.Wait(0)
                ClearScreen()
            end
            
            break
        end
    end

    NetworkSetTalkerProximity(0.0)
    openCharMenu(true)
end)