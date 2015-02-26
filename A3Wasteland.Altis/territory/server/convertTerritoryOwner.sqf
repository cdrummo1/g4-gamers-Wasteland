// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: convertTerritoryOwner.sqf
//	@file Author: AgentRev
//  @file Modified: Munch 2015-02-20 to handle server-side group ownerships of territories changes

private ["_newTerritories", "_newGroup", "_territory", "_territorySavingOn", "_currentTerritoryID", "_currentTerritoryName", "_currentTerritoryOccupiersPlayers", "_currentTerritoryOcupiersUIDs",
"_currentTerritoryOwner", "_currentTerritoryChrono", "_currentTerritoryOwnerGroupUIDs", "_currentTerritoryOwnerGroup"];

_newTerritories = _this select 0;
_newGroup = _this select 1;

// get the UIDs of the players currently in the new group
_newTerritoryOwnerGroupUIDs = [];
{
	if (isPlayer _x) then
	{
		_newTerritoryOwnerGroupUIDs pushBack getPlayerUID _x;
	};
} forEach (units _newGroup);


diag_log format ["[INFO] convertTerritoryOwner called with _newTerritories='%1'  _newGroup='%2'",_newTerritories, _newGroup];
diag_log format ["[INFO] convertTerritoryOwner _newGroup has the following UIDs: %1", _newTerritoryOwnerGroupUIDs];

if (isNil "currentTerritoryDetails") exitWith {};

// attempt to be thread-safe with respect to monitorTerritories use of currentTerritoryDetails data
if (monitorTerritoriesActive) then {
	diag_log "[INFO] convertTerritoryOwner wait on monitorTerritories to go inactive";
	waitUntil {!monitorTerritoriesActive};
	diag_log "[INFO] convertTerritoryOwner resume";
};

_newTerritoryDetails=[];
_newTerritoryOwners=[];
{
	//		0 = Marker ID
	// 		1 = MarkerName: Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = SideHolder: (SIDE) side owning the point currently
	// 		5 = TimeHeld: (INTEGER) Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	//		7 = GroupHolder (GROUP) group owning the point currently (used when SideHolder=Independent)
	//		8 = GroupHolderUIDs []: UIDs of members in the GroupHolder group (used when SideHolder=Independent)

	_currentTerritoryID = _x select 0;				// INT ID
	_currentTerritoryName = _x select 1;				// STRING markerName
	_currentTerritoryOccupiersUIDs = _x select 2;		// [uid,uid,uid,...]
	_currentTerritoryOccupiersPlayers = _x select 3;	// [player, player, player, ...]
	_currentTerritoryOwner = _x select 4;			// SIDE 
	_currentTerritoryChrono = _x select 5;			// INTEGER timeHeld
	_currentTerritoryTimer = _x select 6;			// INTEGER timeOccupied by enemy
	_currentTerritoryOwnerGroup = _x select 7;		// GROUP
	_currentTerritoryOwnerGroupUIDs = _x select 8;	// [uid,uid,uid,...]

	{ // loop over _newTerritories
		if (_x == _currentTerritoryName) then
		{
			if (!(_currentTerritoryOwner in [BLUFOR,OPFOR])) then 
			{
				// update the currentTerritoriesDetails rec with the _newGroup
				_currentTerritoryOwnerGroup = _newGroup;
				
				// update the currentTerritoriesDetails rec with the member UIDs of the new group`
				_currentTerritoryOwnerGroupUIDs = _newTerritoryOwnerGroupUIDs;

				// update the territory db record with the new group ID and group UIDs if this is an Indy territory
				if (_territorySavingOn) then 
				{
					// call fn_saveTerritory to persist the newly changed territory state, if persistence is on
					[_currentTerritoryID, _currentTerritoryName, _currentTerritoryOcupiersUIDs, _currentTerritoryOwner, _currentTerritoryChrono, _newGroup, _newTerritoryOwnerGroupUIDs] call fn_saveTerritory;
					diag_log format ["convertTerritoryOwner updated territory data with [%1,%2,%3,%4,%5,%6,%7]",_currentTerritoryID, _currentTerritoryName, _currentTerritoryOcupiersUIDs, _currentTerritoryOwner, _currentTerritoryChrono, _newGroup, _newTerritoryOwnerGroupUIDs];
				};
			};
		};
	} forEach _newTerritories;

	if (_currentTerritoryOwner != sideUnknown) then {
		if (!(_x select 4 in [BLUFOR,OPFOR])) then
		{
			_newTerritoryOwners pushBack [_currentTerritoryName, _currentTerritoryOwnerGroup];  // territory/group
		} else {
			_newTerritoryOwners pushBack [_currentTerritoryName, _currentTerritoryOwner];	// territory/team
		};
	};
	
	_newTerritoryDetails pushBack [_currentTerritoryID,_currentTerritoryName,_currentTerritoryOccupiersUIDs,_currentTerritoryOccupiersPlayers,_currentTerritoryOwner,_currentTerritoryChrono,_currentTerritoryTimer,_currentTerritoryOwnerGroup,_currentTerritoryOwnerGroupUIDs];
} forEach currentTerritoryDetails;

// update currentTerritoryDetails
currentTerritoryDetails = _newTerritoryDetails;


if !(A3W_currentTerritoryOwners isEqualTo _newTerritoryOwners) then
{
	A3W_currentTerritoryOwners = _newTerritoryOwners;
	publicVariable "A3W_currentTerritoryOwners";
	
	diag_log text "[INFO] converTerritoryOwner: A3W_currentTerritoryOwners was updated:";
	{
		diag_log format ["    %1                  %2",_x select 0, _x select 1];   
	} forEach A3W_currentTerritoryOwners;
};
