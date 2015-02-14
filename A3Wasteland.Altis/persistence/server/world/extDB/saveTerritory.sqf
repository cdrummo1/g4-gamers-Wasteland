// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: saveTerritory.sqf
//	@file Author: Munch after saveVehicle by AgentRev
//  Argument:  array as defined in _vars, below with info for one territory, 

private ["_terRec", "_currentTerritoryData", "_i", "_currentTerritoryName", "_newTerritoryOccupiersPlayers", "_currentTerritoryOwner", "_currentTerritoryChrono", "_newCapPointTimer", "_markerName", "_vars", "_strToSide", "_fileName", "_terName", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOccupiersUIDs", "_currentTerritoryTimer", "_props"];
_terRec = _this;

diag_log format ["saveTerritory got '%1' as arg", _terRec];
//	_currentTerritoryData set [_i, [_currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newCapPointTimer]];

_markerName = _terRec select 0;

// [key name, data type], vLoad variable name
_vars =
[
	[["MarkerName", "STRING"], "_currentTerritoryName"],
	[["Occupiers", "ARRAY"], "_currentTerritoryOccupiers"],  // [player, player, player, ...] -> [uid, uid, uid, ...]
	[["SideHolder", "STRING"], "_currentTerritoryOwnerString"],  // EAST, WEST, GUER, NONE
	[["TimeHeld", "ARRAY"], "_currentTerritoryChrono"],
	[["TimeOccupied", "INTEGER"], "_currentTerritoryTimer"]
];

_strToSide =
{
	switch (toUpper _this) do
	{
		case "WEST":  { BLUFOR };
		case "EAST":  { OPFOR };
		case "GUER":  { INDEPENDENT };
		case "CIV":   { CIVILIAN };
		case "LOGIC": { sideLogic };
		default       { sideUnknown };
	};
};

_fileName = "Territories" call PDB_objectFileName;
_terName = format ["Ter%1", _markerName];
_currentTerritoryName = _markerName;
_currentTerritoryOccupiersPlayers = _terRec select 1;
_currentTerritoryOccupiersUIDs = [];
if (count _currentTerritoryOccupiersPlayers >0) then 
{
	{
		_currentTerritoryOccupiersUIDs pushBack getPlayerUID _x;
	} forEach _currentTerritoryOccupiersPlayers;
};

_currentTerritoryOwner = _terRec select 2; 
_currentTerritoryChrono = _terRec select 3;
_currentTerritoryTimer = _terRec select 4;

_props = [];
_props pushBack ["MarkerName", _markerName];
_props pushBack ["Occupiers", _currentTerritoryOccupiersUIDs];
_props pushBack ["SideHolder", _currentTerritoryOwner];
_props pushBack ["TimeHeld", _currentTerritoryChrono];
_props pushBack ["TimeOccupied", _currentTerritoryTimer];

{
	[_fileName, _terName, _x select 0, _x select 1, false] call PDB_write; // iniDB_write
} forEach _props;

nil
