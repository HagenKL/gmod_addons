local EVENT = {}

EVENT.Title = "Everything is as fast as Flash now!(50% faster)"
EVENT.Time = 120

function EVENT:Begin()
	game.SetTimeScale(1.5)
end

function EVENT:End()
	game.SetTimeScale(1)
end

Randomat:register("flash", EVENT)
