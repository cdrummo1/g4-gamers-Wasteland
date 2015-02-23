// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
/*********************************************************#
# @@ScriptName: updateConnectingClients.sqf
# @@Author: Nick 'Bewilderbeest' Ludlam <bewilder@recoil.org>, AgentRev, Munch
# @@Create Date: 2013-09-15 16:26:38
# @@Modify Date: 2015-02-22 by Munch to handle persistent territory data
# @@Function: Updates connecting players with the correct territory colours/brushes
#*********************************************************/

if (!isServer) exitWith {};

// Exit if territories are not set
if (isNil "currentTerritoryDetails" || {count currentTerritoryDetails == 0}) exitWith {};

private ["_player", "_playerUID", "_playerTeam", "_playerGroup", "_JIP", "_markers", "_newTerritoryOwners", "_newTerritoryDetails", "_markerId", "_markerName", "_markerCaptureUIDs", "_markerCapturePlayers",
 "_markerTeam", "_markerTeam2", "_markerChrono", "_markerTimer", "_markerGroup", "_markerGroupUIDs"];

_player = _this select 0;
_playerUID = getPlayerUID _player;
_playerTeam = side _player;
_playerGroup = group _player;
_JIP = _this select 1;

diag_log format ["[INFO] updateConnectingClients handling request from [Player: %1] [JIP: %2]", _player, _JIP];

_markers = [];
_newTerritoryOwners = [];
_newTerritoryDetails = [];
{
	_found = false;
	_markerId = _x select 0;	// markerID
	_markerName = _x select 1;   // markerName
	_markerCaptureUIDs = _x select 2; // marker capturer's UIDs
	_markerCapturePlayers = _x select 3;
	_markerTeam = _x select 4;	  // ownerTeam
	_markerTeam2 = _markerTeam;
	_markerChrono = _x select 5; 
	_markerTimer = _x select 6;
	_markerGroup = _x select 7;  // ownerGroup
	_markerGroupUIDs = _x select 8; // ownerGroupUIDs
	
	if (!(_markerTeam in [sideUnknown])) then {
		// Special handling for independent's joining ...
		if (!(_markerTeam in [BLUFOR,OPFOR])) then 
		{
			if (!(_playerTeam in [BLUFOR,OPFOR])) then 
			{
				// assign player group membership to the group owning the territory, if the player appears in the _markerGroupUIDs and _markerGroup isn't null
				if ((_playerUID in [_markerGroupUIDs]) && {!(_markerGroup isEqualTo grpNull)}) then
				{
					[_player] join _markerGroup;
					_playerGroup = _markerGroup;
					diag_log format ["[INFO] updateConnectingClients: player %1 UID is in markerGroupUIDs for %2 -> joining player to group %3 (PRI 2 Assign)", _player, _markerName, _markerGroup];
				} else {
					// 1st priority: player previously capped this territory ... assign group ownership of this territory to his group
					if (_playerUID in _markerCaptureUIDs) then 
					{
						// Indy player previously captured this UID ... assign/re-assign ownership of the marker to this player's group & clear other UIDs
						_markerGroupUIDs = _playerUID;
						_markerGroup = _playerGroup;
						diag_log format ["[INFO] updateConnectingClients: player %1 UID is in markerCaptureUIDs for %2 -> assigning marker to playerGroup (%3) (PRI 1 Assign)", _player, _markerName, _markerGroup];
						_found = true;
					};
					
					if (_playerUID in [_markerGroupUIDs] && {!_found}) then 
					{
						// Indy player was previously member of a now non-recognized group that still owns this territory ... re-assign group ownership, but keep other UIDs
						_markerGroup = _playerGroup;
					};
				};
			}; 
			_markerTeam2 = _markerGroup;  // assign group to team2 for Indy's
		};
		
		// add to the array to be sent to the connecting client
		_markers pushBack [_markerName, _markerTeam, _markerGroup];
	}; 
	
	_newTerritoryDetails pushBack [_markerId, _markerName, _markerCaptureUIDs, _markerCapturePlayers, _markerTeam, _markerChrono, _markerTimer, _markerGroup, _markerGroupUIDs];
	_newTerritoryOwners pushBack [_markerName, _markerTeam2];	// territory/team|group
} forEach currentTerritoryDetails;
	
if !(A3W_currentTerritoryOwners isEqualTo _newTerritoryOwners) then
{
	// update the scoreboard var if any assignment changes happened
	A3W_currentTerritoryOwners = _newTerritoryOwners;
	publicVariable "A3W_currentTerritoryOwners";
};	

if !(currentTerritoryDetails isEqualTo _newTerritoryDetails) then
{
	if (monitorTerritoriesActive) then {
		diag_log "[INFO] updateConnectingClients wait on monitorTerritories to go inactive";
		waitUntil {!monitorTerritoriesActive};
		diag_log "INFO] updateConnectingClients resume";
	};
	// update currentTerritoryDetails if any parts of it changed
	currentTerritoryDetails = _newTerritoryDetails;
};

if (_JIP) then 
{
	// exec updateTerritoryMarkers on the client passing the _markers array to loop over with ownerCheck set to true
	[[[_markers, true], "territory\client\updateTerritoryMarkers.sqf"], "BIS_fnc_execVM", _player, false] call BIS_fnc_MP;
} else {
	// return the result to local caller to return back to the client as a targeted pvar for use on the client
	[_markers, true]
};
