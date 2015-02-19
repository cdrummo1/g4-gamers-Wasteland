// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
/*********************************************************#
# @@ScriptName: monitorTerritories.sqf
# @@Author: Nick 'Bewilderbeest' Ludlam <bewilder@recoil.org>, AgentRev
# @@Create Date: 2013-09-09 18:14:47
# @@Modify Date: 2013-09-15 22:40:31
# @@Function:
#*********************************************************/


// Note this is currently unoptimised, and may cause slowness on heavily populated servers
// but it has built-in lag compensation through the use of diag_tickTime to monitor loop
// timings!


// Capture point monitoring explanation:

// 1. Loop through each player on the server to see if they have a variable
//    called TERRITORY_OCCUPATION (which their client sets on them when they
//    move into a territory zone) and collect into a KEY:VALUE pair
//    containing the player and the territory zone they're in
//
// 2. Reduce this array down into an array of each territory currently occupied
//    and an array of the players in that zone
//
// 3. Call _handleCapPointTick with this array. This goes through each territory
//    in turn and compares the current occupants with those from the previous tick
//
// 4. For each territory we call _teamCountsForPlayerArray which returns the
//    relative size of each team in the area
//
// 5. The team counts are then passed to _handleTeamCounts which assesses
//    the action to be taken for each territory: CAPTURE< BLOCK or RESET
//
//    CAPTURE means that the currently dominant team is uncontested and the
//    capture timer should tick up
//
//    BLOCK means the territory is contested and the capture timer does not
//    move
//
//    RESET means that the previous timer value needs to be reset as the
//    dominant team in that territory has changed since the last tick
//
// 6. If the territory timer has reached the capture period then the territory
//    ownership changes in favour of the dominant team. Notifications are sent
//    and the team gets some money.

// In addition, the server gives each player a TERRITORY_ACTIVITY variable which
// denotes capture activity


// timings
#define BASE_SLEEP_INTERVAL 10
#define CAPTURE_PERIOD (3*60) // now A3W_territoryCaptureTime in server config, this is only the fallback value

if(!isServer) exitWith {};

// Prep the lastCapturePointDetails array with our areas to check later on
//
// The idea here is that lastCapturePointDetails holds our structured data checked
// every loop.
//

currentTerritoryDetails = [];
	//		0 = Marker ID
	// 		1 = MarkerName: Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = SideHolder: (SIDE) side owning the point currently
	// 		5 = TimeHeld: (INTEGER) Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)
	//		7 = GroupHolder (GROUP) group owning the point currently (used when SideHolder=Independent)
	//		8 = GroupHolderUIDs []: UIDs of members in the GroupHolder group (used when SideHolder=Independent)

// set A3W_currentTerritoryOwners to empty
A3W_currentTerritoryOwners = [];

diag_log "monitorTerritories initialization start";

// Set up for persistence data, if available, and set initial territory cap states
_territoriesInitialState=[];
_territorySavingOn = ["A3W_territorySaving"] call isConfigOn;
_territoryLoggingOn = ["A3W_territoryLogging"] call isConfigOn && {["A3W_savingMethod", "profile"] call getPublicVar == "extDB"};

diag_log format ["[INFO] monitorTerritories startup with A3W_territoryLogging = %1, A3W_savingMethod = %2 -> _territoryLoggingOn = %3", ["A3W_territoryLogging"] call isConfigOn, ["A3W_savingMethod", "profile"] call getPublicVar, _territoryLoggingOn];

if (_territorySavingOn) then
{
	private ["_newTerritoryOwners"];
	diag_log "monitorTerritories _territorySavingOn is TRUE ... tSave/tLoad invoke";
	call compile preprocessFileLineNumbers "persistence\server\world\tSaveInit.sqf";  // will compile the single territory save method to fn_saveTerritory
	currentTerritoryDetails =  call compile preprocessFileLineNumbers "persistence\server\world\tLoad.sqf";  
	diag_log format ["monitorTerritories: tLoad returned %1 currentTerritoryDetails", count currentTerritoryDetails];
	
	_newTerritoryOwners = [];
	
	{
		diag_log _x;
		
		// get the occupier status
		_currentTerritoryName = _x select 1;
		_currentTerritoryOwner = _x select 4;
		
		//diag_log format ["currentTerritoryDetails rec: %1, %2, %3, %4, %5, %6, ", _currentTerritoryName, _x select 1, _x select 2, _currentTerritoryOwner, _x select 4, _x select 5, _x select 6];
		//diag_log format ["        _currentTerritoryOwner is type %1", typeName   _currentTerritoryOwner];
		if (_currentTerritoryOwner != sideUnknown) then {
			// update the map to show that this territory is occupied
			_newMarkerColor = [_currentTerritoryOwner] call getTeamMarkerColor;
			_currentTerritoryName setMarkerColor _newMarkerColor;
		};
		
		diag_log format ["currentTerritories: marker: %1  owner: %2 typeName(owner): %3", _currentTerritoryName,_currentTerritoryOwner, typeName _currentTerritoryOwner];
		
		_newTerritoryOwners pushBack [_currentTerritoryName,_currentTerritoryOwner];
	} foreach currentTerritoryDetails;
	
	// Set A3W_currentTerritoryOwners with results from load
	A3W_currentTerritoryOwners = _newTerritoryOwners;
	publicVariable "A3W_currentTerritoryOwners";	
} else {
	diag_log "monitorTerritories _territorySavingOn is FALSE ... populating currentTerritoryDetails with default data";
	{
		_markerName = _x select 1;
		//diag_log format ["Adding %1 to lastCapturePointDetails", _markerName];
		currentTerritoryDetails pushBack [0,_markerName, [], [], sideUnknown, 0, 0];
	} forEach (["config_territory_markers", []] call getPublicVar);
};



// This will track how long each loop takes, to monitor how long it really ends up taking when
// the server is lagging to shit
_realLoopTime = BASE_SLEEP_INTERVAL;
_capturePeriod = ["A3W_territoryCaptureTime", CAPTURE_PERIOD] call getPublicVar;

// Store a note of the UID of every player we're indicating is blocked by setting a variable on them.
// We need to mark-sweep this array each iteration to remove contested capping when the territory
// becomes unblocked!
_oldPlayersWithTerritoryActivity = [];
_newPlayersWithTerritoryActivity = [];

//diag_log format["currentTerritoryDetails = %1", currentTerritoryDetails];

//////////////////////////////////////////////////////////////////////////////////////////////////

_isInTeam =
{
	//diag_log format ["_isInTeam called with %1", _this];

	private ["_player", "_team", "_playerTeam"];

	_player = _this select 0;
	_team = _this select 1;
	_playerTeam = group _player;
	if (typeName _team == "SIDE") then { _playerTeam = side _playerTeam };

	(_playerTeam == _team)
};

// Trigger for when a capture of a territory has started
_onCaptureStarted =
{
	private ["_territoryDescriptiveName", "_ownerTeam", "_msg", "_sideObject", "_descriptiveTeamName"];

	_territoryDescriptiveName = _this select 0;
	_ownerTeam = _this select 1;

	/*
	if (_ownerTeam != "") then
	{
		_sideObject = [_ownerTeam] call _sideObjectForSideStr;
		_descriptiveTeamName = [_ownerTeam] call _getTeamName;
		_msg = format["Your territory at %1 is being captured by %2!", _territoryDescriptiveName, _descriptiveTeamName];
		[[_msg], "A3W_fnc_territoryActivityHandler", _sideObject, false] call A3W_fnc_MP;
	};
	*/
};

// Trigger for when a capture of a territory has ended.
_onCaptureFinished =
{
	private ["_oldTeam", "_captureTeam", "_captureValue", "_captureName", "_captureDescription", "_descriptiveTeamName", "_otherTeams", "_captureColor", "_groupCaptures", "_msgWinners", "_msgOthers"];

	diag_log format["_onCapture called with %1", _this];

	_oldTeam = _this select 0;
	_captureTeam = _this select 1;
	_captureValue = _this select 2;
	_captureName = _this select 3;
	_captureDescription = _this select 4;
	_descriptiveTeamName = [_captureTeam] call _getTeamName;

	_otherTeams = [BLUFOR,OPFOR];

	{
		if (!((side _x) in [BLUFOR,OPFOR]) && {{isPlayer _x} count units _x > 0}) then
		{
			_otherTeams pushBack _x;
		};
	} forEach allGroups;

	_otherTeams = _otherTeams - [_captureTeam];

	_captureColor = [_captureTeam, true] call getTeamMarkerColor;

	if (typeName _oldTeam == "GROUP" && {!isNull _oldTeam}) then
	{
		_groupCaptures = (_oldTeam getVariable ["currentTerritories", []]) - [_captureName];
		_oldTeam setVariable ["currentTerritories", _groupCaptures, true];
	};

	if (typeName _captureTeam == "GROUP") then
	{
		_groupCaptures = (_captureTeam getVariable ["currentTerritories", []]) + [_captureName];
		_captureTeam setVariable ["currentTerritories", _groupCaptures, true];
	};

	["pvar_updateTerritoryMarkers", [_captureTeam, [[_captureName], false, _captureTeam, true]]] call fn_publicVariableAll;
	["pvar_updateTerritoryMarkers", [_otherTeams, [[_captureName], false, _captureTeam, false]]] call fn_publicVariableAll;

	_msgWinners = format ["Your team has successfully captured %1 and you've received $%2", _captureDescription, _captureValue];
	["pvar_territoryActivityHandler", [_captureTeam, [_msgWinners, _captureValue]]] call fn_publicVariableAll;

	_msgOthers = format ["%1 has captured %2", _descriptiveTeamName, _captureDescription];
	["pvar_territoryActivityHandler", [_otherTeams, [_msgOthers]]] call fn_publicVariableAll;
};

// Give the human readable name for a team
_getTeamName =
{
	private ["_team", "_teamName"];
	_team = _this select 0;
	//diag_log format["_getTeamName called with %1", _this];

	_teamName = if (typeName _team == "GROUP") then
	{
		"An independent group";
	}
	else
	{
		switch (_team) do
		{
			case BLUFOR: { "BLUFOR" };
			case OPFOR:  { "OPFOR" };
			default      { "Independent" };
		};
	};

	//diag_log format["_getTeamName returning %1", _teamName];

	_teamName
};

// arg: a player object
// ret: BLUFOR, OPFOR side object or group object if Independent
_getPlayerTeam =
{
	private ["_group", "_side"];
	_group = group _this;
	_side = side _group;

	if (_side in [BLUFOR,OPFOR]) then {	_side } else { _group }
};

// Count players in a particular area for each team, and calculate if its
// uncontested or contested, and whether there's a dominant team
_teamCountsForPlayerArray =
{
	//diag_log format["_teamCountsForPlayerArray called with %1", _this];

	private ["_uids", "_players", "_teamCounts", "_contested", "_dominantTeam", "_newTeamCounts", "_playerTeam", "_added", "_team1", "_team1count", "_team2count", "_i"];
	_players = _this select 0;

	_teamCounts = [];

	_contested = false; // true if there are more than one team present
	_dominantTeam = sideUnknown;

	if (count _players > 0) then
	{
		// we have an array of players from the _newTeamCounts setter call
		{
			_playerTeam = _x call _getPlayerTeam;  // side or group if Indy
			// diag_log format ["call to _getPlayerTeam for %1 returned '%2'", _x, _playerTeam];
			
			_added = false;

			{
				if ((_x select 0) isEqualTo _playerTeam) exitWith
				{
					_x set [1, (_x select 1) + 1];
					_added = true;
				};
			} forEach _teamCounts;

			if (!_added) then
			{
				[_teamCounts, [_playerTeam, 1]] call BIS_fnc_arrayPush;
			};
		} forEach _players;

		{
			_team1 = _x select 0;
			_team1count = _x select 1;

			if (_team1count > 0) exitWith
			{
				_dominantTeam = _team1;

				for "_i" from (_forEachIndex + 1) to (count _teamCounts - 1) do
				{
					_team2count = (_teamCounts select _i) select 1;

					if (_team2count > 0) exitWith
					{
						_contested = true;
						_dominantTeam = sideUnknown;
					};
				};
			};
		} forEach _teamCounts;
	};

	//diag_log format["_teamCountsForPlayerArray returns %1", [_teamCounts, _contested, _dominantTeam]];
	[_teamCounts, _contested, _dominantTeam]
};

// Figure out if an area is contested or uncontested in terms of players within proximity,
// and then whether there has been a change since last tick.
//
// This results in an action to take, either "RESET", "CONTINUE" or "BLOCK"
_handleTeamCounts =
{
	//diag_log format["_handleTeamCounts called with %1", _this];

	// We could do something more crazy here like use the player counts to scale cap times
	// but for now we really only look at the contested status, and the dominant team

	private ["_currentCounts", "_newCounts", "_currentTeamCounts", "_currentAreaContested", "_currentDominantTeam", "_newTeamCounts", "_newAreaContested", "_newDominantTeam", "_action"];
	_currentCounts = _this select 0;
	_newCounts = _this select 1;

	_currentTeamCounts = _currentCounts select 0;
	_currentAreaContested = _currentCounts select 1;
	_currentDominantTeam = _currentCounts select 2;

	_newTeamCounts = _newCounts select 0;
	_newAreaContested = _newCounts select 1;
	_newDominantTeam = _newCounts select 2;

	_action = "";  // CAPTURE, BLOCK, RESET

	if (!_newAreaContested) then
	{
		// Territory is currently uncontested. Was the previous state uncontested and the same team?
		if (_currentAreaContested || (_currentDominantTeam isEqualTo _newDominantTeam && !(_currentDominantTeam isEqualTo sideUnknown))) then
		{
			// If it was last contested, or uncontested with the same team, reset our cap counter (or we could carry on?)
			_action = "CAPTURE";
		}
		else
		{
			// Previously uncontested and the team has changed
			_action = "RESET";
		};
	}
	else
	{
		// It's contested
		_action = "BLOCK";
	};

	//diag_log format["_handleTeamCounts returning %1", _action];

	_action
};

_updatePlayerTerritoryActivity =
{
	private ["_updatePlayerTerritoryActivity", "_currentTerritoryOwner", "_newDominantTeam", "_action", "_player", "_playerUID", "_playerTeam","_territoryActivity"];
	// diag_log format["_updatePlayerTerritoryActivity given %1", _this];

	_currentTerritoryOwner = _this select 0;
	_newTerritoryOccupiersPlayers = _this select 1;
	_newDominantTeam = _this select 2;
	_action = _this select 3;

	{
		_player = _x;
		_playerUID = getPlayerUID _player;
		_playerTeam = _player call _getPlayerTeam;

		_territoryActivity = [];

		// Set a variable on them to indicate blocked capping
		if !(_currentTerritoryOwner isEqualTo _newDominantTeam) then
		{
			if (_action == "BLOCK") then
			{
				// We split a BLOCK state into defenders and attackers
				if (_currentTerritoryOwner isEqualTo _playerTeam) then
				{
					_territoryActivity set [0, "BLOCKEDDEFENDER"];
				}
				else
				{
					_territoryActivity set [0, "BLOCKEDATTACKER"];
				};
			}
			else
			{
				_territoryActivity set [0, _action];
			};

			_territoryActivity set [1, _capturePeriod - _newCapPointTimer];
			_newPlayersWithTerritoryActivity pushBack _playerUID;
		};

		//diag_log format["Setting TERRITORY_ACTIVITY to %1 for %2", _territoryActivity, _player];
		_x setVariable ["TERRITORY_ACTIVITY", _territoryActivity, true];
	} forEach _newTerritoryOccupiersPlayers;
};


_handleCapPointTick = {
	private ["_currentTerritoryData", "_newTerritoryData", "_count", "_loopStart", "_currentTerritoryDetails", "_i", "_currentTerritoryName", "_currentTerritoryOccupiersUIDs", 
	"_currentTerritoryOccupiersPlayers",	"_currentTerritoryOwner", "_currentTerritoryChrono", "_currentTerritoryTimer", "_newTerritoryDetails", "_newTerritoryName", "_newTerritoryOccupiersPlayers", 
	"_newTerritoryOcupiersUIDs",
	"_currentTeamCounts", "_newTeamCounts", 	"_currentDominantTeam", "_newDominantTeam", "_newContestedStatus", "_action", "_newCapPointTimer", "_currentDominantTeamName", "_configEntry", 
	"_territoryDescriptiveName", "_newMarkerColor", "_value", "_currentTerritoryOccupiers"];
	
	// diag_log format["_handleCapPointTick called with %1", _this];

	// Into this method comes two arrays. One is the master array called _currentTerritoryData, containing all the
	// cap points, known players within that area, and the timer count for that area.
	// The second array is the current list of cap points and UID's of players at that location
	// These are reconciled by calls to _teamCountsForPlayerArray and _handleTeamCounts

	_newTerritoryData = _this select 0;			// i.e. territoryOccupiersMapConsolidated: [territoryName, [[UID,...],[player,...]]]
	//[_territoryOccupiersMapConsolidated, _territoryName, [_uid, _player]] call fn_addToPairs;  // key,[value] where key is territoryName, [value] is a two elem array of player UIDs, player objs
	// diag_log format["_handleCapPointTick set _newTerritoryData=%1",_newTerritoryData];
	
	_currentTerritoryData = _this select 1;  	// i.e. the global currentTerritoryDetails array  

	// The data structure is as follows:
	// [
	//  [NAME_OF_CAP_POINT, [PLAYERS, AT, POINT], uncontestedOccupiedTime, currentPointOwners]
	// ]
	//

	// Loop over _currentTerritoryData
	_count = count _currentTerritoryData;
	for "_i" from 0 to (_count - 1) do
	{
		_loopStart = diag_tickTime;

		_currentTerritoryDetails = _currentTerritoryData select _i;

		_currentTerritoryID = _currentTerritoryDetails select 0;				// INT ID
		_currentTerritoryName = _currentTerritoryDetails select 1;				// STRING markerName
		_currentTerritoryOccupiersUIDs = _currentTerritoryDetails select 2;		// [uid,uid,uid,...]
		_currentTerritoryOccupiersPlayers = _currentTerritoryDetails select 3;	// [player, player, player, ...]
		_currentTerritoryOwner = _currentTerritoryDetails select 4;			// SIDE 
		_currentTerritoryChrono = _currentTerritoryDetails select 5;			// INTEGER timeHeld
		_currentTerritoryTimer = _currentTerritoryDetails select 6;			// INTEGER timeOccupied by enemy
		_currentTerritoryOwnerGroup = _currentTerritoryDetails select 7;		// GROUP
		_currentTerritoryOwnerGroupUIDs = _currentTerritoryDetails select 8;	// [uid,uid,uid,...]

		// Use BIS_fnc_conditionalSelect since we can't sort arrays using strings FFS.
		// This is slower than my plan to have both _newTerritoryData and _currentTerritoryData sorted in the same way to allow
		// single index lookups into both for equiv data

		//diag_log format["Searching _newTerritoryData for %1", _currentTerritoryName];

		// get the record out of _newTerritoryData where the territory name matches the working _currentTerritoryDeatils rec as a 1 element array 
		_newTerritoryDetails = [_newTerritoryData, { _x select 0 == _currentTerritoryName }] call BIS_fnc_conditionalSelect;  // [territoryName, [uids,players]]
		// _newTerritoryDetails : [ [territoryName, [player, player, ...]]]

		// If territory is is held by anyone, update chrono
		if !(_currentTerritoryOwner isEqualTo sideUnknown) then
		{
			_currentTerritoryChrono = _currentTerritoryChrono + _realLoopTime;
		};

		//diag_log format["BIS_fnc_conditionalSelect found _newTerritoryDetails as %1", _newTerritoryDetails];

		// Do we have ANY people in this territory, i.e., does a _newTerritoryDetails rec exist?
		if (count _newTerritoryData > 0 && {count _newTerritoryDetails > 0}) then
		{
			// Yes: there are player(s) in the territory
			
			diag_log format["Processing point %1 with currentTerritoryData record='%2'", _currentTerritoryName, _currentTerritoryDetails];

			_newTerritoryDetails = _newTerritoryDetails select 0;  // extract the single element array rec to a var of the same name
			// _newTerritoryDetails : [territoryName, [player, player, ...]]

			_newTerritoryName = _newTerritoryDetails select 0;
			// diag_log format ["_handleCapPointTick has _newTerritoryDetails = %1", _newTerritoryDetails];
			
			_newTerritoryOccupiersPlayers = _newTerritoryDetails select 1;  // array of players, i.e., [player, player, ...]

			// diag_log format ["_handleCapPointTick for %1 has _newTerritoryName=%2 _newTerritoryOccupiersPlayers=%3", _currentTerritoryName, _newTerritoryName, _newTerritoryOccupiersPlayers];
			
			// There are players in the territory.  Is it contested or not?
			// diag_log format ["_handleCapPointTick for %1 calling _teamCountsForPlayerArray with _currentTerritoryOccupiersPlayers=%2]", _currentTerritoryName, _currentTerritoryOccupiersPlayers];
			_currentTeamCounts = [_currentTerritoryOccupiersPlayers] call _teamCountsForPlayerArray;  
			
		
			// diag_log format ["     call returned _currentTeamCounts=%1", _currentTeamCounts];
			// diag_log format ["_handleCapPointTick calling _teamCountsForPlayerArray with _newTerritoryOccupiersPlayers=%1", _newTerritoryOccupiersPlayers];
			_newTeamCounts = [_newTerritoryOccupiersPlayers] call _teamCountsForPlayerArray;
			// diag_log format ["     call returned _newTeamCounts=%1", _newTeamCounts];
			
			_currentDominantTeam = _currentTeamCounts select 2;
			_newDominantTeam = _newTeamCounts select 2;
			_newContestedStatus = _newTeamCounts select 1;

			// diag_log format["_handleCapPointTick   _currentTeamCounts: %1", _currentTeamCounts];
			// diag_log format["_handleCapPointTick   _newTeamCounts: %1", _newTeamCounts];

			_action = [_currentTeamCounts, _newTeamCounts] call _handleTeamCounts;

			_newCapPointTimer = _currentTerritoryTimer;

			// diag_log format["_handleCapPointTick   _newContestedStatus is %1, _currentTerritoryOwner is %2, _newDominantTeam is %3, action is %4", _newContestedStatus, _currentTerritoryOwner, _newDominantTeam, _action];
			////////////////////////////////////////////////////////////////////////

			if (_newContestedStatus || !(_currentTerritoryOwner isEqualTo _newDominantTeam)) then
			{
				if (_action == "CAPTURE") then
				{
					if (_currentTerritoryTimer == 0 && !(_currentTerritoryOwner isEqualTo sideUnknown)) then
					{
						// Just started capping. Let the current owners know!
						_currentDominantTeamName = [_currentDominantTeam] call _getTeamName;

						_configEntry = [["config_territory_markers", []] call getPublicVar, { _x select 0 == _currentTerritoryName }] call BIS_fnc_conditionalSelect;
						_territoryDescriptiveName = (_configEntry select 0) select 1;

						[_territoryDescriptiveName, _currentTerritoryOwner] call _onCaptureStarted;
					};

					_newCapPointTimer = _newCapPointTimer + _realLoopTime
				};

				if (_action == "RESET") then
				{
					_newCapPointTimer = 0;
				};

				diag_log format["_handleCapPointTick ---> %1 action is %2 with the timer at %3", _currentTerritoryName, _action, [_newCapPointTimer, _newDominantTeam, _currentDominantTeam]];

				if (_newCapPointTimer >= _capturePeriod && !(_newDominantTeam isEqualTo _currentTerritoryOwner)) then
				{
					// The territory was captured on this iteration
					
					diag_log format ["_handleCapPointTick   Territory '%1' was captured by '%2'!", _currentTerritoryName, _newDominantTeam];
					
					_newMarkerColor = [_newDominantTeam] call getTeamMarkerColor;
					_currentTerritoryName setMarkerColor _newMarkerColor;

					// get the config_territory_markers entry for this territory
					_configEntry = [["config_territory_markers", []] call getPublicVar, { _x select 0 == _currentTerritoryName }] call BIS_fnc_conditionalSelect;
					
					_territoryDescriptiveName = (_configEntry select 0) select 1;
					_value = (_configEntry select 0) select 2;

					// dump what we got
					// diag_log format ["_handleCapPointTick   call to get config_territory_markers entry returned:  name='%1' value='%2'", _territoryDescriptiveName, _value];
					
					// Reset to capTimer to zero
					_newCapPointTimer = 0;
					
					// Reset Chrono to just above zero
					_currentTerritoryChrono = 1;

					// diag_log format["_handleCapPointTick     %1 captured point %2 (%3)", _newDominantTeam, _currentTerritoryName, _territoryDescriptiveName];

					[_currentTerritoryOwner, _newDominantTeam, _value, _currentTerritoryName, _territoryDescriptiveName] call _onCaptureFinished;
					_currentTerritoryOwner = _newDominantTeam;

					
					if (_territorySavingOn) then 
					{
						// call fn_saveTerritory to persist the newly changed territory state, if persistence is on
						[_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newCapPointTimer] call fn_saveTerritory;
						
						// Call above needs to go to: 
						// [_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newTerritoryGroupHolder, _newTerritoryGrouplHolderUIDs]
						
						
						// add a territory capture log event if we're using extDB
						diag_log format ["_territoryLoggingOn = %1", _territoryLoggingOn];
						if (_territoryLoggingOn) then {
							
							[_currentTerritoryID, _currentTerritoryName, _newTerritoryOccupiersPlayers, _currentTerritoryOwner] call fn_logTerritoryCapture;
						};
					};
					
					// Increase capture score
					{
						if ([_x, _newDominantTeam] call _isInTeam) then
						{
							[_x, "captureCount", 1] call fn_addScore;
						};
					} forEach _currentTerritoryOccupiersPlayers;
				};
				
				[_currentTerritoryOwner, _newTerritoryOccupiersPlayers, _newDominantTeam, _action] call _updatePlayerTerritoryActivity;
			};

			// get UIDs of _newTerritoryOccupiersPlayers for saving into 
			_newTerritoryOcupiersUIDs=[];
			{
				_newTerritoryOcupiersUIDs pushBack getPlayerUID _x;
			} forEach _newTerritoryOccupiersPlayers;
			
			// Now ensure we're creating a mirror of _currentTerritoryDetails with all the new info so we can assign it
			// at the end of this iteration
			_currentTerritoryData set [_i, [_currentTerritoryID, _currentTerritoryName, _newTerritoryOcupiersUIDs, _newTerritoryOccupiersPlayers, _currentTerritoryOwner, _currentTerritoryChrono, _newCapPointTimer]];
			
			// diag_log format["_handleCapPointTick   Completed Processing point %1 with currentTerritoryData record='%2'", _currentTerritoryName, _currentTerritoryData select _i];
			
		}
		else
		{
			// Nobody there
			_currentTerritoryData set [_i, [_currentTerritoryID, _currentTerritoryName, [], [], _currentTerritoryOwner, _currentTerritoryChrono, 0]];
		};
	};

	_currentTerritoryData
};

_fn_territoryPayroll = compile preprocessFileLineNumbers "territory\server\territoryPayroll.sqf";
if (["A3W_territoryPayroll"] call isConfigOn) then
{
	[] spawn _fn_territoryPayroll;
};

//////////////////////////////////////////////////////////////////////////////
// MAIN TERRITORY MONITOR LOOP                                              //
//////////////////////////////////////////////////////////////////////////////

while {true} do
{
	private ["_initTime", "_territoryOccupiersMapSingle", "_curCapPoint", "_territoryOccupiersMapConsolidated", "_territoryName", "_player", "_players", "_newCapturePointDetails", "_newTerritoryOwners"];


	_initTime = diag_tickTime;

	// Iterate through each player, and because the client-side trigger has added the var
	// 'TERRITORY_CAPTURE_POINT' onto the player object and set it global, we the server should know
	// where each player is, in terms of capture areas
	_territoryOccupiersMapSingle = [];

	{
		private ["_curCapPoint", "_uid"];

		// Mark / sweep old players who no longer need activity entries
		_uid = getPlayerUID _x;

		if (alive _x) then
		{
			// We don't see dead people. Hahaha...ha!
			_curCapPoint = _x getVariable ["TERRITORY_OCCUPATION", ""];

			if (_curCapPoint != "") then
			{
				// Make the entry
				//diag_log format["%1 has TERRITORY_OCCUPATION for %2", name _x, _curCapPoint];
				//diag_log format["CAP PLAYER LOOP: Adding %1 to _territoryOccupiersMapSingle at %2", _x, _curCapPoint];
				_territoryOccupiersMapSingle pushBack [_curCapPoint, _uid, _x];
			};
		};

		if (_uid in _oldPlayersWithTerritoryActivity) then
		{
			//diag_log format["Removing activity state from %1", _x];
			_x setVariable ["TERRITORY_ACTIVITY", [], true];
		};

	} forEach playableUnits;

	// Reset who's contested and who's not!
	_oldPlayersWithTerritoryActivity = _newPlayersWithTerritoryActivity;
	_newPlayersWithTerritoryActivity = [];

	// Now capPointPlayerMapSingle has [[ "CAP_POINT", "PLAYER"] .. ];

	//diag_log format["_territoryOccupiersMapSingle is %1", _territoryOccupiersMapSingle];
	// Consolidate into one entry per cap point

	_territoryOccupiersMapConsolidated = [];

	if (count _territoryOccupiersMapSingle > 0) then
	{
		// diag_log format["Converting %1 _territoryOccupiersMapSingle entries into _territoryOccupiersMapConsolidated", count _territoryOccupiersMapSingle];
		
		// consolidate the array of [currentCapPoint, uid, player] entries to an array of [currentCapPoint, [[uid,uid,..],[player, player, ...]]] pairs
		{
			_territoryName = _x select 0;
			_uid = _x select 1;
			_player = _x select 2;
			[_territoryOccupiersMapConsolidated, _territoryName, [_player]] call fn_addToPairs;  // key,[value] where key is territoryName, [value] is an array of player objs
		} forEach _territoryOccupiersMapSingle;
		
		// dump territoryOccupiersMapConsolidated
		// diag_log "_territoryOccupiersMapConsolidated dump:";
		{
			_territoryName = _x select 0;
			_players = _x select 1;
			// diag_log format ["Entry:  %1 ->  %2:  %3", _x, _territoryName, _players];
		} forEach _territoryOccupiersMapConsolidated;
	};


	_newCapturePointDetails = [_territoryOccupiersMapConsolidated, currentTerritoryDetails] call _handleCapPointTick;
	// _the above _handleCapPointTick returns our new set of last iteration info
	currentTerritoryDetails = _newCapturePointDetails;

	_newTerritoryOwners = [];
	{ _newTerritoryOwners pushBack [_x select 1, _x select 4 } forEach _newCapturePointDetails;

	if !(A3W_currentTerritoryOwners isEqualTo _newTerritoryOwners) then
	{
		A3W_currentTerritoryOwners = _newTerritoryOwners;
		publicVariable "A3W_currentTerritoryOwners";
	};


	// Reconcile old/new contested occupiers
	//
	// For each one of the UIDs in the _currentContestedOccupiers we find if they're not
	// present in _newContestedOccupiers and if not, remove the TERRITORY_CONTESTED var
	// set on them.
	if (count _newPlayersWithTerritoryActivity > 0) then
	{
		// Remove it, as we're going to go through _oldPlayersWithTerritoryActivity and set each
		// one that's left into non-contested mode by removing the TERRITORY_CONTESTED variable
		// and then _newPlayersWithTerritoryActivity becomes _oldPlayersWithTerritoryActivity
		//diag_log format["Removing UID %1 from _oldPlayersWithTerritoryActivity as they're still capping!", _x];
		_oldPlayersWithTerritoryActivity = [_oldPlayersWithTerritoryActivity, { !(_x in _newPlayersWithTerritoryActivity) }] call BIS_fnc_conditionalSelect;
	};

	sleep BASE_SLEEP_INTERVAL;
	_realLoopTime = diag_tickTime - _initTime;
	diag_log format["TERRITORY SYSTEM: _realLoopTime was %1", _realLoopTime];
};
