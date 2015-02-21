// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: saveTerritory.sqf - save one territory status via extDB
//	@file Author: Munch after saveVehicle by AgentRev
//  Argument:   [_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newTerritoryGroupHolder, _newTerritoryGrouplHolderUIDs]

private ["_terRec", "_sideToStr", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOccupiersUIDs", "_currentTerritoryID", "_currentTerritoryMarkerName", "_currentTerritoryOwnerString", 
"_currentTerritoryChrono", "_currentTerritoryGroupHolderString", "_currentTerritoryGroupHolderUIDs", "_props", "_updateValues"];
_terRec = _this;

diag_log format ["[INFO] saveTerritory called with '%1' as arg", _terRec];

_sideToStr =
{
	switch (_this) do
	{
		case BLUFOR :		{"WEST"};
		case OPFOR :		{ "EAST" };
		case INDEPENDENT :{ "GUER" };
		case CIVILIAN :	{ "CIV" };
		case sideLogic :	{ "LOGIC" };
		default       	{ "UNKNOWN" };
	};
};

//	Marker ID,MarkerName,OccupierUIDs,SideHolder,timeHeld,GroupHolder,GroupHolderUIDs
_currentTerritoryID = _terRec select 0;
_currentTerritoryMarkerName=_terRec select 1;
_currentTerritoryOccupiersUIDs = _terRec select 2;
_currentTerritoryOwnerString = _terRec select 3 call _sideToStr;
_currentTerritoryChrono = _terRec select 4;
if (!((_terRec select 5) isEqualTo grpNull)) then 
{
	_currentTerritoryGroupHolderString = format["%1", _terRec select 5];  // group object to STRING
} else {
	_currentTerritoryGroupHolderString = "";	
};

_currentTerritoryGroupHolderUIDs = _terRec select 6;

if (count _currentTerritoryOccupiersUIDs > 0) then {
	// used on territory captures
	_props =
	[
		["Occupiers", _currentTerritoryOccupiersUIDs],  		// array of UID strings
		["SideHolder", _currentTerritoryOwnerString],  	// EAST, WEST, GUER, "UNKNOWN"
		["GroupHolder", _currentTerritoryGroupHolderString],
		["GroupHolderUIDs", _currentTerritoryGroupHolderUIDs],
		["TimeHeld", _currentTerritoryChrono]
	];
} else {
	// used on territoryPayroll updates (doesn't include Occupiers)
	_props =
	[
		["SideHolder", _currentTerritoryOwnerString],  	// EAST, WEST, GUER, "UNKNOWN"
		["GroupHolder", _currentTerritoryGroupHolderString],
		["GroupHolderUIDs", _currentTerritoryGroupHolderUIDs],
		["TimeHeld", _currentTerritoryChrono]
	];
};

_updateValues = [_props, 0] call extDB_pairsToSQL;
[format ["updateTerritoryCaptureStatus:%1:", _currentTerritoryID] + _updateValues] call extDB_Database_async;

diag_log format ["[INFO] saveTerritory: ran updateTerritoryCaptureStatus SQL for %1 with ID=%2 & updateValues='%3'", _currentTerritoryMarkerName, _currentTerritoryID, _updateValues];

nil
