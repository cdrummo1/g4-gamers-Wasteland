/* 	*********************************************************************** */

/*	=======================================================================
/*	SCRIPT NAME: Server Intro Credits Script by IT07
/*	SCRIPT VERSION: v1.3.4 BETA
/*	Credits for original script: Bohemia Interactive http://bistudio.com
/*	=======================================================================

/*	*********************************************************************** */

//	========== SCRIPT CONFIG ============
	
_onScreenTime = 10; 		//how long one role should stay on screen. Use value from 0 to 10 where 0 is almost instant transition to next role 
//NOTE: Above value is not in seconds!

//	==== HOW TO CUSTOMIZE THE CREDITS ===
//	If you want more or less credits on the screen, you have to add/remove roles.
//	Watch out though, you need to make sure BOTH role lists match eachother in terms of amount.
//	Just take a good look at the _role1 and the rest and you will see what I mean.

//	For further explanation of it all, I included some info in the code.

//	== HOW TO CUSTOMIZE THE COLOR OF CREDITS ==
//	Find line **** and look for: color='#f2cb0b'
//	The numbers and letters between the 2 '' is the HTML color code for a certain yellow.
//	If you want to change the color of the text, search on google for HTML color codes and pick the one your like.
//	Then, replace the existing color code for the code you would like to use instead. Don't forget the # in front of it.
//	HTML Color Codes Examples:	
//	#FFFFFF (white)
//	#000000 (black)	No idea why you would want black, but whatever
//	#C80000 (red)
//	#009FCF (light-blue)
//	#31C300 (Razer Green)			
//	#FF8501 (orange)
//	===========================================


//	SCRIPT START

waitUntil {!isNull player};
waitUntil {alive player};
sleep 15; //Wait in seconds before the credits start after player IS ingame

_role1 = "Welcome back to";
_role1names = ["the G4 wasteland Altis server 1 / A3W v1.1c"];
_role2 = "Thanks to all the players";
_role2names = ["For making this a awesome server!"];
_role3 = "Our G4 TS3 server info is:";
_role3names = ["ts.g4-gamers.com"];
_role4 = "Check out the server stats at";
_role4names = ["www.g4-gamers.com"];
_role5 = "Need help?  Goto your map,";
_role5names = ["click on Server Features"];
_role6 = "or";
_role6names = ["G4 Admin info"];
_role7 = "Always check:";
_role7names = ["Server change log for server changes/updates!"];
_role8 = "Did you know we have server loadouts?";
_role8names = ["Check our website for server loadout details"];
_role9 = "Goto pimp your shit/Server perks at g4-gamers.com,";
_role9names = ["Don't forget we also have a Stratis 1 & 2 servers linked to this server!!"];
_role10 = "Again,";
_role10names = ["THANK YOU and HAVE FUN!!!"];

{
	sleep 2;
	_memberFunction = _x select 0;
	_memberNames = _x select 1;
	_finalText = format ["<t size='0.60' color='#B40404' align='right'>%1<br /></t>", _memberFunction];
	_finalText = _finalText + "<t size='0.80' color='#D8D8D8' align='right'>";
	{_finalText = _finalText + format ["%1<br />", _x]} forEach _memberNames;
	_finalText = _finalText + "</t>";
	_onScreenTime + (((count _memberNames) - 1) * 0.5);
	[
		_finalText,
		[safezoneX + safezoneW - 0.8,0.50],	//DEFAULT: 0.5,0.35
		[safezoneY + safezoneH - 0.8,0.7], 	//DEFAULT: 0.8,0.7
		_onScreenTime,
		0.5
	] spawn BIS_fnc_dynamicText;
	sleep (_onScreenTime);
} forEach [
	//The list below should have exactly the same amount of roles as the list above
	[_role1, _role1names],
	[_role2, _role2names],
	[_role3, _role3names],
	[_role4, _role4names],
	[_role5, _role5names],
	[_role6, _role6names],
	[_role7, _role7names],
	[_role8, _role8names],
	[_role9, _role9names],
	[_role10, _role10names] //make SURE the last one here does NOT have a , at the end
];