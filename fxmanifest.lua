fx_version "cerulean"
game "gta5"
author "Pickle Mods"
description "The best police job in FiveM."
version "v1.2.1"

data_file 'DLC_ITYP_REQUEST' 'npds_picklestirepunct.ytyp'
data_file 'DLC_ITYP_REQUEST' 'grappler_props.ytyp'

ui_page "nui/index.html"

files {
	"nui/index.html",
	"nui/images/*.*",
	"nui/fonts/*.*",
	"nui/sounds/*.*",
	"nui/assets/**/*.*",
	"nui/debug.js",
	"components/**/*.*",
}

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua",
	"locales/locale.lua",
    "locales/translations/*.lua",
	"modules/**/shared.lua",
    "core/shared.lua"
}

client_scripts {
	"bridge/**/**/client.lua",
	"modules/**/client.lua",
    "core/client.lua"
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"bridge/**/**/server.lua",
	"modules/**/server.lua",
    "core/server.lua",
	"config_sv.lua",
}


provides {
	"qb-policejob",
	"esx_policejob",
}

lua54 'yes'

escrow_ignore {
	"config.lua",
	"config_sv.lua",
	"__INSTALL/**/*.*",
	"core/*.*",
	"bridge/**/**/*.*",
	"bridge/**/*.*",
    "locales/locale.lua",
    "locales/translations/*.lua",
}