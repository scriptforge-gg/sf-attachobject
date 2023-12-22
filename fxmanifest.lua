fx_version "cerulean"
game "gta5"
lua54 'yes'

author "mmleczek (scriptforge.gg)"
version "1.0.1"

server_exports {
	"CreateAttachObject",
	"RemoveAttachObject",
	"ClearPlayerObjects",
	"RegisterObject",
	"UnregisterObject",
	"GetObjectsOnPlayer",
	"FixPlayerProps"
}

client_script "client.lua"
server_script "server.lua"