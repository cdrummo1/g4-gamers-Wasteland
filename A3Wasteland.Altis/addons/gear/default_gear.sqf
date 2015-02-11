//@file Version: 1.1
//@file Name: default_gear.sqf
//@file Author: Cael817, Very much a copy of AgentRevs admins.sqf

/*
	The gear.sqf is to be place in the external config folder, that file overrides this one.
	If the external file isnt present the settings from this file is used instead.
	Add "[] execVM "addons\gear\gearCheck.sqf";"
	to the client\functions\spawnAction.sqf
	Add "[] execVM "addons\gear\default_gear.sqf";"
	to the main init.
*/

if (!isServer) exitWith {};

externalConfigFolder = "\A3Wasteland_settings";

if (loadFile (externalConfigFolder + "\gear.sqf") != "") then
{
	call compile preprocessFileLineNumbers (externalConfigFolder + "\gear.sqf");
}
else
{

	/*******************************************************
	 Player UID examples :
	[
		"1234567887654321", // Meatwad
		"8765432112345678", // Master Shake
		"1234876543211234", // Frylock
		"1337133713371337"  // Carl
	];
	 Important: Don't put a comma (,) at the end of the last one
	********************************************************/

		// gearLevel1
		gearLevel1 = 
		[
			"76561197974272346", // 30 days on 1/25/2015
			"76561198049819530", // Doyle
			"76561198039765702",  // Bear
			"76561198036731659" // AKA James (Jim Doweling)
		];

		// gearLevel2
		gearLevel2 = 
		[
			"76561198133974307" // Trench
		];

		// gearLevel3
		gearLevel3 = 
		[
			"76561198010814428", // TBonePut
			"76561197970553941", // Piece
			"76561197976304014", // Solo
			"76561198011606099"  // Dope0nez
		];

		// gearLevel4
		gearLevel4 = 
		[
			// Put player UIDs here
		];

		// gearLevel5
		gearLevel5 = 
		[
			// Put player UIDs here
		];

		// gearLevel6
		gearLevel6 = 
		[
			 // Put player UIDs here
		];

		// gearLevel7
		gearLevel7 = 
		[
			// Put player UIDs here
		];

		// gearLevel8
		gearLevel8 = 
		[
			// Put player UIDs here
		];

		// gearLevel9
		gearLevel9 = 
		[
			// Put player UIDs here
		];

		// gearLevel10
		gearLevel10 = 
		[
			// Put player UIDs here
		];


	/********************************************************/
};

if (typeName gearLevel1 == "ARRAY") then { gearLevel1 = compileFinal str gearLevel1 };
if (typeName gearLevel2 == "ARRAY") then { gearLevel2 = compileFinal str gearLevel2 };
if (typeName gearLevel3 == "ARRAY") then { gearLevel3 = compileFinal str gearLevel3 };
if (typeName gearLevel4 == "ARRAY") then { gearLevel4 = compileFinal str gearLevel4 };
if (typeName gearLevel5 == "ARRAY") then { gearLevel5 = compileFinal str gearLevel5 };
if (typeName gearLevel6 == "ARRAY") then { gearLevel6 = compileFinal str gearLevel6 };
if (typeName gearLevel7 == "ARRAY") then { gearLevel7 = compileFinal str gearLevel7 };
if (typeName gearLevel8 == "ARRAY") then { gearLevel8 = compileFinal str gearLevel8 };
if (typeName gearLevel9 == "ARRAY") then { gearLevel9 = compileFinal str gearLevel9 };
if (typeName gearLevel10 == "ARRAY") then { gearLevel10 = compileFinal str gearLevel10 };

publicVariable "gearLevel1";
publicVariable "gearLevel2";
publicVariable "gearLevel3";
publicVariable "gearLevel4";
publicVariable "gearLevel5";
publicVariable "gearLevel6";
publicVariable "gearLevel7";
publicVariable "gearLevel8";
publicVariable "gearLevel9";
publicVariable "gearLevel10";
