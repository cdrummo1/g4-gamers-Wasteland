// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: saveTerritory.sqf - save one territory status via extDB
//	@file Author: Munch after saveVehicle by AgentRev
//  Argument:   [_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newCapPointTimer]

private ["_terRec", "_sideToStr", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOccupiersUIDs", "_currentTerritoryID", "_currentTerritoryOwner", "_currentTerritoryChrono", "_updateValues", "_markerID"];

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

_currentTerritoryID = _terRec select 0;
_currentTerritoryOwner = _terRec select 3 call _sideToStr;
_currentTerritoryChrono = _terRec select 4;

_updateValues = format["Occupiers=%1,SideHolder=%2,TimeHeld=%3",_currentTerritoryOccupiersUIDs,_currentTerritoryOwner,_currentTerritoryChrono];
[format ["updateTerritoryCaptureStatus:%1:", _markerID] + _updateValues] call extDB_Database_async;

nil
