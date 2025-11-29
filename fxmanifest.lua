fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'ESX Phone Converted from QBCore Convert To ESX by A R d x'
version '1.3.0'

ui_page 'html/index.html'

-- Dependencies memastikan resource ini start SETELAH es_extended dan oxmysql
dependencies {
    'es_extended',
    'oxmysql'
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/animation.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/*.html',
    'html/js/*.js',
    'html/img/*.png',
    'html/css/*.css',
    'html/img/backgrounds/*.png',
    'html/img/apps/*.png',
    'html/img/frames/*.png',

}