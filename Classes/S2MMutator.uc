// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MMutator extends MMutator
	Config(S2Multi);


var S2MDataAgg S2MDA;
var private bool bIsInMainMenu, bNeedToReloadMultiplayerPage;
var private SHMenuBook Book;


event PostLoadGame(bool bLoadFromSaveGame)
{
	local string FEMenuLevel;
	local int i;
	
	PC = U.GetPC();
	
	FEMenuLevel = Caps(class'SHFEGUIPage'.default.FEMenuLevel);
	
	i = InStr(FEMenuLevel, ".UNR");
	
	if(i > -1)
	{
		FEMenuLevel = Left(FEMenuLevel, i);
	}
	
	bIsInMainMenu = FEMenuLevel == Caps(U.GetCurrentMap());
	
	if(bLoadFromSaveGame)
	{
		U.UnloadMutators(FEMenuLevel);
		
		return;
	}
	
	// Initialize multiplayer logic
	U.CC("GSpyLite");
	class'S2MVersion'.static.DebugLog("Initializing external mod");
	
	S2MDA = Spawn(class'S2MDataAgg');
	class'S2MVersion'.static.DebugLog("Initializing data aggregator");
	
	U.LoadHUDItem(class'S2MHUDItem_Chat');
	
	if(bIsInMainMenu)
	{
		foreach AllActors(class'SHMenuBook', Book)
		{
			break;
		}
		
		class'S2MConfig'.default.LoadMode = LM_None;
		class'S2MConfig'.static.StaticSaveConfig();
	}
	
	Level.PauseDelay = U.GetMaxFloat();
	
	// Initialize data aggregator logic
	// ...
	
	switch(class'S2MConfig'.default.LoadMode)
	{
		case LM_None:
			break;
		case LM_Host:
			S2MDA.StartServer(class'S2MConfig'.default.iPort);
			
			break;
		case LM_Connect:
			S2MDA.PreConnectToServer(class'S2MConfig'.default.sIPAddress, class'S2MConfig'.default.iPort);
			
			break;
		default:
			break;
	}
	
	class'S2MConfig'.default.LoadMode = LM_None;
	class'S2MConfig'.static.StaticSaveConfig();
}

event ServerTraveling(string URL, bool bItems)
{
	S2MDA.FireClientEvent("ChangeLevel" @ URL);
	
	super.ServerTraveling(URL, bItems);
}

event Tick(float DeltaTime)
{
	if(!bIsInMainMenu)
	{
		if(U.IM.IsKeyInAction(84, 1)) // T
		{
			PC.Player.GUIController.ReplaceMenu("S2Multi.S2MChatPage");
		}
	}
	else if(bNeedToReloadMultiplayerPage)
	{
		if(IsMainMenuCutsceneFinished())
		{
			PC.Player.GUIController.CloseMenu();
			PC.Player.GUIController.ReplaceMenu("S2Multi.S2MMultiplayerPage");
			
			bNeedToReloadMultiplayerPage = false;
		}
	}
}

function bool IsMainMenuCutsceneFinished()
{
	return Book.GetAnimSequence(20) == 'Page1turnedStatic' || Book.GetAnimSequence(21) == 'Page1turnedStatic';
}


defaultproperties
{
	bAlwaysTick=true
	bNeedToReloadMultiplayerPage=true
}