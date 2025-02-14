// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MVersion extends MInfo
	Config(S2Multi);


var() string Version;
var() string ModName;
var() bool bDebugEnabled;


static function DebugLog(string S)
{
	if(default.bDebugEnabled)
	{
		Log(class'S2MVersion'.default.ModName @ class'S2MVersion'.default.Version @ "--" @ S);
	}
}


defaultproperties
{
	Version="v1.5 Alpha"
	ModName="S2M"
	bDebugEnabled=true
}