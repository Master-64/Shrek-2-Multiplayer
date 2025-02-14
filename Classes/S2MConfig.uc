// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MConfig extends MInfo
	Config(S2Multi);


enum ELoadMode
{
	LM_None,
	LM_Host,
	LM_Connect
};

var config ELoadMode LoadMode;

// Client Config
var config string sUsername;
var config bool bAllowProfaneLanguage, bPlayChatSound;
var config Sound ChatSound;

// Server Config
var config string sIPAddress;
var config bool bGlobalInventory;
var config int iPort, iMaxPlayers;


defaultproperties
{
	sUsername="Unknown Player"
	bAllowProfaneLanguage=true
	bPlayChatSound=true
	ChatSound=Sound'UI.PotionUI_coin_countdown'
	sIPAddress="127.0.0.1"
	iPort=6400
	bGlobalInventory=true
	iMaxPlayers=64
}