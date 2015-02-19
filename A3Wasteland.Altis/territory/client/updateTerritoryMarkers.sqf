// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: updateTerritoryMarkers.sqf
//	@file Author: AgentRev

// Notes: (Munch 2-18-2015) This script gets called two different ways:
//	Method 1: As the action on the public variable event handler for pvar_updateTerritoryMarkers (set & broadcast by the server monitorTerritories script when a territory is captured)
//	Method 2. As a remotely execVM'd script that gets called from the server-side onPlayerConnected handler
//
// These two different invocations get different arguments to process:
//	Method 1: 
//  		a. ["pvar_updateTerritoryMarkers", [_captureTeam, [[_captureName], false, _captureTeam, true]]] call fn_publicVariableAll;
//			Args:  [[_captureName], false, _captureTeam, true]
//		b. ["pvar_updateTerritoryMarkers", [_otherTeams, [[_captureName], false, _captureTeam, false]]] call fn_publicVariableAll;
//			Args: [[_captureName], false, _captureTeam, false]
//
//	Method 2:  [_markers, true], where _markers is an array of [_markerName, _markerTeam]  -> [[_markerName, _markerTeam], true]
// 

#define MARKER_BRUSH_OWNER "Solid"
#define MARKER_BRUSH_OTHER "DiagGrid"

private ["_hintText", "_territories", "_ownerCheck", "_isOwner", "_getTeamMarkerColor", "_marker", "_team", "_playerTeam"];

format ["updateTerritoryMarkers called with '%1'",_this] call BIS_fnc_log;
hint "utm called with "+_this;
_hintText="";

_territories = _this select 0;
_ownerCheck = [_this, 1, false, [false]] call BIS_fnc_param;
_team = [_this, 2, sideUnknown, [sideUnknown,grpNull]] call BIS_fnc_param;
_isOwner = [_this, 3, false, [false]] call BIS_fnc_param;

diag_log format ["[INFO] updateTerritoryMarkers called with _territories=%1  _ownerCheck=%2  _team=%3 _isOwner=%4", _territories,_ownerCheck,_team,_isOwner];

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

{
	if (_ownerCheck) then
	{
	
		// invoked when _ownerCheck is true, i.e. when execVM'd from the server by updateConnectingClients 
	
		_marker = _x select 0;
		_team = _x select 1;
		//_playerTeam = if (typeName _team == "GROUP") then { group player } else { playerSide };
		_playerTeam = playerSide;
		
		diag_log format ["updateTerritoryMarkers: _ownerCheck is true with _marker='%1' _team='%2' (typeName=%3), _playerTeam='%4' (typeName=%5)",_marker, _team, typeName _team, _playerTeam, typeName _playerTeam];
		format ["updateTerritoryMarkers: _ownerCheck is true with _marker='%1' _team='%2' (typeName=%3), _playerTeam='%4' (typeName=%5)",_marker, _team, typeName _team, _playerTeam, typeName _playerTeam] call BIS_fnc_log;
		_hintText = _hintText + "_marker:"+_marker+" _team="+format["%1",_team]+"(type="+(typeName _team)+") _playerTeam="+format["%1",_playerTeam]+"(type="+(typeName _playerTeam)+")\n";

		if (_team == _playerTeam) then
		{
			_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
			format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker] call BIS_fnc_log;
			diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker];
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
			format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker] call BIS_fnc_log;
			diag_log format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker];
		};
	}
	else
	{
	
		// invoked when _ownerCheck is false, i.e., on pvar_updateTerritoryMarkers broadcasts after a territory capture event
		_marker = _x;

		format ["updateTerritoryMarkers: _ownerCheck is false with _marker='%1' _isOwner=%2",_marker, _isOwner] call BIS_fnc_log;
		
		if (_isOwner) then
		{
			_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
			format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OWNER",_marker] call BIS_fnc_log;
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
			format ["updateTerritoryMarkers: setting marker=%1 with MARKER_BRUSH_OTHER",_marker] call BIS_fnc_log;
		};
	};
} forEach _territories;

hint _hintText;
diag_log _hintText;
_hintText call BIS_fnc_log;
