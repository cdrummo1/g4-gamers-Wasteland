// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: territoryPayroll.sqf
//	@file Author: AgentRev

private ["_timeInterval", "_moneyAmount", "_territoryCapped", "_territorySavingOn","_payouts", "_newTerritoryDetails", "_currentTerritoryDetails", "_refreshNeeded", 
"_territoryId", "_territoryName", "_territoryOccupierUIDs", "_territoryOccupiers", "_territoryOwnerSide", "_territoryChrono", "_territoryContestTime", "_territoryOwnerGroup", 
"_territoryOwnerGroupUIDs", "_newTerritoryOwnerGroupUIDs", "_added", "_team", "_count", "_money", "_message"];

if (!isServer) exitWith {};

_timeInterval = ["A3W_payrollInterval", 30*60] call getPublicVar;
_moneyAmount = ["A3W_payrollAmount", 100] call getPublicVar;

_territoryCapped = false;
_territorySavingOn = ["A3W_territorySaving"] call isConfigOn;

diag_log format ["territoryPayroll invoked with timeInterval=%1 moneyAmount=%2 territorySavingOn=%3", _timeInterval, _moneyAmount,_territorySavingOn];

if (_territorySavingOn) then 
{
	// see if the initial persistence load brought with it any capped territories
	{
		_territoryOwnerSide = _x select 4;		// side
		
		if !(_territoryOwnerSide isEqualTo sideUnknown) then
		{
			_territoryCapped = true;
			diag_log format ["Territory %1 is owned by %2 ... set territoryCapped to true", _x select 1, _territoryOwnerSide];
		};
	} forEach currentTerritoryDetails;
};

while {true} do
{

	diag_log "territoryPayroll loop start";
	
	if (_territoryCapped) then
	{
		// Capped territories ... wait the full time
		diag_log format ["territoryPayroll w/ capped territories ... sleeping for %1 sec", _timeInterval];
		sleep _timeInterval;
	}
	else
	{
		// No capped territories ... try again in 1 minute
		diag_log "territoryPayroll w/o capped territories ... sleeping for 60 sec";
		sleep 60;
	};

	diag_log "territoryPayroll loop wake";
	
	// attempt to be thread-safe with respect to monitorTerritories use of currentTerritoryDetails data
	if (monitorTerritoriesActive) then {
		diag_log "territoryPayroll wait on monitorTerritories to go inactive";
		waitUntil !(monitorTerritoriesActive);
		diag_log "territoryPayroll resume";
	};
	
	_payouts = [];

	_newTerritoryDetails = [];
	_currentTerritoryDetails = currentTerritoryDetails;
	_territoryCapped = false;  // turn it off at start of loop
	{
		_refreshNeeded=false;
		_territoryId = _x select 0;    // Id
		_territoryName = _x select 1;  // name
		_territoryOccupierUIDs = _x select 2;
		_territoryOccupiers = _x select 3;  // players
		_territoryOwnerSide = _x select 4;		// side
		_territoryChrono = _x select 5;		// chrono
		_territoryContestTime = _x select 6;
		_territoryOwnerGroup = _x select 7;
		_territoryOwnerGroupUIDs = _x select 8;

		if (!(_territoryOwnerSide in [OPFOR,BLUFOR]) && !(_territoryOwnerGroup isEqual grpNull)) then
		{
			// this is an indy cap ... refresh the groupUIDs
			_newTerritoryOwnerGroupUIDs = [];
			{
				if (isPlayer _x) then
				{
					_newTerritoryOwnerGroupUIDs pushBack _x;
				};
			} forEach (units _territoryOwnerGroup);
			
			if (!(_newTerritoryOwnerGroupUIDs isEqual _territoryOwnerGroupUIDs)) then {
				_refreshNeeded=true;
				_territoryOwnerGroupUIDs = _newTerritoryOwnerGroupUIDs;
			};
		};
		
		diag_log format ["territoryPayroll checking %1: occupiers=%2 owner=%3/%4 chrono=%5", _territoryName,_territoryOccupiers,_territoryOwnerSide,_territoryOwnerGroup,_territoryChrono];
		
		if (_territoryChrono > 0) then
		{
			_territoryCapped = true;

			if (_territoryChrono >= _timeInterval) then
			{
				_added = false;

				{
					if (((_x select 0) isEqualTo _territoryOwnerSide) && ((_x select 1) isEqualTo _territoryOwnerGroup)) exitWith
					{
						_x set [2, (_x select 2) + 1];
						_added = true;
					};
				} forEach _payouts;

				if (!_added) then
				{
					_payouts pushBack [_territoryOwnerSide, _territoryOwnerGroup, 1];
				};
			};
			
			// update the persistence data, if saving is enabled and is needed
			if (_territorySavingOn && _refreshNeeded) then {
				[_territoryId, _territoryName, _territoryOccupiers, _territoryOwnerSide, _territoryChrono, _territoryOwnerGroup, _territoryOwnerGroupUIDs] call fn_saveTerritory;
			};
			
			_newTerritoryDetails pushBack [_territoryId, _territoryName, _territoryOccupierUIDs, _territoryOccupiers, _territoryOwnerSide, _territoryChrono, _territoryContestTime, _territoryOwnerGroup, _territoryOwnerGroupUIDs];
		};
	} forEach currentTerritoryDetails;

	// update currentTerritoryDetails with refreshed data
	currentTerritoryDetails = _newTerritoryDetails;
	
	diag_log format ["territoryPayroll has %1 payouts to make", count _payouts];
	
	{
		_team = _x select 0;
		_group = _x select 1; 
		_count = _x select 2;

		_money = _count * _moneyAmount;
		_message =  format ["Your team received a $%1 bonus for holding %2 territor%3 during the past %4 minutes", [_money] call fn_numbersText, _count, if (_count == 1) then { "y" } else { "ies" }, ceil (_timeInterval / 60)];
		
		if (_team in [OPFOR,BLUFOR]) then {
			diag_log format ["[INFO] territoryPayroll: $%1 payout to team '%2' with %3 caps made", _money, _team, _count];
			[[_message, _money], "A3W_fnc_territoryActivityHandler", _team, false] call A3W_fnc_MP;
		} else {
			diag_log format ["[INFO] territoryPayroll: $%1 payout to Indy group '%2' with %3 caps made", _money, _group, _count];
			[[_message, _money], "A3W_fnc_territoryActivityHandler", _group, false] call A3W_fnc_MP;
		};
	} forEach _payouts;
};

diag_log "territoryPayroll exit";

