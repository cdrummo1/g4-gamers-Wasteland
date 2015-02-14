// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: getTerritories.sqf
//	@file Author: Munch, after AgentRev's getVehicles script
//  Profile and iniDBi implementation of getTerritories.  Reads and returns array containing known territories status
//	in the form of the global currentTerritoryDetails array of the form:
// 		1 = Name of capture marker
// 		2 = List of players in that area [uids]
// 		3 = List of players in that area [player objects] (set to null array)
// 		4 = Team owning the point currently
// 		5 = Time in seconds during which the area has been held
// 		6 = Time in seconds during which the area has been occupied by enemies

private ["_terFileName", "_exists", "_terCount", "_nTerritories", "_vars", "_sideToStr", "_strToSide", "_territories", "_terData", "_terName", "_i", "_params", "_value", "_currentTerritoryOwner"];

_terFileName = "Territories" call PDB_objectFileName;

_exists = _terFileName call PDB_exists; // iniDB_exists
if (isNil "_exists" || {!_exists}) exitWith {[]};

_terCount = [_terFileName, "Info", "TerCount", "NUMBER"] call PDB_read; // iniDB_read
_nTerritories = count (["config_territory_markers", []] call getPublicVar);

diag_log format ["A3Wasteland - Territory persistence data exists in %1 and has info on %2 of %3 territories.", _terFileName, _terCount, _nTerritories];

if (isNil "_terCount" || {_terCount < _nTerritories }) exitWith {[]};

// [key name, data type], vLoad variable name
_vars =
[
	// Marker ID (not stored in iniDB)
	[["MarkerName", "STRING"], "_currentTerritoryName"],
	[["Occupiers", "ARRAY"], "_currentTerritoryOccupiers"],  		// array of UID strings
	[["SideHolder", "STRING"], "_currentTerritoryOwnerString"],  	// EAST, WEST, GUER, NONE
	[["TimeHeld", "INTEGER"], "_currentTerritoryChrono"],
	[["TimeOccupied", "INTEGER"], "_currentTerritoryTimer"]
];

_sideToStr =
{
	switch (toUpper _this) do
	{
		case BLUFOR :		{"WEST"};
		case OPFOR :		{ "EAST" };
		case INDEPENDENT :{ "GUER" };
		case CIVILIAN :	{ "CIV" };
		case sideLogic :	{ "LOGIC" };
		default       	{ "UNKNOWN" };
	};
};


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


_territories = [];

diag_log format ["getTerritories reading territory %1 data recs from %2", _terCount, _terFileName];
for "_i" from 0 to (_terCount-1) do
{
	// Load the data from file
	_terData = [];
	_terData pushBack ["MarkerID",_i];
	_terName = format ["Ter%1", ( (["config_territory_markers", []] call getPublicVar) select _i) select 0];
	{
		_params = _x select 0;  // e.g., ["MarkerName", "STRING"]

		_value = [_terFileName, _terName, _params select 0, _params select 1] call PDB_read;  // 
		
		//diag_log format ["    called PDB_read with ['%1', '%2', '%3', '%4'] got back %5 = _value = '%6'",_terFileName, _terName, _params select 0, _params select 1, _params select 0, _value];
		
		if (!isNil "_value") then { 
			_terData pushBack [_x select 1, _value] 
		} else {
			if ((_params select 1) == "STRING") then {
				_terData pushBack [_params select 0, ""];
			};
			if ((_params select 1) == "ARRAY") then {
				_terData pushBack [_params select 0, []];
			};
			if ((_params select 1) == "INTEGER") then {
				_terData pushBack [_params select 0, 0];
			};
		};
	} forEach _vars;

	_currentTerritoryOwner = (_terData select 2 select 1) call _strToSide;  
	//diag_log format ["Set _currentTerritoryOwner to %1", _currentTerritoryOwner];
	
	//diag_log format ["getTerritories loaded [%1, %2, %3, %4, %5]",_terData select 0 select 1, _terData select 1 select 1, _currentTerritoryOwner, _terData select 3 select 1, _terData select 4 select 1];
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = Team owning the point currently
	// 		5 = Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)	
	_territories pushBack [_terData select 0 select 1, _terData select 1 select 1, _terData select 2 select 1, [], _currentTerritoryOwner, parseNumber (_terData select 4 select 1),0];	
	//					  Marker ID					MarkerName				Occupiers			    Occupiers, SideHolder,       timeHeld

};

diag_log format ["getTerritories return _territories data with %1 records", count _territories];
_territories
