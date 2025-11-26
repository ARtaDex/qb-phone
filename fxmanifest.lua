fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'ESX Phone Converted from QBCore'
version '1.3.0'

ui_page 'html/index.html'

-- Menambahkan dependencies agar script load setelah ESX dan DB siap
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
}