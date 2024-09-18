dist/out.lua: src/Main.hx src/JsonHelper.hx src/RequestHelper.hx src/Storage.hx src/Frollo.hx
	mkdir -p dist
	cd src/ && haxe --lua ../dist/out.lua --main Main -D lua-vanilla -D lua-return

