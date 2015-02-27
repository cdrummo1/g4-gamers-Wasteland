// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: tSaveInit.sqf
//	@file Author: Munch after stub hacked from oSave by AgentRev, [GoT] JoSchaap

private ["_worldDir", "_methodDir", "_savingMethod", "_terFileName", "_cntr", "_markerName"];

#include "functions.sqf"

_worldDir = "persistence\server\world";
_methodDir = format ["%1\%2", _worldDir, call A3W_savingMethodDir];
_savingMethod = ["A3W_savingMethod", "profile"] call getPublicVar;

fn_saveTerritory = [_methodDir, "saveTerritory.sqf"] call mf_compile;

if (_savingMethod == "iniDB") then
{
	diag_log "tSave setting up for territory saving with iniDB";

	_terFileName = "Territories" call PDB_objectFileName;

	// If file doesn't exist, create Info section at the top
	if !(_terFileName call PDB_exists) then // iniDBi file exists?
	{
		[_terFileName, "Info", "TerCount", 0] call PDB_write; // iniDB_write
		
		// write out an empty file with entries for each territory in the mission
		_cntr=0;
		{
			_markerName = _x select 0;
			[_markerName, [], sideUnknown, 0, 0] call fn_saveTerritory;
			_cntr = _cntr + 1;
		} foreach  (["config_territory_markers", []] call getPublicVar);
		
		// update the header with the count of recs written
		[_terFileName, "Info", "TerCount", _cntr] call PDB_write; // iniDB_write
		[_terFileName, "Info", "TerCount", _cntr] call PDB_write; // iniDB_write
		
	};
} else {
	if (_savingMethod == "extDB" && {["A3W_territoryLogging"] call isConfigOn} ) then {
		fn_logTerritoryCapture = [_methodDir, "logTerritoryCapture.sqf"] call mf_compile;
	};
};

A3W_tSaveReady = compileFinal "true";
