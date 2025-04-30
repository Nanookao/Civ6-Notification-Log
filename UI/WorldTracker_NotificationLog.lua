--------------------------------
-- WorldTracker_NotificationLog
-- Version: 3.0
-- Author: FinalFreak16, Nanookao
-- DateCreated: 2025-04-30
--------------------------------
print( "Loading WorldTracker_NotificationLog.lua, ContextPtr:GetID():", ContextPtr:GetID() )
local PANEL_ID = "500-NotificationLog"

-- ===========================================================================
--	INCLUDE
-- ===========================================================================
include("InstanceManager")


-- ===========================================================================
--	UI references
-- ===========================================================================
local m_PanelContainer  :table
local m_Instance		    :table  = {}  -- NotificationLogInstance
ContextPtr:BuildInstance( "NotificationLogInstance", m_Instance )
local m_CheckBox        :table  = Controls.NotificationLogCheck
local m_OptionsInstance :table  = m_Instance.OptionsInstance
local m_OptionsPopup    :table  = m_OptionsInstance.OptionsPopup
-- print( "m_OptionsPopup=", m_OptionsPopup )
local m_Panel           :table  = m_Instance.NotificationLogPanel
local m_Header          :table  = m_Instance.TitleButton
local m_Content         :table  = m_Instance.Content
local m_ListScroll      :table  = m_Instance.ListScroll
local m_EntryStack      :table  = m_Instance.EntryStack
local m_EntryManager    :table  = InstanceManager:new("NotificationEntry", "EntryRoot", m_EntryStack)
local m_EntryInstances  :table  = {}
local m_maxEntries      :number = 50  -- Maximum entries allowed in the log. WARNING: Too many entries can slow down the UI.



-- ===========================================================================
--  Constants
-- ===========================================================================
-- ReportingStatusTypes.DEFAULT == 103780558
-- ReportingStatusTypes.GOSSIP  == -552441153
-- CQUI creates 2 custom message types in CivicsTree_CQUI.lua, TechTree_CQUI.lua
ReportingStatusTypes.CQUI_STATUS_MESSAGE_CIVIC = 3  -- Number to distinguish civic messages
ReportingStatusTypes.CQUI_STATUS_MESSAGE_TECHS = 4  -- Number to distinguish tech messages
ReportingStatusTypes.TurnEnd = 4000  -- arbitrary number

ReportingStatusTypesInv = {}
for k,v in pairs(ReportingStatusTypes) do
  ReportingStatusTypesInv[v] = k
end


-- ===========================================================================
--  Variables
-- ===========================================================================
local m_Hidden      :boolean = false
local m_Closed      :boolean = false

-- Clear notifications between turns
local m_EmptyLogEachTurn  :boolean = (0 ~= GlobalParameters.FF16_DEFAULT_EMPTYLOG)
-- Count the number of new entries each turn
local m_NewMessageCount   :number  = 0

-- List size limits
local m_ListSizeMin   :number = 2 or GlobalParameters.FF16_DEFAULT_LOGSIZE
local m_ListSizeMax   :number = 6 or GlobalParameters.FF16_DEFAULT_MAXLOGSIZE
local m_ListSize      :number = nil   -- list size is not set until Initialize()
local m_EntrySizeY    :number = 35+9  -- SizeY + OffsetY

local m_GL_MaxAllowedSizeY		:number = 390;


-- ===========================================================================
-- Show/hide
-- ===========================================================================
function SetHidden(hidden :boolean)
  m_Hidden = hidden
  -- m_CheckBox:SetCheck(not hidden)
  m_Panel:SetHide(hidden)

  -- Destroy entries to free up memory
  if hidden then  m_EntryManager:DestroyInstances()  end

  ResizePanel()
end

function SetClosed(closed :boolean)
  UI.PlaySound(closed and "Tech_Tray_Slide_Closed" or "Tech_Tray_Slide_Open")
  m_Closed = closed
  m_Content:SetHide(closed)
  ResizePanel()
end
  
function TogglePanel()
  SetClosed(not m_Closed)
end

function ToggleOptions()
  m_OptionsPopup:SetHide(not m_OptionsPopup:IsHidden())
end


-- ===========================================================================
--  Resize
-- ===========================================================================
function RefreshSize()
  local newsize = minmax(#m_EntryInstances, m_ListSizeMin, m_ListSizeMax)
  if m_ListSize == newsize then  return  end

  m_ListSize = newsize
  m_ListScroll:SetSizeY(newsize * m_EntrySizeY)
  ResizePanel()
end


function ResizePanel()
  -- m_EntryStack:CalculateSize()
  -- m_EntryStack:ReprocessAnchoring()
  return m_PanelContainer and m_PanelContainer:CalculateSize()
end


--  Helper
function minmax(value, minimum, maximum)
  if value < minimum then  return minimum  end
  if value > maximum then  return maximum  end
  return value
end




-- ===========================================================================
--  Reset
-- ===========================================================================
function ClearNotifications()
  SetNewMessageCount(0)

  m_EntryInstances = {}
  m_EntryManager:ResetInstances()
  -- m_EntryManager:DestroyInstances()
  RefreshSize()
end


-- ===========================================================================
--  Events
-- ===========================================================================
function OnRefresh()
  RefreshSize()
end


-- Monitor notifications
function OnStatusMessage(message :string, displayTime :number, msgType :number, subType :number)
  -- Ignore displayTime: messages stay visible until cleared
  AddNotification(message, msgType, subType)
  UI.PlaySound("Main_Menu_Mouse_Over")
end


function OnLocalPlayerTurnBegin()
  AddNewTurnNotification( Game.GetCurrentGameTurn() )
end

function OnLocalPlayerTurnEnd()
  -- Empty the log between turns
  if m_EmptyLogEachTurn then  ClearNotifications()  end
  -- New turn, new counter
  SetNewMessageCount(0)
end




-- ===========================================================================
--  Process notification
-- ===========================================================================
function AddNotification(message :string, msgType :number, subType :number)
  local isCombat  :boolean = msgType == ReportingStatusTypes.DEFAULT
  local isGossip  :boolean = msgType == ReportingStatusTypes.GOSSIP
  local isTurnEnd :boolean = msgType == ReportingStatusTypes.TurnEnd

  local dbGossipInfo :table = isGossip and GameInfo.Gossips[subType]
  local msgTypeStr  :string = ReportingStatusTypesInv[msgType]
  local subTypeStr  :string = dbGossipInfo and dbGossipInfo.GossipType
  print( "AddNotification(message= ", message, "msgType= ", msgType, msgTypeStr, "subType= ", subType, subTypeStr )

  local gossipMsg   = dbGossipInfo and Locale.Lookup(dbGossipInfo.Message)
  local gossipDesc  = dbGossipInfo and Locale.Lookup(dbGossipInfo.Description)
  local gossipGroup = dbGossipInfo and dbGossipInfo.GroupType
  local gossipIcon  = dbGossipInfo and "ICON_GOSSIP_"..dbGossipInfo.GroupType
  local gossipVis   = dbGossipInfo and dbGossipInfo.VisibilityLevel

  -- Split the leading icon from gossip text
  local msgIcon,msgText = match(message, "^(\[ICON.*\]) *(.*)")
  if not msgIcon then
    msgIcon = isCombat and "[ICON_DECLARE_SURPRISE_WAR]"
      or isGossip and "[ICON_You]"
    msgText = message
  end

  print( "gossipVis=", gossipVis, "msgIcon=", msgIcon, "gossipIcon=", gossipGroup, "msgText=", msgText, "gossipMsg=", gossipMsg, "gossipDesc=", gossipDesc )


  local uiEntry :table
  -- Remove the earliest entry if the log limit has been reached
  if m_maxEntries <= #m_EntryInstances then
    uiEntry = table.remove(m_EntryInstances, 1)
    -- m_EntryStack:ReleaseChild( uiEntry.EntryRoot )
    -- uiEntry = m_EntryManager:GetAllocatedInstance()
    m_EntryManager:ReleaseInstance(uiEntry)
  end

  -- Get unused Entry instance
  uiEntry = m_EntryManager:GetInstance()

  -- what for?
  uiEntry.EntryRoot:SetOffsetX(not isCombat and -3 or 0)

  -- New turn message is centered, the rest left-aligned
  uiEntry.Message:SetAlign(isTurnEnd and "center" or "left")

  -- Set notification entry text and icon
  uiEntry.Message:SetText(msgText)
  uiEntry.Icon:SetText(msgIcon or "")
  uiEntry.Icon:SetHide(not msgIcon)

  
  -- Add entry to global instances
  table.insert(m_EntryInstances, uiEntry)

  -- Update number of new notifications
  if not isTurnEnd then
    SetNewMessageCount(m_NewMessageCount + 1)
  end

  -- Recalculate panel size
  ContextPtr:RequestRefresh()
end




-- ===========================================================================
function AddNewTurnNotification(iTurn :number)
  local turnLoc = Locale.Lookup("LOC_TOP_PANEL_CURRENT_TURN")
  turnLoc = string.upper(turnLoc)
  local message = "[COLOR_FLOAT_GOLD]"..turnLoc.." "..iTurn
  AddNotification(message, ReportingStatusTypes.TurnEnd)
end


-- ===========================================================================
function SetNewMessageCount(count :number)
  m_NewMessageCount = count

  local pLabel = m_Instance.NewMessageCount
  local text = count == 0 and "" or "[ICON_New]"..count;
  pLabel:SetText(text)

  local tooltipStr = count == 1 and "LOC_FF16_LOG_ENTRY_SINGLE" or "LOC_FF16_LOG_ENTRY_MULTIPLE"
  local tooltipLoc = count.." "..Locale.Lookup(tooltipStr)
  pLabel:SetToolTipString(tooltipLoc)
end




-- ===========================================================================
--  Options popup, sliders
-- ===========================================================================
function m_OptionsInstance.MinSize:ValidateOtherSlider(value :number)
  if value > m_ListSizeMax then
    m_ListSizeMax = value
    m_OptionsInstance.MaxSize:SetSlider(value)
  end
end

function m_OptionsInstance.MaxSize:ValidateOtherSlider(value :number)
  if value < m_ListSizeMin then
    m_ListSizeMin = value
    m_OptionsInstance.MinSize:SetSlider(value)
  end
end


function m_OptionsInstance.MinSize:SetSlider(value :number)
  self.Slider:SetStep(value)
  self.Text:SetText(value)
end

function m_OptionsInstance.MinSize:OnSlider(a,b,c)
  -- UI.PlaySound("Main_Menu_Mouse_Over")
  local value = self.Slider:GetStep()
  self.Text:SetText(value)
  self:ValidateOtherSlider(value)
  RefreshSize()
end


-- ===========================================================================
function InitializeOptions()
  local MinSize = m_OptionsInstance.MinSize
  local MaxSize = m_OptionsInstance.MaxSize

  MaxSize.SetSlider = MinSize.SetSlider
  MaxSize.OnSlider  = MinSize.OnSlider

  MinSize.Slider:RegisterSliderCallback(function(...) MinSize:OnSlider(...) end)
  MaxSize.Slider:RegisterSliderCallback(function(...) MaxSize:OnSlider(...) end)

  -- Set default slider positions
  MinSize:SetSlider(m_ListSizeMin)
  MaxSize:SetSlider(m_ListSizeMax)



  local function OnClickEmptyLog()
    local checked = not control:IsSelected()
    m_EmptyLogEachTurn = checked
    control:SetSelected(checked)
  end

  local pCheckBox = m_OptionsInstance.EmptyLogCheckBox
  pCheckBox:SetSelected(m_EmptyLogEachTurn)
  pCheckBox:RegisterCallback(Mouse.eLClick, OnClickEmptyLog)
end




-- ===========================================================================
--  Testing
-- ===========================================================================
local function DebugTest()
  local event = Events.StatusMessage

  function OnInputHandler(pInputStruct) 
    local uiMsg = pInputStruct:GetMessageType();
    if uiMsg == KeyEvents.KeyUp then 
      local key = pInputStruct:GetKey();
      if key == Keys.G then event("Testing out gossip message, this is basically just an average string.", 10, ReportingStatusTypes.GOSSIP ); return true; end
      if key == Keys.H then event("[ICON_Production] Egypt built a Granary in Cairo.", 10, ReportingStatusTypes.GOSSIP ); return true; end
      if key == Keys.J then OnLocalPlayerTurnEnd(); return true; end
      if key == Keys.F then event("Testing out gossip message, this is an extra long string. There are a lot of words in this one.", 10, ReportingStatusTypes.GOSSIP ); return true; end
      if key == Keys.D then AddNewTurnNotification(Game.GetCurrentGameTurn()); return true; end
      if key == Keys.S then event("Your Warrior (15 damage) attacked an enemy Archer (35 damage)!", 10, ReportingStatusTypes.DEFAULT ); return true; end
      if key == Keys.A then event("Your Warrior [ICON_Ranged] Enemy Scout![NEWLINE]Results: [COLOR_FLOAT_GOLD]Dealt 87HP damage!", 10, ReportingStatusTypes.DEFAULT ); return true; end
    end	
    return false;
  end

  ContextPtr:SetInputHandler(OnInputHandler, true)
end




-- ===========================================================================
--  Init
-- ===========================================================================
function OnInit()
  print("OnInit()")
  ExposedMembers.WorldTracker:AttachPanel(PANEL_ID, m_Panel, m_CheckBox and m_CheckBox:GetParent())
  m_PanelContainer = ExposedMembers.WorldTracker.PanelContainer
  -- ResizePanel()
  --[[
  print( "PanelContainer:", m_PanelContainer, m_PanelContainer:GetID() )
  m_PanelContainer = m_Panel:GetParent()
  print( "NotificationLogPanel:GetParent():", m_PanelContainer, m_PanelContainer:GetID() )
  m_PanelContainer = m_Panel:GetParent():GetParent()
  print( "NotificationLogPanel:GetParent():GetParent():", m_PanelContainer, m_PanelContainer:GetID() )
  --]]
  Subscribe()
end

function OnShutdown()
  print("OnShutdown()")
  ExposedMembers.WorldTracker:AttachPanel(PANEL_ID, nil, nil)
  m_PanelContainer = nil
  Unsubscribe()
end


-- ===========================================================================
function Subscribe()
  Events.StatusMessage        .Add(OnStatusMessage)
  Events.LocalPlayerTurnBegin .Add(OnLocalPlayerTurnBegin)
  Events.LocalPlayerTurnEnd   .Add(OnLocalPlayerTurnEnd)
end

function Unsubscribe()
  Events.StatusMessage        .Remove(OnStatusMessage)
  Events.LocalPlayerTurnBegin .Remove(OnLocalPlayerTurnBegin)
  Events.LocalPlayerTurnEnd   .Remove(OnLocalPlayerTurnEnd)
end


-- ===========================================================================
function Initialize()
  print("Initialize()")

  -- Hot-reload events
  ContextPtr:SetInitHandler(OnInit)
  ContextPtr:SetShutdown(OnShutdown)
  ContextPtr:SetRefreshHandler(OnRefresh)

  -- ContextPtr:BuildInstanceForControl( "NotificationLogInstance", m_Instance, Controls.WorldTrackerVerticalContainer )
  -- ContextPtr:BuildInstance( "NotificationLogInstance", m_Instance )
  -- ContextPtr:BuildInstanceForControl( "NotificationLogOptionsPopup", m_OptionsInstance, m_Panel )

  if m_CheckBox then
    m_CheckBox:SetCheck(true)
    m_CheckBox:RegisterCheckHandler( function() SetHidden(not m_CheckBox:IsChecked()) end )
  end

  --FF16 Add events for Gossip Log
  m_Instance.HeaderButton:RegisterCallback(Mouse.eLClick, TogglePanel)
  -- m_Instance.HeaderButton:RegisterCallback(Mouse.eLClick, ClearNotifications)
  m_Instance.TitleButton :RegisterCallback(Mouse.eLClick, TogglePanel)
  m_Instance.TitleButton :RegisterCallback(Mouse.eRClick, ClearNotifications)
  m_Instance.NewMessageCount:RegisterCallback(Mouse.eLClick, TogglePanel)
  m_Instance.NewMessageCount:RegisterCallback(Mouse.eRClick, ClearNotifications)
  m_Instance.OptionsButton:RegisterCallback(Mouse.eLClick, ToggleOptions)
  m_Instance.OptionsButton:SetToolTipString( Locale.Lookup("LOC_FF16_NOTIFICATION_LOG_TOOLTIP") )
  
  InitializeOptions()
  RefreshSize()
  -- DebugTest()
end


Initialize()
