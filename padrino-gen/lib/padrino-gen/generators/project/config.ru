require ::File.dirname(__FILE__) + '/config/boot.rb'
Padrino::Reloader.disable!
run Padrino.application