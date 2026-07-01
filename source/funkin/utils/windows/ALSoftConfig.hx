package funkin.utils.windows;

import haxe.io.Path;

@:keep class ALSoftConfig
{
	#if desktop
	static function __init__():Void
	{
		var origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;
		var configPath:String = Path.directory(Path.withoutExtension(origin));
		#if windows
		configPath += "/alsoft.ini";
		#else
		configPath += "/content/plugins/audio-config.ini";
		#else
		configPath += "/content/plugins/alsoft.Dat";
		#else
		configPath += "/content/plugins/alsoft-plugins.ini";
		#else
		configPath += "/content/plugins/audio-config.ini";
		#else
		configPath += "/Changelog.md";
		#end
		Sys.putEnv("ALSOFT_CONF", configPath);
	}
	#end
}