// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MChatPage extends MGUIPage
	Config(S2Multi);


var automated config GUIEditBox ChatBox;
var automated config GUIImage ChatBoxBackground;


event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.InitComponent(MyController, MyOwner);
	
	__OnKeyEvent__Delegate = InternalOnKeyEvent;
	__OnKeyType__Delegate = InternalOnKeyType;
	
	TabFooter.WinLeft = 0.493;
	TabFooter.WinTop = 0.9;
	
	CenterComponent(TabFooter);
}

event bool InternalOnKeyType(out byte Key, optional string Unicode)
{
	return false;
}

event bool InternalOnKeyEvent(out byte Key, out byte State, float Delta)
{
	if(Key == 13) // Enter
	{
		SendChatMessage(ChatBox.GetText());
		
		ClosePage();
	}
	
	return super.InternalOnKeyEvent(Key, State, Delta);
}

event InternalOnChange(GUIComponent Sender)
{
	if(!Controller.bCurMenuInitialized)
	{
		return;
	}
	
	switch(Sender)
	{
		case ChatBox:
		default:
			break;
	}
}

function SendChatMessage(string sMessage)
{
	S2MHUDItem_Chat(U.GetHudItems()[U.IsHUDItemLoaded(class'S2MHUDItem_Chat')]).CreateChatMessage(S2MMutator(U.GetMutator(class'S2MMutator')).S2MDA.GetHPPacket().Username, sMessage);
	
	S2MMutator(U.GetMutator(class'S2MMutator')).S2MDA.FireClientEvent("Chat#" $ S2MMutator(U.GetMutator(class'S2MMutator')).S2MDA.GetHPPacket().Username $ "#" $ sMessage);
}


defaultproperties
{
	Begin Object Name=ebChat0 Class=GUIEditBox
		StyleName="SHSolidBox"
		MaxWidth=250
		IniOption="@INTERNAL"
		IniDefault=""
		WinTop=0.605
		WinLeft=0.005
		WinWidth=0.25
		WinHeight=0.06
		OnKeyType=InternalOnKeyType
		OnChange=InternalOnChange
	End Object
	ChatBox=ebChat0
	Begin Object Name=imgChatBoxBackground0 Class=GUIImage
		Image=Texture'storybookanimTX.full_options_button'
		ImageStyle=ISTY_Scaled
		bNeverFocus=true
		WinTop=0.605
		WinLeft=0.005
		WinWidth=0.25
		WinHeight=0.06
	End Object
	ChatBoxBackground=imgChatBoxBackground0
}