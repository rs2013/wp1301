package com.weiplus.client;

/**
 * ...
 * @author Rocks Wang
 */

class Filters {

    //LOMO
    public inline static var colormatrix_lomo: Array<Float> = [
        1.7, 0.1, 0.1, 0, -73.1,
        0, 1.7, 0.1, 0, -73.1,
        0, 0.1, 1.6, 0, -73.1,
        0, 0, 0, 1.0, 0     
    ];

    //黑白
    public inline static var colormatrix_heibai: Array<Float> = [
        0.8, 1.6, 0.2, 0, -163.9,
        0.8, 1.6, 0.2, 0, -163.9,
        0.8, 1.6, 0.2, 0, -163.9,
        0, 0, 0, 1.0, 0     
    ];
    
    //复古
    public inline static var colormatrix_huajiu: Array<Float> = [ 
        0.2, 0.5, 0.1, 0, 40.8,
        0.2, 0.5, 0.1, 0, 40.8, 
        0.2, 0.5, 0.1, 0, 40.8, 
        0, 0, 0, 1, 0     
    ];

    //哥特
    public inline static var colormatrix_gete: Array<Float> = [ 
        1.9, -0.3, -0.2, 0, -87.0,
        -0.2, 1.7, -0.1, 0, -87.0, 
        -0.1, -0.6, 2.0, 0, -87.0, 
        0, 0, 0, 1.0, 0     
    ];

    //锐化
    public inline static var colormatrix_ruise: Array<Float> = [ 
        4.8, -1.0, -0.1, 0, -388.4,
        -0.5, 4.4, -0.1, 0, -388.4, 
        -0.5, -1.0, 5.2, 0, -388.4,
        0, 0, 0, 1.0, 0     
    ];

    //淡雅
    public inline static var colormatrix_danya: Array<Float> = [ 
        0.6, 0.3, 0.1, 0, 73.3,
        0.2, 0.7, 0.1, 0, 73.3, 
        0.2, 0.3, 0.4, 0, 73.3,
        0, 0, 0, 1.0, 0     
    ];

    //酒红
    public inline static var colormatrix_jiuhong: Array<Float> = [ 
        1.2, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.9, 0.0, 0.0, 0.0, 
        0.0, 0.0, 0.8, 0.0, 0.0,
        0, 0, 0, 1.0, 0     
    ];

    //清宁
    public inline static var colormatrix_qingning: Array<Float> = [ 
        0.9, 0, 0, 0, 0, 
        0, 1.1, 0, 0, 0, 
        0, 0, 0.9, 0, 0, 
        0, 0, 0, 1.0, 0     
    ];

    //浪漫
    public inline static var colormatrix_langman: Array<Float> = [ 
        0.9, 0, 0, 0, 63.0, 
        0, 0.9, 0, 0, 63.0, 
        0, 0, 0.9, 0, 63.0, 
        0, 0, 0, 1.0, 0     
    ];

    //光晕
    public inline static var colormatrix_guangyun: Array<Float> = [ 
        0.9, 0, 0, 0, 64.9,
        0, 0.9, 0, 0, 64.9,
        0, 0, 0.9, 0, 64.9,
        0, 0, 0, 1.0, 0     
    ];

    //蓝调
    public inline static var colormatrix_landiao: Array<Float> = [
        2.1, -1.4, 0.6, 0.0, -31.0, 
        -0.3, 2.0, -0.3, 0.0, -31.0,
        -1.1, -0.2, 2.6, 0.0, -31.0, 
        0.0, 0.0, 0.0, 1.0, 0.0
    ];

    //梦幻
    public inline static var colormatrix_menghuan: Array<Float> = [
        0.8, 0.3, 0.1, 0.0, 46.5, 
        0.1, 0.9, 0.0, 0.0, 46.5, 
        0.1, 0.3, 0.7, 0.0, 46.5, 
        0.0, 0.0, 0.0, 1.0, 0.0
    ];

    //夜色
    public inline static var colormatrix_yese: Array<Float> = [
        1.0, 0.0, 0.0, 0.0, -66.6,
        0.0, 1.1, 0.0, 0.0, -66.6, 
        0.0, 0.0, 1.0, 0.0, -66.6, 
        0.0, 0.0, 0.0, 1.0, 0.0
    ];

	public inline static var FILTER_NAMES: Array<String> = [
		"原图", "LOMO", "黑白", "复古", "哥特", "锐化", "淡雅", "酒红", "清宁", "浪漫", "光晕", "蓝调", "梦幻", "夜色"
	];
	
	public inline static var FILTER_MATRICES: Array<Array<Float>> = [
		null, 
		colormatrix_lomo, colormatrix_heibai, colormatrix_huajiu, colormatrix_gete, 
		colormatrix_ruise, colormatrix_danya, colormatrix_jiuhong, colormatrix_qingning, 
		colormatrix_langman, colormatrix_guangyun, colormatrix_landiao, colormatrix_menghuan, 
		colormatrix_yese
	];
	
	private static var map: Hash<Array<Float>>;
	
	public static function getMatrixByName(name: String) : Array<Float> {
		if (map == null) {
			map = new Hash<Array<Float>>();
			for (i in 0...FILTER_NAMES.length) {
				var key = FILTER_NAMES[i];
				var matrix = FILTER_MATRICES[i];
				map.set(key, matrix);
			}
		}
		return map.get(name);
	}
	
	private function new() {
		
	}
	
}