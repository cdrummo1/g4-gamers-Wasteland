// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.0
//	@file Name: leaveGroup.sqf
//	@file Author: [404] Deadbeat
//	@file Created: 20/11/2012 05:19
//  @file Modified: Munch 2015-02-20 revise to handle server-side group ownerships of territories

private ["_oldGroup", "_playerUID"];

_oldGroup = group player;

[player] join grpNull;
player setVariable ["currentGroupRestore", grpNull, true];
player setVariable ["currentGroupIsLeader", false, true];

// have the server remove the player from territory ownerships
pvar_processGroupInvite = ["leave", player, _oldGroup];
publicVariableServer "pvar_processGroupInvite";

