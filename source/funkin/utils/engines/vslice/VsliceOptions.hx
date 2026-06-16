#if VSLICE_ALLOWED
package funkin.utils.engines.vslice;

class VsliceOptions {
    public static var ANTIALIASING(get,never):Bool;    
    public static function get_ANTIALIASING():Bool {
        return ClientPrefs.data.antialiasing;
    }
    public static var IS_LOW_QUALITY(get,never):Bool;    
    public static function get_IS_LOW_QUALITY():Bool {
        return ClientPrefs.isLowQuality;
    }
    public static var SHADERS(get,never):Bool;    
    public static function get_SHADERS():Bool {
        return ClientPrefs.data.shaders;
    }
    public static var FLASHBANG(get,never):Bool;    
    public static function get_FLASHBANG():Bool {
        return ClientPrefs.data.flashing;
    }
    #end
}