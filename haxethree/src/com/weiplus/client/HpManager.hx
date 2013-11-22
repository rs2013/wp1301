package com.weiplus.client;


class HpManager
{
	var __jobject:Dynamic;
	
	
	private static var __create_func:Dynamic;

	public static function _create():com.weiplus.client.HpManager
	{
		if (__create_func == null)
			__create_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "<init>", "()V", true);
		var a = new Array<Dynamic>();
		return new com.weiplus.client.HpManager(__create_func(a));
	}
	
	
	public function new(handle:Dynamic)
	{
		__jobject = handle;
	}
	
	
	private static var _login_func:Dynamic;

	public static function login():Bool
	{
		if (_login_func == null)
			_login_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "login", "()Z", true);
		var a = new Array<Dynamic>();
		return _login_func(a);
	}
	
	
	private static var _restoreBindings_func:Dynamic;

	public static function restoreBindings(arg0:Dynamic /*org.json.JSONArray*/):Void
	{
		if (_restoreBindings_func == null)
			_restoreBindings_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "restoreBindings", "(Lorg/json/JSONArray;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_restoreBindings_func(a);
	}
	
	
	private static var _loginOld_func:Dynamic;

	public static function loginOld():Void
	{
		if (_loginOld_func == null)
			_loginOld_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "loginOld", "()V", true);
		var a = new Array<Dynamic>();
		_loginOld_func(a);
	}
	
	
	private static var _bind_func:Dynamic;

	public static function bind(arg0:String):Void
	{
		if (_bind_func == null)
			_bind_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "bind", "(Ljava/lang/String;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_bind_func(a);
	}
	
	
	private static var _getPublicTimeline_func:Dynamic;

	public static function getPublicTimeline(arg0:Int, arg1:Int, arg2:Float, arg3:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getPublicTimeline_func == null)
			_getPublicTimeline_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getPublicTimeline", "(IIJLorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		_getPublicTimeline_func(a);
	}
	
	
	private static var _getHomeTimeline_func:Dynamic;

	public static function getHomeTimeline(arg0:Int, arg1:Int, arg2:Float, arg3:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getHomeTimeline_func == null)
			_getHomeTimeline_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getHomeTimeline", "(IIJLorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		_getHomeTimeline_func(a);
	}
	
	
	private static var _getUserTimeline_func:Dynamic;

	public static function getUserTimeline(arg0:String, arg1:Int, arg2:Int, arg3:Float, arg4:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getUserTimeline_func == null)
			_getUserTimeline_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getUserTimeline", "(Ljava/lang/String;IIJLorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		a.push(arg4);
		_getUserTimeline_func(a);
	}
	
	
	private static var _getUserInfo_func:Dynamic;

	public static function getUserInfo(arg0:String, arg1:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_getUserInfo_func == null)
			_getUserInfo_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getUserInfo", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		_getUserInfo_func(a);
	}
	
	
	private static var _postStatus_func:Dynamic;

	public static function postStatus(arg0:Array<String>, arg1:String, arg2:String, arg3:String, arg4:String, arg5:String, arg6:String, arg7:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_postStatus_func == null)
			_postStatus_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "postStatus", "([Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		a.push(arg3);
		a.push(arg4);
		a.push(arg5);
		a.push(arg6);
		a.push(arg7);
		_postStatus_func(a);
	}
	
	
	private static var _getAccessToken_func:Dynamic;

	public static function getAccessToken():Dynamic
	{
		if (_getAccessToken_func == null)
			_getAccessToken_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getAccessToken", "()Lcom/harryphoto/api/HpAccessToken;", true);
		var a = new Array<Dynamic>();
		return _getAccessToken_func(a);
	}
	
	
	private static var _getTokenAsJson_func:Dynamic;

	public static function getTokenAsJson():String
	{
		if (_getTokenAsJson_func == null)
			_getTokenAsJson_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getTokenAsJson", "()Ljava/lang/String;", true);
		var a = new Array<Dynamic>();
		return _getTokenAsJson_func(a);
	}
	
	
	private static var _setAccessToken_func:Dynamic;

	public static function setAccessToken(arg0:Dynamic /*com.harryphoto.api.HpAccessToken*/):Void
	{
		if (_setAccessToken_func == null)
			_setAccessToken_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "setAccessToken", "(Lcom/harryphoto/api/HpAccessToken;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_setAccessToken_func(a);
	}
	
	
	private static var _saveAccessToken_func:Dynamic;

	public static function saveAccessToken():Void
	{
		if (_saveAccessToken_func == null)
			_saveAccessToken_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "saveAccessToken", "()V", true);
		var a = new Array<Dynamic>();
		_saveAccessToken_func(a);
	}
	
	
	private static var _logout_func:Dynamic;

	public static function logout():Void
	{
		if (_logout_func == null)
			_logout_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "logout", "()V", true);
		var a = new Array<Dynamic>();
		_logout_func(a);
	}
	
	
	private static var _onActivityResult_func:Dynamic;

	public static function onActivityResult(arg0:Dynamic /*android.app.Activity*/, arg1:Int, arg2:Int, arg3:Dynamic /*android.content.Intent*/):Void
	{
		if (_onActivityResult_func == null)
			_onActivityResult_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "onActivityResult", "(Landroid/app/Activity;IILandroid/content/Intent;)V", true);
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
			_getBinding_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getBinding", "(Lcom/harryphoto/bind/Binding$Type;)Lcom/harryphoto/bind/Binding;", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _getBinding_func(a);
	}
	
	
	private static var _hasBinding_func:Dynamic;

	public static function hasBinding(arg0:String):Bool
	{
		if (_hasBinding_func == null)
			_hasBinding_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "hasBinding", "(Ljava/lang/String;)Z", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _hasBinding_func(a);
	}
	
	
	private static var _isBindingEnabled_func:Dynamic;

	public static function isBindingEnabled(arg0:String):Bool
	{
		if (_isBindingEnabled_func == null)
			_isBindingEnabled_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "isBindingEnabled", "(Ljava/lang/String;)Z", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _isBindingEnabled_func(a);
	}
	
	
	private static var _setBindingEnabled_func:Dynamic;

	public static function setBindingEnabled(arg0:String, arg1:Bool):Void
	{
		if (_setBindingEnabled_func == null)
			_setBindingEnabled_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "setBindingEnabled", "(Ljava/lang/String;Z)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		_setBindingEnabled_func(a);
	}
	
	
	private static var _isBindingSessionValid_func:Dynamic;

	public static function isBindingSessionValid(arg0:String):Bool
	{
		if (_isBindingSessionValid_func == null)
			_isBindingSessionValid_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "isBindingSessionValid", "(Ljava/lang/String;)Z", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _isBindingSessionValid_func(a);
	}
	
	
	private static var _startAuth_func:Dynamic;

	public static function startAuth(arg0:String, arg1:Dynamic /*org.haxe.nme.HaxeObject*/):Void
	{
		if (_startAuth_func == null)
			_startAuth_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "startAuth", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		_startAuth_func(a);
	}
	
	
	private static var _getImageUrl_func:Dynamic;

	public static function getImageUrl(arg0:String):String
	{
		if (_getImageUrl_func == null)
			_getImageUrl_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getImageUrl", "(Ljava/lang/String;)Ljava/lang/String;", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _getImageUrl_func(a);
	}
	
	
	private static var _addBinding_func:Dynamic;

	public static function addBinding(arg0:Dynamic /*com.harryphoto.bind.Binding*/):Void
	{
		if (_addBinding_func == null)
			_addBinding_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "addBinding", "(Lcom/harryphoto/bind/Binding;)V", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		_addBinding_func(a);
	}
	
	
	private static var _createBinding_func:Dynamic;

	public static function createBinding(arg0:Dynamic /*com.harryphoto.bind.Binding$Type*/):Dynamic
	{
		if (_createBinding_func == null)
			_createBinding_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "createBinding", "(Lcom/harryphoto/bind/Binding$Type;)Lcom/harryphoto/bind/Binding;", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		return _createBinding_func(a);
	}
	
	
	private static var _getCandidate_func:Dynamic;

	public static function getCandidate():Dynamic
	{
		if (_getCandidate_func == null)
			_getCandidate_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "getCandidate", "()Lcom/harryphoto/bind/Binding;", true);
		var a = new Array<Dynamic>();
		return _getCandidate_func(a);
	}
	
	
	private static var _createBinding1_func:Dynamic;

	public static function createBinding1(arg0:Dynamic /*com.harryphoto.bind.Binding$Type*/, arg1:Array<String>, arg2:String):Dynamic
	{
		if (_createBinding1_func == null)
			_createBinding1_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HpManager", "createBinding", "(Lcom/harryphoto/bind/Binding$Type;[Ljava/lang/String;)Lcom/harryphoto/bind/Binding;", true);
		var a = new Array<Dynamic>();
		a.push(arg0);
		a.push(arg1);
		a.push(arg2);
		return _createBinding1_func(a);
	}
	
	
}