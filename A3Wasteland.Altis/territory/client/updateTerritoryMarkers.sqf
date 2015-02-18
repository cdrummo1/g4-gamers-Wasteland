// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: updateTerritoryMarkers.sqf
//	@file Author: AgentRev

#define MARKER_BRUSH_OWNER "Solid"
#define MARKER_BRUSH_OTHER "DiagGrid"

private ["_territories", "_ownerCheck", "_isOwner", "_getTeamMarkerColor", "_marker", "_team", "_playerTeam"];

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
		_marker = _x select 0;
		_team = _x select 1;
		_playerTeam = if (typeName _team == "GROUP") then { group player } else { playerSide };

		diag_log format ["[INFO] updateTerritoryMarkers w/OwnerCheck handling territory=%1  marker=%2  _team=%3 _playerTeam=%4", _x,_marker,_team,_playerTeam];

		
		if (_team == _playerTeam) then
		{
			_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
		};
	}
	else
	{
		_marker = _x;

		diag_log format ["[INFO] updateTerritoryMarkers w/o OwnerCheck got '%1', handling marker=%2 _isOwner=%3", _x,_marker,_isOwner];

		
		if (_isOwner) then
		{
			_marker setMarkerColorLocal ([_team, true] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OWNER;
		}
		else
		{
			_marker setMarkerColorLocal ([_team, false] call _getTeamMarkerColor);
			_marker setMarkerBrushLocal MARKER_BRUSH_OTHER;
		};
	};
} forEach _territories;
