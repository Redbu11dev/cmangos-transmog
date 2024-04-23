local EquipTransmogTooltip = CreateFrame("Frame", "EquipTransmogTooltip", GameTooltip)
local Transmog = CreateFrame("Frame")

Transmog.debug = false

Transmog:RegisterEvent("GOSSIP_SHOW")
Transmog:RegisterEvent("GOSSIP_CLOSED")
Transmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
Transmog:RegisterEvent("CHAT_MSG_ADDON")

--local TRANSMOG_CONFIG = {} --hax

transmogOutfits = {}

local TransmogFrame_Find = string.find
local TransmogFrame_ToNumber = tonumber

local _, race = UnitRace('player')
local _, class = UnitClass('player')
local GAME_YELLOW = "|cffffd200"

function twferror(a)
    DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0[TWFError]:|cffffffff ' .. a .. '. Please report.')
end

function twfprint(a)
    if a == nil then
        twferror('Attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(GAME_YELLOW .. a)
end

function twfdebug(a)
    if not Transmog.debug then
        return
    end
    if type(a) == 'boolean' then
        if a then
            twfprint('|cff0070de[DEBUG]|cffffffff[true]')
        else
            twfprint('|cff0070de[DEBUG]|cffffffff[false]')
        end
        return true
    end
    twfprint('|cff0070de[DEBUG:' .. GetTime() .. ']|cffffffff[' .. a .. ']')
end

Transmog.race = string.lower(race)
Transmog.class = string.lower(class)
Transmog.faction = 'A'
if Transmog.race ~= 'human' and Transmog.race ~= 'gnome' and Transmog.race ~= 'dwarf' and Transmog.race ~= 'nightelf' and Transmog.race ~= 'bloodelf' then
    Transmog.faction = 'H'
end

Transmog.prefix = "transmog"

Transmog.availableTransmogItems = {}
Transmog.ItemButtons = {}
Transmog.currentTransmogSlotName = nil
Transmog.currentTransmogSlot = nil
Transmog.page = -1
Transmog.currentPage = 1
Transmog.totalPages = 1
Transmog.ipp = 15
Transmog.numTransmogs = {}
Transmog.transmogDataFromServer = {}
Transmog.transmogStatusFromServer = {}
Transmog.transmogStatusToServer = {}
Transmog.tab = ''
Transmog.equippedItems = {}
Transmog.fashionCoins = 0
Transmog.currentOutfit = nil
Transmog.equippedTransmogs = {}
Transmog.transmogCost = 0
Transmog.transmogCurrency = 0

Transmog.currentTransmogsData = {}

Transmog.availableSets = {}
Transmog.gearChanged = nil
Transmog.localCache = {}

Transmog.inventorySlots = {
    ['HeadSlot'] = 1,
    ['ShoulderSlot'] = 3,
    ['ChestSlot'] = 5,
    ['WaistSlot'] = 6,
    ['LegsSlot'] = 7,
    ['FeetSlot'] = 8,
    ['WristSlot'] = 9,
    ['HandsSlot'] = 10,
    ['BackSlot'] = 15,
    ['MainHandSlot'] = 16,
    ['SecondaryHandSlot'] = 17,
    ['RangedSlot'] = 18
}

Transmog.inventorySlotNames = {
    [1] = "Head Slot",
    [3] = "Shoulder Slot",
    [5] = "Chest Slot",
    [6] = "Waist Slot",
    [7] = "Legs Slot",
    [8] = "Feet Slot",
    [9] = "Wrist Slot",
    [10] = "Hand Slot",
    [15] = "Back Slot",
    [16] = "Main Hand Slot",
    [17] = "Off Hand Slot",
    [18] = "Ranged Slot"
}

Transmog.invTypes = {
    ['INVTYPE_HEAD'] = 1,
    ['INVTYPE_SHOULDER'] = 3,
    ['INVTYPE_CLOAK'] = 16,
    --['INVTYPE_BODY'] = 4, -- shirt
    ['INVTYPE_CHEST'] = 5,
    ['INVTYPE_ROBE'] = 20,
    ['INVTYPE_WAIST'] = 6,
    ['INVTYPE_LEGS'] = 7,
    ['INVTYPE_FEET'] = 8,
    ['INVTYPE_WRIST'] = 9,
    ['INVTYPE_HAND'] = 10,

    ['INVTYPE_WEAPON'] = 13,
    ['INVTYPE_WEAPONMAINHAND'] = 21,

    ['INVTYPE_2HWEAPON'] = 17,

    ['INVTYPE_SHIELD'] = 14,
    ['INVTYPE_WEAPONOFFHAND'] = 22,
    ['INVTYPE_HOLDABLE'] = 23,

    ['INVTYPE_THROWN'] = 25,
    ['INVTYPE_RANGED'] = 15,
    ['INVTYPE_RANGEDRIGHT'] = 26,
}

Transmog.errors = {
	['1'] = 'no money/token',
	['2'] = 'invalid transmog',
	['3'] = 'failed to apply transmog'
    --['0'] = 'no error',
    --['1'] = 'no dest item',
    --['2'] = 'bad slot',
    --['3'] = 'transmog not learned',
    --['4'] = 'no source item proto',
    --['5'] = 'source not valid for destination',
    --['10'] = 'stoi failed',
    --['11'] = 'no coin'
}

-- server side
EQUIPMENT_SLOT_HEAD = 0
EQUIPMENT_SLOT_SHOULDERS = 2
EQUIPMENT_SLOT_BODY = 3 -- shirt ?
EQUIPMENT_SLOT_CHEST = 4
EQUIPMENT_SLOT_WAIST = 5
EQUIPMENT_SLOT_LEGS = 6
EQUIPMENT_SLOT_FEET = 7
EQUIPMENT_SLOT_WRISTS = 8
EQUIPMENT_SLOT_HANDS = 9
EQUIPMENT_SLOT_BACK = 14
EQUIPMENT_SLOT_MAINHAND = 15
EQUIPMENT_SLOT_OFFHAND = 16
EQUIPMENT_SLOT_RANGED = 17

C_INVTYPE_HEAD = 1;
C_INVTYPE_SHOULDERS = 3;
C_INVTYPE_BODY = 4;
C_INVTYPE_CHEST = 5;
C_INVTYPE_WAIST = 6;
C_INVTYPE_LEGS = 7;
C_INVTYPE_FEET = 8;
C_INVTYPE_WRISTS = 9;
C_INVTYPE_HANDS = 10;
C_INVTYPE_WEAPON = 13;
C_INVTYPE_SHIELD = 14;
C_INVTYPE_RANGED = 15;
C_INVTYPE_CLOAK = 16;
C_INVTYPE_2HWEAPON = 17;
C_INVTYPE_ROBE = 20;
C_INVTYPE_WEAPONMAINHAND = 21;
C_INVTYPE_WEAPONOFFHAND = 22;
C_INVTYPE_HOLDABLE = 23;
C_INVTYPE_THROWN = 25;
C_INVTYPE_RANGEDRIGHT = 26;

--C_ITEM_CLASS_WEAPON = 2;
--C_ITEM_CLASS_ARMOR = 4;

--C_ITEM_SUBCLASS_WEAPON_AXE = 0;
--C_ITEM_SUBCLASS_WEAPON_AXE2 = 1;
--C_ITEM_SUBCLASS_WEAPON_BOW = 2;
--C_ITEM_SUBCLASS_WEAPON_GUN = 3;
--C_ITEM_SUBCLASS_WEAPON_MACE = 4;
--C_ITEM_SUBCLASS_WEAPON_MACE2 = 5;
--C_ITEM_SUBCLASS_WEAPON_POLEARM = 6;
--C_ITEM_SUBCLASS_WEAPON_SWORD = 7;
--C_ITEM_SUBCLASS_WEAPON_SWORD2 = 8;
--C_ITEM_SUBCLASS_WEAPON_STAFF = 10;
--C_ITEM_SUBCLASS_WEAPON_FIST = 13;
--C_ITEM_SUBCLASS_WEAPON_DAGGER = 15;
--C_ITEM_SUBCLASS_WEAPON_THROWN = 16;
--C_ITEM_SUBCLASS_WEAPON_SPEAR = 17;
--C_ITEM_SUBCLASS_WEAPON_CROSSBOW = 18;
--C_ITEM_SUBCLASS_WEAPON_WAND = 19;

--C_ITEM_SUBCLASS_ARMOR_CLOTH = 1;
--C_ITEM_SUBCLASS_ARMOR_LEATHER = 2;
--C_ITEM_SUBCLASS_ARMOR_MAIL = 3;
--C_ITEM_SUBCLASS_ARMOR_PLATE = 4;
--C_ITEM_SUBCLASS_ARMOR_SHIELD = 6;

function Transmog:slotIdToServerSlot(slotId)

    local itemType = 99
    if GetInventoryItemLink('player', slotId) then
        local itemName, _, _, _, _, _, _, _, it = GetItemInfo(self:IDFromLink(GetInventoryItemLink('player', slotId)))
        itemType = it
    end

    -- offhandslot exception
    if slotId == 17 and itemType == 'INVTYPE_WEAPON' then
        return EQUIPMENT_SLOT_OFFHAND
    end

    if itemType == 'INVTYPE_HEAD' then
        return EQUIPMENT_SLOT_HEAD
    end
    if itemType == 'INVTYPE_SHOULDER' then
        return EQUIPMENT_SLOT_SHOULDERS
    end
    if itemType == 'INVTYPE_CLOAK' then
        return EQUIPMENT_SLOT_BACK
    end
    if itemType == 'INVTYPE_CHEST' then
        return EQUIPMENT_SLOT_CHEST
    end
    if itemType == 'INVTYPE_ROBE' then
        return EQUIPMENT_SLOT_CHEST
    end
    if itemType == 'INVTYPE_WAIST' then
        return EQUIPMENT_SLOT_WAIST
    end
    if itemType == 'INVTYPE_LEGS' then
        return EQUIPMENT_SLOT_LEGS
    end
    if itemType == 'INVTYPE_FEET' then
        return EQUIPMENT_SLOT_FEET
    end
    if itemType == 'INVTYPE_WRIST' then
        return EQUIPMENT_SLOT_WRISTS
    end
    if itemType == 'INVTYPE_HAND' then
        return EQUIPMENT_SLOT_HANDS
    end
    if itemType == 'INVTYPE_WEAPON' then
        return EQUIPMENT_SLOT_MAINHAND
    end
    if itemType == 'INVTYPE_SHIELD' then
        return EQUIPMENT_SLOT_OFFHAND
    end
    if itemType == 'INVTYPE_RANGED' then
        return EQUIPMENT_SLOT_RANGED
    end
    if itemType == 'INVTYPE_2HWEAPON' then
        return EQUIPMENT_SLOT_MAINHAND
    end
    if itemType == 'INVTYPE_WEAPONMAINHAND' then
        return EQUIPMENT_SLOT_MAINHAND
    end

    if itemType == 'INVTYPE_BACK' then
        return EQUIPMENT_SLOT_BACK
    end

    if itemType == 'INVTYPE_WEAPONOFFHAND' then
        return EQUIPMENT_SLOT_OFFHAND
    end
    if itemType == 'INVTYPE_HOLDABLE' then
        return EQUIPMENT_SLOT_OFFHAND
    end

    if itemType == 'INVTYPE_THROWN' then
        return EQUIPMENT_SLOT_RANGED
    end
    if itemType == 'INVTYPE_RANGED' then
        return EQUIPMENT_SLOT_RANGED
    end
    if itemType == 'INVTYPE_RANGEDRIGHT' then
        return EQUIPMENT_SLOT_RANGED
    end
    twfdebug('99 slotIdToServerSlot err = ' .. slotId)
    return 99
end

Transmog:SetScript("OnEvent", function()

    if event then
        if event == "GOSSIP_SHOW" then
            if UnitName("Target") == "Magister Stellaria" then

                if Transmog.delayedLoad:IsVisible() then
                    twfdebug("Transmog addon loading retry in 5s.")
                else
                    GossipFrame:SetAlpha(0)
                    TransmogFrame:Show()
                end
            end
            return
        end
        if event == "GOSSIP_CLOSED" then
            GossipFrame:SetAlpha(1)
            TransmogFrame:Hide()
            return
        end
        if event == "UNIT_INVENTORY_CHANGED" then

            twfdebug(event)

            if Transmog:EquippedItemsChanged() then

                twfdebug("equipped items changed")

                if TransmogFrame:IsVisible() then
                    twfdebug("visible")
                    Transmog.gearChangedDelay.delay = 1
                else
                    twfdebug("not visible")
                    Transmog.gearChangedDelay.delay = 2
                end
                Transmog:LockPlayerItems()
                Transmog.gearChangedDelay:Show()

            else
                twfdebug("equipped items not changed")
            end

            return
        end
        if event == 'CHAT_MSG_ADDON' then

            if arg1 == "TW_CHAT_MSG_WHISPER" then
                local message = arg2
                local from = arg4
                if string.find(message, 'INSShowTransmogs', 1, true) then
                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:start", "GUILD")
                    for InventorySlotId, itemID in pairs(Transmog.transmogStatusFromServer) do
                        if itemID ~= 0 then

                            local TransmogItemName = GetItemInfo(itemID)

                            if TransmogItemName then
                                -- check if we actually have an item equipped
                                if GetInventoryItemLink('player', InventorySlotId) then
                                    local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
                                    local eName = GetItemInfo(eqItemLink)
                                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:" .. eName .. ":" .. TransmogItemName, "GUILD")
                                end
                            end
                        end
                    end
                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:end", "GUILD")
                end
                return
            end

			if TransmogFrame_Find(arg1, Transmog.prefix, 1, true) then

				twfdebug("CHAT_MSG_ADDON " .. arg2)
				local message = arg2

				if TransmogFrame_Find(message, "AvailableTransmogs", 1, true) then

					--AvailableTransmogs:slot:itemClass+itemSubClass:amount:start
					--AvailableTransmogs:slot:itemClass+itemSubClass:amount:id1:id2:id3...
					--AvailableTransmogs:slot:itemClass+itemSubClass:amount:end
					
					local ex = TransmogFrame_Explode(message, ":")
					
					local slot = TransmogFrame_ToNumber(ex[2])+1
					local itemClass = TransmogFrame_ToNumber(ex[3])
					local amount = TransmogFrame_ToNumber(ex[4])

					if not Transmog.numTransmogs[slot] then
						Transmog.numTransmogs[slot] = {}
					end

					Transmog.numTransmogs[slot][itemClass] = amount

					if TransmogFrame_Find(ex[5], "start", 1, true) then
						if not Transmog.transmogDataFromServer[slot] then
							Transmog.transmogDataFromServer[slot] = {}
						end
						Transmog.transmogDataFromServer[slot][itemClass] = {}
					elseif TransmogFrame_Find(ex[5], "end", 1, true) then
						Transmog:prepareAvailableTransmogs(slot, itemClass)
					else
						for i, itemID in ipairs(ex) do
							if i > 4 then
								itemID = TransmogFrame_ToNumber(itemID)
								if itemID ~= 0 then
									Transmog:cacheItem(itemID)

									table.insert(Transmog.transmogDataFromServer[slot][itemClass], itemID)

									if not Transmog.currentTransmogsData[slot] then
										Transmog.currentTransmogsData[slot] = {}
									end
									if not Transmog.currentTransmogsData[slot][itemClass] then
										Transmog.currentTransmogsData[slot][itemClass] = {}
									end
									table.insert(Transmog.currentTransmogsData[slot][itemClass], {
										['id'] = TransmogFrame_ToNumber(itemID),
										['has'] = false
									})
								end
							end
						end
					end
					return
				end
				if TransmogFrame_Find(message, "TransmogStatus", 1, true) then
				
					--TransmogStatus:amount:InventorySlotId1,itemID1:InventorySlotId2:,temID2:...
					--TransmogStatus:0
					
					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] then
						Transmog.transmogStatusFromServer = {}
						Transmog.transmogStatusToServer = {}

						for _, InventorySlotId in pairs(Transmog.inventorySlots) do
							Transmog.transmogStatusFromServer[InventorySlotId] = 0
							Transmog.transmogStatusToServer[InventorySlotId] = 0
						end
						
						local amount = TransmogFrame_ToNumber(dataEx[2])
						if amount > 0 then
							for i, d in ipairs(dataEx) do
								if i > 2 then
									local slotStatus = TransmogFrame_Explode(d, ",")
									local InventorySlotId = TransmogFrame_ToNumber(slotStatus[1])+1
									local itemID = TransmogFrame_ToNumber(slotStatus[2])
									Transmog.transmogStatusFromServer[InventorySlotId] = itemID
									Transmog.transmogStatusToServer[InventorySlotId] = itemID
									if TransmogFrame_ToNumber(itemID) ~= 0 then
										Transmog:cacheItem(itemID)
									end
								end
							end
						end

						Transmog:transmogStatus()
					end
					return
				end
				if TransmogFrame_Find(message, "NewTransmog", 1, true) then
					-- NewTransmog:itemID
					local dataEx = TransmogFrame_Explode(message, "NewTransmog:")
					twfdebug("NewaTransmog " .. dataEx[2])
					if string.find(message, "|r") then
						twfdebug("1message: [" .. message .. "] contains r")
					end
					if string.find(message, "|r", 1, true) then
						twfdebug("2message: [" .. message .. "] contains r")
					end
					if dataEx[2] and TransmogFrame_ToNumber(dataEx[2]) then
						twfdebug("new transmog " .. dataEx[2])
						Transmog:addWonItem(TransmogFrame_ToNumber(dataEx[2]))
					else
						twfdebug("new transmog not number :[" .. dataEx[2] .. "]")
					end
					return
				end
				if TransmogFrame_Find(message, "TransmogCost", 1, true) then
					
					-- TransmogCost:cost:tokenID:canPurchase
					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] and dataEx[3] and dataEx[4] then
						local cost = TransmogFrame_ToNumber(dataEx[2])
						local tokenID = TransmogFrame_ToNumber(dataEx[3])
						local canPurchase = TransmogFrame_ToNumber(dataEx[4])
						Transmog:updateCost(cost, tokenID, canPurchase)
					end
					return
				end
				if TransmogFrame_Find(message, "ApplyTransmogResult", 1, true) then
				
					--ApplyTransmogResult:success:slot1,itemID1:slot2,itemID2:...
					--ApplyTransmogResult:0
					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] then
						local success = TransmogFrame_ToNumber(dataEx[2])
						local data = {}
						if dataEx[3] then
							for i, str in ipairs(dataEx) do
								if i > 2 then
									local ex = TransmogFrame_Explode(str, ",")
									if ex[1] and ex[2] then
										local slot = TransmogFrame_ToNumber(ex[1])+1
										local itemID = TransmogFrame_ToNumber(ex[2])
										table.insert(data, {slot, itemID})
									end
								end
							end
						end
						
						Transmog:ApplyTransmogResult(success, data)
					end
					return
				end
				return
			end
        end
    end
end)

function Transmog:EquippedItemsChanged()
    for _, InventorySlotId in pairs(self.inventorySlots) do
        if GetInventoryItemLink('player', InventorySlotId) then
            local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
            if self.equippedItems[InventorySlotId] ~= self:IDFromLink(eqItemLink) then
                return true
            end
        end
    end
    return false
end

function Transmog:CacheEquippedGear()
    for _, InventorySlotId in pairs(self.inventorySlots) do
        if GetInventoryItemLink('player', InventorySlotId) then
            self:cacheItem(GetInventoryItemLink('player', InventorySlotId))
        end
    end
end

function Transmog:CacheOutfitsItems()
    for _, data in pairs(transmogOutfits) do
        for _, itemId in data do
            self:cacheItem(itemId)
        end
    end
end

function Transmog:CacheSetItems()
    for _, setData in pairs(self.availableSets) do
        for _, itemId in pairs(setData.items) do
            self:cacheItem(itemId)
        end
    end
end

function Transmog_OnLoad()

	twfdebug("Transmog_OnLoad start")

    local bmLoaded, bmReason = LoadAddOn("Blizzard_BattlefieldMinimap")

    if not BattlefieldMinimapOptions.transmog then
        BattlefieldMinimapOptions.transmog = {}
    end

    Transmog:cacheItem(51217)

    TransmogFrameInstructions:SetText("Are you tired of wearing the same armor every day?\nSelect the item you wish to change and enjoy your new stylish look.")
    TransmogFrameNoTransmogs:SetText("You have yet to uncover any kind of appearance for this item. \nThe appearance will unlock after you equip the item.")

    --if not TRANSMOG_CONFIG then
    --    TRANSMOG_CONFIG = {}
    --end

    --if not TRANSMOG_CONFIG[UnitName('player')] then
    --    TRANSMOG_CONFIG[UnitName('player')] = {}
    --end

    if not transmogOutfits then
        transmogOutfits = {}
    end


    UIDropDownMenu_Initialize(TransmogFrameOutfits, OutfitsDropDown_Initialize);
    UIDropDownMenu_SetWidth(123, TransmogFrameOutfits);
    TransmogFrameSaveOutfit:Disable()
    TransmogFrameDeleteOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TransmogFrameOutfits)

    -- pre cache equipped items
    Transmog:CacheEquippedGear()

    -- pre cache outfits items
    Transmog:CacheOutfitsItems()

    Transmog.availableSets = {}
    --for _, setData in next, TWFSets do
    --    if TransmogFrame_Find(setData.classes, Transmog.class, 1, true) or setData.classes == '' then
    --        if setData.faction == '' or (setData.faction ~= '' and setData.faction == Transmog.faction) then
    --            table.insert(Transmog.availableSets, setData)
    --        end
    --    end
    --end

    -- pre cache set items
    Transmog:CacheSetItems()

    Transmog.newTransmogAlert:HideAnchor()

    Transmog.delayedLoad:Show()

    if Transmog.class == 'druid' or Transmog.class == 'paladin' or Transmog.class == 'shaman' then
        RangedSlot:Hide()
    end

    local TWFHookSetInventoryItem = GameTooltip.SetInventoryItem
    function GameTooltip.SetInventoryItem(self, unit, slot)
        GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
        return TWFHookSetInventoryItem(self, unit, slot)
    end

    local TWFHookSetBagItem = GameTooltip.SetBagItem
    function GameTooltip.SetBagItem(self, container, slot)
        GameTooltip.itemLink = GetContainerItemLink(container, slot)
        _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
        return TWFHookSetBagItem(self, container, slot)
    end
	
	twfdebug("Transmog_OnLoad end")
end

function Transmog:LoadOnce()

	twfdebug("LoadOnce")
    self:aSend("GetTransmogStatus")
	self:aSend("GetAvailableTransmogs")
end

function TransmogFrame_OnShow()

	twfdebug("TransmogFrame_OnShow start")

    Transmog_switchTab('items')
    SetPortraitTexture(TransmogFramePortrait, "target");

    Transmog:Reset()
	
	Transmog:hideItems(false)

    TransmogFramePlayerModel:SetScript('OnMouseUp', function(self)
        TransmogFramePlayerModel:SetScript('OnUpdate', nil)
    end)

    TransmogFramePlayerModel:SetScript('OnMouseWheel', function(self, spining)
        local Z, X, Y = TransmogFramePlayerModel:GetPosition()
        Z = (arg1 > 0 and Z + 1 or Z - 1)

        TransmogFramePlayerModel:SetPosition(Z, X, Y)
    end)

    TransmogFramePlayerModel:SetScript('OnMouseDown', function()
        local StartX, StartY = GetCursorPosition()

        local EndX, EndY, Z, X, Y
        if arg1 == 'LeftButton' then
            TransmogFramePlayerModel:SetScript('OnUpdate', function(self)
                EndX, EndY = GetCursorPosition()

                TransmogFramePlayerModel.rotation = (EndX - StartX) / 34 + TransmogFramePlayerModel:GetFacing()

                TransmogFramePlayerModel:SetFacing(TransmogFramePlayerModel.rotation)

                StartX, StartY = GetCursorPosition()
            end)
        elseif arg1 == 'RightButton' then
            TransmogFramePlayerModel:SetScript('OnUpdate', function(self)
                EndX, EndY = GetCursorPosition()

                Z, X, Y = TransmogFramePlayerModel:GetPosition(Z, X, Y)
                X = (EndX - StartX) / 45 + X
                Y = (EndY - StartY) / 45 + Y

                TransmogFramePlayerModel:SetPosition(Z, X, Y)
                StartX, StartY = GetCursorPosition()
            end)
        end
    end)
end

function Transmog_OnHide()
    HideUIPanel(GossipFrame)
    GossipFrame:Hide()
	twfdebug("Transmog_OnHide")

    PlaySound("igCharacterInfoClose");
    Transmog.currentTransmogSlotName = nil
    Transmog.currentTransmogSlot = nil
    Transmog.currentOutfit = nil
    TransmogFrameSaveOutfit:Disable()
    TransmogFrameDeleteOutfit:Disable()
    UIDropDownMenu_SetText("Outfits", TransmogFrameOutfits)
end

function Transmog:Reset(once)

	twfdebug("Reset")

    if not once then
        self:aSend("GetTransmogStatus")
    end

    TransmogFrameRaceBackground:SetTexture("Interface\\AddOns\\Transmog\\TransmogFrame\\transmogbackground" .. self.race)
    TransmogFrameSplash:Show()
    TransmogFrameInstructions:Show()
    TransmogFrameApplyButton:Disable()

    self.currentPage = 1

	TransmogFrameCurrencyText:Hide()
	TransmogFrameCurrencyIcon:Hide()

    TransmogFramePlayerModel:SetUnit("player")

    Transmog_switchTab(self.tab)
    AddButtonOnEnterTextTooltip(TransmogFrameRevert, "Reset")

end

function Transmog:aSend(data)
    if self.localCache[data] then
        twfdebug("|cff69ccf0 not send " .. data .. " data cached")
    else
		SendChatMessage("." .. self.prefix .. " " .. data)
        twfdebug("|cff69ccf0 send -> " .. data)
    end
end

function Transmog:setProgressBar(collected, possible)
    --TransmogFrameCollectedCollectedStatus:SetText(collected .. "/" .. possible)
	TransmogFrameCollectedCollectedStatus:SetText("Collected: " .. collected)

    --local fillBarWidth = (collected / possible) * TransmogFrameCollected:GetWidth();
	local fillBarWidth = 0;
    TransmogFrameCollectedFillBar:SetPoint("TOPRIGHT", TransmogFrameCollected, "TOPLEFT", fillBarWidth, 0);
    TransmogFrameCollectedFillBar:Show();

    TransmogFrameCollected:SetStatusBarColor(0.0, 0.0, 0.0, 0.5);
    TransmogFrameCollectedBackground:SetVertexColor(0.0, 0.0, 0.0, 0.5);
    TransmogFrameCollectedFillBar:SetVertexColor(0.0, 1.0, 0.0, 0.5);

    TransmogFrameCollected:Show()
end

Transmog.availableTransmogsCacheDelay = CreateFrame("Frame")
Transmog.availableTransmogsCacheDelay:Hide()

Transmog.availableTransmogsCacheDelay.InventorySlotId = 0
Transmog.availableTransmogsCacheDelay.ItemClass = 0

Transmog.availableTransmogsCacheDelay:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

Transmog.availableTransmogsCacheDelay:SetScript("OnUpdate", function()
    local plus = 0.1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        twfdebug("delay cache: " .. Transmog.availableTransmogsCacheDelay.InventorySlotId)
        Transmog:prepareAvailableTransmogs(Transmog.availableTransmogsCacheDelay.InventorySlotId, Transmog.availableTransmogsCacheDelay.ItemClass)
        Transmog.availableTransmogsCacheDelay:Hide()
    end
end)

function Transmog:prepareAvailableTransmogs(slot, itemClass)

	twfdebug("prepareAvailableTransmogs start slot: " .. slot .. " itemClass: " .. itemClass)

	if not Transmog.availableTransmogItems[slot] then
		Transmog.availableTransmogItems[slot] = {}
	end

    self.availableTransmogItems[slot][itemClass] = {}

    for i, itemID in ipairs(self.transmogDataFromServer[slot][itemClass]) do
        itemID = TransmogFrame_ToNumber(itemID)
        local name, link, quality, level, min_level, class, subclass, _, inv_type, tex = GetItemInfo(itemID)
		
		-- This will fail if the item is not currently equipped
		local eqItemLink = nil
		local inventoryItemLink = GetInventoryItemLink('player', slot)
		if inventoryItemLink then
			local _, _, eqItemLink2 = TransmogFrame_Find(inventoryItemLink, "(item:%d+:%d+:%d+:%d+)");
			eqItemLink = eqItemLink2;
		end

        if not name then
            self:cacheItem(itemID);
            twfdebug("caching item " .. itemID)
            Transmog.availableTransmogsCacheDelay.InventorySlotId = slot
			Transmog.availableTransmogsCacheDelay.ItemClass = itemClass
            Transmog.availableTransmogsCacheDelay:Show()
            return
        end

        if name then
			local reset = false
			if eqItemLink then
				reset = itemID == self:IDFromLink(eqItemLink)
			end
            table.insert(self.availableTransmogItems[slot][itemClass], {
                ['id'] = itemID,
                ['reset'] = reset,
                ['name'] = name,
                ['link'] = link,
                ['quality'] = quality,
                ['t1'] = class,
                ['t2'] = subclass,
                ['equip_slot'] = inv_type,
                ['tex'] = tex,
                ['itemLink'] = eqItemLink
            })
        end
    end
	
	twfdebug("prepareAvailableTransmogs end")
end

function Transmog:renderAvailableTransmogs(slot, itemClass)

	twfdebug("renderAvailableTransmogs slot: " .. slot .. " itemClass: " .. itemClass)

    self:setProgressBar(self:tableSize(self.transmogDataFromServer[slot][itemClass]), self.numTransmogs[slot][itemClass])
    if self:tableSize(self.transmogDataFromServer[slot][itemClass]) == 0 then
        TransmogFrameNoTransmogs:Show()
    end

    -- hide all item buttons
    self:hideItems(true)
    self:hideItemBorders()

    local index = 0
    local row = 0
    local col = 0
    local itemIndex = 1

    for _, item in ipairs(self.availableTransmogItems[slot][itemClass]) do

        if index >= (self.currentPage - 1) * self.ipp and index < self.currentPage * self.ipp then

            if not self.ItemButtons[itemIndex] then
                self.ItemButtons[itemIndex] = CreateFrame('Frame', 'TransmogLook' .. itemIndex, TransmogFrame, 'TransmogFrameLookTemplate')
            end

            self.ItemButtons[itemIndex]:SetPoint("TOPLEFT", TransmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)

            self.ItemButtons[itemIndex].name = item.name
            self.ItemButtons[itemIndex].id = item.id

            getglobal('TransmogLook' .. itemIndex .. 'Button'):SetID(item.id)
            getglobal('TransmogLook' .. itemIndex .. 'ButtonRevert'):Hide()
            getglobal('TransmogLook' .. itemIndex .. 'ButtonCheck'):Hide()

            -- highlight Transmogged item
            if item.id == self.transmogStatusToServer[slot] then
                getglobal('TransmogLook' .. itemIndex .. 'Button'):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_selected')
            else
                getglobal('TransmogLook' .. itemIndex .. 'Button'):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_normal')
            end

            local _, _, _, color = GetItemQualityColor(item.quality)
            AddButtonOnEnterTextTooltip(getglobal('TransmogLook' .. itemIndex .. 'Button'), color .. item.name)
            if item.reset then
                getglobal('TransmogLook' .. itemIndex .. 'ButtonRevert'):Show()
            end

            self.ItemButtons[itemIndex]:Show()

            local model = getglobal('TransmogLook' .. itemIndex .. 'ItemModel')

            model:SetUnit("player")
            model:SetRotation(0.61);
            local Z, X, Y = model:GetPosition(Z, X, Y)

            if self.race == 'nightelf' then
                Z = Z + 3
            end
            if self.race == 'gnome' then
                Z = Z - 3
                Y = Y + 1.5
            end
            if self.race == 'dwarf' then
                Y = Y + 1
                Z = Z - 1
            end
            if self.race == 'troll' then
                Z = Z + 2
            end
            if self.race == 'goblin' then
                Z = Z - 0.5
            end

            -- head
            if self.currentTransmogSlot == self.inventorySlots['HeadSlot'] then
                if self.race == 'tauren' then
                    model:SetRotation(0.3);
                    X = X - 0.2
                    Y = Y + 0.2
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                end
                if self.race == 'dwarf' then
                    Y = Y + 0.5
                end
                model:SetPosition(Z + 5.8, X, Y - 2.2)
            end

            -- shoulder
            if self.currentTransmogSlot == self.inventorySlots['ShoulderSlot'] then
                if self.race == 'dwarf' then
                    Y = Y - 0.2
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                    Z = Z - 0.5
                end
                if self.race == 'nightelf' then
                    Z = Z - 1
                end
                model:SetPosition(Z + 5.8, X + 0.5, Y - 1.7)
            end

            -- cloak
            if self.currentTransmogSlot == self.inventorySlots['BackSlot'] then
                model:SetRotation(3.2);
                model:SetPosition(Z + 3.8, X, Y - 0.7)
            end

            -- chest
            if self.currentTransmogSlot == self.inventorySlots['ChestSlot'] then
                if self.race == 'tauren' then
                    model:SetRotation(0.3);
                    X = X - 0.2
                    Y = Y + 0.5
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                    Z = Z - 0.5
                end
                model:SetRotation(0.61);
                model:SetPosition(Z + 5.8, X + 0.1, Y - 1.2)
            end

            -- bracer
            if self.currentTransmogSlot == self.inventorySlots['WristSlot'] then
                model:SetRotation(1.5);
                if self.race == 'gnome' then
                    Y = Y - 1
                end
                if self.race == 'tauren' then
                    X = X - 0.2
                end
                if self.race == 'dwarf' then
                    X = X - 0.3
                    Y = Y - 0.4
                end
                if self.race == 'troll' then
                    Y = Y + 0.6
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                    Z = Z - 0.5
                end
                model:SetPosition(Z + 5.8, X + 0.4, Y - 0.3)
            end

            -- hands
            if self.currentTransmogSlot == self.inventorySlots['HandsSlot'] then
                model:SetRotation(1.5);
                if self.race == 'gnome' then
                    Y = Y - 0.7
                end
                if self.race == 'tauren' then
                    X = X - 0.2
                end
                if self.race == 'dwarf' then
                    Z = Z - 0.2
                    X = X - 0.3
                    Y = Y - 0.1
                end
                if self.race == 'troll' then
                    Y = Y + 0.9
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                    Z = Z - 0.5
                end
                model:SetPosition(Z + 5.8, X + 0.4, Y - 0.3)
            end

            -- belt
            if self.currentTransmogSlot == self.inventorySlots['WaistSlot'] then
                model:SetRotation(0.31);
                if self.race == 'gnome' then
                    Y = Y - 0.7
                end
                if self.race == 'tauren' then
                    Z = Z + 1
                    Y = Y + 0.3
                end
                if self.race == 'goblin' then
                    Y = Y + 1.5
                    Z = Z - 0.5
                end
                model:SetPosition(Z + 5.8, X, Y - 0.4)
            end

            -- pants
            if self.currentTransmogSlot == self.inventorySlots['LegsSlot'] then
                model:SetRotation(0.31);
                if self.race == 'gnome' then
                    Z = Z + 2
                    Y = Y - 1.5
                end
                if self.race == 'dwarf' then
                    Y = Y - 0.9
                end
                model:SetPosition(Z + 3.8, X, Y + 0.9)
            end

            -- boots
            if self.currentTransmogSlot == self.inventorySlots['FeetSlot'] then
                model:SetRotation(0.61);
                if self.race == 'gnome' then
                    Z = Z + 2
                    Y = Y - 1.9
                end
                if self.race == 'dwarf' then
                    Y = Y - 0.6
                end
                model:SetPosition(Z + 4.8, X, Y + 1.5)
            end

            -- mh
            if self.currentTransmogSlot == self.inventorySlots['MainHandSlot'] then
                model:SetRotation(0.61);
                if self.race == 'gnome' then
                    Y = Y - 2
                end
                if self.race == 'dwarf' then
                    Y = Y - 1
                end
                model:SetPosition(Z + 3.8, X, Y + 0.4)
            end

            -- oh
            if self.currentTransmogSlot == self.inventorySlots['SecondaryHandSlot'] then
                model:SetRotation(-0.61);
                model:SetPosition(Z + 3.8, X, Y)
                if self.race == 'gnome' then
                    Y = Y - 1.5
                end
                if self.race == 'dwarf' then
                    Y = Y - 1
                end
            end

            -- ranged
            if self.currentTransmogSlot == self.inventorySlots['RangedSlot'] then
                model:SetRotation(-0.61)
                if self.invTypes[item.equip_slot] == C_INVTYPE_RANGEDRIGHT then
                    model:SetRotation(0.61);
                end
                if self.race == 'troll' then
                    Y = Y + 1.5
                end
                if self.race == 'goblin' then
                    Y = Y + 1
                end
                if self.race == 'gnome' then
                    Y = Y - 1.5
                end
                model:SetPosition(Z + 3.8, X, Y)
            end

            model:Undress()

            if self.currentTransmogSlot == self.inventorySlots['SecondaryHandSlot'] then
                TransmogFramePlayerModel:TryOn(self.equippedItems[self.inventorySlots['MainHandSlot']])
            end

            model:TryOn(item.id);

            col = col + 1
            if col == 5 then
                row = row + 1
                col = 0
            end

            itemIndex = itemIndex + 1

        end
        index = index + 1
    end

    self.totalPages = self:ceil(self:tableSize(self.availableTransmogItems[slot][itemClass]) / self.ipp)

    TransmogFramePageText:SetText("Page " .. self.currentPage .. "/" .. self.totalPages)

    if self.currentPage == 1 then
        TransmogFrameLeftArrow:Disable()
    else
        TransmogFrameLeftArrow:Enable()
    end

    if self.currentPage == self.totalPages or self:tableSize(self.availableTransmogItems[slot][itemClass]) < self.ipp then
        TransmogFrameRightArrow:Disable()
    else
        TransmogFrameRightArrow:Enable()
    end

    if self.totalPages > 1 then
        self:showPagination()
    else
        self:hidePagination()
    end

    if self.currentTransmogSlotName then
        getglobal(self.currentTransmogSlotName .. 'BorderSelected'):Show()
    end

end

function Transmog:transmogStatus()
	twfdebug("TransmogStatus")
	
    -- cache data
    for InventorySlotId, itemID in pairs(self.transmogStatusFromServer) do
		if itemID ~= 0 then

			local TransmogItemName = GetItemInfo(itemID)

            if TransmogItemName then
                -- check if we actually have an item equipped
                if GetInventoryItemLink('player', InventorySlotId) then
                    local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
                    local eName = GetItemInfo(eqItemLink)
                    self.equippedTransmogs[eName] = TransmogItemName
                end
            else
				twfdebug("Slot: "..InventorySlotId.. " itemID: " .. itemID)
                self:cacheItem(itemID)
            end
        end
    end

    -- add paperdoll textures
    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        local frame = getglobal(slotName)
        if frame then

            local texture
            local texEx = TransmogFrame_Explode(frame:GetName(), 'Slot')
            texture = string.lower(texEx[1])

            if texture == 'wrist' then
                texture = texture .. 's'
            end
            if texture == 'back' then
                texture = 'chest'
            end

            getglobal(frame:GetName() .. 'ItemIcon'):SetTexture('Interface\\Paperdoll\\ui-paperdoll-slot-' .. texture)
            getglobal(frame:GetName() .. 'NoEquip'):Show()
            getglobal(frame:GetName() .. 'BorderHi'):Hide()

            AddButtonOnEnterTextTooltip(frame, self.inventorySlotNames[InventorySlotId], "There is no equipped item in this slot", true)
        end
    end

    -- add item textures
    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        self.equippedItems[InventorySlotId] = 0
        if GetInventoryItemLink('player', InventorySlotId) then

            local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
            local itemName, _, _, _, _, _, _, _, _, tex = GetItemInfo(eqItemLink)

            self.equippedItems[InventorySlotId] = self:IDFromLink(eqItemLink)

            local frame = getglobal(slotName)

            if frame then

                frame:Enable()
                frame:SetID(InventorySlotId)

                getglobal(frame:GetName() .. 'AutoCast'):Hide()
                getglobal(frame:GetName() .. 'AutoCast'):SetModel("Interface\\Buttons\\UI-AutoCastButton.mdx")
                getglobal(frame:GetName() .. 'AutoCast'):SetAlpha(0.3)

                getglobal(frame:GetName() .. 'NoEquip'):Hide()

                getglobal(frame:GetName() .. 'Revert'):Hide()

                if self.transmogStatusFromServer[InventorySlotId] and self.transmogStatusFromServer[InventorySlotId] ~= 0 then
                    getglobal(frame:GetName() .. 'BorderHi'):Show()
                    AddButtonOnEnterTooltipFashion(frame, eqItemLink, self.equippedTransmogs[itemName], true)

                    local _, _, _, _, _, _, _, _, _, TransmogTex = GetItemInfo(self.transmogStatusFromServer[InventorySlotId])

                    getglobal(frame:GetName() .. 'ItemIcon'):SetTexture(TransmogTex)
                    getglobal(frame:GetName() .. 'Revert'):Show()
                else
                    getglobal(frame:GetName() .. 'BorderHi'):Hide()
                    AddButtonOnEnterTooltipFashion(frame, eqItemLink)
                    getglobal(frame:GetName() .. 'ItemIcon'):SetTexture(tex)
                end
            end
        end
    end

    self:calculateCost()
end

function Apply_OnClick()

    TransmogFrameApplyButton:Disable()

	local slots = ""
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusToServer) do
        if Transmog.transmogStatusFromServer[InventorySlotId] ~= itemID then
			slots = slots .. InventorySlotId-1 .. ":" .. Transmog.transmogStatusToServer[InventorySlotId] .. ","
        end
    end
	
	Transmog:aSend("ApplyTransmog "..slots)
end

function Transmog:ApplyTransmogResult(success, data)
	
	twfdebug("ApplyTransmogResult success: "..success)
	
	if success == 1 then
		for i, pair in ipairs(data) do
			local slot = pair[1]
			local itemID = pair[2]
			if itemID == 0 then
				Transmog:addTransmogAnim(slot, 'reset')
			else
				Transmog:addTransmogAnim(slot)
			end
			
			Transmog.transmogStatusFromServer[slot] = itemID
			Transmog.transmogStatusToServer[slot] = itemID
		end
		
		PlaySoundFile("Interface\\AddOns\\Transmog\\TransmogFrame\\ui_transmogrify_apply.ogg", "Dialog");
		
		Transmog:transmogStatus()
	end
	
	--Transmog:Reset()
end

function Transmog:addTransmogAnim(id, reset)
	twfdebug("addTransmogAnim id: "..id)

    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        if id == InventorySlotId then
            local frame = getglobal(slotName)
            if frame then
                self.itemAnimationFrames[self:tableSize(self.itemAnimationFrames) + 1] = {
                    ['frame'] = frame,
                    ['borderHi'] = getglobal(frame:GetName() .. "BorderHi"),
                    ['borderFull'] = getglobal(frame:GetName() .. "BorderFull"),
                    ['autocast'] = getglobal(frame:GetName() .. "AutoCast"),
                    ['reset'] = reset,
                    ['dir'] = 1
                }
                break
            end
        end
    end

    if self:tableSize(self.itemAnimationFrames) == self:tableSize(self.applyTimer.actions) then
        self.itemAnimation:Show()
    end
end

function Transmog:frameFromInvType(invType, clientSlot)

    if invType == 'INVTYPE_WEAPON' and clientSlot == 17 then
        return SecondaryHandSlot
    end

    if invType == 'INVTYPE_HEAD' then
        return HeadSlot
    end
    if invType == 'INVTYPE_SHOULDER' then
        return ShoulderSlot
    end
    if invType == 'INVTYPE_CLOAK' then
        return BackSlot
    end
    if invType == 'INVTYPE_CHEST' or invType == 'INVTYPE_ROBE' then
        return ChestSlot
    end
    if invType == 'INVTYPE_WRIST' then
        return WristSlot
    end
    if invType == 'INVTYPE_HAND' then
        return HandsSlot
    end
    if invType == 'INVTYPE_WAIST' then
        return WaistSlot
    end
    if invType == 'INVTYPE_LEGS' then
        return LegsSlot
    end
    if invType == 'INVTYPE_FEET' then
        return FeetSlot
    end

    if invType == 'INVTYPE_WEAPONMAINHAND' or
            invType == 'INVTYPE_2HWEAPON' or
            invType == 'INVTYPE_WEAPON' or
            invType == 'INVTYPE_WEAPONMAINHAND'
    then
        return MainHandSlot
    end
    if invType == 'INVTYPE_WEAPONOFFHAND' or
            invType == 'INVTYPE_HOLDABLE' or
            invType == 'INVTYPE_SHIELD'
    then
        return SecondaryHandSlot
    end
    if invType == 'INVTYPE_RANGED' or
            invType == 'INVTYPE_RANGEDRIGHT' then
        return RangedSlot
    end
    return nil
end

function Transmog_Try(itemId, slotName, newReset)
	twfdebug("Transmog_Try itemID: " .. itemId .. "slotName: " .. slotName)

    if newReset and getglobal(slotName .. "NoEquip"):IsVisible() then
        return false
    end

    Transmog:hideItemBorders()

    if Transmog.tab == 'sets' and not newReset then

        TransmogFramePlayerModel:SetUnit("player")
        --Transmog:getFashionCoins()
        Transmog:transmogStatus()

        for InventorySlotId, data in pairs(Transmog.transmogStatusFromServer) do
            Transmog.transmogStatusToServer[InventorySlotId] = data
        end

        local setIndex = itemId
        for _, setItemId in ipairs(Transmog.availableSets[setIndex]['items']) do

            local found = false
            for _, data in ipairs(Transmog.currentTransmogsData) do
                for _, d in ipairs(data) do
                    if d['id'] == setItemId then
                        found = true
                    end
                end
            end

            if found then

                local slot = Transmog.invTypes[Transmog.availableSets[setIndex]['itemsExtended'][setItemId]['slot']]
                local frame = Transmog:frameFromInvType(Transmog.availableSets[setIndex]['itemsExtended'][setItemId]['slot'])

                -- check if player has items equipped where sets would go
                if GetInventoryItemLink('player', slot) then
                    local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', slot), "(item:%d+:%d+:%d+:%d+)");
                    local equippedName = GetItemInfo(eqItemLink)

                    if equippedName ~= Transmog.availableSets[setIndex]['itemsExtended'][setItemId]['name'] then

                        TransmogFramePlayerModel:TryOn(setItemId)

                        getglobal(frame:GetName() .. "ItemIcon"):SetTexture(Transmog.availableSets[setIndex]['itemsExtended'][setItemId]['tex'])

                        getglobal(frame:GetName() .. 'BorderHi'):Show()
                        getglobal(frame:GetName() .. 'AutoCast'):Show()

                        Transmog.transmogStatusToServer[Transmog.invTypes[Transmog.availableSets[setIndex]['itemsExtended'][setItemId]['slot']]] = setItemId

                    end

                else
                    getglobal(frame:GetName() .. 'BorderHi'):Hide()
                    getglobal(frame:GetName() .. 'AutoCast'):Hide()
                end

            end

        end

        getglobal(slotName):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_selected')

        Transmog:calculateCost()

        Transmog:EnableOutfitSaveButton()

        return true
    end

    if newReset then
        local InventorySlotId = Transmog.inventorySlots[slotName]

        itemId = Transmog:IDFromLink(GetInventoryItemLink('player', InventorySlotId))

        Transmog.transmogStatusToServer[InventorySlotId] = 0

        getglobal(slotName .. 'BorderHi'):Hide()
        getglobal(slotName .. 'AutoCast'):Hide()

        if Transmog.transmogStatusFromServer[InventorySlotId] ~= Transmog.transmogStatusToServer[InventorySlotId] then
            getglobal(slotName .. 'AutoCast'):Show()
        end

        TransmogFramePlayerModel:TryOn(itemId);

        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemId)

        getglobal(slotName .. "ItemIcon"):SetTexture(tex)

        AddButtonOnEnterTooltipFashion(getglobal(slotName), GetInventoryItemLink('player', InventorySlotId))

        local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
        local eName = GetItemInfo(eqItemLink)

        Transmog.equippedTransmogs[eName] = nil

        Transmog:calculateCost()
        Transmog:EnableOutfitSaveButton()

        return true
    end

    if itemId == Transmog:IDFromLink(GetInventoryItemLink('player', Transmog.currentTransmogSlot)) then
        getglobal(Transmog.currentTransmogSlotName .. 'BorderHi'):Hide()
        Transmog.transmogStatusToServer[Transmog.currentTransmogSlot] = 0
    else
        getglobal(Transmog.currentTransmogSlotName .. 'BorderHi'):Show()
        Transmog.transmogStatusToServer[Transmog.currentTransmogSlot] = itemId
    end

    for itemIndex, data in ipairs(Transmog.ItemButtons) do
        getglobal('TransmogLook' .. itemIndex .. 'Button'):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_normal')
        if data.id == itemId then
            getglobal('TransmogLook' .. itemIndex .. 'Button'):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_selected')
        end
    end

    getglobal(Transmog.currentTransmogSlotName .. 'AutoCast'):Hide()

    if Transmog.transmogStatusFromServer[Transmog.currentTransmogSlot] ~= Transmog.transmogStatusToServer[Transmog.currentTransmogSlot] then
        getglobal(Transmog.currentTransmogSlotName .. 'AutoCast'):Show()
    end

    if slotName == 'SecondaryHandSlot' then
        TransmogFramePlayerModel:TryOn(Transmog.equippedItems[Transmog.inventorySlots['MainHandSlot']])
    end

    TransmogFramePlayerModel:TryOn(itemId);

    local name, linkString, quality, level, min_level, class, subclass, stack, inv_type, tex, price = GetItemInfo(itemId)

    getglobal(Transmog.currentTransmogSlotName .. "ItemIcon"):SetTexture(tex)

    --AddButtonOnEnterTooltipFashion(_G[Transmog.currentTransmogSlotName], GetInventoryItemLink('player', Transmog.currentTransmogSlot), itemName)
    --local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', Transmog.currentTransmogSlot), "(item:%d+:%d+:%d+:%d+)");
    --local eName = GetItemInfo(eqItemLink)
    --Transmog.equippedTransmogs[eName] = itemName

    Transmog:calculateCost()

    Transmog:EnableOutfitSaveButton()

end

function Transmog:IDFromLink(link)
    local itemSplit = TransmogFrame_Explode(link, ':')
    if itemSplit[2] and TransmogFrame_ToNumber(itemSplit[2]) then
        return TransmogFrame_ToNumber(itemSplit[2])
    end
    return nil
end

function Transmog:hidePagination()
    TransmogFrameLeftArrow:Hide()
    TransmogFrameRightArrow:Hide()
    TransmogFramePageText:Hide()
end

function Transmog:showPagination()
    TransmogFrameLeftArrow:Show()
    TransmogFrameRightArrow:Show()
    TransmogFramePageText:Show()
end

function Transmog:hideItems(hideButton)
    for index, button in ipairs(self.ItemButtons) do
		if hideButton then
			button:Hide()
		else
			getglobal('TransmogLook' .. index):Hide()
		end
    end
end

function Transmog:hideItemBorders()
    for index, _ in ipairs(self.ItemButtons) do
        getglobal('TransmogLook' .. index .. 'Button'):SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\item_bg_normal')
	end
end

function Transmog:calculateCost(to)

	twfdebug("Transmog:calculateCost")

	local slots = ""
    local transmogs = 0
    local resets = 0

    for InventorySlotId, data in pairs(self.transmogStatusFromServer) do
        if data ~= self.transmogStatusToServer[InventorySlotId] then
            if self.transmogStatusToServer[InventorySlotId] ~= 0 then
                transmogs = transmogs + 1
				slots = slots .. InventorySlotId-1 .. ":" .. self.transmogStatusToServer[InventorySlotId] .. ","
            else
                resets = resets + 1
            end
        end
    end

    if to == 0 then
        transmogs = 0
        resets = 0
    end
	
    if transmogs == 0 then
        if resets > 0 then
            TransmogFrameApplyButton:Enable()
            TransmogFrameApplyButton:SetText("Apply Reset")
        else
            TransmogFrameApplyButton:Disable()
            TransmogFrameApplyButton:SetText("Change any Items")
        end
		
		TransmogFrameCurrencyText:Hide()
		TransmogFrameCurrencyIcon:Hide()
    else
		self:aSend("CalculateTransmogCost "..slots)
		TransmogFrameApplyButton:Disable()
    end
end

function formatCurrency(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount - gold * 10000) / 100)
    local copper = amount - gold * 10000 - silver * 100
    return copper, silver, gold
end

function Transmog:updateCost(cost, tokenID, canPurchase)
	twfdebug("updateCost cost:" .. cost .. " tokenID: " .. tokenID .. " canPurchase: " .. canPurchase)

	if canPurchase == 1 then
		TransmogFrameApplyButton:Enable()
		TransmogFrameApplyButton:SetText("Apply Transmog")
	else
		TransmogFrameApplyButton:Disable()
		if tokenID == 0 then
			TransmogFrameApplyButton:SetText("Not enough money")
		else
			TransmogFrameApplyButton:SetText("Not enough tokens")
		end
	end
	
	if cost > 0 then
	
		TransmogFrameCurrencyText:Show()
		TransmogFrameCurrencyIcon:Show()
		
		if tokenID == 0 then
			local copper, silver, gold = formatCurrency(cost)
			local costText = ""
			if gold > 0 then
				costText = gold .. "g"
			end
			if silver > 0 then
				if gold > 0 then
					costText = costText .. " "
				end
				
				costText = costText .. silver .. "s"
			end
			if copper > 0 then
				if gold > 0 or silver > 0 then
					costText = costText .. " "
				end
				
				costText = costText .. copper .. "c"
			end
			
			TransmogFrameCurrencyText:SetText(costText)
			TransmogFrameCurrencyIcon:SetNormalTexture("Interface\\Icons\\inv_misc_coin_01")
			TransmogFrameCurrencyIcon:SetPushedTexture("Interface\\Icons\\inv_misc_coin_01")
			AddButtonOnEnterTextTooltip(TransmogFrameCurrencyIcon, "Money")
		else
			local name, linkString, _, _, _, _, _, _, _, tex = GetItemInfo(tokenID)
			if not name then
				return
			end
			
			local _, _, itemLink = TransmogFrame_Find(linkString, "(item:%d+:%d+:%d+:%d+)");
			
			TransmogFrameCurrencyText:SetText(cost)
			TransmogFrameCurrencyIcon:SetNormalTexture(tex)
			TransmogFrameCurrencyIcon:SetPushedTexture(tex)
			AddButtonOnEnterTooltipFashion(TransmogFrameCurrencyIcon, itemLink)
		end
	end
end

function Transmog:HidePlayerItemsAnimation()
    HeadSlotAutoCast:Hide()
    ShoulderSlotAutoCast:Hide()
    BackSlotAutoCast:Hide()
    ChestSlotAutoCast:Hide()
    WristSlotAutoCast:Hide()
    HandsSlotAutoCast:Hide()
    WaistSlotAutoCast:Hide()
    LegsSlotAutoCast:Hide()
    FeetSlotAutoCast:Hide()
    MainHandSlotAutoCast:Hide()
    SecondaryHandSlotAutoCast:Hide()
    RangedSlotAutoCast:Hide()
end

function Transmog:hidePlayerItemsBorders()
    HeadSlotBorderSelected:Hide()
    ShoulderSlotBorderSelected:Hide()
    BackSlotBorderSelected:Hide()
    ChestSlotBorderSelected:Hide()
    WristSlotBorderSelected:Hide()
    HandsSlotBorderSelected:Hide()
    WaistSlotBorderSelected:Hide()
    LegsSlotBorderSelected:Hide()
    FeetSlotBorderSelected:Hide()
    MainHandSlotBorderSelected:Hide()
    SecondaryHandSlotBorderSelected:Hide()
    RangedSlotBorderSelected:Hide()
end

function Transmog:LockPlayerItems()
    for slot, _ in pairs(Transmog.inventorySlots) do
        getglobal(slot):Disable()
        SetDesaturation(getglobal(slot .. 'ItemIcon'), 1);
    end
end

function Transmog:UnlockPlayerItems()

end

function Transmog:tableSize(t)
    if type(t) ~= 'table' then
        twfdebug('t not table')
        return 0
    end
    local size = 0
    for _ in pairs(t) do
        size = size + 1
    end
    return size
end

function Transmog:ceil(num)
    if num > math.floor(num) then
        return math.floor(num + 1)
    end
    return math.floor(num + 0.5)
end

function Transmog:ItemClassStrToNum(itemClassStr)
	local itemClass = -1
	
	if itemClassStr then
		if itemClassStr == "Weapon" or itemClassStr == "Arma" then
			itemClass = 2
		elseif itemClassStr == "Armor" or itemClassStr == "Armadura" then
			itemClass = 4
		end
	end
	
	if itemClass == -1 then
		twferror("Invalid item class " .. itemClassStr)
	end
	
	return itemClass
end

function Transmog:ItemSubclassStrToNum(itemSubclassStr)
	local itemSubclass = -1
	
	if itemSubclassStr then
		if itemSubclassStr == "One-Handed Axes" or itemSubclassStr == "Hachas de una mano" then
			itemSubclass = 0
		elseif itemSubclassStr == "Two-Handed Axes" or itemSubclassStr == "Hachas de dos manos" then
			itemSubclass = 1
		elseif itemSubclassStr == "Bows" or itemSubclassStr == "Arcos" then
			itemSubclass = 2
		elseif itemSubclassStr == "Guns" or itemSubclassStr == "Armas de fuego" then
			itemSubclass = 3
		elseif itemSubclassStr == "One-Handed Maces" or itemSubclassStr == "Mazas de una mano" then
			itemSubclass = 4
		elseif itemSubclassStr == "Two-Handed Maces" or itemSubclassStr == "Mazas de dos manos" then
			itemSubclass = 5
		elseif itemSubclassStr == "Polearms" or itemSubclassStr == "Armas de asta" then
			itemSubclass = 6
		elseif itemSubclassStr == "One-Handed Swords" or itemSubclassStr == "Espadas de una mano" then
			itemSubclass = 7
		elseif itemSubclassStr == "Two-Handed Swords" or itemSubclassStr == "Espadas de dos manos" then
			itemSubclass = 8
		elseif itemSubclassStr == "Staves" or itemSubclassStr == "Bastones" then
			itemSubclass = 10
		elseif itemSubclassStr == "Fist Weapons" or itemSubclassStr == "Armas de puño" then
			itemSubclass = 13
		elseif itemSubclassStr == "Daggers" or itemSubclassStr == "Dagas" then
			itemSubclass = 15
		elseif itemSubclassStr == "Crossbows" or itemSubclassStr == "Ballestas" then
			itemSubclass = 18
		elseif itemSubclassStr == "Wands" or itemSubclassStr == "Varitas" then
			itemSubclass = 19
		elseif itemSubclassStr == "Cloth" or itemSubclassStr == "Tela" then
			itemSubclass = 1
		elseif itemSubclassStr == "Leather" or itemSubclassStr == "Cuero" then
			itemSubclass = 2
		elseif itemSubclassStr == "Mail" or itemSubclassStr == "Malla" then
			itemSubclass = 3
		elseif itemSubclassStr == "Plate" or itemSubclassStr == "Placas" then
			itemSubclass = 4
		elseif itemSubclassStr == "Shields" or itemSubclassStr == "Escudos" then
			itemSubclass = 6
		end
	end
	
	if itemSubclass == -1 then
		twferror("Invalid item subclass " .. itemSubclassStr)
	end
	
	return itemSubclass
end

function selectTransmogSlot(InventorySlotId, slotName)

	twfdebug("selectTransmogSlot slot: " .. InventorySlotId)

    TransmogFrameNoTransmogs:Hide()

    if InventorySlotId == -1 then
        Transmog:hidePlayerItemsBorders()
        Transmog:HidePlayerItemsAnimation()
        Transmog:hideItems(true)
        Transmog:hideItemBorders()
        Transmog:hidePagination()
        TransmogFrameSplash:Show()
        TransmogFrameInstructions:Show()
        TransmogFrameCollected:Hide()
        Transmog.currentTransmogSlotName = nil
        Transmog.currentTransmogSlot = nil
        return true
    end

    if getglobal(slotName .. "NoEquip"):IsVisible() then
        return false
    end

    TransmogFrameSplash:Hide()
    TransmogFrameInstructions:Hide()

    Transmog.currentPage = 1
    Transmog.currentTransmogSlotName = slotName
    Transmog.currentTransmogSlot = InventorySlotId

    if Transmog.tab == 'sets' then
        Transmog_switchTab('items')
        return
    end

    if not GetInventoryItemLink('player', Transmog.currentTransmogSlot) then
        selectTransmogSlot(-1)
        return
    end

    local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', Transmog.currentTransmogSlot), "(item:%d+:%d+:%d+:%d+)");
    local itemName, _, _, _, _, itemClass, itemSubclass, _, invType = GetItemInfo(eqItemLink)

    local eqItemId = Transmog:IDFromLink(eqItemLink)

    if Transmog.transmogStatusFromServer[Transmog.currentTransmogSlot] and Transmog.transmogStatusFromServer[Transmog.currentTransmogSlot] ~= 0 then
        TransmogFramePlayerModel:TryOn(Transmog.transmogStatusFromServer[Transmog.currentTransmogSlot])
    else
        TransmogFramePlayerModel:TryOn(eqItemId)
    end

    Transmog:hideItems(false)
    Transmog:hidePlayerItemsBorders()

    Transmog:renderAvailableTransmogs(InventorySlotId, Transmog:ItemClassStrToNum(itemClass) + Transmog:ItemSubclassStrToNum(itemSubclass))
end

function TransmogModel_OnLoad()
    TransmogFramePlayerModel.rotation = 0.61;
    TransmogFramePlayerModel:SetRotation(TransmogFramePlayerModel.rotation);
end

function AddButtonOnEnterTextTooltip(frame, text, ext, error, anchor, x, y)
    frame:SetScript("OnEnter", function(self)
        if anchor and x and y then
            FashionTooltip:SetOwner(this, anchor, x, y)
        else
            FashionTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 15, -(this:GetHeight() / 4) + 20)
        end

        if error then
            FashionTooltip:AddLine(FONT_COLOR_CODE_CLOSE .. text)
            FashionTooltip:AddLine("|cffff2020" .. ext)
        else
            FashionTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE .. text)
            if ext then
                FashionTooltip:AddLine(FONT_COLOR_CODE_CLOSE .. ext)
            end
        end
        FashionTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        FashionTooltip:Hide()
    end)
end

function AddButtonOnEnterTooltipFashion(frame, itemLink, TransmogText, revert)

    if TransmogFrame_Find(itemLink, "|", 1, true) then
        local ex = TransmogFrame_Explode(itemLink, "|")

        if not ex[2] or not ex[3] then
            twferror('bad addButtonOnEnterTooltip itemLink syntax')
            twferror(itemLink)
            return false
        end

        frame:SetScript("OnEnter", function(self)
            FashionTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 10, -(this:GetHeight() / 4));
            FashionTooltip:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));

            local tLabel = getglobal(FashionTooltip:GetName() .. "TextLeft2")
            if tLabel and TransmogText then
                if revert then
                    tLabel:SetText('|cfff471f5Transmogrified to:\n' .. TransmogText .. '\n|cffffd200Right-Click to revert\n|cffffffff' .. tLabel:GetText())
                else
                    tLabel:SetText('|cfff471f5Transmogrified to:\n' .. TransmogText .. '\n|cffffffff' .. tLabel:GetText())
                end
            end

            FashionTooltip:AddLine("");
            FashionTooltip:Show();

        end)
    else
        frame:SetScript("OnEnter", function(self)
            FashionTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4) + 10, -(this:GetHeight() / 4));
            FashionTooltip:SetHyperlink(itemLink);
            local tLabel = getglobal(FashionTooltip:GetName() .. "TextLeft2")
            if tLabel and TransmogText then
                if revert then
                    tLabel:SetText('|cfff471f5Transmogrified to:\n' .. TransmogText .. '\n|cffffd200Right-Click to revert\n|cffffffff' .. tLabel:GetText())
                else
                    tLabel:SetText('|cfff471f5Transmogrified to:\n' .. TransmogText .. '\n|cffffffff' .. tLabel:GetText())
                end
            end
            FashionTooltip:Show();
        end)
    end
    frame:SetScript("OnLeave", function(self)
        FashionTooltip:Hide();
    end)
end

function Transmog_ChangePage(dir)
    Transmog.currentPage = Transmog.currentPage + dir
    if Transmog.tab == 'items' then
        Transmog:renderAvailableTransmogs(Transmog.currentTransmogSlot)
    else
        Transmog_switchTab(Transmog.tab)
    end
end

function Transmog_revert()
    Transmog:Reset()
    Transmog:calculateCost(0)
end

function Transmog_switchTab(to)

	twfdebug("Transmog_switchTab " .. to)

    Transmog.tab = to
    if to == 'items' then
        TransmogFrameItemsButton:SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_active')
        TransmogFrameItemsButton:SetPushedTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_active')
        TransmogFrameItemsButtonText:SetText(HIGHLIGHT_FONT_COLOR_CODE .. 'Items')

        TransmogFrameSetsButton:SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_inactive')
        TransmogFrameSetsButton:SetPushedTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_inactive')
        TransmogFrameSetsButtonText:SetText(FONT_COLOR_CODE_CLOSE .. 'Sets')

        if Transmog.currentTransmogSlot ~= nil then
            selectTransmogSlot(Transmog.currentTransmogSlot, Transmog.currentTransmogSlotName)
        else
            selectTransmogSlot(-1)
        end

    elseif to == 'sets' then

        selectTransmogSlot(-1)

        TransmogFrameSplash:Hide()
        TransmogFrameInstructions:Hide()

        TransmogFrameSetsButton:SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_active')
        TransmogFrameSetsButton:SetPushedTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_active')
        TransmogFrameSetsButtonText:SetText(HIGHLIGHT_FONT_COLOR_CODE .. 'Sets')

        TransmogFrameItemsButton:SetNormalTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_inactive')
        TransmogFrameItemsButton:SetPushedTexture('Interface\\AddOns\\Transmog\\TransmogFrame\\tab_inactive')
        TransmogFrameItemsButtonText:SetText(FONT_COLOR_CODE_CLOSE .. 'Items')

        Transmog:hideItems(false)
        Transmog:hideItemBorders()

        local index = 0
        local row = 0
        local col = 0
        local setIndex = 1
        local completedSets = 0

        for i, set in next, Transmog.availableSets do

            -- calculate completed sets
            local numCollectedItems = 0
            for _, itemID in ipairs(set.items) do
                if GetItemInfo(itemID) then
                    for _, data in ipairs(Transmog.currentTransmogsData) do
                        for _, d in ipairs(data) do
                            if d['id'] == itemID then
                                numCollectedItems = numCollectedItems + 1
                            end
                        end
                    end
                end
            end

            if numCollectedItems == Transmog:tableSize(set.items) then
                completedSets = completedSets + 1
            end

            if index >= (Transmog.currentPage - 1) * Transmog.ipp and index < Transmog.currentPage * Transmog.ipp then

                if not Transmog.ItemButtons[setIndex] then
                    Transmog.ItemButtons[setIndex] = CreateFrame('Frame', 'TransmogLook' .. setIndex, TransmogFrame, 'TransmogFrameLookTemplate')
                end

                Transmog.ItemButtons[setIndex]:SetPoint("TOPLEFT", TransmogFrame, "TOPLEFT", 263 + col * 90, -105 - 120 * row)

                Transmog.ItemButtons[setIndex].name = set.name

                getglobal('TransmogLook' .. setIndex .. 'Button'):SetID(i)
                getglobal('TransmogLook' .. setIndex .. 'ButtonRevert'):Hide()
                getglobal('TransmogLook' .. setIndex .. 'ButtonCheck'):Hide()

                Transmog.availableSets[i]['itemsExtended'] = {}

                local setItemsText = ''
                local founds = 0
                for _, itemID in set.items do
                    local setItemName, _, _, _, _, _, _, _, equip_slot, xtex = GetItemInfo(itemID)

                    if setItemName then

                        local found = false
                        for _, data in ipairs(Transmog.currentTransmogsData) do
                            for _, d in next, data do
                                if d['id'] == itemID then
                                    found = true
                                    founds = founds + 1
                                    d['has'] = true
                                end
                            end
                        end

                        if found then
                            setItemsText = setItemsText .. FONT_COLOR_CODE_CLOSE .. setItemName .. "\n"
                        else
                            setItemsText = setItemsText .. GRAY_FONT_COLOR_CODE .. setItemName .. "\n"
                        end

                        Transmog.availableSets[i]['itemsExtended'][itemID] = {
                            ['name'] = setItemName,
                            ['slot'] = equip_slot,
                            ['tex'] = xtex
                        }

                    end
                end

                if founds == Transmog:tableSize(set.items) then
                    getglobal('TransmogLook' .. setIndex .. 'ButtonCheck'):Show()
                end

                AddButtonOnEnterTextTooltip(getglobal('TransmogLook' .. setIndex .. 'Button'), set.name .. " " .. founds .. "/" .. Transmog:tableSize(set.items), setItemsText)

                Transmog.ItemButtons[setIndex]:Show()

                local model = getglobal('TransmogLook' .. setIndex .. 'ItemModel')

                model:SetUnit("player")
                model:SetRotation(0.61);
                local Z, X, Y = model:GetPosition(Z, X, Y)

                model:SetPosition(Z + 1.5, X, Y)

                model:Undress()
                for _, itemID in set.items do
                    model:TryOn(itemID)
                end

                col = col + 1
                if col == 5 then
                    row = row + 1
                    col = 0
                end

                setIndex = setIndex + 1

            end
            index = index + 1
        end

        Transmog.totalPages = Transmog:ceil(Transmog:tableSize(Transmog.availableSets) / Transmog.ipp)

        TransmogFramePageText:SetText("Page " .. Transmog.currentPage .. "/" .. Transmog.totalPages)

        if Transmog.currentPage == 1 then
            TransmogFrameLeftArrow:Disable()
        else
            TransmogFrameLeftArrow:Enable()
        end

        if Transmog.currentPage == Transmog.totalPages or Transmog:tableSize(Transmog.availableSets) < Transmog.ipp then
            TransmogFrameRightArrow:Disable()
        else
            TransmogFrameRightArrow:Enable()
        end

        if Transmog.totalPages > 1 then
            Transmog:showPagination()
        else
            Transmog:hidePagination()
        end

        Transmog:setProgressBar(completedSets, Transmog:tableSize(Transmog.availableSets))

    end
end

function TransmogFrame_Explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = TransmogFrame_Find(str, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = TransmogFrame_Find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local characterPaperDollFrames = {
    CharacterHeadSlot,
    CharacterShoulderSlot,
    CharacterBackSlot,
    CharacterChestSlot,
    CharacterWristSlot,
    CharacterHandsSlot,
    CharacterWaistSlot,
    CharacterLegsSlot,
    CharacterFeetSlot,
    CharacterMainHandSlot,
    CharacterSecondaryHandSlot,
    CharacterRangedSlot,
}

-- self
EquipTransmogTooltip:SetScript("OnShow", function()
    if GameTooltip.itemLink then

        if not PaperDollFrame:IsVisible() then
            return
        end

        local _, _, itemLink = TransmogFrame_Find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");

        if not itemLink then
            return
        end

        for _, frame in ipairs(characterPaperDollFrames) do
            if GameTooltip:IsOwned(frame) == 1 then

                local itemName = GetItemInfo(itemLink)

                if Transmog.equippedTransmogs[itemName] then

                    local tLabel = getglobal(GameTooltip:GetName() .. "TextLeft2")

                    if tLabel then
                        --tLabel:SetText('|cfff471f5Transmogrified to:\n' .. Transmog.equippedTransmogs[itemName] .. '\n|cffffffff' .. tLabel:GetText())
                    end

                    GameTooltip:Show()
                end

            end

        end

    end
end)

EquipTransmogTooltip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
end)

-- Apply Timer
Transmog.applyTimer = CreateFrame("Frame")
Transmog.applyTimer:Hide()

Transmog.applyTimer:SetScript("OnShow", function()
    this.startTime = GetTime()
    Transmog.applyTimer.actionIndex = 0
end)
Transmog.applyTimer:SetScript("OnHide", function()
end)

Transmog.applyTimer.actions = {}
Transmog.applyTimer.actionIndex = 0

Transmog.applyTimer:SetScript("OnUpdate", function()
    local plus = 0.1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        Transmog.applyTimer.actionIndex = Transmog.applyTimer.actionIndex + 1

        local action = Transmog.applyTimer.actions[Transmog.applyTimer.actionIndex]

        if action then
            if action.type == 'do' then
                Transmog:aSend("ApplyTransmog:" .. action.serverSlot .. ":" .. action.itemId .. ":" .. action.InventorySlotId)
                action.sent = true
            else
                if action.type == 'reset' then
                    Transmog:aSend("ResetTransmog:" .. action.serverSlot .. ":" .. action.InventorySlotId)
                    action.sent = true
                end
            end
        end

        local allDone = true
        for _, action in ipairs(Transmog.applyTimer.actions) do
            if not action.sent then
                allDone = false
            end
        end
        if allDone then
            Transmog.applyTimer:Hide()
        end
        this.startTime = GetTime()
    end
end)

-- DoTransmog/ResetTransmog Animation
Transmog.itemAnimation = CreateFrame("Frame")
Transmog.itemAnimation:Hide()

Transmog.itemAnimation:SetScript("OnShow", function()
    this.startTime = GetTime()
    for _, frame in ipairs(Transmog.itemAnimationFrames) do
        frame.autocast:Hide()
        if frame.reset then
            frame.borderFull:Show()
            frame.borderFull:SetAlpha(.9)
            frame.borderHi:Show()
            frame.borderHi:SetWidth(48)
            frame.borderHi:SetHeight(48)
        else
            frame.borderFull:Show()
            frame.borderFull:SetAlpha(.2)
            frame.borderHi:Show()
            frame.borderHi:SetWidth(32)
            frame.borderHi:SetHeight(32)
        end
    end
end)
Transmog.itemAnimation:SetScript("OnHide", function()
    Transmog.currentTransmogSlot = nil
    Transmog_switchTab('items')

    Transmog:aSend("GetTransmogStatus")

    Transmog:calculateCost(0)
end)

Transmog.itemAnimationFrames = {}

Transmog.itemAnimation:SetScript("OnUpdate", function()
    local plus = 0.01
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        for index, frame in ipairs(Transmog.itemAnimationFrames) do
            if frame.reset then
                frame.borderFull:SetAlpha(frame.borderFull:GetAlpha() - 0.05)
                if frame.borderHi:GetWidth() > 32 then
                    frame.borderHi:SetWidth(frame.borderHi:GetWidth() - 0.5)
                    frame.borderHi:SetHeight(frame.borderHi:GetHeight() - 0.5)
                end
            else
                frame.borderFull:SetAlpha(frame.borderFull:GetAlpha() + 0.05 * frame.dir)
                if frame.borderHi:GetWidth() < 48 then
                    frame.borderHi:SetWidth(frame.borderHi:GetWidth() + 0.5)
                    frame.borderHi:SetHeight(frame.borderHi:GetHeight() + 0.5)
                end
            end
            if frame.borderFull:GetAlpha() >= 1 then
                frame.dir = -1
            end
            if frame.borderFull:GetAlpha() <= 0.1 then
                frame.borderHi:Hide()
                frame.borderHi:SetWidth(48)
                frame.borderHi:SetHeight(48)

                --CooldownFrame_SetTimer(_G[frame.frame:GetName() .. 'Sparkle'], GetTime() - 1, 1, 1)

                Transmog.itemAnimationFrames[index] = nil
            end
        end

        if Transmog:tableSize(Transmog.itemAnimationFrames) == 0 then
            Transmog.itemAnimation:Hide()
        end

        this.startTime = GetTime()

    end
end)

-- delayedLoad Timer - disabled for now
Transmog.delayedLoad = CreateFrame("Frame")
Transmog.delayedLoad:Hide()

Transmog.delayedLoad:SetScript("OnShow", function()
    twfdebug("delayedLoad show")
    this.startTime = GetTime()
end)
Transmog.delayedLoad:SetScript("OnHide", function()
    Transmog:LoadOnce()
    Transmog:Reset(true)
end)

Transmog.delayedLoad:SetScript("OnUpdate", function()
    local gt = GetTime() * 1000
    local st = (this.startTime + 1) * 1000
    if gt >= st then
        Transmog.delayedLoad:Hide()
    end
end)

-- win new transmog
Transmog.newTransmogAlert = CreateFrame("Frame")
Transmog.newTransmogAlert:Hide()
Transmog.newTransmogAlert.wonItems = {}

function Transmog.newTransmogAlert:HideAnchor()
    NewTransmogAlertFrame:SetBackdrop({
        bgFile = "",
        tile = true,
    })
    NewTransmogAlertFrame:EnableMouse(false)
    NewTransmogAlertFrameTitle:Hide()
    NewTransmogAlertFrameTestPlacement:Hide()
    NewTransmogAlertFrameClosePlacement:Hide()
end

Transmog.delayAddWonItem = CreateFrame("Frame")
Transmog.delayAddWonItem:Hide()
Transmog.delayAddWonItem.data = {}

Transmog.delayAddWonItem:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.delayAddWonItem:SetScript("OnUpdate", function()
    local plus = 0.2
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local atLeastOne = false
        for id, data in pairs(Transmog.delayAddWonItem.data) do
            if Transmog.delayAddWonItem.data[id] then
                atLeastOne = true
                Transmog:addWonItem(id)
                Transmog.delayAddWonItem.data[id] = nil
            end
        end

        if not atLeastOne then
            Transmog.delayAddWonItem:Hide()
        end
    end
end)

Transmog.gearChangedDelay = CreateFrame("Frame")
Transmog.gearChangedDelay:Hide()
Transmog.gearChangedDelay.delay = 1

Transmog.gearChangedDelay:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.gearChangedDelay:SetScript("OnUpdate", function()
    local gt = GetTime() * 1000
    local st = (this.startTime + Transmog.gearChangedDelay.delay) * 1000
    if gt >= st then

        selectTransmogSlot(-1)
        Transmog_revert()

        Transmog:UnlockPlayerItems()
        Transmog.gearChangedDelay:Hide()
    end
end)

function Transmog:addWonItem(itemID)
    local name, linkString, quality, level, min_level, class, subclass, stack, inv_type, tex, price = GetItemInfo(itemID)
	
	twfdebug("addWonItem itemID: " .. itemID)

	if not name or not quality then
		twfdebug("delayed")
		self.delayAddWonItem.data[itemID] = true
		self.delayAddWonItem:Show()
		return false
	end

    if name then
		
        local _, _, itemLink = TransmogFrame_Find(linkString, "(item:%d+:%d+:%d+:%d+)");

        self:cacheItem(itemID)

        twfprint(GAME_YELLOW .. '[' .. name .. ']' .. HIGHLIGHT_FONT_COLOR_CODE .. ' was added to your collection.')

        local newTransmogIndex = 0
        for i = 1, self:tableSize(self.newTransmogAlert.wonItems), 1 do
            if not self.newTransmogAlert.wonItems[i].active then
                newTransmogIndex = i
                break
            end
        end

        if newTransmogIndex == 0 then
            newTransmogIndex = self:tableSize(self.newTransmogAlert.wonItems) + 1
        end

        if not self.newTransmogAlert.wonItems[newTransmogIndex] then
            self.newTransmogAlert.wonItems[newTransmogIndex] = CreateFrame("Frame", "NewTransmogAlertFrame" .. newTransmogIndex, NewTransmogAlertFrame, "TransmogWonItemTemplate")
        end

        self.newTransmogAlert.wonItems[newTransmogIndex]:SetPoint("TOP", NewTransmogAlertFrame, "BOTTOM", 0, (20 + 100 * newTransmogIndex))
        self.newTransmogAlert.wonItems[newTransmogIndex].active = true
        self.newTransmogAlert.wonItems[newTransmogIndex].frameIndex = 0
        self.newTransmogAlert.wonItems[newTransmogIndex].doAnim = true

        self.newTransmogAlert.wonItems[newTransmogIndex]:SetAlpha(0)
        self.newTransmogAlert.wonItems[newTransmogIndex]:Show()

        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetNormalTexture(tex)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetPushedTexture(tex)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'ItemName'):SetText(HIGHLIGHT_FONT_COLOR_CODE .. name)

        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetScript("OnEnter", function(self)
            FashionTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
            FashionTooltip:SetHyperlink(itemLink);
            FashionTooltip:Show();
        end)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetScript("OnLeave", function(self)
            FashionTooltip:Hide();
        end)

        self:StartNewTransmogAlertAnimation()

    end
end

function Transmog_testNewTransmogAlert()
    Transmog:addWonItem(19364)
end

function Transmog:StartNewTransmogAlertAnimation()
    if self:tableSize(self.newTransmogAlert.wonItems) > 0 then
        self.newTransmogAlert.showLootWindow = true
    end
    if not self.newTransmogAlert:IsVisible() then
        self.newTransmogAlert:Show()
    end
end

Transmog.newTransmogAlert.showLootWindow = false

Transmog.newTransmogAlert:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.newTransmogAlert:SetScript("OnUpdate", function()
    if Transmog.newTransmogAlert.showLootWindow then
        if GetTime() >= (this.startTime + 0.03) then

            this.startTime = GetTime()

            for i, d in ipairs(Transmog.newTransmogAlert.wonItems) do

                if Transmog.newTransmogAlert.wonItems[i].active then

                    local frame = getglobal('NewTransmogAlertFrame' .. i)

                    local image = 'loot_frame_xmog_'

                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetPoint('LEFT', 160, -9)
                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetWidth(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'IconNormalTexture'):SetWidth(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetHeight(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'IconNormalTexture'):SetHeight(36)

                    if Transmog.newTransmogAlert.wonItems[i].frameIndex < 10 then
                        image = image .. '0' .. Transmog.newTransmogAlert.wonItems[i].frameIndex
                    else
                        image = image .. Transmog.newTransmogAlert.wonItems[i].frameIndex;
                    end

                    Transmog.newTransmogAlert.wonItems[i].frameIndex = Transmog.newTransmogAlert.wonItems[i].frameIndex + 1

                    if Transmog.newTransmogAlert.wonItems[i].doAnim then

                        local backdrop = {
                            bgFile = 'Interface\\AddOns\\Transmog\\TransmogFrame\\anim\\' .. image,
                            tile = false
                        };
                        if Transmog.newTransmogAlert.wonItems[i].frameIndex <= 30 then
                            frame:SetBackdrop(backdrop)
                        end
                        frame:SetAlpha(frame:GetAlpha() + 0.03)
                        getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if Transmog.newTransmogAlert.wonItems[i].frameIndex == 35 then
                        --stop and hold last frame
                        Transmog.newTransmogAlert.wonItems[i].doAnim = false
                    end

                    if Transmog.newTransmogAlert.wonItems[i].frameIndex > 119 then
                        frame:SetAlpha(frame:GetAlpha() - 0.03)
                        getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if Transmog.newTransmogAlert.wonItems[i].frameIndex == 150 then

                        Transmog.newTransmogAlert.wonItems[i].frameIndex = 0
                        frame:Hide()
                        Transmog.newTransmogAlert.wonItems[i].active = false

                    end
                end
            end
        end
    end
end)

function Transmog_close_placement()
    twfprint('|cAnchor window closed. Type |cfffff569/transmog |cto show the Anchor window.')
    Transmog.newTransmogAlert:HideAnchor()
end

function Transmog.newTransmogAlert:ShowAnchor()
    NewTransmogAlertFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    NewTransmogAlertFrame:EnableMouse(true)
    NewTransmogAlertFrameTitle:Show()
    NewTransmogAlertFrameTestPlacement:Show()
    NewTransmogAlertFrameClosePlacement:Show()
end

function OutfitsDropDown_Initialize()

    for name, data in pairs(transmogOutfits) do
        local info = {}
        info.text = name
        info.value = 1
        info.arg1 = name
        info.checked = Transmog.currentOutfit == name
        info.func = Transmog_LoadOutfit
        info.tooltipTitle = name
        local descText = ''
        for slot, itemID in pairs(data) do
            if itemID == 0 then
                --descText = descText .. FONT_COLOR_CODE_CLOSE ..  slot .. ": None \n"
            else
				Transmog:cacheItem(itemID)
                local n, _, quality, _, _, _, _, _, equip_slot = GetItemInfo(itemID)
				
				--dirty fix
                if quality == nil then quality = 0 end
				
				--dirty fix
                if n == nil then n = "error" end
				
                local _, _, _, color = GetItemQualityColor(quality)

                --descText = descText .. FONT_COLOR_CODE_CLOSE .. getglobal(equip_slot) .. ": " .. color .. n .. "\n"
                descText = descText .. FONT_COLOR_CODE_CLOSE .. color .. n .. "\n"
            end
        end
        info.tooltipText = descText
        UIDropDownMenu_AddButton(info)
    end

    if Transmog:tableSize(transmogOutfits) < 20 then
        local _, _, _, color = GetItemQualityColor(2)

        local newOutfit = {}
        newOutfit.text = color .. "+ New Outfit"
        newOutfit.value = 1
        newOutfit.arg1 = 1
        newOutfit.checked = false
        newOutfit.func = Transmog_NewOutfitPopup
        UIDropDownMenu_AddButton(newOutfit)
    end

end

function Transmog_LoadOutfit(outfit)
    UIDropDownMenu_SetText(outfit, TransmogFrameOutfits)

    Transmog.currentOutfit = outfit

    Transmog:EnableOutfitSaveButton()

    TransmogFrameDeleteOutfit:Enable()

    Transmog:hideItemBorders()

    for slot, itemID in pairs(transmogOutfits[outfit]) do

        local eq_slot, tex
        local hasItemEquipped = false

        if GetInventoryItemLink('player', slot) then
            hasItemEquipped = true
        end

        if hasItemEquipped then

            if itemID == 0 then
                local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', slot), "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, equip_slot, outfitTex = GetItemInfo(eqItemLink)
                eq_slot = equip_slot
                tex = outfitTex
            else
                local _, _, _, _, _, _, _, _, equip_slot, outfitTex = GetItemInfo(itemID)
                eq_slot = equip_slot
                tex = outfitTex
            end

            local frame

            frame = Transmog:frameFromInvType(eq_slot)

            if hasItemEquipped then
                TransmogFramePlayerModel:TryOn(itemID)
            end

            if frame then

                getglobal(frame:GetName() .. "ItemIcon"):SetTexture(tex)

                if Transmog.transmogStatusToServer[slot] ~= itemID then
                    getglobal(frame:GetName() .. 'BorderHi'):Show()
                    getglobal(frame:GetName() .. 'AutoCast'):Show()
                end

                if itemID == 0 or not hasItemEquipped then
                    getglobal(frame:GetName() .. 'BorderHi'):Hide()
                    getglobal(frame:GetName() .. 'AutoCast'):Hide()
                end

            end

            Transmog.transmogStatusToServer[slot] = itemID

        end

    end
    Transmog:calculateCost()
end

function Transmog_SaveOutfit()
	transmogOutfits[Transmog.currentOutfit] = {}
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusFromServer) do
        if itemID ~= 0 then
            transmogOutfits[Transmog.currentOutfit][InventorySlotId] = itemID
        end
    end
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusToServer) do
        if itemID ~= 0 then
            transmogOutfits[Transmog.currentOutfit][InventorySlotId] = itemID
        end
    end
    TransmogFrameSaveOutfit:Disable()
end

function Transmog:EnableOutfitSaveButton()
    if self.currentOutfit ~= nil then
        TransmogFrameSaveOutfit:Enable()
    end
end

function Transmog_deleteOutfit()
    transmogOutfits[Transmog.currentOutfit] = nil
    TransmogFrameSaveOutfit:Disable()
    TransmogFrameDeleteOutfit:Disable()
    Transmog.currentOutfit = nil
    UIDropDownMenu_SetText("Outfits", TransmogFrameOutfits)
    Transmog_revert()
end

StaticPopupDialogs["TRANSMOG_NEW_OUTFIT"] = {
    text = "Enter Outfit Name:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function()
        local outfitName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        if outfitName == '' then
            StaticPopup_Show('TRANSMOG_OUTFIT_EMPTY_NAME')
            return
        end
        if transmogOutfits[outfitName] then
            StaticPopup_Show('TRANSMOG_OUTFIT_EXISTS')
            return
        end
        transmogOutfits[outfitName] = {}
        UIDropDownMenu_SetText(outfitName, TransmogFrameOutfits)
        Transmog.currentOutfit = outfitName
        Transmog:EnableOutfitSaveButton()
        Transmog_SaveOutfit()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText('')
    end,
    timeout = 0,
    whileDead = 0,
    hideOnEscape = 1,
};

StaticPopupDialogs["TRANSMOG_OUTFIT_EXISTS"] = {
    text = "Outfit Name already exists.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["TRANSMOG_OUTFIT_EMPTY_NAME"] = {
    text = "Outfit Name not valid.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_DELETE_OUTFIT"] = {
    text = "Delete Outfit ?",
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        Transmog_deleteOutfit()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
};

function Transmog_NewOutfitPopup()
    StaticPopup_Show('TRANSMOG_NEW_OUTFIT')
end

function Transmog:cacheItem(linkOrID)

    if not linkOrID then
        twfdebug("cache item call with null " .. type(linkOrID))
    end

    if not linkOrID or linkOrID == 0 then
        twfdebug("cache item call with null2 " .. type(linkOrID))
        return
    end

    if TransmogFrame_ToNumber(linkOrID) then
        if GetItemInfo(linkOrID) then
            -- item ok, break
            return true
        else
            local item = "item:" .. linkOrID .. ":0:0:0"
            local _, _, itemLink = TransmogFrame_Find(item, "(item:%d+:%d+:%d+:%d+)");
            linkOrID = itemLink
        end
    else
        if TransmogFrame_Find(linkOrID, "|", 1, true) then
            local _, _, itemLink = TransmogFrame_Find(linkOrID, "(item:%d+:%d+:%d+:%d+)");
            linkOrID = itemLink
            if GetItemInfo(self:IDFromLink(linkOrID)) then
                -- item ok, break
                return true
            end
        end
    end

    GameTooltip:SetHyperlink(linkOrID)

end

SLASH_TRANSMOG1 = "/transmog"
SlashCmdList["TRANSMOG"] = function(cmd)
    if cmd then
        Transmog.newTransmogAlert:ShowAnchor()
    end
end
SLASH_TRANSMOGDEBUG1 = "/transmogdebug"
SlashCmdList["TRANSMOGDEBUG"] = function(cmd)
    if cmd then
        if Transmog.debug then
            Transmog.debug = false
            twfprint("Transmog debug off")
        else
            Transmog.debug = true
            twfprint("Transmog debug on")
        end
    end
end
