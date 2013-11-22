package com.weiplus.client;


class HaxeCamera
{
	var __jobject:Dynamic;
	
	
	public function new(handle:Dynamic)
	{
		__jobject = handle;
	}
	
	
	private static var _getNumberOfCameras_func:Dynamic;

	public static function getNumberOfCameras():Int
	{
//		if (_getNumberOfCameras_func == null)
//			_getNumberOfCameras_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getNumberOfCameras", "()I", true);
//		var a = new Array<Dynamic>();
//		return _getNumberOfCameras_func(a);
        return 1;
	}
	
	
	private static var _getCurrentCameraId_func:Dynamic;

	public static function getCurrentCameraId():Int
	{
//		if (_getCurrentCameraId_func == null)
//			_getCurrentCameraId_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getCurrentCameraId", "()I", true);
//		var a = new Array<Dynamic>();
//		return _getCurrentCameraId_func(a);
        return 0;
	}
	
	
	private static var _getCameraInfo_func:Dynamic;

	public static function getCameraInfo(arg0:Int):Dynamic
	{
//		if (_getCameraInfo_func == null)
//			_getCameraInfo_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getCameraInfo", "(I)[I", true);
//		var a = new Array<Dynamic>();
//		a.push(arg0);
//		return _getCameraInfo_func(a);
        return null;
	}
	
	
	private static var _switchOrientation_func:Dynamic;

	public static function switchOrientation():Void
	{
//		if (_switchOrientation_func == null)
//			_switchOrientation_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "switchOrientation", "()V", true);
//		var a = new Array<Dynamic>();
//		_switchOrientation_func(a);
	}
	
	
	private static var _openCamera_func:Dynamic;

	public static function openCamera(arg0:Int, arg1:Dynamic /*org.haxe.nme.HaxeObject*/, arg2:String):Void
	{
//		if (_openCamera_func == null)
//			_openCamera_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "openCamera", "(ILorg/haxe/nme/HaxeObject;Ljava/lang/String;)V", true);
//		var a = new Array<Dynamic>();
//        a.push(arg0);
//        a.push(arg1);
//        a.push(arg2);
//		_openCamera_func(a);
	}
	
	
	private static var _closeCamera_func:Dynamic;

	public static function closeCamera():Void
	{
//		if (_closeCamera_func == null)
//			_closeCamera_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "closeCamera", "()V", true);
//		var a = new Array<Dynamic>();
//		_closeCamera_func(a);
	}
	
	
	private static var _getFlashModes_func:Dynamic;

	public static function getFlashModes():Dynamic
	{
//		if (_getFlashModes_func == null)
//			_getFlashModes_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getFlashModes", "()[Ljava/lang/String;", true);
//		var a = new Array<Dynamic>();
//		return _getFlashModes_func(a);
        return [ "auto" ];
	}
	
	
	private static var _switchFlashMode_func:Dynamic;

	public static function switchFlashMode():Void
	{
//		if (_switchFlashMode_func == null)
//			_switchFlashMode_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "switchFlashMode", "()V", true);
//		var a = new Array<Dynamic>();
//		_switchFlashMode_func(a);
	}
	
	
	private static var _getMaxZoom_func:Dynamic;

	public static function getMaxZoom():Float
	{
//		if (_getMaxZoom_func == null)
//			_getMaxZoom_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getMaxZoom", "()D", true);
//		var a = new Array<Dynamic>();
//		return _getMaxZoom_func(a);
        return 1;
	}
	
	
	private static var _getZoom_func:Dynamic;

	public static function getZoom():Float
	{
//		if (_getZoom_func == null)
//			_getZoom_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "getZoom", "()D", true);
//		var a = new Array<Dynamic>();
//		return _getZoom_func(a);
        return 1;
	}
	
	
	private static var _setZoom_func:Dynamic;

	public static function setZoom(arg0:Float):Void
	{
//		if (_setZoom_func == null)
//			_setZoom_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "setZoom", "(D)V", true);
//		var a = new Array<Dynamic>();
//		a.push(arg0);
//		_setZoom_func(a);
	}
	
	
	private static var _snap_func:Dynamic;

	public static function snap(arg0:String, arg1:Dynamic /*org.haxe.nme.HaxeObject*/, arg2:String):Void
	{
//		if (_snap_func == null)
//			_snap_func = openfl.utils.JNI.createStaticMethod("com/weiplus/client/HaxeCamera", "snap", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;Ljava/lang/String;)V", true);
//		var a = new Array<Dynamic>();
//		a.push(arg0);
//		a.push(arg1);
//        a.push(arg2);
//		_snap_func(a);
	}
	
	
}