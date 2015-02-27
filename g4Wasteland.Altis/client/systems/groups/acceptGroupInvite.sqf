// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.0
//	@file Name: acceptGroupInvite.sqf
//	@file Author: [404] Deadbeat, AgentRev
//	@file Created: 20/11/2012 05:19
//  @file Modified: Munch 2015-02-20 to handle server-side group ownerships of territories
//  @file   This is a client-side script, invoked when a player accepts a group invite.  It 
//			sends pvar_processGroupInvite to the server for processing by \server\functions\processGroupInvite
//			which will handle any territory transfers and broadcast results back to affected clients

private ["_playerUID", "_senderUID", "_sender", "_newGroup"];

_playerUID = getPlayerUID player;

// Find the sender's UID
{
	if (_x select 1 == _playerUID) exitWith
	{
		_senderUID = _x select 0;
	};
} forEach currentInvites;

// Find the sender
if (!isNil "_senderUID") then
{
	{
		if (getPlayerUID _x == _senderUID) exitWith
		{
			_sender = _x;
			_newGroup = group _sender;
		};
	} forEach call allPlayers;
};

if (!isNil "_sender" && {side _newGroup == playerSide}) then
{
	_oldGroup = group player;

	[player] join _newGroup;
	waitUntil {_newGroup = group player; _newGroup != _oldGroup};

	if (_newGroup == group _sender) then
	{
		pvar_processGroupInvite = ["accept", _playerUID, _oldGroup, _newGroup];
		publicVariableServer "pvar_processGroupInvite";
	};

	player globalChat "You have accepted the invite.";
	player setVariable ["currentGroupRestore", _newGroup, true];
	player setVariable ["currentGroupIsLeader", false, true];
}
else
{
	if (!isNil "_senderUID") then
	{
		pvar_processGroupInvite = ["decline", _senderUID, _playerUID];
		publicVariableServer "pvar_processGroupInvite";
	};

	player globalChat "The group no longer exists or the leader disconnected / changed sides";
};
