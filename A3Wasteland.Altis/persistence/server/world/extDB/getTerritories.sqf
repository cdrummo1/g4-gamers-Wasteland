// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: getTerritories.sqf
//	@file Author: Munch, after AgentRev's getVehicles script
//  Profile and iniDBi implementation of getTerritories.  Reads and returns array containing known territories status
//	in the form of the global currentTerritoryDetails array of the form:
//		0 = Marker ID 
// 		1 = Name of capture marker
// 		2 = List of players in that area [uids]
// 		3 = List of players in that area [player objects] (set to null array)
// 		4 = Team owning the point currently
// 		5 = Time in seconds during which the area has been held
// 		6 = Time in seconds during which the area has been occupied by enemies


_strToSide =
{
	_sideStr = _this;
	//diag_log format ["getTerritories._strToSide called with _sideStr='%1'  (sideUnknown is %2)", _sideStr, sideUnknown];
	switch (toUpper _sideStr) do
	{
		case "WEST":  { BLUFOR };
		case "EAST":  { OPFOR };
		case "GUER":  { INDEPENDENT };
		case "CIV":   { CIVILIAN };
		case "LOGIC": { sideLogic };
		default       { sideUnknown };
	};
};


// DB column name, tLoad variable name
_vars =
[
	[["MarkerID","INTEGER"], "_currentTerritoryID"],
	[["MarkerName", "STRING"], "_currentTerritoryName"],
	[["Occupiers", "ARRAY"], "_currentTerritoryOccupiers"],  		// array of UID strings
	[["SideHolder", "STRING"], "_currentTerritoryOwnerString"],  	// EAST, WEST, GUER, NONE
	[["TimeHeld", "INTEGER"], "_currentTerritoryChrono"],
];

_columns = "";
{
	_columns = _columns + ((if (_columns != "") then { "," } else { "" }) + (_x select 0));
} forEach _vars;

_result = [format ["getServerTerritoriesCaptureStatus:%1:%2:%3", call A3W_extDB_ServerID, call A3W_extDB_MapID, _columns], 2, true] call extDB_Database_async;

_territories = [];

{
	_terData = [];
	
	{
		if (!isNil "_x") then
		{
			_terData pushBack [(_vars select _forEachIndex) select 1, _x];
		};
	} forEach _x;
	_currentTerritoryOwner = (_terData select 3 select 1) call _strToSide; 
		//diag_log format ["Set _currentTerritoryOwner to %1", _currentTerritoryOwner];
	
	//diag_log format ["getTerritories loaded [%1, %2, %3, %4, %5]",_terData select 0 select 1, _terData select 1 select 1, _currentTerritoryOwner, _terData select 3 select 1, _terData select 4 select 1];
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = side owning the point currently
	// 		5 = Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	_territories pushBack [_terData select 0 select 1, _terData select 1 select 1, _terData select 2 select 1, [], _currentTerritoryOwner, parseNumber (_terData select 4 select 1),0];
	//					  Marker ID					MarkerName				Occupiers			    Occupiers, SideHolder,       timeHeld
} forEach _result;

_territories
