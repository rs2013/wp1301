@echo on
pushd d:\work\ws_haxe\wp1301\android\bin\classes
haxelib run nme generate -java-externs com/weiplus/client/HaxeStub.class .
haxelib run nme generate -java-externs com/weiplus/client/HpManager.class .
move /y com\weiplus\client\*.hx d:\work\ws_haxe\wp1301\haxeone\src\com\weiplus\client
popd
