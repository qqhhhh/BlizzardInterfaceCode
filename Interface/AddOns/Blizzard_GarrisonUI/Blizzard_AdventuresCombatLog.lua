---------------------------------------------------------------------------------
--- Combat Log Helpers						                                  ---
---------------------------------------------------------------------------------

local function IsAllyBoardIndex(boardIndex) 
	return	boardIndex == Enum.GarrAutoBoardIndex.AllyLeftBack or
			boardIndex == Enum.GarrAutoBoardIndex.AllyRightBack or
			boardIndex == Enum.GarrAutoBoardIndex.AllyLeftFront or
			boardIndex == Enum.GarrAutoBoardIndex.AllyCenterFront or
			boardIndex == Enum.GarrAutoBoardIndex.AllyRightFront;
end

local function IsEventOffensive(eventType) 
	return	eventType == Enum.GarrAutoMissionEventType.MeleeDamage or
			eventType == Enum.GarrAutoMissionEventType.RangeDamage or
			eventType == Enum.GarrAutoMissionEventType.SpellMeleeDamage or 
			eventType == Enum.GarrAutoMissionEventType.SpellRangeDamage or 
			eventType == Enum.GarrAutoMissionEventType.PeriodicDamage or
			eventType == Enum.GarrAutoMissionEventType.Died;
end

local function EventHasPoints(eventType) 
	return	eventType == Enum.GarrAutoMissionEventType.MeleeDamage or
			eventType == Enum.GarrAutoMissionEventType.RangeDamage or
			eventType == Enum.GarrAutoMissionEventType.SpellMeleeDamage or 
			eventType == Enum.GarrAutoMissionEventType.SpellRangeDamage or 
			eventType == Enum.GarrAutoMissionEventType.PeriodicDamage or
			eventType == Enum.GarrAutoMissionEventType.Heal or
			eventType == Enum.GarrAutoMissionEventType.PeriodicHeal;
end

local function GetCombatLogEntryForEventType(spellName, eventType, caster, target, amount, element) 
--TODO: Finalize design of combat log to stop using nonlocalized string
	if eventType == Enum.GarrAutoMissionEventType.MeleeDamage then
		return COVENANT_MISSIONS_COMBAT_LOG_MELEE_DAMAGE:format(caster, target, amount);
	elseif  eventType == Enum.GarrAutoMissionEventType.RangeDamage then
		return COVENANT_MISSIONS_COMBAT_LOG_RANGE_DAMAGE:format(caster, target, amount);
	elseif  eventType == Enum.GarrAutoMissionEventType.SpellMeleeDamage then
		return COVENANT_MISSIONS_COMBAT_LOG_SPELL_MELEE_DAMAGE:format(caster, spellName, target, amount, element);
	elseif  eventType == Enum.GarrAutoMissionEventType.SpellRangeDamage then
		return COVENANT_MISSIONS_COMBAT_LOG_SPELL_RANGE_DAMAGE:format(caster, spellName, target, amount, element);
	elseif  eventType == Enum.GarrAutoMissionEventType.PeriodicDamage then
		return COVENANT_MISSIONS_COMBAT_LOG_PERIODIC_DAMAGE:format(caster, spellName, amount, element, target);
	elseif  eventType == Enum.GarrAutoMissionEventType.ApplyAura then
		return COVENANT_MISSIONS_COMBAT_LOG_APPLY_AURA:format(caster, spellName, target);
	elseif  eventType == Enum.GarrAutoMissionEventType.Heal then
		return COVENANT_MISSIONS_COMBAT_LOG_HEAL:format(caster, spellName, target, amount);
	elseif  eventType == Enum.GarrAutoMissionEventType.PeriodicHeal then
		return COVENANT_MISSIONS_COMBAT_LOG_PERIODIC_HEAL:format(caster, spellName, target, amount);
	elseif  eventType == Enum.GarrAutoMissionEventType.Died then
		return COVENANT_MISSIONS_COMBAT_LOG_DIED:format(caster, target);
	elseif  eventType == Enum.GarrAutoMissionEventType.RemoveAura then
		return COVENANT_MISSIONS_COMBAT_LOG_REMOVE_AURA:format(caster, spellName, target);
	else
		return COVENANT_MISSIONS_COMBAT_LOG_SPELL_RANGE_DAMAGE:format(caster, spellName, target, amount, element);
	end
end

local function GetCombatLogTextColor(combatLogEvent)
	if IsAllyBoardIndex(combatLogEvent.casterBoardIndex) then
		if IsEventOffensive(combatLogEvent.type) then 
			return WHITE_FONT_COLOR;
		else
			return GREEN_FONT_COLOR;
		end
	else
		return RED_FONT_COLOR;
	end
end

---------------------------------------------------------------------------------
--- Adventures Combat Log Mixin				                                  ---
---------------------------------------------------------------------------------

AdventuresCombatLogMixin = { }

function AdventuresCombatLogMixin:OnLoad()
	self.CombatLogMessageFrame:SetMaxLines(5000);
	self.CombatLogMessageFrame:SetFading(false);
	self.CombatLogMessageFrame:SetFontObject(ChatFontNormal);
	self.CombatLogMessageFrame:SetIndentedWordWrap(true);
	self.CombatLogMessageFrame:SetJustifyH("LEFT");
	self.CombatLogMessageFrame:SetOnScrollChangedCallback(function(messageFrame, offset)
		messageFrame.ScrollBar:SetValue(messageFrame:GetNumMessages() - offset);
	end);

	self.damageTypeKeys = {};
	local damageClassStrings = C_Garrison.GetAutoCombatDamageClassValues();

	for _, damageClassString in ipairs(damageClassStrings) do
		self.damageTypeKeys[damageClassString.damageClassValue] = damageClassString.locString;
	end
end

function AdventuresCombatLogMixin:Clear()
	self.CombatLogMessageFrame:Clear();
end

function AdventuresCombatLogMixin:AddCombatRound(roundIndex, currentRound, totalRounds) 
	self:AddCombatRoundHeader(roundIndex, totalRounds);
	for eventIndex = 1, #currentRound.events do 
		self:AddCombatEvent(currentRound.events[eventIndex]);
	end
end

function AdventuresCombatLogMixin:AddCombatRoundHeader(roundIndex, totalRounds) 
	self.CombatLogMessageFrame:AddMessage(" ");
	self.CombatLogMessageFrame:AddMessage(COVENANT_MISSIONS_COMBAT_LOG_ROUND:format(roundIndex, totalRounds), YELLOW_FONT_COLOR:GetRGB());
	self.CombatLogMessageFrame:AddMessage(" ");
end

function AdventuresCombatLogMixin:AddCombatEvent(combatLogEvent)
	local spellInfo = C_Garrison.GetCombatLogSpellInfo(combatLogEvent.spellID);
	local spellName = spellInfo.name;
	local damageType = self.damageTypeKeys[spellInfo.schoolMask];
	local caster = self:GetNameAtBoardIndex(combatLogEvent.casterBoardIndex);
	local eventHasPoints = EventHasPoints(combatLogEvent.type);
	local textColor = GetCombatLogTextColor(combatLogEvent);

	for _, targetInfoEntry in ipairs(combatLogEvent.targetInfo) do
		local target = self:GetNameAtBoardIndex(targetInfoEntry.boardIndex);
		local amount = eventHasPoints and targetInfoEntry.points or "";
		local logEntry = GetCombatLogEntryForEventType(spellName, combatLogEvent.type, caster, target, amount, damageType);

		self.CombatLogMessageFrame:AddMessage(logEntry, textColor:GetRGB());
	end
end

function AdventuresCombatLogMixin:AddVictoryState(winState)
	local winStateText = winState and COVENANT_MISSIONS_COMBAT_LOG_VICTORY or COVENANT_MISSIONS_COMBAT_LOG_LOSS;
	self.CombatLogMessageFrame:AddMessage(winStateText, YELLOW_FONT_COLOR:GetRGB());
end

function AdventuresCombatLogMixin:GetCompleteScreen()
	return self:GetParent();
end

function AdventuresCombatLogMixin:GetNameAtBoardIndex(boardIndex)
	local frame = self:GetCompleteScreen():GetFrameFromBoardIndex(boardIndex);
	return frame:GetName() or "";
end