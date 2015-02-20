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
_playerUID = getPlayerUID _player;
_playerTeam = side _player;
_playerGroup = group _player;
_JIP = _this select 1;

_markers = [];

{
	_markerName = _x select 1;   // markerName
	_markerCaptureUIDs = _x select 2; // marker capturer's UIDs
	_markerTeam = _x select 4;	  // ownerTeam
	_markerGroup = _x select 7;  // ownerGroup
	_markerGroupUIDs = _x select 8; // ownerGroupUIDs

	if (!(_markerTeam isEqual sideUnknown)) {
	
		// Special handling for independent's joining ...
		if (!(_playerTeam in [OPFOR,BLUFOR]) && !(_markerTeam in [OPFOR,BLUFOR])) then 
		{
			// 2nd priority:  assign player group membership to the group owning the territory, if the player appears in the _markerGroupUIDs and _markerGroup isn't null
			if (_playerUID in [_markerGroupUIDs] && !{_markerGroup isEQqualTo grpNull}) then
			{
				[_player] join _markerGroup;
				_playerGroup = _markerGroup;
			} else {
				// 1st priority: player previously capped this territory ... assign group ownership to his group
				if (_playerUID in _markerCaptureUIDs) then {
					// Indy player previously captured this UID ... assign/re-assign ownership of the marker to this player's group
					_x set [7, _playerGroup];
					_x set [8, [_playerUID]];
					_markerGroup = _playerGroup;
				};
			};
			_markers pushBack [_markerName, _markerTeam, _markerGroup];
		};
	};
	
} forEach currentTerritoryDetails;
	//		0 = Marker ID
	// 		1 = MarkerName: Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = SideHolder: (SIDE) side owning the point currently
	// 		5 = TimeHeld: (INTEGER) Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	//		7 = GroupHolder (GROUP) group owning the point currently (used when SideHolder=Independent)
	//		8 = GroupHolderUIDs []: UIDs of members in the GroupHolder group (used when SideHolder=Independent)
	
diag_log format ["updateConnectingClients [Player: %1] [JIP: %2]", _player, _JIP];

// exec updateTerritoryMarkers on the client passing the _markers array to loop over with ownerCheck set to true
[[[_markers, true], "territory\client\updateTerritoryMarkers.sqf"], "BIS_fnc_execVM", _player, false] call BIS_fnc_MP;
