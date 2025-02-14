// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************
// 
// * Destruction support -- [Difficulty: 2/5] When an actor is destroyed on any client, make sure it is destroyed for everyone else
// * Disable client controller(s) -- [Difficulty: 2.5/5] Make sure other players cannot automatically run logic on their own from another client's perspective
// * Global console commands -- [Difficulty: 1/5] Add support for a chat command that can run a console command across all clients
// * No pausing -- [Difficulty: 1/5] Make sure the game is unable to pause. This should be the case, as it's a live server
// * Touch support -- [Difficulty: 2/5] When a client touches any important actor, make sure that code is ran for everyone else
// * Frontend interface -- [Difficulty: 5/5] For making creating and joining servers as easy as possible. This would be any and every sort of GUI to handle information, plus distributing that information both internally and externally
// Gamerule support -- [Difficulty: 3/5] Add support for adding gamerules to a server, that of which can enforce certain character types, maximum player caps, etc.. This would require both internal and external support
// Inventory support -- [Difficulty: 3/5] When a client picks up an item, it should be given to everyone (configurable, on by default)
// Level transfer support -- [Difficulty: 5/5] Add support for transferring a server across levels
// Save support
// Enemy support -- [Difficulty: 6/5] Add support for enemies to target specific players. Will require either a full enemy re-code, or something very hacky
// Spectating support -- [Difficulty: ?/5] Add support for players to toggle between spectating and playing
// 
// Bugs:
// Spawn logic doesn't work without looping


class S2MDataAgg extends MInfo
	Config(S2Multi);


const ClientSpawnAttempts = 100;					// Default in MUtils is 25, increasing to 100 due to the importance of this working
const MissingLevelPacketIDRadiusCheckSize = 125.0f;	// This could break replication if the value is set too high, deals with packet loss and guessing/recovering lost packets

struct LevelPacketStruct
{
	var Actor ID;			// Only relevant to client, do not replicate unless init packet
	var vector Location;	// The location of the actor
	var rotator Rotation;	// The rotation of the actor
	var float Health;		// The health of the actor
	var name Anim, State;	// The current animation of the actor, and the current state of the actor
	var bool bDestructive;	// If true, this packet is requesting to destroy its ID
};

struct PlayersPacketStruct
{
	var Actor ID;			// Only relevant to client, do not replicate unless init packet
	var string Username;	// The name of the client
	var bool bHost;			// If true, this player packet is the host
};

var protected array<LevelPacketStruct> InitServerLevelPacket, ClientLevelPacket, ServerLevelPacket;
var protected array<PlayersPacketStruct> InitServerPlayersPacket, ServerPlayersPacket, ClientPlayersPacket;
var protected array<string> Events;
var protected array<Actor> MissingIDBuffer;
var protected vector vWorldSpawn;
var protected rotator rWorldSpawn;
var protected S2MGameRules GR;	// Handle this later, not relevant yet
var protected int iOldPlayerPacketLength, iPlayerPacketLength, iSimilarActorPacketCheckRadius;
var protected travel bool bServerStarted;
var protected bool bLevelLoaded;
var class<Actor> tClass;


event PostBeginPlay()
{
	super.PostBeginPlay();
}

event PostLoadGame(bool bLoadFromSaveGame)
{
	local S2MGameRules tGR;
	
	// Loading a save breaks a lot of stuff, abort everything
	if(bLoadFromSaveGame)
	{
		Destroy();
		
		return;
	}
	
	// Initialize game rules
	// ...
	
	foreach AllActors(class'S2MGameRules', tGR)
	{
		break;
	}
	
	if(tGR == none)
	{
		GR = Spawn(class'S2MGameRules');
	}
	
	// Calculate world spawn
	// ...
	
	// This isn't a good way to do this, but for now, it'll work
	vWorldSpawn = U.GetHP().Location;
	rWorldSpawn = U.GetHP().Rotation;
	
	bLevelLoaded = true;
}

function StartServer(int Port)
{
	// Add ourselves onto the client packet list
	ClientPlayersPacket.Insert(ClientPlayersPacket.Length, 1);
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].Username = class'S2MConfig'.default.sUsername;
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID = U.GetHP();
	// Whoever started the server is automatically the host, for obvious reasons
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].bHost = true;
	
	UpdateClientPlayersPacket();
	
	// Create the initialization packet so that others connecting will be properly initialized
	InitServerLevelPacket = InitHost();
	InitServerPlayersPacket = ClientPlayersPacket;
	
	UpdateInitServerLevelPacket();
	UpdateInitServerPlayersPacket();
	
	FireClientEvent("Start" @ string(Port)); // External
	
	class'S2MVersion'.static.DebugLog("Initialization packet created by" @ GetHPPacket().Username);
	class'S2MVersion'.static.DebugLog("Server starting up...");
	
	bServerStarted = true;
}

function StopServer()
{
	if(!GetHPPacket().bHost)
	{
		class'S2MVersion'.static.DebugLog("Can't terminate a server you aren't hosting.");
		
		return;
	}
	
	FireClientEvent("Disconnect"); // External
	FireClientEvent("Stop"); // External
	
	class'S2MVersion'.static.DebugLog("Terminating server...");
}

function PreConnectToServer(string IP, int Port)
{
	FireClientEvent("Connect" @ IP @ string(Port)); // External
	
	class'S2MVersion'.static.DebugLog("Initiating server connection, awaiting response...");
}

function ConnectToServer()
{
	local array<string> Ds;
	
	class'S2MVersion'.static.DebugLog("Response received, connection being established...");
	
	// Initialize provided server player packet
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
	
	if(Ds.Length > 0)
	{
		ServerPlayersPacket = FormatStringPlayersPacket(Ds);
		
		// Handle server packet
		// ...
	}
	else
	{
		class'S2MVersion'.static.DebugLog("Initialization client packet is empty, this is about to get bad!");
	}
	
	ClientPlayersPacket.Insert(ClientPlayersPacket.Length, 1);
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].Username = class'S2MConfig'.default.sUsername;
	// Since any new client will always require a new physical player, we create a new player and switch the control of the client HP to the new spawned client
	// This change will be reflected for all other clients
	// Make sure this is customizable later on!
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID = CreateNewClient(class'Shrek');
	
	// If applicable, make the newly-connected client assume control of the newly-spawned player pawn
	if(ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID != U.GetHP() && U.GetHP().IsA('KWPawn'))
	{
		// This might be too hacky to include for long?
		ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID.Tag = ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID.Name;
		ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID.SetPropertyText("Label", string(ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID.Name));
		
		KWPawn(U.GetHP()).SwitchControlToPawn(ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID.GetPropertyText("Label"));
	}
	
	UpdateClientPlayersPacket();
	
	// Initialize provided server level packet
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
	
	if(Ds.Length > 0)
	{
		ServerLevelPacket = FormatStringLevelPacket(Ds);
		
		// Handle server packet
		// ...
	}
	else
	{
		class'S2MVersion'.static.DebugLog("Initialization server packet is empty, this could be bad.");
	}
	
	class'S2MVersion'.static.DebugLog("Client connected to host:" @ GetHostPacket().Username);
	
	// This is the point where we'd initialize the gamerule logic
	// I'm not going to do that yet, since it's currently not relevant
	// class'S2MVersion'.static.DebugLog("Initializing gamerules...");
	
	bServerStarted = true;
}

function PreDisconnectFromServer()
{
	FireClientEvent("Disconnect"); // External
	
	class'S2MVersion'.static.DebugLog("Disconnecting client...");
}

function DisconnectFromServer()
{
	bServerStarted = false;
	
	class'S2MVersion'.static.DebugLog("Disconnected client");
	
	U.ChangeLevel(class'SHFEGUIPage'.default.FEMenuLevel);
}

function UpdateInitServerLevelPacket() // Expensive function to update the initialization server packet
{
	U.SaveStringArray(FormatLevelPacket(InitServerLevelPacket), "..\\System\\S2Multi\\InitServerLevel.S2M");
	
	class'S2MVersion'.static.DebugLog("Server level initialization packet updated");
}

function UpdateInitServerPlayersPacket() // (potentially) Expensive function to update the initialization client packet
{
	U.SaveStringArray(FormatPlayersPacket(InitServerPlayersPacket), "..\\System\\S2Multi\\InitServerPlayers.S2M");
	
	class'S2MVersion'.static.DebugLog("Server players initialization packet updated");
}

function UpdateClientPlayersPacket()
{
	U.SaveStringArray(FormatPlayersPacket(ClientPlayersPacket), "..\\System\\S2Multi\\ClientPlayers.S2M");
	
	class'S2MVersion'.static.DebugLog("Client players packet updated");
}

function PlayersPacketStruct GetHPPacket()
{
	local int i;
	
	ReadInitServerPlayers();
	
	HP = U.GetHP();
	
	for(i = 0; i < InitServerPlayersPacket.Length; i++)
	{
		if(InitServerPlayersPacket[i].ID == HP)
		{
			return InitServerPlayersPacket[i];
		}
	}
	
	class'S2MVersion'.static.DebugLog("Failed to get HP packet, things are about to get really bad!");
}

function PlayersPacketStruct GetHostPacket()
{
	local int i;
	
	ReadInitServerPlayers();
	
	for(i = 0; i < InitServerPlayersPacket.Length; i++)
	{
		if(InitServerPlayersPacket[i].bHost)
		{
			return InitServerPlayersPacket[i];
		}
	}
	
	class'S2MVersion'.static.DebugLog("Failed to get host packet, things are about to get really bad!");
}

event Destroyed()
{
	class'S2MVersion'.static.DebugLog("Data aggregator destroyed, disconnecting client!");
	
	PreDisconnectFromServer();
	UpdateEvents(Events);
	
	super.Destroyed();
}

event Tick(float DeltaTime)
{
	local array<string> Ds;
	local Actor A;
	local int i;
	
	if(!bLevelLoaded)
	{
		return;
	}
	
	// Handle all events
	// ...
	
	HP = U.GetHP();
	
	Events = GetEvents();
	ProcessEvents();
	
	if(!bServerStarted)
	{
		UpdateEvents(Events);
		
		return;
	}
	
	// Handle packets
	// ...
	
	// Update the client level packet if anything changes
	U.SaveStringArray(FormatLevelPacket(GetClientLevelPacket()), "..\\System\\S2Multi\\ClientLevel.S2M");
	
	ClearMissingIDBuffer();
	
	// See if the server has any new level data sent to the client
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received level data packet with a size of" @ string(Ds.Length) @ "from server, replicating packet to client...");
			
			ServerLevelPacket = FormatStringLevelPacket(Ds);
			
			// React to server level packet being received
			// ...
			
			// Replicate new packet data to client
			for(i = 0; i < ServerLevelPacket.Length; i++)
			{
				AddMissingIDBuffer(ServerLevelPacket[i].ID);
				
				if(ServerLevelPacket[i].ID == HP)
				{
					continue;
				}

				if(ServerLevelPacket[i].bDestructive)
				{
					U.FancyDestroy(ServerLevelPacket[i].ID);

					continue;
				}
				
				U.MFancySetLocation(ServerLevelPacket[i].ID, ServerLevelPacket[i].Location);
				U.FancySetRotation(ServerLevelPacket[i].ID, ServerLevelPacket[i].Rotation);
				U.SetHealth(Pawn(ServerLevelPacket[i].ID), ServerLevelPacket[i].Health, true);
				ServerLevelPacket[i].ID.LoopAnim(ServerLevelPacket[i].Anim);
				ServerLevelPacket[i].ID.GotoState(ServerLevelPacket[i].State);
			}
			
			// Empty server packet for client (performance reasons)
			ServerLevelPacket.Remove(0, ServerLevelPacket.Length);
			
			// Adding line break so that the file is able to be saved, since it uses CR LF formatting
			Ds.Remove(0, Ds.Length);
			Ds.Insert(0, 1);
			
			U.SaveStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
		}
	}
	
	// See if the server has any new player data sent to the client
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received player data packet with a size of" @ string(Ds.Length) @ "from server, replicating packet to client...");
			
			ServerPlayersPacket = FormatStringPlayersPacket(Ds);
			
			// React to server player packet being received
			// ...
			
			// Replicate new packet data to client
			// ...
			
			for(i = 0; i < ServerPlayersPacket.Length; i++)
			{
				if(ServerPlayersPacket[i].ID == none)
				{
					// Create new client since the client doesn't physically exist for this client yet
					// ...
					
					// Make sure this is customizable later on!
					ServerPlayersPacket[i].ID = CreateNewClient(class'Shrek');
				}
			}
			
			// Empty server packet for client (performance reasons)
			ServerPlayersPacket.Remove(0, ServerPlayersPacket.Length);
			
			// Adding line break so that the file is able to be saved, since it uses CR LF formatting
			Ds.Remove(0, Ds.Length);
			Ds.Insert(0, 1);
			
			U.SaveStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
		}
	}
	
	// Handle player touching logic
	// ...
	
	for(i = 0; i < InitServerPlayersPacket.Length; i++)
	{
		foreach InitServerPlayersPacket[i].ID.TouchingActors(class'Actor', A)
		{
			A.Touch(HP);
		}
	}
	
	UpdateEvents(Events);
}

function ReadInitServerLevel()
{
	local array<string> Ds;
	
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\InitServerLevel.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received init level data packet with a size of" @ string(Ds.Length) @ "from server, reading in...");
			
			InitServerLevelPacket = FormatStringLevelPacket(Ds);
		}
	}
}

function ReadInitServerPlayers()
{
	local array<string> Ds;
	
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\InitServerPlayers.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received init player data packet with a size of" @ string(Ds.Length) @ "from server, reading in...");
			
			InitServerPlayersPacket = FormatStringPlayersPacket(Ds);
		}
	}
}

function Actor CreateNewClient(class<Actor> C)
{
	local Actor A;
	
	if(!U.MFancySpawn(C, vWorldSpawn, rWorldSpawn, A, ClientSpawnAttempts))
	{
		return none;
	}
	
	if(A.IsA('KWPawn'))
	{
		U.GivePawnController(KWPawn(A));
	}
	
	// Don't send this data over since it's irrelevant to every other client
	AddMissingIDBuffer(A);
	
	return A;
}

function DisableMovementForOtherPlayers()
{
	local int i;
	
	ReadInitServerPlayers();
	
	HP = U.GetHP();
	
	for(i = 0; i < InitServerPlayersPacket.Length; i++)
	{
		if(InitServerPlayersPacket[i].ID != HP)
		{
			Pawn(InitServerPlayersPacket[i].ID).UnPossessed();
		}
	}
}

function AddMissingIDBuffer(Actor A) // Should probably rename this
{
	MissingIDBuffer.Insert(MissingIDBuffer.Length, 1);
	MissingIDBuffer[MissingIDBuffer.Length - 1] = A;
}

function bool CheckMissingIDBuffer(Actor A)
{
	local int i;
	
	for(i = 0; i < MissingIDBuffer.Length; i++)
	{
		if(MissingIDBuffer[i] == A)
		{
			return true;
		}
	}
	
	return false;
}

function ClearMissingIDBuffer()
{
	MissingIDBuffer.Remove(0, MissingIDBuffer.Length);
}

function ProcessEvents()
{
	local int i;
	local array<string> TokenArray;
	local bool B;
	
	if(Events.Length > 0)
	{
		// Handle server events
		// ...
		
		if(Events[0] == "")
		{
			return;
		}
		
		for(i = 0; i < Events.Length; i++)
		{
			if(Left(Events[i], 1) != "!" || Events[i] == "")
			{
				continue;
			}
			
			if(!B)
			{
				class'S2MVersion'.static.DebugLog("Received" @ string(Events.Length) @ "events from server, processing events now...");
				
				B = true;
			}
			
			Events[i] = Mid(Events[i], 1);
			
			class'S2MVersion'.static.DebugLog("Event:" @ Events[i]);
			
			TokenArray = U.Split(Events[i], "#");
			
			// List of all possible events, plus functionality
			switch(Caps(TokenArray[0]))
			{
				case "CONNECTED": // External
					ConnectToServer();
				case "CLIENTCONNECTED": // External
					ReadInitServerLevel();
					ReadInitServerPlayers();
					DisableMovementForOtherPlayers();
					
					break;
				case "DISCONNECTED": // External
					DisconnectFromServer();
					
					break;
				case "UPDATEINIT": // External
					UpdateInitServerLevelPacket();
					UpdateInitServerPlayersPacket();
					
					break;
				case "CHANGELEVEL":
					U.ChangeLevel(Mid(Events[i], Len(TokenArray[0]) + 1));
					
					Events.Remove(i, 1);
					
					return;
				case "CHAT":
					HudItems = U.GetHudItems();
					
					if(!class'S2MConfig'.default.bAllowProfaneLanguage)
					{
						if(class'S2MProfaneWords'.static.IsProfane(Mid(Events[i], Len(TokenArray[0]) + Len(TokenArray[1]) + 2)))
						{
							S2MHUDItem_Chat(HudItems[U.IsHUDItemLoaded(class'S2MHUDItem_Chat')]).CreateChatMessage(TokenArray[1], "^1[Censored]");
							
							break;
						}
					}
					
					S2MHUDItem_Chat(HudItems[U.IsHUDItemLoaded(class'S2MHUDItem_Chat')]).CreateChatMessage(TokenArray[1], Mid(Events[i], Len(TokenArray[0]) + Len(TokenArray[1]) + 2));
					
					break;
				case "GCC":
					U.CC(Mid(Events[i], Len(TokenArray[0]) + 1));
					
					break;
				default:
					break;
			}
			
			// If the client event was processed by the server, erase the client event
			Events.Remove(i, 1);
			
			i--;
		}
	}
}

function FireClientEvent(string sEvent)
{
	local array<string> Ds;
	local int i;
	
	Ds = GetEvents();
	
	// Remove empty spaces in event data file
	for(i = 0; i < Ds.Length; i++)
	{
		if(Ds[i] == "")
		{
			Ds.Remove(Max(i - 1, 0), 1);
			
			i--;
		}
	}
	
	Ds.Insert(Ds.Length, 1);
	Ds[Ds.Length - 1] = "#" $ sEvent;
	
	UpdateEvents(Ds);
}

function UpdateEvents(array<string> Ds)
{
	if(Ds.Length == 0)
	{
		// Adding line break so that the file is able to be saved, since it uses CR LF formatting
		Ds.Insert(0, 1);
	}
	
	U.SaveStringArray(Ds, "..\\System\\S2Multi\\Events.S2M");
}

function array<string> GetEvents()
{
	local array<string> Ds;
	
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\Events.S2M");
	
	return Ds;
}

function array<LevelPacketStruct> InitHost() // Initialize the host's packet
{
	local array<Actor> As;
	local Mover M;
	local TimedCue TC;
	local Pawn P;
	local Pickup PU;
	local Trigger T;
	
	// Get all relevant actor pointers
	foreach DynamicActors(class'Mover', M)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = M;
	}
	
	foreach DynamicActors(class'Trigger', T)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = T;
	}
	
	foreach DynamicActors(class'Pawn', P)
	{
		// Prevents camera locking
		if(P.IsA('BaseCam') || P.IsA('BaseCamTarget'))
		{
			continue;
		}
		
		As.Insert(As.Length, 1);
		As[As.Length - 1] = P;
	}
	
	foreach DynamicActors(class'Pickup', PU)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = PU;
	}
	
	foreach DynamicActors(class'TimedCue', TC)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = TC;
	}
	
	// Format the packet with the data acquired
	return GetRelevantData(As);
}

function array<LevelPacketStruct> GetClientLevelPacket() // Get the client level packet
{
	local array<Actor> As;
	local Mover M;
	local TimedCue TC;
	local Pawn P;
	local Pickup PU;
	local Trigger T;
	local array<LevelPacketStruct> Ps, RPs;
	local int i, j;
	local array<byte> bFound;
	
	// Get all relevant actor pointers
	foreach DynamicActors(class'Mover', M)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = M;
	}
	
	foreach DynamicActors(class'Trigger', T)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = T;
	}
	
	foreach DynamicActors(class'Pawn', P)
	{
		// Prevents camera locking
		if(P.IsA('BaseCam') || P.IsA('BaseCamTarget'))
		{
			continue;
		}
		
		As.Insert(As.Length, 1);
		As[As.Length - 1] = P;
	}
	
	foreach DynamicActors(class'Pickup', PU)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = PU;
	}
	
	foreach DynamicActors(class'TimedCue', TC)
	{
		As.Insert(As.Length, 1);
		As[As.Length - 1] = TC;
	}

	// Extract and format the relevant data from the actor's indexed into a packet
	Ps = GetRelevantData(As);
	
	// Don't check far around in packets if not much has changed, this impacts performance hard at high values
	iSimilarActorPacketCheckRadius = Max(Abs(InitServerLevelPacket.Length - Ps.Length), 1);
	
	bFound.Insert(0, Max(InitServerLevelPacket.Length, Ps.Length));
	
	// Scrape the packet for changes from the initialization packet
	for(i = 0; i < InitServerLevelPacket.Length; i++)
	{
		// Destroy check
		if(InitServerLevelPacket[i].ID == none)
		{
			// Actor was destroyed
			InitServerLevelPacket[i].bDestructive = true;
			
			RPs.Insert(RPs.Length, 1);
			RPs[RPs.Length - 1] = InitServerLevelPacket[i];
			
			// I think this is bad to add
			// bFound[i] = 1;
			
			continue;
		}
		
		// Differ check
		for(j = Max(i - iSimilarActorPacketCheckRadius, 0); j < Min(i + iSimilarActorPacketCheckRadius, Ps.Length); j++)
		{
			if(InitServerLevelPacket[i].ID == Ps[j].ID)
			{
				bFound[i] = 2;
				
				// Actor packet still remains when compared to InitServerLevelPacket
				// Does it differ?
				
				if(InitServerLevelPacket[i] != Ps[j])
				{
					// Yes it does, write that difference
					RPs.Insert(RPs.Length, 1);
					RPs[RPs.Length - 1] = Ps[j];
				}
				
				// No it does not
				
				break;
			}
		}
		
		// 0 == NULL
		// 1 == False
		// 2 == True
		if(bFound[i] == 0)
		{
			bFound[i] = 1;
		}
	}
	
	return RPs;
	
	// !? Spawn check, causing memory leak AAAAAAAAAAAAAAAAAAAA
	for(j = 0; j < Max(InitServerLevelPacket.Length, Ps.Length); j++)
	{
		if(bFound[j] == 1)
		{
			// For performance sake, this condition is being split
			if(Ps[j].ID != none)
			{
				// Actor spawned in
				RPs.Insert(RPs.Length, 1);
				RPs[RPs.Length - 1] = Ps[j];
				
				// This is the memory leak, it constantly keeps adding onto the init level packet. Happens once I pickup a coin and keeps adding by 1 infinitely
				// This makes the iteration count go up infinitely, eventually causing the game to lag too much
				InitServerLevelPacket.Insert(InitServerLevelPacket.Length, 1);
				InitServerLevelPacket[InitServerLevelPacket.Length - 1] = Ps[j];
				Log(string(Ps[j].ID));
				Log(string(InitServerLevelPacket.Length));
			}
		}
	}
	
	return RPs;
}

function array<LevelPacketStruct> GetRelevantData(array<Actor> As)
{
	local array<LevelPacketStruct> Ps;
	local int i, i1;
	local name Anim;
	local float F, Health;
	local Actor A;
	
	for(i = 0; i < As.Length; i++)
	{
		// In theory this should improve performance since it reduces index calls
		A = As[i];
		
		if(A.Mesh != none)
		{
			// Figure out what animation is visually showing and use that
			// ~+1 MS since it does a lot of looping
			Anim = 'None';
			
			for(i1 = 14; i1 > -1; i1--)
			{
				A.GetAnimParams(i1, Anim, F, F);
				
				if(Anim != 'None')
				{
					break;
				}
			}
		}
		
		if(A.IsA('Pawn'))
		{
			// This function call is expensive if the pawn is not a KWPawn
			Health = U.GetHealth(Pawn(A));
		}
		else
		{
			Health = 0.0;
		}
		
		Ps.Insert(Ps.Length, 1);
		Ps[i].ID = A;
		Ps[i].Location = A.Location;
		Ps[i].Rotation = A.Rotation;
		Ps[i].Health = Health;
		Ps[i].Anim = Anim;
		Ps[i].State = A.GetStateName();
	}
	
	return Ps;
}

function array<string> FormatLevelPacket(array<LevelPacketStruct> Ps)
{
	local array<string> Ds;
	local int i;
	
	for(i = 0; i < Ps.Length; i++)
	{
		// Make sure that any packet being formatted into a level packet originally had a valid ID
		// If it does not, then we need to not make a level packet with that data, since it would otherwise cause an infinite loop
		if(CheckMissingIDBuffer(Ps[i].ID))
		{
			continue;
		}
		
		Ds.Insert(Ds.Length, 1);
		Ds[Ds.Length - 1] = string(Ps[i].ID) $ "#" $ string(Ps[i].Location) $ "#" $ string(Ps[i].Rotation) $ "#" $ string(Ps[i].Health) $ "#" $ string(Ps[i].Anim) $ "#" $ string(Ps[i].State) $ "#" $ U.BoolToString(Ps[i].bDestructive);
	}
	
	return Ds;
}

function array<string> FormatPlayersPacket(array<PlayersPacketStruct> Ps)
{
	local array<string> Ds;
	local int i;
	
	for(i = 0; i < Ps.Length; i++)
	{
		Ds.Insert(Ds.Length, 1);
		Ds[Ds.Length - 1] = string(Ps[i].ID) $ "#" $ Ps[i].Username $ "#" $ U.BoolToString(Ps[i].bHost);
	}
	
	return Ds;
}

function array<LevelPacketStruct> FormatStringLevelPacket(array<string> Ds)
{
	local array<LevelPacketStruct> Ps;
	local array<string> TokenArray;
	local int i;
	
	for(i = 0; i < Ds.Length; i++)
	{
		Ps.Insert(Ps.Length, 1);
		
		TokenArray = U.Split(Ds[i], "#");
		
		if(TokenArray.Length != 7)
		{
			class'S2MVersion'.static.DebugLog("Level data packet is not formatted correctly, prepare for issues...");
		}
		
		Ps[i].ID = Actor(FindObject(TokenArray[0], class'Actor'));
		
		// Confirm actor ID is present for client
		// ...
		
		if(Ps[i].ID == none)
		{
			// The actor pointers don't line up, do your best to find something similar!
			Ps[i].ID = MissingLevelPacketID(TokenArray[0], Ps[i]);
			
			if(Ps[i].ID != none)
			{
				// Similar actor found
				AddMissingIDBuffer(Ps[i].ID);
				
				class'S2MVersion'.static.DebugLog("Missing actor ID in level packet. Similar actor nearby, assuming it's the same, might cause issues...");
			}
			else
			{
				// Okay, we didn't find any similar actors, now
				// we need to physically spawn a new actor in
				
				// Ps[i].ID = SmartSpawn(StringActorPointerToClass(TokenArray[0]));
				// AddMissingIDBuffer(Ps[i].ID);
				
				// class'S2MVersion'.static.DebugLog("Missing actor ID in level packet. Spawning in new actor for client, may cause minor temporary displacement or actor duplication...");
			}
		}
		
		Ps[i].Location = vector(TokenArray[1]);
		Ps[i].Rotation = rotator(TokenArray[2]);
		Ps[i].Health = float(TokenArray[3]);
		Ps[i].Anim = U.SName(TokenArray[4]);
		Ps[i].State = U.SName(TokenArray[5]);
		Ps[i].bDestructive = bool(TokenArray[6]);
	}
	
	return Ps;
}

function Actor MissingLevelPacketID(string ID, LevelPacketStruct Ps)
{
	local Actor A;
	local name nClass;
	local array<string> TokenArray;
	
	TokenArray = U.Split(ID, ".");
	
	if(TokenArray.Length == 2)
	{
		nClass = U.SName(string(StringActorPointerToClass(TokenArray[1])));
	}
	else
	{
		nClass = U.SName(string(StringActorPointerToClass(TokenArray[0])));
	}
	
	foreach RadiusActors(class'Actor', A, MissingLevelPacketIDRadiusCheckSize, Ps.Location)
	{
		if(A.IsA(nClass))
		{
			return A;
		}
	}
}

function class<Actor> StringActorPointerToClass(string sPointer)
{
	local string S;
	local array<string> TokenArray;
	
	TokenArray = U.Split(sPointer, ".");
	
	S = TokenArray[1];
	
	// Get rid of any numbers in the actor pointer
	while(U.IsNumeric(Right(S, 1)))
	{
		S = Left(S, Len(S) - 1);
	}
	
	SetPropertyText("tClass", S);
	
	return tClass;
}

function Actor SmartSpawn(class<Actor> C)
{
	local Actor A;
	local Light L;
	local vector vSpawnLocation;
	
	// Get a location that has a good chance of having a lot of open space
	foreach AllActors(class'Light', L)
	{
		break;
	}
	
	if(L == none)
	{
		vSpawnLocation = L.Location;
	}
	else
	{
		vSpawnLocation = vWorldSpawn;
	}
	
	if(!U.MFancySpawn(C, vSpawnLocation,, A))
	{
		return none;
	}
	
	if(A.IsA('KWPawn'))
	{
		U.GivePawnController(KWPawn(A));
	}
	
	return A;
}

function array<PlayersPacketStruct> FormatStringPlayersPacket(array<string> Ds)
{
	local array<PlayersPacketStruct> Ps;
	local array<string> TokenArray;
	local int i;
	
	for(i = 0; i < Ds.Length; i++)
	{
		Ps.Insert(Ps.Length, 1);
		
		TokenArray = U.Split(Ds[i], "#");
		
		if(TokenArray.Length != 3)
		{
			class'S2MVersion'.static.DebugLog("Player data packet is not formatted correctly, issues may arise...");
		}
		
		Ps[i].ID = Actor(FindObject(TokenArray[0], class'Actor'));
		Ps[i].Username = TokenArray[1];
		Ps[i].bHost = bool(TokenArray[2]);
	}
	
	return Ps;
}


defaultproperties
{
	bStatic=false
}