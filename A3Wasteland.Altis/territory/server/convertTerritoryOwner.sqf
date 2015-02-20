// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: convertTerritoryOwner.sqf
//	@file Author: AgentRev

private ["_newTerritories", "_newGroup", "_territory", "_territorySavingOn", "_currentTerritoryID", "_currentTerritoryName", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOwner", "_currentTerritoryChrono", 
"_currentTerritoryOwnerGroupUIDs", "_currentTerritoryOwnerGroup"];

_newTerritories = _this select 0;
_newGroup = _this select 1;

if (isNil "currentTerritoryDetails") exitWith {};

{
	_territory = _x;
	{
		if (_x select 1 == _territory) exitWith
		{
			_x set [7, _newGroup];
			//_x set [3, 0]; // reset chrono
			
			
			// update the territory db record with the new group ID and group UIDs
			if (_territorySavingOn) then 
			{
				_currentTerritoryID = _x select 0;
				_currentTerritoryName = _x select 1;
				_currentTerritoryOccupiersPlayers = _x select 2;
				_currentTerritoryOwner = _x select 4;
				_currentTerritoryChrono = _x select 5;
			
				// get the UIDs of the players currently in the new Territory Owners group
				_currentTerritoryOwnerGroupUIDs = [];
				{
					if (isPlayer _x) then
					{
						_currentTerritoryOwnerGroupUIDs pushBack _x;
					};
				} forEach (units _newGroup);
			
				// call fn_saveTerritory to persist the newly changed territory state, if persistence is on
				[_currentTerritoryID, _currentTerritoryName, _currentTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _currentTerritoryOwnerGroup, _currentTerritoryOwnerGroupUIDs] call fn_saveTerritory;

			};
			
		};
	} forEach currentTerritoryDetails;
} forEach _newTerritories;
