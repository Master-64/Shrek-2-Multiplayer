// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MGameRules extends MInfo
	Config(S2Multi);


var() array< class<Actor> > AllowedPlayerClasses;
var() bool bAllowDuplicatePlayers;
var() int iMaxPlayers;


defaultproperties
{
	bAllowDuplicatePlayers=true
	iMaxPlayers=64
}