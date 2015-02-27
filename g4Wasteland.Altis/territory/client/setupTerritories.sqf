// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: setupTerritoryDB.sqf
//	@file Author: Munch, after setupPlayerDB.sqf by AgentRev
//  @file Date: 22-Feb-2015 

if (isDedicated) exitWith {};

_territoryFuncs = "territory\client";

diag_log text "[INFO] setupTerritories compiling applyTerritoryData.sqf and fn_requestTerritoryData";

fn_applyTerritoryData = [_territoryFuncs, "applyTerritoryData.sqf"] call mf_compile;

fn_requestTerritoryData =
{
	pvar_requestTerritoryData = [player, getPlayerUID player, netId player];
	diag_log format["[INFO] fn_requestTerritoryData called to create and send pvar_requestTerritoryData='%1'", pvar_requestTerritoryData];
	publicVariableServer "pvar_requestTerritoryData";
} call mf_compile;

("pvar_applyTerritoryData_" + getPlayerUID player) addPublicVariableEventHandler
{
	diag_log format ["pvar_applyTerritoryData_%1 invoked! with _this='%2'",getPlayerUID player,_this];
	
	(_this select 1) spawn
	{
		_data = _this;

		waitUntil {!isNil "bis_fnc_init" && {bis_fnc_init}}; // wait for loading screen to be done

		_data call fn_applyTerritoryData;

		territoryData_loaded = true;  //unblock client/init.sqf
	};
};
