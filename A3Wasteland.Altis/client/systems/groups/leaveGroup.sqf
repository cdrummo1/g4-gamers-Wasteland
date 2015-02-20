// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.0
//	@file Name: leaveGroup.sqf
//	@file Author: [404] Deadbeat
//	@file Created: 20/11/2012 05:19
//  @file Modified: Munch 2015-02-20 revise to handle server-side group ownerships of territories

private ["_oldTeam", "_oldTerritories"];

_oldGroup = group player;

if (!(_oldTeam in [OPFOR,BLUFOR])) then 
{
	[_oldGroup getVariable ["currentTerritories", []], false, side _oldGroup, false] call updateTerritoryMarkers;
};

[player] join grpNull;
player setVariable ["currentGroupRestore", grpNull, true];
player setVariable ["currentGroupIsLeader", false, true];

// remove the player from the currentTerritoryDetails & persistence recs for this group
_oldTerritories = _oldGroup getVariable ["currentTerritories", []];
pvar_convertTerritoryOwner = [_oldTerritories, _oldGroup];
publicVariableServer "pvar_convertTerritoryOwner";

