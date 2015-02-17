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

private ["_strToSide", "_sideStr", "_vars", "_columns", "_result", "_territories", "_terData", "_currentTerritoryOwner", "_currentTerritoryOccupiers", "_currentTerritoryOwnerString", "_currentTerritoryChrono", "_markerName", "_result2", "_markerID", "_props", "_updateValues"];

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
	["ID", "_currentTerritoryID"],
	["MarkerName", "_currentTerritoryName"],
	["Occupiers", "_currentTerritoryOccupiers"],  		// array of UID strings
	["SideHolder", "_currentTerritoryOwnerString"],  	// EAST, WEST, GUER, "UNKNOWN"
	["TimeHeld", "_currentTerritoryChrono"]
];

_columns = "";
{
	_columns = _columns + ((if (_columns != "") then { "," } else { "" }) + (_x select 0));
} forEach _vars;

diag_log format ["[INFO] getTerritories: Calling getServerTerritoriesCaptureStatus sql with _columns='%1'",_columns];

_result = [format ["getServerTerritoriesCaptureStatus:%1:%2:%3", call A3W_extDB_ServerID, call A3W_extDB_MapID, _columns], 2, true] call extDB_Database_async;

diag_log format ["[INFO] getTerritories: Call to getServerTerritoriesCaptureStatus sql returned %1 recs: %2",(count _result), _result];
//diag_log format ["rec 0: has size %1 with %2", count _result select 0, _result select 0];
_territories = [];

{
	diag_log format ["[INFO] getTerritories: handling record %1 field record: '%2'", count _x, _x];

	
	_terData = [];
	
	{
		if (!isNil "_x") then
		{
			diag_log format ["    setting _terData elem [%1,%2]", (_vars select _forEachIndex) select 1, _x];
			_terData pushBack [(_vars select _forEachIndex) select 1, _x];
		};
	} forEach _x;
	_currentTerritoryOwner = (_terData select 3 select 1) call _strToSide; 

	
	diag_log format ["[INFO] getTerritories: loaded [%1, %2, %3, %4, %5]",_terData select 0 select 1, _terData select 1 select 1, _terData select 2 select 1, _currentTerritoryOwner,  _terData select 4 select 1];
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = side owning the point currently
	// 		5 = Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	_territories pushBack [_terData select 0 select 1, _terData select 1 select 1, _terData select 2 select 1, [], _currentTerritoryOwner, _terData select 4 select 1, 0];
	//					  Marker ID					MarkerName				Occupiers			    Occupiers, SideHolder,       timeHeld, timeOccupied
	
	
} forEach _result;

// Check that a complete set of territories were loaded, & if not, create db & territories recs for any missing ones
if (count _territories < count (["config_territory_markers", []] call getPublicVar)) then {
	

	_currentTerritoryOccupiers=[];
	_currentTerritoryOwnerString="UNKNOWN";
	_currentTerritoryChrono=0;
	
	diag_log "[INFO] A3Wasteland - mismatch in saved territory info ... initializing/updating with data from config_territory_markers";
	
	{
		_markerName = format ["""%1""", _x select 0];
		
		diag_log format ["getTerritories: calling db to see if marker '%1' exists", _markerName];
		
		// Does this marker exist ?
		//_result = [format ["getServerTerritoryCaptureStatusFromMarkerName:%1:%2:%3", call A3W_extDB_ServerID, call A3W_extDB_MapID, _markerName], 2, true] call extDB_Database_async;
		_result2 = ([format ["checkServerTerritory:%1:%2:%3", call A3W_extDB_ServerID, call A3W_extDB_MapID, _markerName], 2] call extDB_Database_async) select 0;
		
		diag_log format ["getTerritories: db call to fetch rec for marker='%1' returned '%2'", _markerName, _result2];
		
		if (!_result2) then {
			// need to create data for this marker
			diag_log format ["[INFO] getTerritories: Marker '%1' does not exist in db ... creating record",_markerName];
			
			// create territory rec w/ 'single array' (?) query return
			_markerID = ([format ["newTerritoryCaptureStatus:%1:%2", call A3W_extDB_ServerID, call A3W_extDB_MapID], 2, false] call extDB_Database_async) select 0;

			_markerName=_x select 0;
			_props =
			[
				["MarkerName", _x select 0],
				["Occupiers", _currentTerritoryOccupiers],  		// array of UID strings
				["SideHolder", _currentTerritoryOwnerString],  	// EAST, WEST, GUER, "UNKNOWN"
				["TimeHeld", _currentTerritoryChrono]
			];
			_updateValues = [_props, 0] call extDB_pairsToSQL;
			[format ["updateTerritoryCaptureStatus:%1:", _markerID] + _updateValues] call extDB_Database_async;

			diag_log format ["[INFO] getTerritories:   assigned ID=%1 to Marker %2", _markerID, _markerName];
			
			_territories pushBack [_markerID,_markerName,_currentTerritoryOccupiers,[], sideUnknown,0,0];
			//					  Marker ID,MarkerName,Occupiers,Occupiers,SideHolder,timeHeld
		} else {
			diag_log ["[INFO] getTerritories: Marker '%1' exists in db", _markerName];
		};
	} forEach (["config_territory_markers", []] call getPublicVar);
};
_territories
