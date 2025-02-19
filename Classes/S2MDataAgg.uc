// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************
// 
// Gamerule support -- [Difficulty: 3/5] Add support for adding gamerules to a server, that of which can enforce certain character types, maximum player caps, etc..
// Inventory support -- [Difficulty: 3/5] When a client picks up an item, it should be given to everyone (configurable, on by default).
// Level transfer support -- [Difficulty: 5/5] Add support for transferring a server across levels.
// Save support -- [Difficulty: 3.5/5] Replace save fairy mechanics with a co-op friendly method that doesn't involve using the original save system.
// Enemy support -- [Difficulty: 6/5] Add support for enemies to target specific players. Unsure if the original enemy system is capable of this modification in real-time. Will need plenty of testing.
// Spectating support -- [Difficulty: 5/5] Add support for players to toggle between spectating and playing.


class S2MDataAgg extends MInfo
	Config(S2Multi);


const ClientSpawnAttempts = 100;					// Default in MUtils is 25, increased to 100 due to the importance of this working.
const MissingLevelPacketIDRadiusCheckSize = 125.0f;	// Unsure if this is necessary any longer.

struct LevelPacketStruct
{
	var Actor ID;			// The actor pointer.
	var vector Location;	// The location of the actor.
	var rotator Rotation;	// The rotation of the actor.
	var float Health;		// The health of the actor.
	var name Anim, State;	// The current animation and state of the actor.
};

struct PlayersPacketStruct
{
	var Actor ID;			// The actor pointer.
	var string Username;	// The name of the client.
	var bool bHost;			// If true, this player packet is the host.
};

struct TranslateStruct
{
	var string HostPtr, ClientPtr;	// The string-casted actor pointers across games.
};

var protected array<LevelPacketStruct> InitServerLevelPacket, ClientLevelPacket, ServerLevelPacket;
var protected array<PlayersPacketStruct> InitServerPlayersPacket, ServerPlayersPacket, ClientPlayersPacket;
var protected array<string> Events;
var protected array<TranslateStruct> Translators;
var protected array<Actor> IgnoreIDBuffer;
var protected vector vWorldSpawn;
var protected rotator rWorldSpawn;
var protected S2MGameRules GR;	// Handle this later, not relevant yet.
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
	
	// Loading a save breaks a lot of stuff, abort everything.
	if(bLoadFromSaveGame)
	{
		Destroy();
		
		return;
	}
	
	// Initialize game rules.
	// We're not using game rules yet, but might as well leave this in for now.
	
	foreach AllActors(class'S2MGameRules', tGR)
	{
		break;
	}
	
	if(tGR == none)
	{
		GR = Spawn(class'S2MGameRules');
	}
	
	// Calculate world spawn.
	
	// This isn't a good way to determine the world spawn for stock levels, but should be perfect for modded levels.
	vWorldSpawn = U.GetHP().Location;
	rWorldSpawn = U.GetHP().Rotation;
	
	bLevelLoaded = true;
}

// Starts a server.
function StartServer(int Port)
{
	// Add ourselves onto the client packet list.
	ClientPlayersPacket.Insert(ClientPlayersPacket.Length, 1);
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].Username = class'S2MConfig'.default.sUsername;
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID = U.GetHP();

	// Whoever started the server is automatically the host, for obvious reasons.
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].bHost = true;
	
	UpdateClientPlayersPacket();
	
	// Create the initialization packet so that others connecting will be properly initialized.
	InitServerLevelPacket = InitHost();
	InitServerPlayersPacket = ClientPlayersPacket;
	
	UpdateInitServerLevelPacket();
	UpdateInitServerPlayersPacket();
	
	FireClientEvent("Start" @ string(Port)); // External
	
	class'S2MVersion'.static.DebugLog("Initialization packet created by" @ GetHPPacket().Username $ ".");
	class'S2MVersion'.static.DebugLog("Server starting up...");

	// This is the point where we'd initialize the gamerule logic. I'm not going to do that yet, since it's currently irrelevant.
	// class'S2MVersion'.static.DebugLog("Initializing gamerules...");
	
	bServerStarted = true;
}

// Stops the server if it's the host.
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

// Prepares connecting to a server.
function PreConnectToServer(string IP, int Port)
{
	FireClientEvent("Connect" @ IP @ string(Port)); // External
	
	class'S2MVersion'.static.DebugLog("Initiating server connection, awaiting response...");
}

// Connects to a server.
function ConnectToServer()
{
	local array<string> Ds;
	
	class'S2MVersion'.static.DebugLog("Response received, connection being established...");
	
	// Initialize provided server player packet.
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
	
	if(Ds.Length > 0)
	{
		ServerPlayersPacket = FormatStringPlayersPacket(Ds);
		
		// Handle server player packet.
	}
	else
	{
		class'S2MVersion'.static.DebugLog("Initialization client packet is empty, this is about to get bad!");
	}
	
	// Prepare a new client player packet.
	ClientPlayersPacket.Insert(ClientPlayersPacket.Length, 1);
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].Username = class'S2MConfig'.default.sUsername;
	ClientPlayersPacket[ClientPlayersPacket.Length - 1].ID = U.GetHP();
	
	UpdateClientPlayersPacket();
	
	// Initialize provided server level packet.
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
	
	if(Ds.Length > 0)
	{
		ServerLevelPacket = FormatStringLevelPacket(Ds);
		
		// Handle server level packet.
	}
	else
	{
		class'S2MVersion'.static.DebugLog("Initialization server packet is empty, this could be bad.");
	}
	
	class'S2MVersion'.static.DebugLog("Client connected to host:" @ GetHostPacket().Username);
	
	// This is the point where we'd initialize the gamerule logic. I'm not going to do that yet, since it's currently irrelevant.
	// class'S2MVersion'.static.DebugLog("Initializing gamerules...");
	
	bServerStarted = true;
}

// Prepares disconnecting from the server.
function PreDisconnectFromServer()
{
	FireClientEvent("Disconnect"); // External
	
	class'S2MVersion'.static.DebugLog("Disconnecting client...");
}

// Disconnects from the server.
function DisconnectFromServer()
{
	bServerStarted = false;
	
	class'S2MVersion'.static.DebugLog("Disconnected client.");
	
	U.ChangeLevel(class'SHFEGUIPage'.default.FEMenuLevel);
}

// Updates the init server level packet. Expensive.
function UpdateInitServerLevelPacket()
{
	U.SaveStringArray(FormatLevelPacket(InitServerLevelPacket), "..\\System\\S2Multi\\InitServerLevel.S2M");
	
	class'S2MVersion'.static.DebugLog("Server level initialization packet updated.");
}

// Updates the init server player packet. Expensive.
function UpdateInitServerPlayersPacket()
{
	U.SaveStringArray(FormatPlayersPacket(InitServerPlayersPacket), "..\\System\\S2Multi\\InitServerPlayers.S2M");
	
	class'S2MVersion'.static.DebugLog("Server players initialization packet updated.");
}

// Updates the client player packet. Expensive.
function UpdateClientPlayersPacket()
{
	U.SaveStringArray(FormatPlayersPacket(ClientPlayersPacket), "..\\System\\S2Multi\\ClientPlayers.S2M");
	
	class'S2MVersion'.static.DebugLog("Client players packet updated.");
}

// Returns the current player's packet.
function PlayersPacketStruct GetHPPacket()
{
	local int i;
	
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

// Returns the current host's packet.
function PlayersPacketStruct GetHostPacket()
{
	local int i;
	
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
	local int i, j;
	local array<string> Ps;
	
	if(!bLevelLoaded)
	{
		return;
	}
	
	// Handle all events.
	
	HP = U.GetHP();
	
	Events = GetEvents();
	ProcessEvents();
	
	if(!bServerStarted)
	{
		UpdateEvents(Events);
		
		return;
	}
	
	// Handle packets.
	
	// Update the client level packet if anything changes, plus translate this packet to the host.
	Ps = FormatLevelPacket(GetClientLevelPacket());

	// This is probably expensive with high translator counts, but how else would you do this?
	for(i = 0; i < Translators.Length; i++)
	{
		for(j = 0; i < Ps.Length; i++)
		{
			if(InStr(Ps[j], Translators[i].ClientPtr) != -1)
			{
				ReplaceText(Ps[j], Translators[i].ClientPtr, Translators[i].HostPtr);

				break;
			}
		}
	}

	U.SaveStringArray(Ps, "..\\System\\S2Multi\\ClientLevel.S2M");
	
	ClearIgnoreIDBuffer();
	
	// See if the server has any new level data sent to the client.
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received level data packet with a size of" @ string(Ds.Length) @ "from server, replicating packet to client...");
			
			ServerLevelPacket = FormatStringLevelPacket(Ds);
			
			// React to server level packet being received.
			
			// Replicate new packet data to client.
			for(i = 0; i < ServerLevelPacket.Length; i++)
			{
				AddIgnoreIDBuffer(ServerLevelPacket[i].ID);
				
				if(ServerLevelPacket[i].ID == HP)
				{
					continue;
				}
				
				U.MFancySetLocation(ServerLevelPacket[i].ID, ServerLevelPacket[i].Location);
				U.FancySetRotation(ServerLevelPacket[i].ID, ServerLevelPacket[i].Rotation);
				U.SetHealth(Pawn(ServerLevelPacket[i].ID), ServerLevelPacket[i].Health, true);
				ServerLevelPacket[i].ID.LoopAnim(ServerLevelPacket[i].Anim);
				ServerLevelPacket[i].ID.GotoState(ServerLevelPacket[i].State);
			}
			
			// Empty server packet for client (performance reasons).
			ServerLevelPacket.Remove(0, ServerLevelPacket.Length);
			
			// Adding line break so that the file is able to be saved, since it uses CR LF formatting.
			Ds.Remove(0, Ds.Length);
			Ds.Insert(0, 1);
			
			U.SaveStringArray(Ds, "..\\System\\S2Multi\\ServerLevel.S2M");
		}
	}
	
	// See if the server has any new player data sent to the client.
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
	
	if(Ds.Length > 0)
	{
		if(Ds[0] != "")
		{
			class'S2MVersion'.static.DebugLog("Received player data packet with a size of" @ string(Ds.Length) @ "from server, replicating packet to client...");
			
			ServerPlayersPacket = FormatStringPlayersPacket(Ds);
			InitServerPlayersPacket = ServerPlayersPacket;

			UpdateInitServerPlayersPacket();
			
			// React to server player packet being received.
			
			// Replicate new packet data to client.
			
			// for(i = 0; i < ServerPlayersPacket.Length; i++)
			// {
			// 	
			// }
			
			// Empty server packet for client (performance reasons).
			ServerPlayersPacket.Remove(0, ServerPlayersPacket.Length);
			
			// Adding line break so that the file is able to be saved, since it uses CR LF formatting.
			Ds.Remove(0, Ds.Length);
			Ds.Insert(0, 1);
			
			U.SaveStringArray(Ds, "..\\System\\S2Multi\\ServerPlayers.S2M");
		}
	}
	
	// Handle player touching logic.
	for(i = 0; i < InitServerPlayersPacket.Length; i++)
	{
		foreach InitServerPlayersPacket[i].ID.TouchingActors(class'Actor', A)
		{
			A.Touch(HP);
		}
	}
	
	UpdateEvents(Events);
}

// Reads the init server level external file. Expensive.
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

// Reads the init server player external file. Expensive.
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

// Creates a new player client at world spawn.
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
	
	// Don't send this data over since it's irrelevant to every other client.
	AddIgnoreIDBuffer(A);
	
	return A;
}

// Disables movement logic for other players in the server, except for the client. For replication.
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

// Adds an actor into the "ignore ID buffer." For the tick the actor is in this buffer, it will not be considered a change to others.
function AddIgnoreIDBuffer(Actor A)
{
	IgnoreIDBuffer.Insert(IgnoreIDBuffer.Length, 1);
	IgnoreIDBuffer[IgnoreIDBuffer.Length - 1] = A;
}

// Returns true if the provided actor is inside the "ignore ID buffer."
function bool CompareIgnoreIDBuffer(Actor A)
{
	local int i;
	
	for(i = 0; i < IgnoreIDBuffer.Length; i++)
	{
		if(IgnoreIDBuffer[i] == A)
		{
			return true;
		}
	}
	
	return false;
}

// Clears the "ignore ID buffer."
function ClearIgnoreIDBuffer()
{
	IgnoreIDBuffer.Remove(0, IgnoreIDBuffer.Length);
}

// Processes all input events, which are denoted via "!".
function ProcessEvents()
{
	local int i, j;
	local array<string> TokenArray;
	local array<LevelPacketStruct> Ps;
	local bool B;
	
	if(Events.Length > 0)
	{
		// Handle server events.
		
		if(Events[0] == "")
		{
			return;
		}
		
		for(i = 0; i < Events.Length; i++)
		{
			// Make sure we only process an event if it is specified as an input event (with "!").
			if(Left(Events[i], 1) != "!" || Events[i] == "")
			{
				continue;
			}
			
			// Logging hack.
			if(!B)
			{
				class'S2MVersion'.static.DebugLog("Received" @ string(Events.Length) @ "events from server, processing events now...");
				
				B = true;
			}
			
			// Remove the "!" from the beginning of the event input string.
			Events[i] = Mid(Events[i], 1);
			
			class'S2MVersion'.static.DebugLog("Firing event:" @ Events[i]);
			
			TokenArray = U.Split(Events[i], "#");
			
			// List of all possible events, plus functionality
			switch(Caps(TokenArray[0]))
			{
				case "CONNECTED": // External
					// Runs code related to connecting.
					ConnectToServer();
				case "CLIENTCONNECTED": // External
					// Acts as if a client has connected.
					ReadInitServerLevel();
					ReadInitServerPlayers();
					DisableMovementForOtherPlayers();
					
					break;
				case "DISCONNECTED": // External
					// Disconnects from the server.
					DisconnectFromServer();
					
					break;
				case "UPDATEINIT": // External
					// Updates both external init files at once. Expensive.
					UpdateInitServerLevelPacket();
					UpdateInitServerPlayersPacket();
					
					break;
				case "HOST_CREATE": // External
					// Avert your eyes everyone :D
					// Creates an actor on the host.
					TokenArray.Remove(0, 1);

					InitServerLevelPacket.Insert(InitServerLevelPacket.Length, 1);
					InitServerLevelPacket[InitServerLevelPacket.Length - 1] = FormatStringLevelPacket(TokenArray)[0];

					break;
				case "CLIENT_CREATE": // External
					// Avert your eyes everyone :D
					// Creates an actor on the client, assumes the given actor pointer exists on the host, remembers to translate the data when needed, then spawns in the actor.
					TokenArray.Remove(0, 1);

					Ps = FormatStringLevelPacket(TokenArray);

					InitServerLevelPacket.Insert(InitServerLevelPacket.Length, 1);
					InitServerLevelPacket[InitServerLevelPacket.Length - 1] = Ps[0];

					Ps[0].ID = SmartSpawn(StringActorPointerToClass(TokenArray[0]));

					Translators.Insert(Translators.Length, 1);
					Translators[Translators.Length - 1].HostPtr = TokenArray[0];
					Translators[Translators.Length - 1].ClientPtr = string(Ps[0].ID);

					break;
				case "HOST_DESTROY": // External
					// Destroys an actor on the host. Expensive.
					U.FancyDestroy(Actor(FindObject(TokenArray[1], class'Actor')));

					ReadInitServerLevel();

					break;
				case "CLIENT_DESTROY": // External
					// Destroys an actor on the client, after translating what the pointer would normally be for the client. Expensive.
					for(j = 0; j < Translators.Length; j++)
					{
						if(InStr(TokenArray[1], Translators[j].ClientPtr) != -1)
						{
							ReplaceText(TokenArray[1], Translators[j].ClientPtr, Translators[j].HostPtr);

							break;
						}
					}

					U.FancyDestroy(Actor(FindObject(TokenArray[1], class'Actor')));

					UpdateInitServerLevelPacket();

					break;
				case "CHANGELEVEL":
					// Changes the level.
					U.ChangeLevel(TokenArray[1]);
					
					Events.Remove(i, 1);
					
					return;
				case "CHAT":
					// Types in the chat.
					HudItems = U.GetHudItems();
					
					// Client-sided chat censor logic.
					if(!class'S2MConfig'.default.bAllowProfaneLanguage)
					{
						if(class'S2MProfaneWords'.static.IsProfane(TokenArray[2]))
						{
							TokenArray[2] = "^1[Censored]";
						}
					}
					
					// Looks complicated, but we're calling the dynamic HUD item that is our chat, then displaying the chat message provided.
					S2MHUDItem_Chat(HudItems[U.IsHUDItemLoaded(class'S2MHUDItem_Chat')]).CreateChatMessage(TokenArray[1], TokenArray[2]);
					
					break;
				case "GCC":
					// Runs a console command.
					U.CC(TokenArray[1]);
					
					break;
				default:
					break;
			}
			
			// If the client event was processed by the server, erase the client event.
			Events.Remove(i, 1);
			
			i--;
		}
	}
}

// Fires an event out from the client.
function FireClientEvent(string sEvent)
{
	local array<string> Ds;
	local int i;
	
	Ds = GetEvents();
	
	// Remove empty spaces in event data file. This is necessary for CR LF formatting!
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

// Updates the external events file. This is expensive.
function UpdateEvents(array<string> Ds)
{
	if(Ds.Length == 0)
	{
		// Adding line break so that the file is able to be saved, since it uses CR LF formatting. Important!
		Ds.Insert(0, 1);
	}
	
	U.SaveStringArray(Ds, "..\\System\\S2Multi\\Events.S2M");
}

// Reads the external events file. This is expensive.
function array<string> GetEvents()
{
	local array<string> Ds;
	
	U.LoadStringArray(Ds, "..\\System\\S2Multi\\Events.S2M");
	
	return Ds;
}

// Initialize the host's level packet.
function array<LevelPacketStruct> InitHost()
{
	local array<Actor> As;
	local Mover M;
	local TimedCue TC;
	local Pawn P;
	local Pickup PU;
	local Trigger T;
	
	// Get all relevant actor pointers.
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
		// Prevents camera locking.
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
	
	// Format the packet with the data acquired.
	return GetRelevantData(As);
}

// Get the client level packet, which tracks everything that is changing each tick, and also fires external events each time an actor spawns or despawns.
function array<LevelPacketStruct> GetClientLevelPacket()
{
	local array<Actor> As;
	local Mover M;
	local TimedCue TC;
	local Pawn P;
	local Pickup PU;
	local Trigger T;
	local array<LevelPacketStruct> Ps, RPs;
	local int i, j;
	local bool bFound;
	
	// Get all current relevant actor pointers.
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
		// Prevents camera locking.
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

	// Extract and format the relevant data from the actor's indexed into a packet.
	Ps = GetRelevantData(As);
	
	// Scrape the packet for changes from the initialization packet.
	for(i = 0; i < InitServerLevelPacket.Length; i++)
	{
		// Destroy check.
		if(InitServerLevelPacket[i].ID == none)
		{
			// Actor was destroyed.
			if(GetHostPacket().bHost)
			{
				FireClientEvent("HOST_DESTROY" @ FormatSingleLevelPacket(InitServerLevelPacket[i]));
			}
			else
			{
				FireClientEvent("CLIENT_DESTROY" @ FormatSingleLevelPacket(InitServerLevelPacket[i]));
			}

			InitServerLevelPacket.Remove(i, 1);

			i--;

			continue;
		}
	}
	
	for(i = 0; i < Ps.Length; i++)
	{	
		// Differ check, big performance hit, I think?
		for(j = 0; j < InitServerLevelPacket.Length; j++)
		{
			if(Ps[i].ID == InitServerLevelPacket[j].ID)
			{
				bFound = true;

				// Actor packet still remains when compared to InitServerLevelPacket.
				// Does it differ?
				if(Ps[i] != InitServerLevelPacket[j])
				{
					// Yes it does, write that difference.
					RPs.Insert(RPs.Length, 1);
					RPs[RPs.Length - 1] = InitServerLevelPacket[j];
				}
				
				break;
			}
		}

		if(!bFound)
		{
			// Actor is being spawned.
			if(GetHostPacket().bHost)
			{
				FireClientEvent("HOST_CREATE" @ FormatSingleLevelPacket(Ps[i]));
			}
			else
			{
				FireClientEvent("CLIENT_CREATE" @ FormatSingleLevelPacket(Ps[i]));
			}
		}
	}
	
	return RPs;
}

// Returns an array of level packets from an array of actors. It's basically extracting necessary data from the actors to then get ported to a level packet format.
function array<LevelPacketStruct> GetRelevantData(array<Actor> As)
{
	local array<LevelPacketStruct> Ps;
	local int i, i1;
	local name Anim;
	local float F, Health;
	local Actor A;
	
	for(i = 0; i < As.Length; i++)
	{
		// In theory this should improve performance since it reduces index calls?
		A = As[i];
		
		if(A.Mesh != none)
		{
			// Figure out what animation is (likely) visually showing and use that.
			// ~+1 MS since it does a lot of looping.
			// !? Maybe there's a way to optimize this.
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
			// This function call is expensive if the pawn is not a KWPawn.
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

// Converts an array of level packets to string form, for the external file.
function array<string> FormatLevelPacket(array<LevelPacketStruct> Ps)
{
	local array<string> Ds;
	local int i;
	
	for(i = 0; i < Ps.Length; i++)
	{
		// Make sure that any packet being formatted into a level packet originally had a valid ID. If it does not, then we need to not make a level packet with that data, since it would otherwise cause an infinite loop
		if(CompareIgnoreIDBuffer(Ps[i].ID))
		{
			continue;
		}
		
		Ds.Insert(Ds.Length, 1);
		Ds[Ds.Length - 1] = string(Ps[i].ID) $ "#" $ string(Ps[i].Location) $ "#" $ string(Ps[i].Rotation) $ "#" $ string(Ps[i].Health) $ "#" $ string(Ps[i].Anim) $ "#" $ string(Ps[i].State);
	}
	
	return Ds;
}

// Converts a single level packet to string form, for the external file.
function string FormatSingleLevelPacket(LevelPacketStruct Ps)
{
	// Make sure that any packet being formatted into a level packet originally had a valid ID. If it does not, then we need to not make a level packet with that data, since it would otherwise cause an infinite loop
	if(CompareIgnoreIDBuffer(Ps.ID))
	{
		return "";
	}
	
	return string(Ps.ID) $ "#" $ string(Ps.Location) $ "#" $ string(Ps.Rotation) $ "#" $ string(Ps.Health) $ "#" $ string(Ps.Anim) $ "#" $ string(Ps.State);
}

// Converts an array of player packets to string form, for the external file.
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

// Converts an array of level packets in string form back into their original form.
function array<LevelPacketStruct> FormatStringLevelPacket(array<string> Ds)
{
	local array<LevelPacketStruct> Ps;
	local array<string> TokenArray;
	local int i, j;
	local bool bTranslated;
	
	for(i = 0; i < Ds.Length; i++)
	{
		Ps.Insert(Ps.Length, 1);
		
		bTranslated = false;

		TokenArray = U.Split(Ds[i], "#");
		
		if(TokenArray.Length != 7)
		{
			class'S2MVersion'.static.DebugLog("Level data packet is not formatted correctly, prepare for issues...");
		}
		
		// Confirm actor ID is present for client.
		Ps[i].ID = Actor(FindObject(TokenArray[0], class'Actor'));

		// This block of code is responsible for dynamically spawning actors if needed.
		if(Ps[i].ID == none)
		{
			if(!GetHPPacket().bHost)
			{
				// Check to see if we've seen a pointer come from the host that needed translation.
				for(j = 0; j < Translators.Length; j++)
				{
					if(Translators[j].HostPtr == TokenArray[0])
					{
						// If we're here, we've previously dealt with this pointer, so let's translate it! :D
						Ps[i].ID = Actor(FindObject(Translators[j].ClientPtr, class'Actor'));

						bTranslated = true;

						if(Ps[i].ID == none)
						{
							class'S2MVersion'.static.DebugLog("A translation error in interpreting a level data packet failed, minor issues will occur!");
						}

						break;
					}
				}
			}
			else
			{
				class'S2MVersion'.static.DebugLog("Received a packet as the host that somehow has an invalid ID, this could be fatal!");
			}

			if(!bTranslated)
			{
				class'S2MVersion'.static.DebugLog("Received an unknown level data packet, ignoring...");

				continue;
			}
		}
		
		Ps[i].Location = vector(TokenArray[1]);
		Ps[i].Rotation = rotator(TokenArray[2]);
		Ps[i].Health = float(TokenArray[3]);
		Ps[i].Anim = U.SName(TokenArray[4]);
		Ps[i].State = U.SName(TokenArray[5]);
	}
	
	return Ps;
}

// Takes an actor pointer in string form and a level packet, then returns an actor if any actor near where the actor string pointer was supposed to be is there.
function Actor MissingLevelPacketID(string ID, LevelPacketStruct Ps)
{
	local Actor A;
	local name nClass;
	local array<string> TokenArray;

	// !? This logic might be unnecessary, unsure.
	
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

// Converts a string containing an actor pointer to a class.
function class<Actor> StringActorPointerToClass(string sPointer)
{
	local string S;
	local array<string> TokenArray;
	
	TokenArray = U.Split(sPointer, ".");
	
	S = TokenArray[1];
	
	// Get rid of any numbers in the actor pointer.
	while(U.IsNumeric(Right(S, 1)))
	{
		S = Left(S, Len(S) - 1);
	}
	
	SetPropertyText("tClass", S);
	
	return tClass;
}

// Tries to spawn in an actor in any location possible.
function Actor SmartSpawn(class<Actor> C)
{
	local Actor A;
	local Light L;
	local bool bReturn;
	
	// Get a location that has a good chance of having a lot of open space. I know this is hacky, but how else can you actually do this?
	foreach AllActors(class'Light', L)
	{
		bReturn = U.MFancySpawn(C, L.Location,, A);

		break;
	}

	if(!bReturn)
	{
		bReturn = U.MFancySpawn(C, vWorldSpawn,, A);

		if(!bReturn)
		{
			return none;
		}
	}
	
	if(A.IsA('KWPawn'))
	{
		U.GivePawnController(KWPawn(A));
	}
	
	return A;
}

// Converts an array of player packets in string form back into their original form.
function array<PlayersPacketStruct> FormatStringPlayersPacket(array<string> Ds)
{
	local array<PlayersPacketStruct> Ps;
	local array<string> TokenArray;
	local int i, j;
	local bool bTranslated;
	
	for(i = 0; i < Ds.Length; i++)
	{
		Ps.Insert(Ps.Length, 1);
		
		TokenArray = U.Split(Ds[i], "#");
		
		if(TokenArray.Length != 3)
		{
			class'S2MVersion'.static.DebugLog("Player data packet is not formatted correctly, issues may arise...");
		}

		// Confirm actor ID is present for client.
		Ps[i].ID = Actor(FindObject(TokenArray[0], class'Actor'));

		// This block of code is responsible for dynamically spawning actors if needed.
		if(Ps[i].ID == none)
		{
			if(!GetHPPacket().bHost)
			{
				// Check to see if we've seen a pointer come from the host that needed translation.
				for(j = 0; j < Translators.Length; j++)
				{
					if(Translators[j].HostPtr == TokenArray[0])
					{
						// If we're here, we've previously dealt with this pointer, so let's translate it! :D
						Ps[i].ID = Actor(FindObject(Translators[j].ClientPtr, class'Actor'));

						bTranslated = true;

						if(Ps[i].ID == none)
						{
							class'S2MVersion'.static.DebugLog("A translation error in interpreting a player data packet failed, minor issues will occur!");
						}

						break;
					}
				}
			}
			else
			{
				class'S2MVersion'.static.DebugLog("Received a packet as the host that somehow has an invalid ID, this could be fatal!");
			}

			if(!bTranslated)
			{
				class'S2MVersion'.static.DebugLog("Received an unknown player data packet, ignoring...");

				continue;
			}
		}
		
		Ps[i].ID = Actor(FindObject(TokenArray[0], class'Actor'));
		Ps[i].Username = TokenArray[1];
		Ps[i].bHost = bool(TokenArray[2]);
	}
	
	return Ps;
}

// A simple translation debug function that may be helpful to some.
function TranslatorDebug()
{
	local int i;

	for(i = 0; i < Translators.Length; i++)
	{
		class'S2MVersion'.static.DebugLog("Translator" @ string(i) $ ": Host is" @ Translators[i].HostPtr $ ", client is" @ Translators[i].ClientPtr);
	}
}


defaultproperties
{
	bStatic=false
}