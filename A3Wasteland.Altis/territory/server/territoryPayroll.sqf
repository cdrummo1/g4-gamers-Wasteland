// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: territoryPayroll.sqf
//	@file Author: AgentRev

private ["_timeInterval", "_moneyAmount", "_territoryCapped", "_territorySavingOn", "_territoryName", "_territoryOccupiers", "_territoryOwner", "_territoryChrono", "_payouts", "_territoryId", "_added", "_team", "_count", "_money", "_message"];

if (!isServer) exitWith {};

_timeInterval = ["A3W_payrollInterval", 30*60] call getPublicVar;
_moneyAmount = ["A3W_payrollAmount", 100] call getPublicVar;

_territoryCapped = false;
_territorySavingOn = ["A3W_territorySaving"] call isConfigOn;

diag_log format ["territoryPayroll invoked with timeInterval=%1 moneyAmount=%2 territorySavingOn=%3", _timeInterval, _moneyAmount,_territorySavingOn];

if (_territorySavingOn) then 
{
	// see if the persistence load brought with it any capped territories
	{
		_territoryOwner = _x select 4;		// side
		
		if !(_territoryOwner isEqualTo sideUnknown) then
		{
			_territoryCapped = true;
			diag_log format ["Territory %1 is owned by %2 ... set territoryCapped to true", _territoryName, _territoryOwner];
		};
	} forEach currentTerritoryDetails;
	//		0 = Marker ID
	// 		1 = Name of capture marker
	// 		2 = List of players in that area [uids]
	// 		3 = List of players in that area [player objects] (set to null array)
	// 		4 = side owning the point currently
	// 		5 = Time in seconds during which the area has been held
	//		6 = Time in seconds during which the area has been contested (set to 0)

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
	
	_payouts = [];

	{
		_territoryId = _x select 0;    // Id
		_territoryName = _x select 1;  // name
		_territoryOccupiers = _x select 3;  // players
		_territoryOwner = _x select 4;		// side
		_territoryChrono = _x select 5;		// chrono

		diag_log format ["territoryPayroll checking %1: occupiers=%2 owner=%3 chrono=%4", _territoryName,_territoryOccupiers,_territoryOwner,_territoryChrono];
		
		if (_territoryChrono > 0) then
		{
			_territoryCapped = true;

			if (_territoryChrono >= _timeInterval) then
			{
				_added = false;

				{
					if ((_x select 0) isEqualTo _territoryOwner) exitWith
					{
						_x set [1, (_x select 1) + 1];
						_added = true;
					};
				} forEach _payouts;

				if (!_added) then
				{
					_payouts pushBack [_territoryOwner, 1];
				};
			};
			
			// update the persistence data, if saving is enabled
			if (_territorySavingOn) then {
				[_territoryId, _territoryName, _territoryOccupiers, _territoryOwner, _territoryChrono, 0] call fn_saveTerritory;
			};
		};
	} forEach currentTerritoryDetails;

	diag_log format ["territoryPayroll has %1 payouts to make", count _payouts];
	
	{
		_team = _x select 0;
		_count = _x select 1;

		_money = _count * _moneyAmount;
		_message =  format ["Your team received a $%1 bonus for holding %2 territor%3 during the past %4 minutes", [_money] call fn_numbersText, _count, if (_count == 1) then { "y" } else { "ies" }, ceil (_timeInterval / 60)];

		diag_log format ["[INFO] territoryPayroll: $%1 payout to team '%2' with %3 caps made", _money, _team, _count];
		
		[[_message, _money], "A3W_fnc_territoryActivityHandler", _team, false] call A3W_fnc_MP;
	} forEach _payouts;

};

diag_log "territoryPayroll exit";

