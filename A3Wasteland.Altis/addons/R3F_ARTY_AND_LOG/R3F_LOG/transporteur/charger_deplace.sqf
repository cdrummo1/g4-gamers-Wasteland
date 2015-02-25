/**
 * Load the object moved by the player in a carrier
 *
 * Copyright (C) 2010 madbull ~R3F~
 *
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
private ["_object", "_carrier", "_objects_charges", "_chargement_actuel", "_i", "_cout_capacite_object", "_chargement_maxi", "_position_attache", "_nb_tirage_pos"];

if (R3F_LOG_mutex_local_verrou) then
{
	player globalChat STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	R3F_LOG_mutex_local_verrou = true;

	private ["_object", "_classes_carriers", "_carrier", "_i"];

	_object = R3F_LOG_joueur_deplace_objet;

	_carrier = nearestObjects [_object, R3F_LOG_classes_transporteurs, 22];
	// Because the carrier can be a transportable object
	_carrier = _carrier - [_object];

	if (count _carrier > 0) then
	{
		_carrier = _carrier select 0;

		if (alive _carrier && ((velocity _carrier) call BIS_fnc_magnitude < 6) && (getPos _carrier select 2 < 2) && !(_carrier getVariable "R3F_LOG_disabled")) then
		{
			private ["_objects_charges", "_chargement_actuel", "_cout_capacite_object", "_chargement_maxi"];

			_objects_charges = _carrier getVariable "R3F_LOG_objets_charges";

			// The current load calculation
			_chargement_actuel = 0;
			{
				for [{_i = 0}, {_i < count R3F_LOG_CFG_objets_transportables}, {_i = _i + 1}] do
				{
					if (_x isKindOf (R3F_LOG_CFG_objets_transportables select _i select 0)) exitWith
					{
						_chargement_actuel = _chargement_actuel + (R3F_LOG_CFG_objets_transportables select _i select 1);
					};
				};
			} forEach _objects_charges;

			// Search of the capacity of the object
			_cout_capacite_object = 99999;
			for [{_i = 0}, {_i < count R3F_LOG_CFG_objets_transportables}, {_i = _i + 1}] do
			{
				if (_object isKindOf (R3F_LOG_CFG_objets_transportables select _i select 0)) exitWith
				{
					_cout_capacite_object = (R3F_LOG_CFG_objets_transportables select _i select 1);
				};
			};

			// Research the maximum capacity of the carrier
			_chargement_maxi = 0;
			for [{_i = 0}, {_i < count R3F_LOG_CFG_transporteurs}, {_i = _i + 1}] do
			{
				if (_carrier isKindOf (R3F_LOG_CFG_transporteurs select _i select 0)) exitWith
				{
					_chargement_maxi = (R3F_LOG_CFG_transporteurs select _i select 1);
				};
			};

			// If the object box in the vehicle
			if (_chargement_actuel + _cout_capacite_object <= _chargement_maxi) then
			{
				// Is stored on the network the new vehicle content
				_objects_charges = _objects_charges + [_object];
				_carrier setVariable ["R3F_LOG_objets_charges", _objects_charges, true];
				_object setVariable ["R3F_LOG_est_transporte_par", _carrier, true];

				player globalChat STR_R3F_LOG_action_charger_deplace_en_cours;

				// Make releasing the object the player (if it has in " hand " )
				_object disableCollisionWith _carrier;
				R3F_LOG_joueur_deplace_objet = objNull;
				sleep 2;

				// Choose a disengaged position ( 50m radius sphere ) in the air in a cube 9km ^ 3
				private ["_nb_tirage_pos", "_position_attache"];
				_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
				_nb_tirage_pos = 1;
				while {(!isNull (nearestObject _position_attache)) && (_nb_tirage_pos < 25)} do
				{
					_position_attache = [random 3000, random 3000, (10000 + (random 3000))];
					_nb_tirage_pos = _nb_tirage_pos + 1;
				};

				[R3F_LOG_PUBVAR_point_attache, true] call fn_enableSimulationGlobal;
				[_object, true] call fn_enableSimulationGlobal;
				_object attachTo [R3F_LOG_PUBVAR_point_attache, _position_attache];
				_object enableCollisionWith _carrier;

				player globalChat format [STR_R3F_LOG_action_charger_deplace_fait, getText (configFile >> "CfgVehicles" >> (typeOf _carrier) >> "displayName")];
			}
			else
			{
				player globalChat STR_R3F_LOG_action_charger_deplace_pas_assez_de_place;
			};
		};
	};

	R3F_LOG_mutex_local_verrou = false;
};
