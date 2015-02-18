// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
/*********************************************************#
# @@ScriptName: updateConnectingClients.sqf
# @@Author: Nick 'Bewilderbeest' Ludlam <bewilder@recoil.org>, AgentRev
# @@Create Date: 2013-09-15 16:26:38
# @@Modify Date: 2013-09-15 17:22:37
# @@Function: Updates JIP players with the correct territory colours
#*********************************************************/

if (!isServer) exitWith {};

// Exit if territories are not set
if (isNil "currentTerritoryDetails" || {count currentTerritoryDetails == 0}) exitWith {};

private ["_player", "_JIP", "_markers", "_markerName", "_markerTeam"];

_player = _this select 0;
_JIP = _this select 1;

_markers = [];

{
	_markerName = _x select 1;
	_markerTeam = _x select 4;

	if (typeName _markerTeam == "GROUP" || {_markerTeam != sideUnknown}) then
	{
		_markers pushBack [_markerName, _markerTeam];
	};
} forEach currentTerritoryDetails;
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = side owning the point currently
	// 		5 = Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	
diag_log format ["updateConnectingClients [Player: %1] [JIP: %2]", _player, _JIP];

[[[_markers, true], "territory\client\updateTerritoryMarkers.sqf"], "BIS_fnc_execVM", _player, false] call BIS_fnc_MP;
