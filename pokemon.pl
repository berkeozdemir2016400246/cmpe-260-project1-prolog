% Ali Berke Özdemir
% 2016400246
% compiling: yes
% complete: yes

:- include(pokemon_data).


%some utilities


%finds the larger of two numbers, called pokemon_type_multiplier
larger(Result, One, Two):- 								One>=Two, Result = One.
larger(Result, One, Two):- 								One<Two, Result = Two.

%gets the list of all pokemon, useful in various contexts
allPokes(PokemonList):-			
														findall(Pokemon,
															pokemon_stats(Pokemon,_,_,_,_),
															PokemonList).

%helper method for pokemon_tournament, determines who the winner is by the HP of each pokemon
winner(Trainer1,_,Winner,HP1,HP2):-						HP1>=HP2,
														Winner=Trainer1.
														
winner(_,Trainer2,Winner,HP1,HP2):-						HP1<HP2,
														Winner=Trainer2.

%helper for 4.12, h(ealth) is the 2nd element of the list, a(attack) is 3rd and d(efense) is 4th, list format is [Pokemon,HP,ATK,DEF]
criteria(h,2).
criteria(a,3).
criteria(d,4).

%helper for 4.12, recursively constructs a list of [[Pokemon1,HP1,ATK1,DEF1],[Pokemon2,HP2,ATK2,DEF2]...] from [Pokemon1,Pokemon2...]
with_stats([Pokemon|PokemonSet], [StatHead|PokemonSetWithStats]):-	
														pokemon_stats(Pokemon,_,HP,ATK,DEF),
														StatHead=[Pokemon,HP,ATK,DEF],
														with_stats(PokemonSet,PokemonSetWithStats).
with_stats([],[]).

%compare method for lists, compares lists by their nth element
nthcompare(N,>,A,B) :- nth1(N,A,X),nth1(N,B,Y), X @> Y.
nthcompare(_,<,_,_).


%project predicates


%find_pokemon_evolution(+PokemonLevel, +Pokemon, -EvolvedPokemon)
%base case for recursion, if level required for evolution is lower than pokes level, cannot evolve, stop
find_pokemon_evolution(PokemonLevel, Pokemon, EvolvedPokemon) :-
														allPokes(AllPokes),
														member(Pokemon,AllPokes),
														pokemon_evolution(Pokemon,_,Level),
														Level>PokemonLevel,
														EvolvedPokemon=Pokemon.
																	
%base case for recursion, if pokemon has no evolutions to carry(aka does not match any pokemon_evolution facts) stop
find_pokemon_evolution(_, Pokemon, EvolvedPokemon) :-	
														allPokes(AllPokes),
														member(Pokemon,AllPokes),
														\+ pokemon_evolution(Pokemon,_,_),
														EvolvedPokemon=Pokemon.
																
%recursion, determine the next evolution,check if it can evolve, run find_pokemon_evolution with the evolved pokemon
find_pokemon_evolution(PokemonLevel, Pokemon, EvolvedPokemon) :-
														allPokes(AllPokes),
														member(Pokemon,AllPokes),
														pokemon_evolution(Pokemon, NextEvolution, Level),
														Level=<PokemonLevel,
														find_pokemon_evolution(PokemonLevel, NextEvolution, EvolvedPokemon).	


%pokemon_level_stats (+PokemonLevel, ?Pokemon, -PokemonHp, -PokemonAttack, -PokemonDefense)
%determine the base stats from pokemon_stats, determine Hp,Attack and Defense with the Base+Multiplier*Level formula
pokemon_level_stats(PokemonLevel, Pokemon, PokemonHp, PokemonAttack,PokemonDefense) :-
														pokemon_stats(Pokemon, _ , BaseHP, BaseATK, BaseDEF),
														PokemonHp is BaseHP+2*PokemonLevel,
														PokemonAttack is BaseATK+1*PokemonLevel,
														PokemonDefense is BaseDEF+1*PokemonLevel.


%single_type_multiplier(?AttackerType, ?DefenderType, Multiplier)
%get list of attackers type multipliers with type_attack_chart, get the list of types with pokemon_types, find the index of desired multiplier from TypeList, match the indices found to the types at BigTypes to get DefenderType
single_type_multiplier(AttackerType, DefenderType, Multiplier):-
														type_chart_attack(AttackerType, TypeList),
														pokemon_types(BigTypes),
														nth0(Index, TypeList, Multiplier),
														nth0(Index, BigTypes, DefenderType).
																	

%type_multiplier(?AttackerType, +DefenderTypeList, ?Multiplier)
%assume two-type defender, find multiplier against type One of defender, find multiplier for type Two of defender, multiply both for the combined multiplier
type_multiplier(AttackerType, DefenderTypeList, Multiplier):-
														DefenderTypeList = [One,Two],
														single_type_multiplier(AttackerType, One, MultiplierOne),
														single_type_multiplier(AttackerType, Two, MultiplierTwo),
														Multiplier is MultiplierOne*MultiplierTwo.

%for 1 type defenders, same as the single_type_multiplier
type_multiplier(AttackerType, DefenderTypeList, Multiplier):-
														DefenderTypeList = [One],
														single_type_multiplier(AttackerType, One, Multiplier).
																
																
																
%pokemon_type_multiplier(?AttackerPokemon, ?DefenderPokemon, ?Multiplier)
%assume two type attacker,get the defenders type list, find multiplier against defender with type one, find type multiplier with type two using type_multiplier, assign multiplier to be the larger of the two
pokemon_type_multiplier(AttackerPokemon, DefenderPokemon, Multiplier) :-
														pokemon_stats(AttackerPokemon, AttackerList , _ , _ , _ ),
														pokemon_stats(DefenderPokemon, DefenderTypeList, _ , _ , _ ),
														AttackerList = [AttackerOne,AttackerTwo],
														type_multiplier(AttackerOne, DefenderTypeList, MultiplierOne),
														type_multiplier(AttackerTwo, DefenderTypeList, MultiplierTwo),
														larger(Multiplier, MultiplierOne, MultiplierTwo).

%assume one type attacker, get defenders type list, type_multiplier is the Multiplier
pokemon_type_multiplier(AttackerPokemon, DefenderPokemon, Multiplier) :-		pokemon_stats(AttackerPokemon, [AttackerOne], _ , _ , _ ),
																				pokemon_stats(DefenderPokemon, DefenderTypeList, _ , _ , _ ),
																				type_multiplier(AttackerOne, DefenderTypeList, Multiplier).
																				
																				
%pokemon_attack(+AttackerPokemon, +AttackerPokemonLevel, +DefenderPokemon, +DefenderPokemonLevel, -Damage)
%find the attack stat of attacker, defense stat of defender and the type multiplier between them, calculate the damage according to formula
pokemon_attack(AttackerPokemon, AttackerPokemonLevel, DefenderPokemon, DefenderPokemonLevel, Damage):-
														pokemon_level_stats(AttackerPokemonLevel, AttackerPokemon, _ , Attack , _ ),
														pokemon_level_stats(DefenderPokemonLevel, DefenderPokemon, _ , _ , Defense),
														pokemon_type_multiplier(AttackerPokemon,DefenderPokemon,Multiplier),
														Damage is (0.5*AttackerPokemonLevel*(Attack/Defense)*Multiplier)+1.
																										
																																			
%pokemon_fight(+Pokemon1,+Pokemon1Level, +Pokemon2, +Pokemon2Level, -Pokemon1HP, -Pokemon2HP, -Rounds)
%find Damage from Poke1 to Poke2 and Poke2 to Poke1, than recursively subtract it from their hps until one goes below 0
pokemon_fight(Pokemon1,Pokemon1Level, Pokemon2, Pokemon2Level, Pokemon1HP, Pokemon2HP, Rounds):- 							
														pokemon_level_stats(Pokemon1Level, Pokemon1, Pokemon1HPMax, _, _),
														pokemon_level_stats(Pokemon2Level, Pokemon2, Pokemon2HPMax, _, _),
														pokemon_attack(Pokemon1, Pokemon1Level, Pokemon2, Pokemon2Level, Damage1),
														pokemon_attack(Pokemon2, Pokemon2Level, Pokemon1, Pokemon1Level, Damage2),
														pokemon_fight_round(Pokemon1HPMax, Pokemon2HPMax, Damage1, Damage2,Pokemon1HP,Pokemon2HP, Rounds, 0).
																
%recursion, subtract the damage, from each pokemon, increment the round, continue with the recursion
pokemon_fight_round(Pokemon1HP, Pokemon2HP, Damage1, Damage2,Pokemon1FinalHP,Pokemon2FinalHP, Round, CurrentRound):-
														Pokemon1HP > 0,
														Pokemon2HP > 0,
														NewPokemon1HP is Pokemon1HP-Damage2,
														NewPokemon2HP is Pokemon2HP-Damage1,
														NewCurrentRound is CurrentRound+1,
														pokemon_fight_round(NewPokemon1HP,NewPokemon2HP, Damage1, Damage2, Pokemon1FinalHP, Pokemon2FinalHP, Round, NewCurrentRound).

%base case, if one of pokemon is below zero, equalize Round, HP1 and HP2 to their final valus
pokemon_fight_round(Pokemon1HP, Pokemon2HP, _, _,Pokemon1HP,Pokemon2HP, Round, Round):-
														(Pokemon1HP =<0;Pokemon2HP =<0),!.
																																
																													
%pokemon_tournament(+PokemonTrainer1, +PokemonTrainer2, -WinnerTrainerList)
%find pokemons and levels of each trainer and pass them to the recursive function
pokemon_tournament(Trainer1, Trainer2, WinnerTrainerList):-
														pokemon_trainer(Trainer1, T1Pokemons, T1Levels),
														pokemon_trainer(Trainer2, T2Pokemons, T2Levels),
														pokemon_tournament_round(Trainer1, T1Pokemons, T1Levels,Trainer2, T2Pokemons, T2Levels, WinnerTrainerList).
																																								
%recursive helper for 4.8, get the head of each trainers pokemon list, evolve them, run pokemon_fight on them, determine the winner with winner method in the utilities, pass the tails to the recursive function																				
pokemon_tournament_round(Trainer1, T1Pokemons, T1Levels, Trainer2, T2Pokemons, T2Levels, WinnerTrainerList):-
														T1Pokemons = [Pokemon1|T1PokemonsTail],
														T1Levels=[Level1|T1LevelsTail],
														T2Pokemons = [Pokemon2|T2PokemonsTail],
														T2Levels	= [Level2|T2LevelsTail],
														find_pokemon_evolution(Level1,Pokemon1,Evolved1),
														find_pokemon_evolution(Level2,Pokemon2,Evolved2),
														pokemon_fight(Evolved1,Level1,Evolved2,Level2,HP1,HP2,_),
														winner(Trainer1, Trainer2, Winner, HP1, HP2),
														WinnerTrainerList = [Winner|Tail],
														pokemon_tournament_round(Trainer1, T1PokemonsTail, T1LevelsTail, Trainer2, T2PokemonsTail, T2LevelsTail, Tail).
																																								
%base case of recursion with 1 pokemon left in each team
pokemon_tournament_round(Trainer1, T1Pokemons, T1Levels, Trainer2, T2Pokemons, T2Levels, WinnerTrainerList):-
														T1Pokemons = [Pokemon1],
														T1Levels=[Level1],
														T2Pokemons = [Pokemon2],
														T2Levels	= [Level2],
														find_pokemon_evolution(Level1,Pokemon1,Evolved1),
														find_pokemon_evolution(Level2,Pokemon2,Evolved2),
														pokemon_fight(Evolved1,Level1,Evolved2,Level2,HP1,HP2,_),
														winner(Trainer1, Trainer2, Winner, HP1, HP2),
														WinnerTrainerList = [Winner].																																							
																																																																						
																																		
%best_pokemon(+EnemyPokemon, +LevelCap, -RemainingHP, -BestPokemon)
%using findall make a list of RemainingHealth-Pokemon pairs of each pokemon against EnemyPokemon using pokemon_fight, sort them with keysort, reverse to get highest first, Head of that list is RemainingHP-Pokemon with RemainingHP being the largest value in the list
best_pokemon(EnemyPokemon, LevelCap, RemainingHP, BestPokemon):-	
														findall(Remaining-Pokemon, pokemon_fight(Pokemon,LevelCap,EnemyPokemon, LevelCap, Remaining, _, _), Results),
														keysort(Results,Sorted),
														reverse(Sorted,Last),
														Last=[RemainingHP-BestPokemon|_].


%best_pokemon_team(+OpponentTrainer, -PokemonTeam)
%get the team and levels of the enemy trainer, pass those to the recursive function
best_pokemon_team(OpponentTrainer, PokemonTeam):-
														pokemon_trainer(OpponentTrainer,OpponentTeam,OpponentLevels),
														best_pokemon_list_parse(OpponentTeam,OpponentLevels, PokemonTeam).

%recursive helper of 4.10, get the Heads of each list, find H with best_pokemon, H is the head of the PokemonTeam, pass tails of each list to recursive function
best_pokemon_list_parse(OpponentTeam,OpponentLevels,PokemonTeam):-
														OpponentTeam=[Pokemon1|OpponentTeamTail],
														OpponentLevels=[Level1|OpponentLevelTail],
														PokemonTeam=[H|T],
														best_pokemon(Pokemon1,Level1, _, H),
														best_pokemon_list_parse(OpponentTeamTail, OpponentLevelTail, T).

%base case for recursive function, only 1 element in each list																							
best_pokemon_list_parse(OpponentTeam,OpponentLevels,PokemonTeam):-
														OpponentTeam=[Pokemon1],
														OpponentLevels=[Level1],
														PokemonTeam=[T],
														best_pokemon(Pokemon1,Level1, _, T).
										
										
%pokemon_types(+TypeList, InitialPokemonList, -PokemonList)
%finds all pokemon that are members of the initial list and that have the type in the type lists
pokemon_types(TypeList, InitialPokemonList, PokemonList):-
														findall(Pokemon,(member(Pokemon,InitialPokemonList), pokemon_types_2(TypeList,Pokemon)),PokemonList).

%recursive function to check if pokemon has a type that is in the TypeList, recurses over TypeList to compare each type with PokemonTypeList
pokemon_types_2([H|TypeListTail],Pokemon):-				
														pokemon_stats(Pokemon,PokemonTypeList,_,_,_),
														((member(H,PokemonTypeList),!); pokemon_types_2(TypeListTail,Pokemon)).


%generate_pokemon_team(LikedTypes,DislikedTypes,Criterion,Count,PokemonTeam)
%get the list of all pokemon, run pokemon_types with LikedTypes and DislikedTypes over the list of AllPokes, subtract resulting DislikedPokes from LikedPokes(this makes sure that only pokemons of LikedType are in and no Pokemons of the DislikedType)
%use with_stats on resulting SubtractedList to find a list that contains pokemon together with their stats, use criteria to find wich element of each pokemons list said criterion corresponds to, use predsort with nthcompare(Number_coming_from_criteria) to sort according to that
%criterion, reverse because it was in ascending order, use findall to get the with first Count elements of that set, sort and reverse again because bag is not guaranteed to be in order(I know that reverse stuff could be done with a better overloading but it was not working on my machine and findall at the end could 
%be done much easier with take/3 but this way it handles cases where count is < than the length of list so..)
generate_pokemon_team(LikedTypes,DislikedTypes,Criterion,Count,PokemonTeam):-
														allPokes(AllPokes),
														pokemon_types(LikedTypes, AllPokes, LikedPokes),
														pokemon_types(DislikedTypes, AllPokes, DislikedPokes),
														subtract(LikedPokes,DislikedPokes,EndSet),
														with_stats(EndSet,StatSet),
														criteria(Criterion,Number),
														predsort(nthcompare(Number), StatSet,SortedSet),
														reverse(SortedSet,ReverseSet),
														findall(Element,
															(nth0(Index,ReverseSet,Element),
															Index<Count),
															Bag),
														predsort(nthcompare(Number), Bag, SortedBag),!,
														reverse(SortedBag,PokemonTeam).