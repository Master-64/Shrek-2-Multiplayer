// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MProfaneWords extends MInfo
	Config(S2Multi);


var() array<string> ProfaneWords;


static function bool IsProfane(string S)
{
	local int i;
	
	S = class'MUtils'.static.AlphaNumeric(Caps(S));
	
	for(i = 0; i < default.ProfaneWords.Length; i++)
	{
		if(InStr("" @ S @ "", "" @ default.ProfaneWords[i] @ "") > -1)
		{
			return true;
		}
	}
	
	return false;
}



// Many offensive words below!!
// Don't read the list if you're easily offended.
// Only common swear word terms are used, loopholes can easily be made.
// I do not condone the usage of the words or phrases in the list.
// You have been warned!






































defaultproperties
{
	ProfaneWords(0)="Arse"
	ProfaneWords(1)="Arsin"
	ProfaneWords(2)="Arsing"
	ProfaneWords(3)="Arsed"
	ProfaneWords(4)="Arses"
	ProfaneWords(5)="Arsehead"
	ProfaneWords(6)="Arseheads"
	ProfaneWords(7)="Arsehole"
	ProfaneWords(8)="Arseholes"
	ProfaneWords(9)="Ass"
	ProfaneWords(10)="Asses"
	ProfaneWords(11)="Asshole"
	ProfaneWords(12)="Assholes"
	ProfaneWords(13)="Bastard"
	ProfaneWords(14)="Bastards"
	ProfaneWords(15)="Bitch"
	ProfaneWords(16)="Bitchin"
	ProfaneWords(17)="Bitching"
	ProfaneWords(18)="Bitches"
	ProfaneWords(19)="Blyat"
	ProfaneWords(20)="Bullshit"
	ProfaneWords(21)="Bullshittin"
	ProfaneWords(22)="Bullshitting"
	ProfaneWords(23)="Cock"
	ProfaneWords(24)="Cockin"
	ProfaneWords(25)="Cocking"
	ProfaneWords(26)="Cocked"
	ProfaneWords(27)="Cocker"
	ProfaneWords(28)="Cockers"
	ProfaneWords(29)="Cocks"
	ProfaneWords(30)="Cocksucker"
	ProfaneWords(31)="Cocksuckers"
	ProfaneWords(32)="Crap"
	ProfaneWords(33)="Crappin"
	ProfaneWords(34)="Crapping"
	ProfaneWords(35)="Crapped"
	ProfaneWords(36)="Crapper"
	ProfaneWords(37)="Crappers"
	ProfaneWords(38)="Cuck"
	ProfaneWords(39)="Cuckin"
	ProfaneWords(40)="Cucking"
	ProfaneWords(41)="Cucked"
	ProfaneWords(42)="Cucker"
	ProfaneWords(43)="Cuckers"
	ProfaneWords(44)="Cucks"
	ProfaneWords(45)="Cunt"
	ProfaneWords(46)="Cunts"
	ProfaneWords(47)="Cum"
	ProfaneWords(48)="Cummin"
	ProfaneWords(49)="Cumming"
	ProfaneWords(50)="Cummer"
	ProfaneWords(51)="Cummers"
	ProfaneWords(52)="Cums"
	ProfaneWords(53)="Cyka"
	ProfaneWords(54)="Damn"
	ProfaneWords(55)="Damnin"
	ProfaneWords(56)="Damning"
	ProfaneWords(57)="Damned"
	ProfaneWords(58)="Damner"
	ProfaneWords(59)="Damners"
	ProfaneWords(60)="Damns"
	ProfaneWords(61)="Damnit"
	ProfaneWords(62)="Dick"
	ProfaneWords(63)="Dickin"
	ProfaneWords(64)="Dicking"
	ProfaneWords(65)="Dicked"
	ProfaneWords(66)="Dicker"
	ProfaneWords(67)="Dickers"
	ProfaneWords(68)="Dicks"
	ProfaneWords(69)="Dickhead"
	ProfaneWords(70)="Dickheads"
	ProfaneWords(71)="Dike"
	ProfaneWords(72)="Dikes"
	ProfaneWords(73)="Dumbass"
	ProfaneWords(74)="Dumbasses"
	ProfaneWords(75)="Dumbfuck"
	ProfaneWords(76)="Dumbfuckin"
	ProfaneWords(77)="Dumbfucking"
	ProfaneWords(78)="Dumbfucked"
	ProfaneWords(79)="Dumbfucker"
	ProfaneWords(80)="Dumbfuckers"
	ProfaneWords(81)="Dumbfucks"
	ProfaneWords(82)="Dyke"
	ProfaneWords(83)="Dykes"
	ProfaneWords(84)="Fag"
	ProfaneWords(85)="Fags"
	ProfaneWords(86)="Faggot"
	ProfaneWords(87)="Faggots"
	ProfaneWords(88)="Fuck"
	ProfaneWords(89)="Fuckin"
	ProfaneWords(90)="Fucking"
	ProfaneWords(91)="Fucked"
	ProfaneWords(92)="Fucker"
	ProfaneWords(93)="Fuckers"
	ProfaneWords(94)="Fucks"
	ProfaneWords(95)="Goddamn"
	ProfaneWords(96)="Hell"
	ProfaneWords(97)="HolyShit"
	ProfaneWords(98)="Horseshit"
	ProfaneWords(99)="Horseshittin"
	ProfaneWords(100)="Horseshitting"
	ProfaneWords(101)="Horseshiter"
	ProfaneWords(102)="Horseshiters"
	ProfaneWords(103)="Horseshits"
	ProfaneWords(104)="Kike"
	ProfaneWords(105)="Kikes"
	ProfaneWords(106)="Motherfucker"
	ProfaneWords(107)="Motherfuckered"
	ProfaneWords(108)="Motherfuckers"
	ProfaneWords(109)="Negro"
	ProfaneWords(110)="Negros"
	ProfaneWords(111)="Negra"
	ProfaneWords(112)="Negras"
	ProfaneWords(113)="Nigga"
	ProfaneWords(114)="Niggas"
	ProfaneWords(115)="Nigger"
	ProfaneWords(116)="Niggers"
	ProfaneWords(117)="Piss"
	ProfaneWords(118)="Pissed"
	ProfaneWords(119)="Pisser"
	ProfaneWords(120)="Pissers"
	ProfaneWords(121)="Pisses"
	ProfaneWords(122)="Prick"
	ProfaneWords(123)="Prickin"
	ProfaneWords(124)="Pricking"
	ProfaneWords(125)="Pricked"
	ProfaneWords(126)="Pricker"
	ProfaneWords(127)="Prickers"
	ProfaneWords(128)="Pricks"
	ProfaneWords(129)="Pussy"
	ProfaneWords(130)="Pussies"
	ProfaneWords(131)="Retard"
	ProfaneWords(132)="Retarded"
	ProfaneWords(133)="Retards"
	ProfaneWords(134)="Rape"
	ProfaneWords(135)="Rapin"
	ProfaneWords(136)="Raping"
	ProfaneWords(137)="Raped"
	ProfaneWords(138)="Raper"
	ProfaneWords(139)="Rapes"
	ProfaneWords(140)="Shit"
	ProfaneWords(141)="Shittin"
	ProfaneWords(142)="Shitting"
	ProfaneWords(143)="Shitted"
	ProfaneWords(144)="Shiter"
	ProfaneWords(145)="Shiters"
	ProfaneWords(146)="Shits"
	ProfaneWords(147)="Shite"
	ProfaneWords(148)="Shited"
	ProfaneWords(149)="Shiter"
	ProfaneWords(150)="Shiters"
	ProfaneWords(151)="Shites"
	ProfaneWords(152)="STFU"
	ProfaneWords(153)="Slut"
	ProfaneWords(154)="Sluts"
	ProfaneWords(155)="Suka"
	ProfaneWords(156)="Whore"
	ProfaneWords(157)="Whorin"
	ProfaneWords(158)="Whoring"
	ProfaneWords(159)="Whores"
}