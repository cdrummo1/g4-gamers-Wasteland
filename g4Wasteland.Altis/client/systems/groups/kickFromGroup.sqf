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

[_target] join grpNull;
_target setVariable ["currentGroupRestore", grpNull, true];
_target setVariable ["currentGroupIsLeader", false, true];
waitUntil {grpNull = group player};

pvar_processGroupInvite = ["kick", _senderUID, _playerUID];
publicVariableServer "pvar_processGroupInvite";


player globalChat format["you have kicked %1 from the group",name _target];
