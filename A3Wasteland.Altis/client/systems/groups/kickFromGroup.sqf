// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.0
//	@file Name: kickFromGroup.sqf
//	@file Author: [404] Deadbeat
//	@file Created: 20/11/2012 05:19
//  @file Modified: Munch 2015-02-20 revise to handle server-side group ownerships of territories

#define groupManagementDialog 55510
#define groupManagementGroupList 55512

disableSerialization;

private ["_dialog", "_groupListBox", "_index", "_playerData", "_oldTerritories"];

_dialog = findDisplay groupManagementDialog;
_groupListBox = _dialog displayCtrl groupManagementGroupList;

_index = lbCurSel _groupListBox;
_playerData = _groupListBox lbData _index;

//Check selected data is valid
{ if (getPlayerUID _x == _playerData) exitWith { _target = _x } } forEach (call allPlayers);

//Checks
if (isNil "_target") exitWith {player globalChat "you must select someone to kick first"};
if (_target == player) exitWith {player globalChat "you can't kick yourself"};

_group = group _target;  // the group to kick the target from

if (!(side _target in [OPFOR,BLUFOR])) then 
{
	// indy player got kicked ... update his display to show he no longer has ownership of the group's territories
	pvar_updateTerritoryMarkers = [_target, [_group getVariable ["currentTerritories", []], false, side _target, false]];
	publicVariable "pvar_updateTerritoryMarkers";	
};

[_target] join grpNull;
_target setVariable ["currentGroupRestore", grpNull, true];
_target setVariable ["currentGroupIsLeader", false, true];

// remove the player from the currentTerritoryDetails & persistence recs for this group
_oldTerritories = _group getVariable ["currentTerritories", []];
pvar_convertTerritoryOwner = [_oldTerritories, _group];
publicVariableServer "pvar_convertTerritoryOwner";

player globalChat format["you have kicked %1 from the group",name _target];
