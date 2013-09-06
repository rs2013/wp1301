@echo on
pushd D:\work\ws_haxe\wp1301\haxeone\bin\android\bin\bin\classes
haxelib run openfl generate -java-externs com/weiplus/client/HaxeStub.class .
haxelib run openfl generate -java-externs com/weiplus/client/HpManager.class .
haxelib run openfl generate -java-externs com/weiplus/client/HaxeCamera.class .
move /y com\weiplus\client\*.hx d:\work\ws_haxe\wp1301\haxeone\src\com\weiplus\client
popd
