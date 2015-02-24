// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: convertTerritoryOwner.sqf
//	@file Author: AgentRev
//  @file Modified: Munch 2015-02-20 to handle server-side group ownerships of territories changes

private ["_newTerritories", "_newGroup", "_territory", "_territorySavingOn", "_currentTerritoryID", "_currentTerritoryName", "_currentTerritoryOccupiersPlayers", 
"_currentTerritoryOwner", "_currentTerritoryChrono", "_currentTerritoryOwnerGroupUIDs", "_currentTerritoryOwnerGroup"];

_newTerritories = _this select 0;
_newGroup = _this select 1;

if (isNil "currentTerritoryDetails") exitWith {};

// attempt to be thread-safe with respect to monitorTerritories use of currentTerritoryDetails data
if (monitorTerritoriesActive) then {
	diag_log "[INFO] convertTerritoryOwner wait on monitorTerritories to go inactive";
	waitUntil {!monitorTerritoriesActive};
	diag_log "[INFO] convertTerritoryOwner resume";
};

{
	_newTerritoryOwners=[];
	_territory = _x;
	{
		if (_x select 1 == _territory) then
		{
			if (!(_currentTerritoryOwner in [BLUFOR,OPFOR])) then 
			{
				// update the currentTerritoriesDetails rec with the _newGroup
				_x set [7, _newGroup];
				
				// get the UIDs of the players currently in the new Territory Owners group
				_newTerritoryOwnerGroupUIDs = [];
				{
					if (isPlayer _x) then
					{
						_newTerritoryOwnerGroupUIDs pushBack _x;
					};
				} forEach (units _newGroup);
				
				// update the currentTerritoriesDetails rec with the member UIDs of the new group`
				_x set [8, _currentTerritoryOwnerGroupUIDs];
			
				// update the territory db record with the new group ID and group UIDs if this is an Indy territory
				if (_territorySavingOn) then 
				{
					_currentTerritoryID = _x select 0;
					_currentTerritoryName = _x select 1;
					_currentTerritoryOccupiersPlayers = _x select 2;
					_currentTerritoryOwner = _x select 4;
					_currentTerritoryChrono = _x select 5;
				
					// call fn_saveTerritory to persist the newly changed territory state, if persistence is on
					[_currentTerritoryID, _currentTerritoryName, _currentTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newGroup, _newTerritoryOwnerGroupUIDs] call fn_saveTerritory;
				};
			};
		};
		
		if (_x select 4 != sideUnknown) then {
			if (!(_x select 4 in [BLUFOR,OPFOR])) then
			{
				_newTerritoryOwners pushBack [_x select 1, _x select 7];  // territory/group
			} else {
				_newTerritoryOwners pushBack [_x select 1, _x select 4];	// territory/team
			};
		};
		
	} forEach currentTerritoryDetails;
} forEach _newTerritories;

if !(A3W_currentTerritoryOwners isEqualTo _newTerritoryOwners) then
{
	A3W_currentTerritoryOwners = _newTerritoryOwners;
	publicVariable "A3W_currentTerritoryOwners";
	
	diag_log text "[INFO] converTerritoryOwner: A3W_currentTerritoryOwners was updated:";
	{
		diag_log format ["    %1                  %2",_x select 0, _x select 1];   
	} forEach A3W_currentTerritoryOwners;
};
