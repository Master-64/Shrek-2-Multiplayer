// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MMultiplayerPage extends MGUIPage
	Config(S2Multi);


enum ECurrentMenu
{
	CM_Connect,
	CM_Host,
	CM_Settings
};

struct AvailableMapsStruct
{
	var array<string> sAvailableMaps, URLs;
};

var ECurrentMenu CurrentMenu;
var AvailableMapsStruct AvailableMaps;
var int iSelectedLevel;

// Core multiplayer menu
var automated config GUIButton Singleplayer, ConnectTab, HostTab, SettingsTab;
var automated config GUIComponent CoreGUI[4];
var localized string lSingleplayer, lhSingleplayer, lConnectTab, lhConnectTab, lHostTab, lhHostTab, lSettingsTab, lhSettingsTab;

// Connect menu
var automated config GUIEditBox C_UsernameBox, IPAddressBox, C_PortBox;
var automated config GUILabel C_UsernameLabel, IPAddressLabel, C_PortLabel, ConnectLabels[3];
var automated config GUIButton Connect;
var automated config GUIComponent ConnectGUI[4];
var localized string l_C_UsernameBox, lh_C_UsernameBox, lIPAddressBox, lhIPAddressBox, l_C_PortBox, lh_C_PortBox, lConnect, lhConnect;

// Host menu
var automated config GUIEditBox H_UsernameBox, H_PortBox;
var automated config GUILabel H_UsernameLabel, H_PortLabel, LevelSelectLabel, HostLabels[3];
var automated config SHGUIComboBox LevelSelect;
var automated config GUIButton HostServer;
var automated config GUIComponent HostGUI[4];
var localized string l_H_UsernameBox, lh_H_UsernameBox, l_H_PortBox, lh_H_PortBox, lHostServer, lhHostServer, lLevelSelect, lhLevelSelect;

// Settings menu
var automated config GUILabel ClientSettingsLabel, ServerSettingsLabel, ProfaneLanguageLabel, ChatSoundsLabel, GlobalInventoryLabel, MaxPlayersLabel, SettingsLabels[6];
// - Client
var automated config GUIButton ProfaneLanguage, ChatSounds;
// - Server
var automated config GUIButton GlobalInventory;
var automated config GUIEditBox MaxPlayers;
// - Other
var automated config GUIComponent SettingsGUI[4];
var localized string lClientSettings, lServerSettings, lProfaneLanguage, lhProfaneLanguage, lChatSounds, lhChatSounds, lGlobalInventory, lhGlobalInventory, lMaxPlayers, lhMaxPlayers;


event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;
	local bool bFoundFirstMap;
	
	super.InitComponent(MyController, MyOwner);
	
	__OnClick__Delegate = InternalOnClick;
	__OnKeyType__Delegate = InternalOnKeyType;
	
	for(i = 0; i < Controls.Length; i++)
	{
		Controls[i].__OnChange__Delegate = InternalOnChange;
	}
	
	TabFooter.WinLeft = 0.493;
	TabFooter.WinTop = 0.9;
	
	CenterComponent(TabFooter);
	
	CoreGUI[0] = Singleplayer;
	CoreGUI[1] = ConnectTab;
	CoreGUI[2] = HostTab;
	CoreGUI[3] = SettingsTab;
	
	for(i = 0; i < 4; i++)
	{
		CenterComponent(CoreGUI[i]);
	}
	
	ConnectGUI[0] = C_UsernameBox;
	ConnectGUI[1] = IPAddressBox;
	ConnectGUI[2] = C_PortBox;
	ConnectGUI[3] = Connect;
	ConnectLabels[0] = C_UsernameLabel;
	ConnectLabels[1] = IPAddressLabel;
	ConnectLabels[2] = C_PortLabel;
	
	for(i = 0; i < 4; i++)
	{
		CenterComponent(ConnectGUI[i]);
		
		if(i < 3)
		{
			CenterComponent(ConnectLabels[i]);
		}
	}
	
	HostGUI[0] = H_UsernameBox;
	HostGUI[1] = H_PortBox;
	HostGUI[2] = LevelSelect;
	HostGUI[3] = HostServer;
	HostLabels[0] = H_UsernameLabel;
	HostLabels[1] = H_PortLabel;
	HostLabels[2] = LevelSelectLabel;
	
	for(i = 0; i < 4; i++)
	{
		CenterComponent(HostGUI[i]);
		
		if(i < 3)
		{
			CenterComponent(HostLabels[i]);
		}
	}
	
	SettingsGUI[0] = ProfaneLanguage;
	SettingsGUI[1] = ChatSounds;
	SettingsGUI[2] = GlobalInventory;
	SettingsGUI[3] = MaxPlayers;
	SettingsLabels[0] = ClientSettingsLabel;
	SettingsLabels[1] = ServerSettingsLabel;
	SettingsLabels[2] = ProfaneLanguageLabel;
	SettingsLabels[3] = ChatSoundsLabel;
	SettingsLabels[4] = GlobalInventoryLabel;
	SettingsLabels[5] = MaxPlayersLabel;
	
	for(i = 0; i < 6; i++)
	{
		if(i < 4)
		{
			CenterComponent(SettingsGUI[i]);
		}
		
		CenterComponent(SettingsLabels[i]);
	}
	
	Singleplayer.Caption = lSingleplayer;
	Singleplayer.Hint = lhSingleplayer;
	ConnectTab.Caption = lConnectTab;
	ConnectTab.Hint = lhConnectTab;
	HostTab.Caption = lHostTab;
	HostTab.Hint = lhHostTab;
	SettingsTab.Caption = lSettingsTab;
	SettingsTab.Hint = lhSettingsTab;
	C_UsernameLabel.Caption = l_C_UsernameBox;
	C_UsernameBox.Hint = lh_C_UsernameBox;
	IPAddressLabel.Caption = lIPAddressBox;
	IPAddressBox.Hint = lhIPAddressBox;
	C_PortLabel.Caption = l_C_PortBox;
	C_PortBox.Hint = lh_C_PortBox;
	Connect.Caption = lConnect;
	Connect.Hint = lhConnect;
	H_UsernameLabel.Caption = l_H_UsernameBox;
	H_UsernameBox.Hint = lh_H_UsernameBox;
	H_PortLabel.Caption = l_H_PortBox;
	H_PortBox.Hint = lh_H_PortBox;
	LevelSelectLabel.Caption = lLevelSelect;
	LevelSelect.Edit.Hint = lhLevelSelect;
	HostServer.Caption = lHostServer;
	HostServer.Hint = lhHostServer;
	ClientSettingsLabel.Caption = lClientSettings;
	ServerSettingsLabel.Caption = lServerSettings;
	ProfaneLanguageLabel.Caption = lProfaneLanguage;
	ProfaneLanguage.Hint = lhProfaneLanguage;
	ChatSoundsLabel.Caption = lChatSounds;
	ChatSounds.Hint = lhChatSounds;
	GlobalInventoryLabel.Caption = lGlobalInventory;
	GlobalInventory.Hint = lhGlobalInventory;
	MaxPlayersLabel.Caption = lMaxPlayers;
	MaxPlayers.Hint = lhMaxPlayers;
	
	AvailableMaps.URLs = U.GetAvailableMaps();
	AvailableMaps.sAvailableMaps = MakeReadableMapNames(AvailableMaps.URLs);
	
	for(i = 0; i < AvailableMaps.sAvailableMaps.Length; i++)
	{
		LevelSelect.AddItem(AvailableMaps.sAvailableMaps[i]);
	}
	
	for(i = 0; i < AvailableMaps.sAvailableMaps.Length; i++)
	{
		if(AvailableMaps.sAvailableMaps[i] == "Storybook (1)")
		{
			bFoundFirstMap = true;
			
			iSelectedLevel = i;
			
			break;
		}
	}
	
	ProfaneLanguage.Caption = U.BoolToString(class'S2MConfig'.default.bAllowProfaneLanguage);
	ChatSounds.Caption = U.BoolToString(class'S2MConfig'.default.bPlayChatSound);
	GlobalInventory.Caption = U.BoolToString(class'S2MConfig'.default.bGlobalInventory);
	
	ChangeMenu(CM_Connect);
}

function array<string> MakeReadableMapNames(array<string> Ms)
{
	local int i;
	
	for(i = 0; i < Ms.Length; i++)
	{
		switch(Ms[i])
		{
			case "1_Shreks_Swamp":
				Ms[i] = "Shrek's Swamp";
				
				break;
			case "2_Carriage_Hijack":
				Ms[i] = "Carriage Hijack";
				
				break;
			case "3_The_Hunt_Part1":
				Ms[i] = "Spooky Forest (1)";
				
				break;
			case "3_The_Hunt_Part2":
				Ms[i] = "Spooky Forest (2)";
				
				break;
			case "3_The_Hunt_Part3":
				Ms[i] = "Spooky Forest (3)";
				
				break;
			case "3_The_Hunt_Part4":
				Ms[i] = "Spooky Forest (4)";
				
				break;
			case "4_FGM_Office":
				Ms[i] = "Fairy Godmother's Office (Cutscene)";
				
				break;
			case "4_FGM_PIB":
				Ms[i] = "Fairy Godmother's Laboratory (PIB)";
				
				break;
			case "5_FGM_Donkey":
				Ms[i] = "Fairy Godmother's Laboratory (Donkey)";
				
				break;
			case "6_Hamlet":
				Ms[i] = "Walking The Path (1)";
				
				break;
			case "6_Hamlet_End":
				Ms[i] = "Walking The Path (3)";
				
				break;
			case "6_Hamlet_Mine":
				Ms[i] = "Walking The Path (2)";
				
				break;
			case "7_Prison_Donkey":
				Ms[i] = "Prison Break (Steed)";
				
				break;
			case "8_Prison_PIB":
				Ms[i] = "Prison Break (PIB)";
				
				break;
			case "9_Prison_Shrek":
				Ms[i] = "Prison Break (Shrek)";
				
				break;
			case "10_Castle_Siege":
				Ms[i] = "Castle Siege";
				
				break;
			case "11_FGM_Battle":
				Ms[i] = "Fairy Godmother Battle";
				
				break;
			case "Beanstalk_bonus":
				Ms[i] = "Beanstalk Bonus World #1";
				
				break;
			case "Beanstalk_bonus_dawn":
				Ms[i] = "Beanstalk Bonus World #2";
				
				break;
			case "Beanstalk_bonus_knight":
				Ms[i] = "Beanstalk Bonus World #3";
				
				break;
			case "Book_FrontEnd":
				Ms[i] = "Storybook (Front End)";
				
				break;
			case "Book_Story_1":
				Ms[i] = "Storybook (1)";
				
				break;
			case "Book_Story_2":
				Ms[i] = "Storybook (2)";
				
				break;
			case "Book_Story_3":
				Ms[i] = "Storybook (3)";
				
				break;
			case "Book_Story_4":
				Ms[i] = "Storybook (4)";
				
				break;
			case "Book_StoryBook":
				Ms[i] = "Storybook (Book)";
				
				break;
			case "Credits":
				Ms[i] = "Credits";
				
				break;
			case "Entry":
				Ms[i] = "Entry";
				
				break;
			case "SH2_Preamble":
				Ms[i] = "Shrek 2 Preamble";
				
				break;
			default:
				Ms[i] = "[CUSTOM]" @ Ms[i];
				
				break;
		}
	}
	
	return Ms;
}

function ChangeMenu(ECurrentMenu NewMenu) // Changes the current menu
{
	local int i;
	local bool bShow;
	
	bShow = NewMenu == CM_Connect;
	
	for(i = 0; i < 4; i++)
	{
		ConnectGUI[i].SetVisibility(bShow);
		ConnectGUI[i].bAcceptsInput = bShow;
		ConnectGUI[i].SetFocus(none);
		
		if(i < 3)
		{
			ConnectLabels[i].SetVisibility(bShow);
		}
	}
	
	bShow = NewMenu == CM_Host;
	
	for(i = 0; i < 4; i++)
	{
		HostGUI[i].SetVisibility(bShow);
		HostGUI[i].bAcceptsInput = bShow;
		HostGUI[i].SetFocus(none);
		
		if(i < 3)
		{
			HostLabels[i].SetVisibility(bShow);
		}
	}
	
	bShow = NewMenu == CM_Settings;
	
	for(i = 0; i < 6; i++)
	{
		if(i < 4)
		{
			SettingsGUI[i].SetVisibility(bShow);
			SettingsGUI[i].bAcceptsInput = bShow;
			SettingsGUI[i].SetFocus(none);
		}
		
		SettingsLabels[i].SetVisibility(bShow);
	}
	
	C_UsernameBox.SetText(class'S2MConfig'.default.sUsername);
	H_UsernameBox.SetText(class'S2MConfig'.default.sUsername);
	C_PortBox.SetText(string(class'S2MConfig'.default.iPort));
	H_PortBox.SetText(string(class'S2MConfig'.default.iPort));
	
	CurrentMenu = NewMenu;
}

event bool InternalOnClick(GUIComponent Sender)
{
	super.InternalOnClick(Sender);
	
	switch(Sender)
	{
		case Singleplayer:
			U.UnloadMutators();
			ClosePage();
			
			break;
		case ConnectTab:
			ChangeMenu(CM_Connect);
			
			break;
		case HostTab:
			ChangeMenu(CM_Host);
			
			break;
		case SettingsTab:
			ChangeMenu(CM_Settings);
			
			break;
		case Connect:
			// Run connection logic
			// ...
			
			class'S2MConfig'.default.LoadMode = LM_Connect;
			class'S2MConfig'.static.StaticSaveConfig();
			
			S2MMutator(U.GetMutator(class'S2MMutator')).S2MDA.PreConnectToServer(class'S2MConfig'.default.sIPAddress, class'S2MConfig'.default.iPort);
			
			U.Level.LevelAction = LEVACT_Connecting;
			U.CC("Set HUD ConnectingMessage Connecting to server, connection failed if this message disappears!");
			
			// Wait for external mod to respond
			// ...
			
			SetTimer(7.0, false);
			
			break;
		case HostServer:
			// Run server hosting logic
			// ...
			
			class'S2MConfig'.default.LoadMode = LM_Host;
			class'S2MConfig'.static.StaticSaveConfig();
			
			U.ChangeLevel(AvailableMaps.URLs[iSelectedLevel]);
			ClosePage();
			
			break;
		case ProfaneLanguage:
			class'S2MConfig'.default.bAllowProfaneLanguage = !class'S2MConfig'.default.bAllowProfaneLanguage;
			class'S2MConfig'.static.StaticSaveConfig();
			
			ProfaneLanguage.Caption = U.BoolToString(class'S2MConfig'.default.bAllowProfaneLanguage);
			
			break;
		case ChatSounds:
			class'S2MConfig'.default.bPlayChatSound = !class'S2MConfig'.default.bPlayChatSound;
			class'S2MConfig'.static.StaticSaveConfig();
			
			ChatSounds.Caption = U.BoolToString(class'S2MConfig'.default.bPlayChatSound);
			
			break;
		case GlobalInventory:
			class'S2MConfig'.default.bGlobalInventory = !class'S2MConfig'.default.bGlobalInventory;
			class'S2MConfig'.static.StaticSaveConfig();
			
			GlobalInventory.Caption = U.BoolToString(class'S2MConfig'.default.bGlobalInventory);
			
			break;
		default:
			break;
	}
	
	return true;
}

event Timer()
{
	U.Level.LevelAction = LEVACT_None;
}

event InternalOnChange(GUIComponent Sender)
{
	local int i;
	
	if(!Controller.bCurMenuInitialized)
	{
		return;
	}
	
	switch(Sender)
	{
		case C_UsernameBox:
			class'S2MConfig'.default.sUsername = C_UsernameBox.GetText();
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		case IPAddressBox:
			class'S2MConfig'.default.sIPAddress = IPAddressBox.GetText();
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		case C_PortBox:
			class'S2MConfig'.default.iPort = int(C_PortBox.GetText());
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		case H_UsernameBox:
			class'S2MConfig'.default.sUsername = H_UsernameBox.GetText();
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		case H_PortBox:
			class'S2MConfig'.default.iPort = int(H_PortBox.GetText());
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		case LevelSelect:
			for(i = 0; i < AvailableMaps.sAvailableMaps.Length; i++)
			{
				iSelectedLevel = -1;
				
				if(AvailableMaps.sAvailableMaps[i] == LevelSelect.Edit.GetText())
				{
					iSelectedLevel = i;
					
					break;
				}
			}
			
			break;
		case MaxPlayers:
			class'S2MConfig'.default.iMaxPlayers = int(MaxPlayers.GetText());
			class'S2MConfig'.static.StaticSaveConfig();
			
			break;
		default:
			break;
	}
}

function bool InternalOnKeyType(out byte Key, optional string Unicode)
{
	return false;
}

event InternalOnLoadINI(GUIComponent Sender, string S)
{
	switch(Sender)
	{
		case C_UsernameBox:
			C_UsernameBox.SetText(class'S2MConfig'.default.sUsername);
			
			break;
		case H_UsernameBox:
			H_UsernameBox.SetText(class'S2MConfig'.default.sUsername);
			
			break;
		case IPAddressBox:
			IPAddressBox.SetText(class'S2MConfig'.default.sIPAddress);
			
			break;
		case C_PortBox:
			C_PortBox.SetText(string(class'S2MConfig'.default.iPort));
			
			break;
		case H_PortBox:
			H_PortBox.SetText(string(class'S2MConfig'.default.iPort));
			
			break;
		case LevelSelect:
			LevelSelect.SetText(AvailableMaps.sAvailableMaps[iSelectedLevel]);
			
			break;
		case MaxPlayers:
			MaxPlayers.SetText(string(class'S2MConfig'.default.iMaxPlayers));
			
			break;
		default:
			break;
	}
}

event string InternalOnSaveINI(GUIComponent Sender) // Only here to prevent throwing an error
{
	return "";
}


defaultproperties
{
	Begin Object Name=btnSingleplayer0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.75
		WinLeft=0.15
		WinWidth=0.12
		WinHeight=0.1
		OnClick=InternalOnClick
	End Object
	Singleplayer=btnSingleplayer0
	Begin Object Name=btnConnectTab0 Class=GUIButton
		StyleName="SHOptionLabel"
		bNeverFocus=true
		WinTop=0.1
		WinLeft=0.42
		WinWidth=0.08
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	ConnectTab=btnConnectTab0
	Begin Object Name=btnHostTab0 Class=GUIButton
		StyleName="SHOptionLabel"
		bNeverFocus=true
		WinTop=0.1
		WinLeft=0.5
		WinWidth=0.08
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	HostTab=btnHostTab0
	Begin Object Name=btnSettingsTab0 Class=GUIButton
		StyleName="SHOptionLabel"
		bNeverFocus=true
		WinTop=0.1
		WinLeft=0.58
		WinWidth=0.08
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	SettingsTab=btnSettingsTab0
	Begin Object Name=ebUsername0 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=20
		IniOption="@INTERNAL"
		WinTop=0.4
		WinLeft=0.5
		WinWidth=0.3
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	C_UsernameBox=ebUsername0
	Begin Object Name=lblUsername0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.35
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
	End Object
	C_UsernameLabel=lblUsername0
	Begin Object Name=ebIPAddress0 Class=GUIEditBox
		StyleName="SHSolidBox"
		bFloatOnly=true
		IniOption="@INTERNAL"
		WinTop=0.5
		WinLeft=0.4
		WinWidth=0.2
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	IPAddressBox=ebIPAddress0
	Begin Object Name=lblIPAddress0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.45
		WinLeft=0.4
		WinWidth=0.2
		WinHeight=0.05
	End Object
	IPAddressLabel=lblIPAddress0
	Begin Object Name=ebPort0 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=5
		bIntOnly=true
		IniOption="@INTERNAL"
		WinTop=0.5
		WinLeft=0.6
		WinWidth=0.2
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	C_PortBox=ebPort0
	Begin Object Name=lblPort0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.45
		WinLeft=0.6
		WinWidth=0.2
		WinHeight=0.05
	End Object
	C_PortLabel=lblPort0
	Begin Object Name=btnConnect0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.6
		WinLeft=0.5
		WinWidth=0.1
		WinHeight=0.1
		OnClick=InternalOnClick
	End Object
	Connect=btnConnect0
	Begin Object Name=ebUsername1 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=20
		IniOption="@INTERNAL"
		WinTop=0.4
		WinLeft=0.5
		WinWidth=0.3
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	H_UsernameBox=ebUsername1
	Begin Object Name=lblUsername1 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.35
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
	End Object
	H_UsernameLabel=lblUsername1
	Begin Object Name=ebPort1 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=5
		bIntOnly=true
		IniOption="@INTERNAL"
		WinTop=0.5
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	H_PortBox=ebPort1
	Begin Object Name=lblPort1 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.45
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
	End Object
	H_PortLabel=lblPort1
	Begin Object Name=cbLevelSelect0 Class=SHGUIComboBox
		StyleName="SHSolidBox"
		bNeverFocus=true
		bReadOnly=true
		bShowListOnFocus=true
		IniOption="@INTERNAL"
		IniDefault="Storybook (1)"
		WinTop=0.6
		WinLeft=0.44
		WinWidth=0.4
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	LevelSelect=cbLevelSelect0
	Begin Object Name=lblLevelSelect0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.55
		WinLeft=0.44
		WinWidth=0.2
		WinHeight=0.05
	End Object
	LevelSelectLabel=lblLevelSelect0
	Begin Object Name=btnHostServer0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.6
		WinLeft=0.7
		WinWidth=0.1
		WinHeight=0.1
		OnClick=InternalOnClick
	End Object
	HostServer=btnHostServer0
	Begin Object Name=lblClientSettings0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.3
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
	End Object
	ClientSettingsLabel=lblClientSettings0
	Begin Object Name=lblServerSettings0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.5
		WinLeft=0.5
		WinWidth=0.2
		WinHeight=0.05
	End Object
	ServerSettingsLabel=lblServerSettings0
	Begin Object Name=btnProfaneLanguage0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.4
		WinLeft=0.4
		WinWidth=0.1
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	ProfaneLanguage=btnProfaneLanguage0
	Begin Object Name=lblProfaneLanguage0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.35
		WinLeft=0.4
		WinWidth=0.2
		WinHeight=0.05
	End Object
	ProfaneLanguageLabel=lblProfaneLanguage0
	Begin Object Name=btnChatSounds0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.4
		WinLeft=0.6
		WinWidth=0.1
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	ChatSounds=btnChatSounds0
	Begin Object Name=lblChatSounds0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.35
		WinLeft=0.6
		WinWidth=0.2
		WinHeight=0.05
	End Object
	ChatSoundsLabel=lblChatSounds0
	Begin Object Name=btnGlobalInventory0 Class=GUIButton
		StyleName="SHSolidBox"
		bNeverFocus=true
		WinTop=0.6
		WinLeft=0.4
		WinWidth=0.1
		WinHeight=0.05
		OnClick=InternalOnClick
	End Object
	GlobalInventory=btnGlobalInventory0
	Begin Object Name=lblGlobalInventory0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.55
		WinLeft=0.4
		WinWidth=0.2
		WinHeight=0.05
	End Object
	GlobalInventoryLabel=lblGlobalInventory0
	Begin Object Name=ebMaxPlayers0 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=3
		bIntOnly=true
		IniOption="@INTERNAL"
		WinTop=0.6
		WinLeft=0.6
		WinWidth=0.2
		WinHeight=0.05
		OnClick=InternalOnClick
		OnChange=InternalOnChange
		OnKeyType=InternalOnKeyType
		OnLoadINI=InternalOnLoadINI
		OnSaveINI=InternalOnSaveINI
	End Object
	MaxPlayers=ebMaxPlayers0
	Begin Object Name=lblMaxPlayers0 Class=GUILabel
		StyleName="SHSolidBox"
		TextAlign=TXTA_Center
		WinTop=0.55
		WinLeft=0.6
		WinWidth=0.2
		WinHeight=0.05
	End Object
	MaxPlayersLabel=lblMaxPlayers0
	bEscapeClosesPage=false
}