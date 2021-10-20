QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:GetUserCharacters", function(source, cb)
    local src = source

    QBCore.Functions.ExecuteSql(false, 'SELECT * FROM `players` WHERE `steam` = \'' .. GetPlayerIdentifier(src) ..'\'', function(result)
        if result ~= nil then
            cb(result)
        else
            cb(false)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:GetServerLogs", function(source, cb)
    exports['ghmattimysql']:execute('SELECT * FROM server_logs', function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback("test:yeet", function(source, cb)
    local steamId = GetPlayerIdentifiers(source)[1]
    local plyChars = {}
    
    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @steam', {['@steam'] = steamId}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)

            table.insert(plyChars, result[i])
        end
        cb(plyChars)
    end)
end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid, inf)
    local src = source
    local info = inf
    QBCore.Functions.ExecuteSql(false, "SELECT * FROM `playerskins` WHERE `citizenid` = '"..cid.."'", function(result)
        if result[1] ~= nil then
            cb(result[1].model, result[1].skin, info)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('qb-multicharacter:server:disconnect')
AddEventHandler('qb-multicharacter:server:disconnect', function()
    local src = source
    DropPlayer(src, "Je bent gedisconnect van Santos Roleplay")
end)


RegisterServerEvent('qb-multicharacter:server:loadUserData')
AddEventHandler('qb-multicharacter:server:loadUserData', function(cData)
    local src = source
    if QBCore.Player.Login(src, cData.dat[1]) then
        print('^2[qb-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.dat[1]..') has succesfully loaded!')
        QBCore.Commands.Refresh(src)
        loadHouseData()

        TriggerEvent('qb-logs:server:createLog', GetCurrentResourceName(), 'qb-multicharacter:server:loadUserData', "Loaded citizenID " .. cData.dat[1] .. ".", src)
        TriggerClientEvent('apartments:client:setupSpawnUI', src, cData)
	end
end)

RegisterServerEvent('qb-multicharacter:server:createCharacter')
AddEventHandler('qb-multicharacter:server:createCharacter', function(data, cid)
    local src = source
    local newData = {}
    newData.charinfo = data
    newData.cid = cid
    if QBCore.Player.Login(src, false, newData) then
        print('^2[qb-core]^7 '..GetPlayerName(src)..' has succesfully loaded!')
        QBCore.Commands.Refresh(src)
        loadHouseData()

        TriggerEvent('qb-logs:server:createLog', GetCurrentResourceName(), 'qb-multicharacter:server:createCharacter', "Created new character.", src)

        TriggerClientEvent("qb-multicharacter:client:closeNUI", src)
        TriggerClientEvent('apartments:client:setupSpawnUI', src, newData)
        GiveStarterItems(src)
	end
end)

RegisterServerEvent('qb-multicharacter:server:deleteCharacter')
AddEventHandler('qb-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    QBCore.Player.DeleteCharacter(src, citizenid)

    TriggerEvent('qb-logs:server:createLog', GetCurrentResourceName(), 'qb-multicharacter:server:createCharacter', "Deleted character.", src)
end)

function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    for k, v in pairs(QBCore.Shared.StarterItems) do
        local info = {}
        if v.item == "id_card" then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == "driver_license" then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = "A1-A2-A | AM-B | C1-C-CE"
        end
        Player.Functions.AddItem(v.item, 1, false, info)
    end
end

function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
	QBCore.Functions.ExecuteSql(false, "SELECT * FROM `houselocations`", function(result)
		if result[1] ~= nil then
			for k, v in pairs(result) do
				local owned = false
				if tonumber(v.owned) == 1 then
					owned = true
				end
				local garage = v.garage ~= nil and json.decode(v.garage) or {}
				Houses[v.name] = {
					coords = json.decode(v.coords),
					owned = v.owned,
					price = v.price,
					locked = true,
					adress = v.label, 
					tier = v.tier,
					garage = garage,
					decorations = {},
				}
				HouseGarages[v.name] = {
					label = v.label,
					takeVehicle = garage,
				}
			end
		end
		TriggerClientEvent("qb-garages:client:houseGarageConfig", -1, HouseGarages)
		TriggerClientEvent("qb-houses:client:setHouseConfig", -1, Houses)
	end)
end

QBCore.Commands.Add("char", "Log-Uit door Admin", {}, false, function(source, args)
    QBCore.Player.Logout(source)
    TriggerClientEvent('qb-multicharacter:client:chooseChar', source)
    TriggerEvent('qb-logs:server:createLog', GetCurrentResourceName(), 'command char', "Used the command **char**", source)
end, "god")

QBCore.Commands.Add("closeNUI", "Close NUI", {}, false, function(source, args)
    TriggerClientEvent('qb-multicharacter:client:closeNUI', source)
end)