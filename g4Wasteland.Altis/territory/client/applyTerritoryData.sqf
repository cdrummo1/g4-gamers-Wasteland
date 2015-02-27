// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: applyTerritoryData.sqf
//	@file Author: Munch
//  @file Date: 22-Feb-2015 
//  Called by publicVariableEventHandler for "pvar_applyTerritoryData" with territories capture state data

if (isDedicated) exitWith {};

diag_log format ["[INFO] applyTerritoryData calling updateTerritoryMarkers with _this = '%1'", _this];

_this execVM "territory\client\updateTerritoryMarkers.sqf";

