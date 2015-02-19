// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: saveTerritory.sqf - save one territory status via extDB
//	@file Author: Munch after saveVehicle by AgentRev
//  Argument:   [_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newTerritoryGroupHolder, _newTerritoryGrouplHolderUIDs]

private ["_terRec", "_sideToStr", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOccupiersUIDs", "_currentTerritoryID", "_currentTerritoryMarkerName", "_currentTerritoryOwnerString", "_currentTerritoryChrono", "_props", "_updateValues"];
_terRec = _this;

diag_log format ["saveTerritory got '%1' as arg", _terRec];

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

// convert player objects to UIDs
_currentTerritoryOccupiersPlayers = _terRec select 2;
_currentTerritoryOccupiersUIDs = [];
if (count _currentTerritoryOccupiersPlayers >0) then 
{
	{
		_currentTerritoryOccupiersUIDs pushBack getPlayerUID _x;
	} forEach _currentTerritoryOccupiersPlayers;
};

//					  Marker ID,MarkerName,Occupiers,Occupiers,SideHolder,timeHeld
_currentTerritoryID = _terRec select 0;
_currentTerritoryMarkerName=_terRec select 1;
_currentTerritoryOwnerString = _terRec select 3 call _sideToStr;
_currentTerritoryChrono = _terRec select 4;
_currentTerritoryGroupHolderString = _terRec select 5;
_currentTerritoryGroupHolderUIDs = _terRec select 6;


_props =
[
	["Occupiers", _currentTerritoryOccupiersUIDs],  		// array of UID strings
	["SideHolder", _currentTerritoryOwnerString],  	// EAST, WEST, GUER, "UNKNOWN"
	["GroupHolder", _currentTerritoryGroupHolderString],
	["GroupHolderUIDs", _currentTerritoryGroupHolderUIDs],
	["TimeHeld", _currentTerritoryChrono]
];
_updateValues = [_props, 0] call extDB_pairsToSQL;
[format ["updateTerritoryCaptureStatus:%1:", _currentTerritoryID] + _updateValues] call extDB_Database_async;

diag_log format ["[INFO] saveTerritory: ran updateTerritoryCaptureStatus for %1 with ID=%2 updateValues=%3", _currentTerritoryMarkerName, _currentTerritoryID, _updateValues];

nil
