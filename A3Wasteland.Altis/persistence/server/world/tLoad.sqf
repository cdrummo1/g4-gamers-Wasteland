// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: tLoad.sqf
//	@file Author: Munch, based on vLoad by AgentRev, JoSchaap, Austerror
//
// called from monitorTerritories, right before the main monitoring loop starts
// loads data into an array that can be assigned to the global currentTerritoryDetails array

private ["_worldDir", "_methodDir", "_terCount", "_territories"];

_worldDir = "persistence\server\world";
_methodDir = format ["%1\%2", _worldDir, call A3W_savingMethodDir];

_terCount = 0;
_territories = [];

diag_log format["tLoad invoked with A3W_savingMethodDir = '%1'",call A3W_savingMethodDir];

// call getTerritories to read and return array containing last known territories status
// method assumes that all defined territories have been previously saved so that the return
// array is complete
// Array format:
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = Team owning the point currently
	// 		5 = Time in seconds during which the area has been held
	// 		6 = Time in seconds during which the area has been occupied by enemies
_territories = call compile preprocessFileLineNumbers format ["%1\getTerritories.sqf", _methodDir];

diag_log format["tLoad call to getTerritories returned %1 recs in _territories", count _territories];

if (count _territories < count (["config_territory_markers", []] call getPublicVar)) then {
	diag_log format ["A3Wasteland - mismatch in saved territory info ... load aborted; returning config_territory_markers defaults."];
	{
		_markerName = _x select 0;
		//diag_log format ["Adding %1 to lastCapturePointDetails", _markerName];
		_territories pushBack [_markerName, [], sideUnknown, 0, 0];
	} forEach (["config_territory_markers", []] call getPublicVar);
} else {
	diag_log format ["A3Wasteland - world persistence loaded %1 territories from %2", count _territories, call A3W_savingMethodName];
};

// return the territories array
_territories

