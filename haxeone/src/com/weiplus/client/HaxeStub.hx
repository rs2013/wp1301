package com.weiplus.client;

class HaxeStub
{
	var __jobject:Dynamic;
	
	
	private static var __create_func:Dynamic;

	public static function _create():com.weiplus.client.HaxeStub
	{
		if (__create_func == null)
			__create_func = nme.JNI.createStaticMethod("com/weiplus/client/HaxeStub", "<init>", "()V", true);
		var a = new Array<Dynamic>();
		return new com.weiplus.client.HaxeStub(__create_func(a));
	}
	
	
	public function new(handle:Dynamic)
	{
		__jobject = handle;
	}
	
	
	private static var _getBuffer_func:Dynamic;

	public static function getBuffer():Dynamic
	{
		if (_getBuffer_func == null)
			_getBuffer_func = nme.JNI.createStaticMethod("com/weiplus/client/HaxeStub", "getBuffer", "()[I", true);
		var a = new Array<Dynamic>();
		return _getBuffer_func(a);
	}
	
	
}
