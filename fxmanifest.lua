fx_version 'cerulean'

game 'gta5'
author 'MiritoKaba'
description ''
version '1.0'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}

shared_scripts {
    '@ox_lib/init.lua',
	'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

client_scripts {
	'client/*.lua',
}

files {
    'locales/*.lua'
}

lua54 'yes'