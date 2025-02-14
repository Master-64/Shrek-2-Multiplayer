// *****************************************************
// *	   Shrek 2 Multiplayer (S2M) by Master_64	   *
// *		  Copyrighted (c) Master_64, 2020		   *
// *   May be modified but not without proper credit!  *
// *****************************************************


class S2MHUDItem_Chat extends MHUDItem
	Config(S2Multi);


#exec TEXTURE IMPORT NAME=Backdrop FILE=Textures\Backdrop.dds


const MaxChatBufferSize = 256;
const MaxChatHistoryDisplay = 6;
const BufferClearCount = 64;

struct ChatStruct
{
	var() string sUsername, sFullMessage;
	var array<string> sMessage;
	var() float fDisplayTime;
	var Color cTextColor;
	var() Texture BackdropTexture;
	var() MUtils.EFont Font;
};

var() float fOffsetX, fOffsetY;
var() array<ChatStruct> Chat;
var protected ChatStruct ChatBuffer[256];
var protected int iCurrBufferIndex;


function DrawHudItem(Canvas C)
{
	local float fTempOffsetX, fTempOffsetY, fTextW, fTextH, fTextTotalW, fTextTotalH, fTextPTotalH, fDeltaTime, fRectX, fRectY;
	local int i, j;
	
	fDeltaTime = U.GetDeltaTime();
	
	fTempOffsetX = fOffsetX * C.SizeX;
	fTempOffsetY = fOffsetY * C.SizeY;
	
	for(i = Chat.Length - 1; i >= 0; i--)
	{
		if(Chat[i].sMessage.Length == 0)
		{
			FormatMessage(C, Chat[i]);
		}
		
		Chat[i].fDisplayTime -= fDeltaTime;
		
		C.Font = U.GetFontFromEnum(Chat[i].Font);
		
		fTextTotalW = 0.0;
		fTextTotalH = 0.0;
		
		for(j = 0; j < Chat[i].sMessage.Length; j++)
		{
			C.TextSize(Chat[i].sMessage[j], fTextW, fTextH);
			
			fTextTotalW = Max(fTextTotalW, fTextW);
			fTextTotalH += fTextH;
			fTextPTotalH += fTextH;
		}
		
		// Don't display a message too high up, arbitrarily cuts off any message once the chat window is larger than half of the height of the screen
		if(C.SizeY * 0.5 < fTextPTotalH)
		{
			continue;
		}
		
		fTempOffsetX = fOffsetX * C.SizeX;
		fTempOffsetY = fOffsetY * C.SizeY;
		
		if(Chat[i].fDisplayTime <= 0.0)
		{
			Chat[i].fDisplayTime = 0.0;
			
			Chat.Remove(i, 1);
			
			continue;
		}
		
		fTempOffsetY -= fTextPTotalH;
		
		fRectX = fTempOffsetX + fTextTotalW + (C.SizeX * fOffsetX);
		fRectY = fTextTotalH;
		
		C.SetPos(fTempOffsetX - (C.SizeX * fOffsetX), fTempOffsetY);
		C.DrawTile(Chat[i].BackdropTexture, fRectX, fRectY, 0.0, 0.0, Chat[i].BackdropTexture.USize, Chat[i].BackdropTexture.VSize);
		
		for(j = 0; j < Chat[i].sMessage.Length; j++)
		{
			C.TextSize(Chat[i].sMessage[j], fTextW, fTextH);
			
			U.DrawShadowText(C, Chat[i].sMessage[j], Chat[i].cTextColor, U.MakeColor(0, 0, 0, 255), fTempOffsetX, fTempOffsetY, 2.0);
			
			fTempOffsetY += fTextH;
		}
	}
}

function FormatMessage(Canvas C, out ChatStruct CH)
{
	local float fTextW, fTextH, fMaxWidth, fSpaceWidth;
	local int i, iLineCount, SubLen, RemainingLen;
	
	CH.cTextColor = ParseColorCodes(CH.sFullMessage);
	
	CH.sFullMessage = TrimWhitespace(CH.sFullMessage);
	
	C.Font = U.GetFontFromEnum(CH.Font);
	C.TextSize(" ", fSpaceWidth, fTextH);
	C.TextSize(CH.sUsername $ ":" @ CH.sFullMessage, fTextW, fTextH);
	fMaxWidth = Min(C.SizeX * 0.25, fTextW);
	
	CH.sFullMessage = TrimWhitespace(CH.sUsername $ ":" @ CH.sFullMessage);
	RemainingLen = Len(CH.sFullMessage);
	
	while(RemainingLen > 0)
	{
		iLineCount = U.Ceiling(fTextW / fMaxWidth);
		
		for(i = 0; i < iLineCount; i++)
		{
			CH.sMessage.Insert(CH.sMessage.Length, 1);
			
			SubLen = Min(RemainingLen, U.Floor(fMaxWidth / fSpaceWidth));
			
			while(SubLen > 0 && SubLen < RemainingLen && Mid(CH.sFullMessage, SubLen, 1) != " ")
			{
				SubLen--;
			}
			
			if(SubLen == 0)
			{
				SubLen = U.Floor(fMaxWidth / fSpaceWidth);
				CH.sMessage[CH.sMessage.Length - 1] = Left(CH.sFullMessage, SubLen + 1) $ "-";
			}
			else
			{
				CH.sMessage[CH.sMessage.Length - 1] = Left(CH.sFullMessage, SubLen);
			}
			
			CH.sFullMessage = Mid(CH.sFullMessage, SubLen + 1, RemainingLen - SubLen);
			RemainingLen = Len(CH.sFullMessage);
			
			if(RemainingLen <= 0)
			{
				break;
			}
		}
	}
}

function string TrimWhitespace(string InputString)
{
	local int StartIndex, EndIndex;
	
	EndIndex = Len(InputString) - 1;
	
	while(StartIndex <= EndIndex && Mid(InputString, StartIndex, 1) == " ")
	{
		StartIndex++;
	}
	
	while(EndIndex >= StartIndex && Mid(InputString, EndIndex, 1) == " ")
	{
		EndIndex--;
	}
	
	return Mid(InputString, StartIndex, EndIndex - StartIndex + 1);
}

function Color ParseColorCodes(out string sFullMessage)
{
	local string sCode;
	local int iCode;
	
	iCode = InStr(sFullMessage, "^");
	
	if(iCode > -1)
	{
		if(U.IsNumeric(Mid(sFullMessage, iCode + 1, 1)))
		{
			sCode = Mid(sFullMessage, iCode, 2);
			
			U.RemoveText(sFullMessage, sCode);
		}
	}
	
	switch(sCode)
	{
		case "^0": // Black
			return U.MakeColor(0, 0, 0, 255);
		case "^1": // Red
			return U.MakeColor(255, 0, 0, 255);
		case "^2": // Orange
			return U.MakeColor(255, 127, 0, 255);
		case "^3": // Yellow
			return U.MakeColor(255, 255, 0, 255);
		case "^4": // Green
			return U.MakeColor(0, 255, 0, 255);
		case "^5": // Cyan
			return U.MakeColor(0, 255, 255, 255);
		case "^6": // Teal
			return U.MakeColor(0, 127, 127, 255);
		case "^7": // Blue
			return U.MakeColor(0, 0, 255, 255);
		case "^8": // Purple
			return U.MakeColor(127, 0, 255, 255);
		case "^9": // Pink
			return U.MakeColor(255, 0, 255, 255);
		default: // White
			return U.MakeColor(255, 255, 255, 255);
	}
}

function CreateChatMessage(string sUsername, string sMessage, optional float fDisplayTime, optional Texture BackdropTexture, optional MUtils.EFont Font, optional bool bDoNotBuffer)
{
	if(sUsername == "")
	{
		sUsername = "Unknown User";
	}
	
	if(fDisplayTime == 0.0)
	{
		fDisplayTime = 11.0;
	}
	
	if(BackdropTexture == none)
	{
		Texture'Backdrop'.bAlphaTexture = true;
		BackdropTexture = Texture'Backdrop';
	}
	
	if(Font == F_DefaultFont)
	{
		Font = F_BigArielFont;
	}
	
	Chat.Insert(Chat.Length, 1);
	Chat[Chat.Length - 1].sUsername = sUsername;
	Chat[Chat.Length - 1].sFullMessage = sMessage;
	Chat[Chat.Length - 1].fDisplayTime = fDisplayTime;
	Chat[Chat.Length - 1].BackdropTexture = BackdropTexture;
	Chat[Chat.Length - 1].Font = Font;
	
	if(!bDoNotBuffer)
	{
		ChatBuffer[iCurrBufferIndex] = Chat[Chat.Length - 1];
		
		iCurrBufferIndex++;
		
		if(iCurrBufferIndex % BufferClearCount == 0)
		{
			ClearBuffer(iCurrBufferIndex);
		}
		
		if(iCurrBufferIndex >= MaxChatBufferSize)
		{
			iCurrBufferIndex = 0;
		}
		
		if(class'S2MConfig'.default.bPlayChatSound && class'S2MConfig'.default.ChatSound != none)
		{
			U.PlayASound(, class'S2MConfig'.default.ChatSound);
		}
	}
}

function ClearChat()
{
	Chat.Remove(0, Chat.Length);
	
	ClearBuffer(0);
	ClearBuffer(MaxChatBufferSize / 4);
	ClearBuffer(MaxChatBufferSize / 2);
	ClearBuffer(MaxChatBufferSize / 4 + MaxChatBufferSize / 2);
}

private function ClearBuffer(int iIndex)
{
	local int i, iCurrentIndex;
	local ChatStruct CS;
	
	for(i = 0; i < BufferClearCount; i++)
	{
		iCurrentIndex = (iIndex + i) % MaxChatBufferSize;
		ChatBuffer[iCurrentIndex] = CS;
	}
}

function ShowChatHistory()
{
	local int i, iIndex;
	
	for(i = 0; i < MaxChatHistoryDisplay; i++)
	{
		iIndex = iCurrBufferIndex - 1 - i;
		
		if(iIndex < 0)
		{
			iIndex += MaxChatBufferSize;
		}
		
		if(Len(ChatBuffer[iIndex].sFullMessage) == 0)
		{
			continue;
		}
		
		CreateChatMessage("[HISTORY]" @ ChatBuffer[iIndex].sUsername, ChatBuffer[iIndex].sFullMessage, ChatBuffer[iIndex].fDisplayTime, ChatBuffer[iIndex].BackdropTexture, ChatBuffer[iIndex].Font, true);
	}
}

function BufferDebug()
{
	local int i;
	
	for(i = 0; i < MaxChatBufferSize; i++)
	{
		CreateChatMessage("BufferDebug", "Debug Message #" $ string(i), 0.1);
	}
	
	for(i = 0; i < MaxChatBufferSize; i++)
	{
		Log("Index:" @ string(i) $ ", Message:" @ ChatBuffer[i].sFullMessage);
	}
}


defaultproperties
{
	fOffsetX=0.01
	fOffsetY=0.6
	bAlwaysTick=true
}