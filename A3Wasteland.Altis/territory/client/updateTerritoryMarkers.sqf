// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: updateTerritoryMarkers.sqf
//	@file Author: AgentRev

// Notes: (Munch 2-18-2015) This script gets called three different ways:
//	Method 1: As the action on the public variable event handler for pvar_updateTerritoryMarkers (set & broadcast by the server monitorTerritories script when a territory is captured, or when a player is kicked from a group)
//	Method 2. As execVM'd from applyTerritory data with payload from pvar_request/response of territory data on client initialization
//   Method 3: As a client-side direct call from e.g., <acceptGroupInvite, leaveGroup>.sqf
//
// These two different invocations get different arguments to process:
//	Methods 1 & 3: 
//  		1.a. ["pvar_updateTerritoryMarkers", [_captureTeam, [[_captureName], false, _captureTeam, true]]] call fn_publicVariableAll;
//			Args:  [[_captureName], false, _captureTeam, true] *
//		1.b. ["pvar_updateTerritoryMarkers", [_otherTeams, [[_captureName], false, _captureTeam, false]]] call fn_publicVariableAll;
//			Args: [[_captureName], false, _captureTeam, false] *
//		1.c  pvar_updateTerritoryMarkers = [_target, [_group getVariable ["currentTerritories", []], false, _targetSide, false]]; (Indy kickFromGroup)
//			Args:  [_group getVariable ["currentTerritories", []], false, _targetSide, false]  (Indy kickFromGroup) *
//		3.a  [_newTerritories, false, side _newGroup, true] call updateTerritoryMarkers;  (Indy acceptGroupInvite)  -- add territories *
//		3.b  [_oldGroup getVariable ["currentTerritories", []], false, _team, false] call updateTerritoryMarkers; (Indy leaveGroup)) -- remove territories *
//
//	Method 2:  [_markers, true], where _markers is an array of [_markerName, _markerTeam, _markerGroup] (remote execVM from server updateConnectingClients)
//			Args: [[_markerName, _markerTeam, _markerGroup], true]
// 
// [_newTerritories, false, _newGroup, true]

#define MARKER_BRUSH_OWNER "Solid"
#define MARKER_BRUSH_OTHER "DiagGrid"

private ["_hintText", "_territories", "_ownerCheck", "_isOwner", "_getTeamMarkerColor", "_marker", "_team", "_playerTeam", "_countSetOwner"];

diag_log format ["updateTerritoryMarkers called with '%1'",_this];

_hintText="";
_countSetOwner=0;
_territories = _this select 0;
_ownerCheck = [_this, 1, false, [false]] call BIS_fnc_param;
_team = [_this, 2, sideUnknown, [sideUnknown]] call BIS_fnc_param;
_isOwner = [_this, 3, false, [false]] call BIS_fnc_param;

diag_log format ["[INFO] updateTerritoryMarkers called with _territories=%1  _ownerCheck=%2  _team=%3 _isOwner=%4", _territories,_ownerCheck,_team,_isOwner];
diag_log format ["[INFO] player %1 is in group %2", player, group player];

_getTeamMarkerColor = if (isNil "getTeamMarkerColor") then
{
	compile preprocessFileLineNumbers "territory\client\getTeamMarkerColor.sqf";
}
else
{
	getTeamMarkerColor
};

if (isNull player) then
{
	waitUntil {!isNull player};
};


{	// loop over the array of territories
	if (_ownerCheck) then
	{
		// Method 2: invoked when _ownerCheck is true, i.e. when execVM'd from the server by updateConnectingClients 
		// we're looping over the array of '_territories', each containing: [_markerName, _markerTeam, _markerGroup]
		_marker = _x select 0;
		_team = _x select 1;
		_group = _x select 2;

		_playerTeam = playerSide;
		_playerGroup = group player;
		
		diag_log format ["updateTerritoryMarkers: _ownerCheck is true with _marker='%1' _team='%2' (typeName=%3), _group'%4' (typeName=%5) _playerTeam='%6' (typeName=%7)",_marker, _team, typeName _team, _group, typeName _group, _playerTeam, typeName _playerTeam];
		
		if (_team == _playerTeam) then
		{
			if ((_team in [OPFOR,BLUFOR]) || {(!(_team in [OPFOR,BLUFOR])) && _group isEqualTo _playerGroup}) then 
			{
				_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
				_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
				//format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker] call BIS_fnc_log;
				diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker];
				_countSetOwner=_countSetOwner+1;
			} else {
				_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
				_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
				//format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker] call BIS_fnc_log;
				diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker];
			};
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
			//format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker] call BIS_fnc_log;
			diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker];
		};
	}
	else
	{
		// Method 1 & 3: invoked when _ownerCheck is false, i.e., on pvar_updateTerritoryMarkers broadcasts after a territory capture event, or direct calls
		// we're looping over the array of '_territories', each containing: _markerName that we're either setting or unsetting owner on as a whole
		_marker = _x;

		diag_log format ["updateTerritoryMarkers: _ownerCheck is false with _marker='%1' _isOwner=%2",_marker, _isOwner];
		
		if (_isOwner) then
		{
			_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
			diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker];
			_countSetOwner=_countSetOwner+1;
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
			diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker];
		};
	};
} forEach _territories;

//diag_log format ["[INFO] updateTerritoryMarkers exiting after setting %1 markers as owner", _countSetOwner];
