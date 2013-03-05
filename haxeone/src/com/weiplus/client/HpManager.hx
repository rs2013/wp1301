package com.weiplus.client;


class HpManager
{
	var __jobject:Dynamic;
	
	
	private static var __create_func:Dynamic;

	public static function _create():com.weiplus.client.HpManager
	{
		if (__create_func == null)
			__create_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "<init>", "()V", true);
		var a = new Array<Dynamic>();
		return new com.weiplus.client.HpManager(__create_func(a));
	}
	
	
	public function new(handle:Dynamic)
	{
		__jobject = handle;
	}
	
	
	private static var _check_func:Dynamic;

	public static function check():Bool
	{
		if (_check_func == null)
			_check_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "check", "()Z", true);
		var a = new Array<Dynamic>();
		return _check_func(a);
	}
	
	
	private static var _login_func:Dynamic;

	public static function login():Void
	{
		if (_login_func == null)
			_login_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "login", "()V", true);
		var a = new Array<Dynamic>();
		_login_func(a);
	}
	
	
	private static var _getPublicTimeline_func:Dynamic;

	public static function getPublicTimeline(arg0:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getPublicTimeline_func == null)
			_getPublicTimeline_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getPublicTimeline", "(Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_getPublicTimeline_func(a);
	}
	
	
	private static var _getHomeTimeline_func:Dynamic;

	public static function getHomeTimeline(arg0:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getHomeTimeline_func == null)
			_getHomeTimeline_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getHomeTimeline", "(Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_getHomeTimeline_func(a);
	}
	
	
	private static var _getUserTimeline_func:Dynamic;

	public static function getUserTimeline(arg0:String, arg1:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getUserTimeline_func == null)
			_getUserTimeline_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getUserTimeline", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		_getUserTimeline_func(a);
	}
	
	
	private static var _getUserInfo_func:Dynamic;

	public static function getUserInfo(arg0:String, arg1:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getUserInfo_func == null)
			_getUserInfo_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getUserInfo", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		_getUserInfo_func(a);
	}
	
	
	private static var _postStatus_func:Dynamic;

	public static function postStatus(arg0:String, arg1:String, arg2:String, arg3:String, arg4:String, arg5:String, arg6:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_postStatus_func == null)
			_postStatus_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "postStatus", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		a.push(arg4);
		a.push(arg5);
		a.push(arg6);
		_postStatus_func(a);
	}
	
	
	private static var _getAccessToken_func:Dynamic;

	public static function getAccessToken():Dynamic
	{
		if (_getAccessToken_func == null)
			_getAccessToken_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getAccessToken", "()Lcom/harryphoto/api/HpAccessToken;", true);
		var a = new Array<Dynamic>();
		return _getAccessToken_func(a);
	}
	
	
	private static var _setAccessToken_func:Dynamic;

	public static function setAccessToken(arg0:Dynamic /*com.harryphoto.api.HpAccessToken*/):Void
	{
		if (_setAccessToken_func == null)
			_setAccessToken_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "setAccessToken", "(Lcom/harryphoto/api/HpAccessToken;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_setAccessToken_func(a);
	}
	
	
	private static var _saveAccessToken_func:Dynamic;

	public static function saveAccessToken():Void
	{
		if (_saveAccessToken_func == null)
			_saveAccessToken_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "saveAccessToken", "()V", true);
		var a = new Array<Dynamic>();
		_saveAccessToken_func(a);
	}
	
	
	private static var _logout_func:Dynamic;

	public static function logout():Void
	{
		if (_logout_func == null)
			_logout_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "logout", "()V", true);
		var a = new Array<Dynamic>();
		_logout_func(a);
	}
	
	
	private static var _onActivityResult_func:Dynamic;

	public static function onActivityResult(arg0:Dynamic /*android.app.Activity*/, arg1:Int, arg2:Int, arg3:Dynamic /*android.content.Intent*/):Void
	{
		if (_onActivityResult_func == null)
			_onActivityResult_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "onActivityResult", "(Landroid/app/Activity;IILandroid/content/Intent;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		_onActivityResult_func(a);
	}
	
	
	private static var _getBinding_func:Dynamic;

	public static function getBinding(arg0:Dynamic /*com.harryphoto.bind.Binding$Type*/):Dynamic
	{
		if (_getBinding_func == null)
			_getBinding_func = nme.JNI.createStaticMethod("com/weiplus/client/HpManager", "getBinding", "(Lcom/harryphoto/bind/Binding$Type;)Lcom/harryphoto/bind/Binding;", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _getBinding_func(a);
	}
	
	
}