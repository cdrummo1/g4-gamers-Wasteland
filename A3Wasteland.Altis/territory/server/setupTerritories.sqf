// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: setupTerritories.sqf
//	@file Author: Munch after AgentRev's setupPlayerDB.sqf
//  creates pvar handler for client calls to request territory state data on connection
// 

if (!isServer) exitWith {};

"pvar_requestTerritoryData" addPublicVariableEventHandler
{
	// _this = [player, getPlayerUID player, netId player]
	(_this select 1) spawn
	{
		_player = _this select 0;
		_UID = _this select 1;
		_netID = _this select 2;
		
		if (!isNil "updateConnectingClients") then
		{
			_data = [_player, false] call updateConnectingClients;
		
			[[_this, _data],
			{
				_pVal = _this select 0;
				_data = _this select 1;

				_player = _pVal select 0;
				_UID = _pVal select 1;
				_pNetId = _pVal select 2;

				_pvarName = "pvar_applyTerritoryData_" + _UID;

				missionNamespace setVariable [_pvarName, _data];
				(owner _player) publicVariableClient _pvarName;
			}] execFSM "call.fsm";
		} else {
			diag_log format ["[ERROR] setupTerritories called by player=%1, but updateConnectingClients is nil so can't proceed!",_player];
		};
	};
};
