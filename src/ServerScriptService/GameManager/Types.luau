--!strict
--!optimize 2

local types = {}

export type array<t> = {[number]:t}
export type dictionary<t> = {[string]:t}

export type roundSnapshot = {
	currentTurnIndex:number,
	usedCardCount:number,

	initialDeckSize:number?,
	roundTime:number?,

	deck:{string},
	pillarsTable:{Model},
	playerTable:{string},
	plrCards:array<{string}>,
}

export type Helpers = {
	getPlayerTable: (() -> {string})?,
	getPillarsTable: (() -> {Model})?,
	getDeck: (() -> {string})?,
	getPlrCardsProvider: (() -> array<{string}>)?,
	
	copyTable: <T>(t:T) -> T,
	isPlayer: (number) -> (boolean, Player?),
	setProviders: (provider:() -> {string}, provider2:() -> {Model}, provider3:() -> {string}, provider4:() -> array<{string}>) -> (),
}

export type StealInfo = {
	playerStealingIndex:number,
	playerGettingStolenFromIndex:number,
	requestedCard:string?,
}

export type deckManager = {
	TurnsToDo:number,
	IsRoundTerminated:boolean,
	InitialDeck:{string}?,
	CurrentDeck:{string}?,

	CreatePlayerDecks: (numberOfPlayers: number) -> {any},
	CreateDeck: (numberOfPlayers: number) -> {string},
	InsertCardAtRandomPosition: (deck: {string}, card: string) -> {string},
	InsertCardAtPosition: (deck: {string}, card: string, position: number) -> {string},
	GetTurnCount: () -> number,
	SetTurnCount: (turns: number) -> (),
	Shuffle: (deck: {any}) -> {any},
}

return nil