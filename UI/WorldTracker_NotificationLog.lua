--[[
-- Created by FinalFreak16
-- Notification Log Mod - v2.0
--]]
-- ===========================================================================
-- Base File
-- ===========================================================================
include("WorldTracker_Expansion1");

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_persistGossipLog        :boolean  = false   -- Default state for gossip entries persisting between turns
local m_gossipLogInstance		:table	 = {}; 		-- New Gossip log instance
local m_gossipLogNewEntryCount	:number  = 0;		-- Counter for number of new entries each turn
local m_gossipEntryInstances	:table	 = {};
local m_gossipOptionsInstance	:table	 = {};
local m_maxLogEntries = 50;   --Maximum allows entries allowed in the log. WARNING: Increase this at your own risk! 

-- Default Log sizes
local m_GL_MainPanel_SizeY	 	:number = 28;  
local m_GL_GossipLogPanel_SizeY :number = 28; 
local m_GL_ScrollPanel_SizeY	:number = 30;
local m_GL_MaxAllowedSizeY		:number = 390;
local m_GL_CurrentSetSize		:number = 0;
local m_GL_EntrySize			:number = 44;

-- Flags
local m_gossipOptionsHidden		:boolean = true;
local m_gossipTurnCounterAdded	:boolean = false;
local m_isCustomGossipMessage	:boolean = false;

-- ===========================================================================

-- ===========================================================================
--	OVERRIDE FUNCTIONS
-- ===========================================================================
function RealizeEmptyMessage()
	local hideall = (m_hideChat and m_hideCivics and m_hideResearch and m_hideGossipLog)
	Controls.EmptyPanel:SetHide(not hideall);
end

function OnLocalPlayerTurnBegin()
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 then
		m_needsRefresh = true;
	end
	
	m_gossipTurnCounterAdded = false;
end

-- ===========================================================================
--	NEW FUNCTIONS
-- ===========================================================================

-- Toggle Log on and off
function ToggleGossipLog(hide :boolean)
  -- print( "ToggleGossipLog()" )
  local uiList = m_gossipLogInstance.GossipLogContainer
  if hide == nil then  hide = not uiList:IsHidden()  end

  uiList:SetHide(hide)
  if Controls.GossipCheck then  Controls.GossipCheck:SetCheck(not hide)  end
  -- LuaEvents.WorldTracker_ToggleNotificationLogPanel(hide)

	RealizeEmptyMessage();
	RealizeStack();
end

-- Toggle persist mode on an off
function ToggleGossipLogPersist(persistGossipLog:boolean)
	if persistGossipLog ~= nil then
		m_persistGossipLog = persistGossipLog;		
	end

	--print("Gossip Log Persist is now: ", m_persistGossipLog);	
end

-- Update gossip log using Event.StatusMessage.Add() calls
function UpdateGossipLog(logString :string, type:number )
	local isTurnCountEntry = false;
	local isCombatEntry = false;
	
	local controlTable = {};
	local gossipString;
	local gossipIcon;
	local gossipText = logString;
	
	--print(gossipText);
	
	if(type == ReportingStatusTypes.DEFAULT) then
		isCombatEntry = true;
		--Generate new LogEntry instance, put in controlTable, parent is Gossip log stack
		ContextPtr:BuildInstanceForControl( "GossipLogEntry", controlTable, m_gossipLogInstance.GossipLogStack );	
		--print(logString);
	else	
		if(string.find(logString, "]TURN")) then
			ContextPtr:BuildInstanceForControl( "TurnCountLogEntry", controlTable, m_gossipLogInstance.GossipLogStack );
			isTurnCountEntry = true;
		else
			--Generate new LogEntry instance, put in controlTable, parent is Gossip log stack
			ContextPtr:BuildInstanceForControl( "GossipLogEntry", controlTable, m_gossipLogInstance.GossipLogStack );	
		
			-- Add icons to normal gossip text.
			if not(string.find(logString, "ICON")) then
				logString = "[ICON_You]" .. logString;
			end
		end
	end
			
	-- Split string into Icon and Text
	if not(isCombatEntry) then
		gossipString = strSplit(logString, "] ");
		gossipIcon = gossipString[1] .. "]";
		gossipText = gossipString[2];
		controlTable.LogRoot:SetOffsetX(-3);	
	else
		gossipIcon = "[ICON_DECLARE_SURPRISE_WAR]"
		gossipText = logString;
	end
		
	if(isTurnCountEntry) then
		gossipText = logString;	
	end
	
	if(m_isCustomGossipMessage == true) then
		gossipText = logString;			
		m_isCustomGossipMessage = false;	
	end		
		
	--Set log entry text	
	controlTable.String:SetText(gossipText);		
	if(gossipIcon and not isTurnCountEntry) then
		controlTable.Icon:SetText(gossipIcon);
	end
	
	--Add entry to global instances
	table.insert( m_gossipEntryInstances, controlTable );

	--Update number of new entries notification + tooltip
	if not(isTurnCountEntry) then
		m_gossipLogNewEntryCount = m_gossipLogNewEntryCount+1;
		local newLogText = "[ICON_New]" .. m_gossipLogNewEntryCount;
		m_gossipLogInstance.NewLogNumber:SetText(newLogText);
	end
	
	-- Grammar
	if(m_gossipLogNewEntryCount < 2) then
		m_gossipLogInstance.NewLogNumber:SetToolTipString(m_gossipLogNewEntryCount .. " " .. Locale.Lookup("LOC_FF16_LOG_ENTRY_SINGLE"));
	else
		m_gossipLogInstance.NewLogNumber:SetToolTipString(m_gossipLogNewEntryCount .. " " .. Locale.Lookup("LOC_FF16_LOG_ENTRY_MULTIPLE"));
	end
	
	-- Remove the earliest entry if the log limit has been reached
	if(table.count(m_gossipEntryInstances) > m_maxLogEntries) then
		m_gossipLogInstance.GossipLogStack:ReleaseChild( m_gossipEntryInstances[1].LogRoot);
		table.remove(m_gossipEntryInstances, 1);
	end
	
	-- Refresh log and reprocess size
	m_gossipLogInstance.GossipLogStack:CalculateSize();	
	m_gossipLogInstance.GossipLogStack:ReprocessAnchoring();
	
	-- Auto Resize Log
	if(m_GL_CurrentSetSize == 0) then
		local gossipStackSize = m_gossipLogInstance.GossipLogStack:GetSizeY() + 10;
		if not(m_GL_MainPanel_SizeY + gossipStackSize > m_GL_MaxAllowedSizeY) then
			m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MainPanel_SizeY + gossipStackSize);
			m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_GossipLogPanel_SizeY + gossipStackSize);
			m_gossipLogInstance.GossipScrollBar:SetOffsetX(400);
		else
			m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MaxAllowedSizeY);
			m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_MaxAllowedSizeY);
			m_gossipLogInstance.GossipScrollBar:SetOffsetX(20);
		end
	end
		
	UpdateGossipLogScrollBar(m_GL_CurrentSetSize);
	
end

-- Function for splitting strings
function strSplit(self, delimiter)
    local result = {};
    for match in (self..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- Empty the log between turns
function ClearLogs()
	if not(m_persistGossipLog) then
		ClearGossipLog();
	end
	
	m_gossipLogNewEntryCount = 0;
	m_gossipLogInstance.NewLogNumber:SetText("");		
end

-- Empty the log between turns (when persist is disabled)
function ClearGossipLog()

	local numLogInstances:number = table.count(m_gossipEntryInstances);

	-- limit chat log
	for i=1, numLogInstances do
		m_gossipLogInstance.GossipLogStack:ReleaseChild( m_gossipEntryInstances[i].LogRoot);	
	end
	
	-- Reset log
	m_gossipEntryInstances = {};
	m_gossipLogInstance.NewLogNumber:SetText("");
	m_gossipLogInstance.GossipLogStack:CalculateSize();
	m_gossipLogInstance.GossipLogStack:ReprocessAnchoring();
	
	-- Reset Log Size
	if(m_GL_CurrentSetSize == 0) then
		m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MainPanel_SizeY);
		m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_GossipLogPanel_SizeY);
		UpdateGossipLogScrollBar(m_gossipLogNewEntryCount);
	end

end

-- Toggle Options Panel for Log
function OnOpenGossipLogOptions()

	if(m_gossipOptionsHidden) then
		m_gossipOptionsInstance.GossipOptionsRoot:SetHide(false);
		m_gossipOptionsHidden = false;
	else
		m_gossipOptionsInstance.GossipOptionsRoot:SetHide(true);
		m_gossipOptionsHidden = true;
	end
end

-- Intercept screen notifications and forward to log instead
function UpdateLogs(logString :string, fDisplayTime:number, type:number )
	
	if(type == ReportingStatusTypes.GOSSIP) then		
		if not(m_gossipTurnCounterAdded) then
			AddTurnCounterToLogs(Game.GetCurrentGameTurn(), 1);
			m_gossipTurnCounterAdded = true;
		end
		
		UpdateGossipLog(logString, type);
	elseif(type == ReportingStatusTypes.DEFAULT) then
		
		if not(m_combatTurnCounterAdded) then
			AddTurnCounterToLogs(Game.GetCurrentGameTurn(), 2);
			m_combatTurnCounterAdded = true;
		end
		
		UpdateGossipLog(logString, type);
	end
		
	 UI.PlaySound("Main_Menu_Mouse_Over");
end

-- Change the log size based on specified size in options
function SetGossipLogSizeLock(logSize:number)

	if(logSize == 0) then -- Auto adjust

		local spacer = 10;
		if(m_gossipLogNewEntryCount == 0) then
			spacer = 0;
		end
		
		local gossipStackSize = m_gossipLogInstance.GossipLogStack:GetSizeY() + spacer;
		if not(m_GL_MainPanel_SizeY + gossipStackSize > m_GL_MaxAllowedSizeY) then		
			m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MainPanel_SizeY + gossipStackSize);
			m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_GossipLogPanel_SizeY + gossipStackSize);		
		else -- dont allow any bigger than size 8 log
			m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MaxAllowedSizeY);
			m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_MaxAllowedSizeY);
		end

	else -- manual lock on size	
		m_gossipLogInstance.MainPanel:SetSizeY(m_GL_MainPanel_SizeY + m_GL_EntrySize*logSize +10);
		m_gossipLogInstance.GossipLogPanel:SetSizeY(m_GL_GossipLogPanel_SizeY + m_GL_EntrySize*logSize +10);	
	end
	 
	UpdateGossipLogScrollBar(logSize);
end

-- Show/Hide the scrollbar when necessary
function UpdateGossipLogScrollBar(logSize:number)
	
	if(m_persistGossipLog) then
		local numLogInstances:number = table.count(m_gossipEntryInstances);
		if(numLogInstances) then
			if(logSize == 0) then
				if(numLogInstances > 8) then
					m_gossipLogInstance.GossipScrollBar:SetOffsetX(20);
				end
			else			
				if(numLogInstances > logSize) then
					m_gossipLogInstance.GossipScrollBar:SetOffsetX(20);
				else
					m_gossipLogInstance.GossipScrollBar:SetOffsetX(400);
				end
			end
		end
	else
		if not(logSize == 0) then
			if(m_gossipLogNewEntryCount > logSize) then
				m_gossipLogInstance.GossipScrollBar:SetOffsetX(20);
			else
				m_gossipLogInstance.GossipScrollBar:SetOffsetX(400);
			end
		end
	end
end

function AddTurnCounterToLogs(turnNo:number, logType:number)
	local turnLookup = Locale.Lookup("{LOC_TOP_PANEL_CURRENT_TURN:upper} ");
	local turnString = "[COLOR_FLOAT_GOLD]" .. turnLookup  .. turnNo;
	
	if(m_persistCombatLog and logType == 2) then
		UpdateCombatLog(turnString, ReportingStatusTypes.DEFAULT);
	end
	
	if(m_persistGossipLog and logType == 1) then
		UpdateGossipLog(turnString, ReportingStatusTypes.GOSSIP);
	end
end

function InitializeLogPreferences()

	-- Log Size Slider
	m_gossipOptionsInstance.LogSizeSlider:RegisterSliderCallback(
    	function(option)
            -- Guard against multiple calls with the same value
            if(logSize_sliderValue ~= option) then
                logSize_sliderValue = option;
                logSize_sliderStep = m_gossipOptionsInstance.LogSizeSlider:GetStep();
				
				local logSizeText = "LOC_FF16_LOGSIZE_AUTO";
                if(logSize_sliderStep == 0) then 
					logSizeText = "LOC_FF16_LOGSIZE_AUTO";
				else
					logSizeText = logSize_sliderStep;
				end			
				m_gossipOptionsInstance.LogSizeText:LocalizeAndSetText(logSizeText);       

				if(m_gossipOptionsInstance.LogSizeSlider:GetStep() > m_gossipOptionsInstance.LogMaxSizeSlider:GetStep()+1) then				
					m_gossipOptionsInstance.LogMaxSizeSlider:SetStep(logSize_sliderStep-1);
					m_gossipOptionsInstance.LogMaxSizeText:LocalizeAndSetText(logSize_sliderStep); 				
				end
				
				m_GL_CurrentSetSize = logSize_sliderStep;
				SetGossipLogSizeLock(m_GL_CurrentSetSize);
				UI.PlaySound("Main_Menu_Mouse_Over");
            end
    	end
    );
	
	-- Log Max Size Slider
	m_gossipOptionsInstance.LogMaxSizeSlider:RegisterSliderCallback(
    	function(option)
            -- Guard against multiple calls with the same value
            if(logMaxSize_sliderValue ~= option) then
                logMaxSize_sliderValue = option;
                logMaxSize_sliderStep = m_gossipOptionsInstance.LogMaxSizeSlider:GetStep();
				
				local logMaxSizeText = logMaxSize_sliderStep+1;
 	
				m_gossipOptionsInstance.LogMaxSizeText:LocalizeAndSetText(logMaxSizeText);   

				if(m_gossipOptionsInstance.LogSizeSlider:GetStep() > m_gossipOptionsInstance.LogMaxSizeSlider:GetStep()) then
					if(m_gossipOptionsInstance.LogSizeSlider:GetStep() ~= 0) then
						m_gossipOptionsInstance.LogSizeSlider:SetStep(logMaxSize_sliderStep+1);
						m_gossipOptionsInstance.LogSizeText:LocalizeAndSetText(logMaxSizeText);

						m_GL_CurrentSetSize = logMaxSize_sliderStep+1;
						SetGossipLogSizeLock(m_GL_CurrentSetSize);
						UI.PlaySound("Main_Menu_Mouse_Over");
					end
				end
				
				m_GL_MaxAllowedSizeY = (m_GL_MainPanel_SizeY+10)+m_GL_EntrySize*(logMaxSize_sliderStep+1);
				--print(m_GL_MaxAllowedSizeY);
				
				if(m_gossipOptionsInstance.LogSizeSlider:GetStep() == 0) then
					local gossipStackSize = m_gossipLogInstance.GossipLogStack:GetSizeY() + 10 + m_GL_MainPanel_SizeY;
					--print("Vs", gossipStackSize);
					if(gossipStackSize >= m_GL_MaxAllowedSizeY) then
						SetGossipLogSizeLock(logMaxSize_sliderStep+1);
					end
				end
				
				UI.PlaySound("Main_Menu_Mouse_Over");
            end
    	end
    );
		
	-- Set default step positions
	m_gossipOptionsInstance.LogSizeSlider:SetStep(GlobalParameters.FF16_DEFAULT_LOGSIZE);
	if(m_gossipOptionsInstance.LogSizeSlider:GetStep() == 0) then
		m_gossipOptionsInstance.LogSizeText:LocalizeAndSetText("LOC_FF16_LOGSIZE_AUTO");
	else
		m_GL_CurrentSetSize = GlobalParameters.FF16_DEFAULT_LOGSIZE;
		SetGossipLogSizeLock(m_GL_CurrentSetSize);
		m_gossipOptionsInstance.LogSizeText:LocalizeAndSetText(m_gossipOptionsInstance.LogSizeSlider:GetStep());
	end
	
	m_gossipOptionsInstance.LogMaxSizeSlider:SetStep(GlobalParameters.FF16_DEFAULT_MAXLOGSIZE-1);
	m_gossipOptionsInstance.LogMaxSizeText:LocalizeAndSetText(m_gossipOptionsInstance.LogMaxSizeSlider:GetStep()+1); 
	m_GL_MaxAllowedSizeY = (m_GL_MainPanel_SizeY+10)+m_GL_EntrySize*(GlobalParameters.FF16_DEFAULT_MAXLOGSIZE-1);

	local isEmptyLog = GlobalParameters.FF16_DEFAULT_EMPTYLOG;
	if(isEmptyLog == 0) then
		m_persistGossipLog = true;
	else
		m_persistGossipLog = false;
	end
	
	PopulateCheckBox(m_gossipOptionsInstance.EmptyLogCheckBox, isEmptyLog,
        function(option)
            if(option == true) then 
				m_persistGossipLog = false; 		
			else
				m_persistGossipLog = true;
			end
        end
    );
	
end

function PopulateCheckBox(control, current_value, check_handler, is_locked)
    
    if (is_locked == nil) then
		is_locked = false;
	end

    if(current_value == 0) then
        control:SetSelected(false);
    else
        control:SetSelected(true);
    end

    control:SetDisabled(is_locked ~= false);

    if(check_handler) then
        control:RegisterCallback(Mouse.eLClick, 
            function()
			    local selected = not control:IsSelected();
			    control:SetSelected(selected);
                check_handler(selected);
            end
        );
		control:RegisterCallback(Mouse.eMouseEnter, function()
            UI.PlaySound("Main_Menu_Mouse_Over");
		end);
    end

end

function Test()
		
	ContextPtr:SetInputHandler( 
	function( pInputStruct ) 
		local uiMsg = pInputStruct:GetMessageType();
		if uiMsg == KeyEvents.KeyUp then 
			local key = pInputStruct:GetKey();
			if key == Keys.G then LuaEvents.Custom_GossipMessage("Testing out gossip message, this is basically just an average string.", 10, ReportingStatusTypes.GOSSIP ); return true; end
			if key == Keys.H then LuaEvents.Custom_GossipMessage("[ICON_Production] Egypt built a Granary in Cairo.", 10, ReportingStatusTypes.GOSSIP ); return true; end
			if key == Keys.J then ClearLogs(); return true; end
			if key == Keys.F then LuaEvents.Custom_GossipMessage("Testing out gossip message, this is an extra long string. There are a lot of words in this one.", 10, ReportingStatusTypes.GOSSIP ); return true; end
			if key == Keys.D then AddTurnCounterToLogs(Game.GetCurrentGameTurn(), 1); return true; end
			if key == Keys.S then LuaEvents.Custom_GossipMessage("Your Warrior (15 damage) attacked an enemy Archer (35 damage)!", 10, ReportingStatusTypes.DEFAULT ); return true; end
			if key == Keys.A then LuaEvents.Custom_GossipMessage("Your Warrior [ICON_Ranged] Enemy Scout![NEWLINE]Results: [COLOR_FLOAT_GOLD]Dealt 87HP damage!", 10, ReportingStatusTypes.DEFAULT ); return true; end
		end	
		return false;
	end, true);
	
end

function Initialize()
	print("FinalFreak16: Loading Mod - Notification Log.");
	
	ContextPtr:BuildInstanceForControl( "GossipLogInstance", 	m_gossipLogInstance,		Controls.WorldTrackerVerticalContainer );
	ContextPtr:BuildInstanceForControl( "GossipOptionsPanel",  	m_gossipOptionsInstance,	m_gossipLogInstance.MainPanel );

	if Controls.GossipCheck then
		Controls.GossipCheck:SetCheck(true)
		Controls.GossipCheck:RegisterCheckHandler( function() ToggleGossipLog(not Controls.GossipCheck:IsChecked()) end )
	end

	--FF16 Add events for Gossip Log
	m_gossipLogInstance.TitleButton:RegisterCallback(Mouse.eLClick, function() ToggleGossipLog() end );
	m_gossipLogInstance.TitleButton:RegisterCallback(Mouse.eRClick, ClearGossipLog);
	m_gossipLogInstance.NewLogNumber:RegisterCallback(Mouse.eRClick, ClearGossipLog);
	m_gossipLogInstance.OptionsButton:RegisterCallback(Mouse.eLClick, OnOpenGossipLogOptions);
	m_gossipLogInstance.OptionsButton:SetToolTipString(Locale.Lookup("LOC_FF16_NOTIFICATION_LOG_TOOLTIP"));
	m_gossipLogInstance.GossipLogScrollPanel:RegisterScrollCallback(function(control:table, percent:number)
		if m_gossipLogInstance.GossipLogScrollPanel:GetScrollValue() ~= percent then
			m_gossipLogInstance.GossipLogScrollPanel:SetScrollValue(percent);
		end
	end);
	
	InitializeLogPreferences();
	
	--FF16: Events
	LuaEvents.Custom_GossipMessage.Add(UpdateLogs);
	Events.LocalPlayerTurnEnd.Add( ClearLogs );
	Events.StatusMessage.Add(UpdateLogs);
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);
	--Test();
end
Initialize();
