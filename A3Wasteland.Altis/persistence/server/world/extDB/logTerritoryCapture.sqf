// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: logTerritoryCapture.sqf - save one territory capture event via extDB
//	@file Author: Munch
//  Argument:   [_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner]
//
//	Called from monitorTerritories when a new territory capture event occurs, extDB is the persistence method dir, and A3W_territoryLogging=1

//  a3wasteland.ini sql used:
// 	[addTerritoryCaptureLog]
//	SQL1_1 = INSERT INTO TerritoryCaptureLog SET $INPUT_1, CaptureTime = NOW();

private ["_terRec", "_sideToStr", "_currentTerritoryID", "_currentTerritoryMarkerName", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOccupiersUIDs", "_currentTerritoryOwnerString", "_props", "_insertValues"];

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

_currentTerritoryID = _terRec select 0;
_currentTerritoryMarkerName=_terRec select 1;
_currentTerritoryOccupiersUIDs = _terRec select 2;
_currentTerritoryOwnerString = _terRec select 3 call _sideToStr;
if (!(_terRec select 4 isEqualTo grpNull)) then 
{
	_currentTerritoryGroupHolderString = "";
} else {
	_currentTerritoryGroupHolderString = format["%1", _terRec select 5];  // group object to STRING
};


_props =
[
	["Id", _currentTerritoryID],
	["MarkerName", _currentTerritoryMarkerName],
	["Occupiers", _currentTerritoryOccupiersUIDs],  		// array of UID strings
	["SideHolder", _currentTerritoryOwnerString],  		// EAST, WEST, GUER, UNKNOWN
	["GroupHolder", _currentTerritoryOwnerGroup]
];
_insertValues = [_props, 0] call extDB_pairsToSQL;
[format ["addTerritoryCaptureLog:%1",  _insertValues]] call extDB_Database_async;

diag_log format ["[INFO] logTerritoryCapture: ran addTerritoryCaptureLog with insertValues=%1", _insertValues];

nil
