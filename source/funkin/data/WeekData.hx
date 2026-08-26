package funkin.data;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

typedef WeekFile = {
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
	@:optional var hideStorySongs:Array<String>;
	@:optional var storyDifficulties:String;
	@:optional var freeplayDifficulties:String;
	@:optional var section:Dynamic;
	@:optional var sections:Dynamic;
}

class WeekData
{
	public var folder:String = '';
	static var reloadTargetSection:String = 'freeplay';
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var hideStorySongs:Array<String>;
	public var difficulties:String;
	public var storyDifficulties:String;
	public var freeplayDifficulties:String;
	public var section:Dynamic;
	public var sections:Dynamic;
	public var fileName:String;

	public static function createWeekFile():WeekFile 
	{
		var weekFile:WeekFile = {
				songs: [
					["Bopeebo", "dad", [146, 113, 253]],
					["Fresh", "dad", [146, 113, 253]],
					["Dad Battle", "dad", [146, 113, 253]]
				],

			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: '',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			hideStorySongs: [],
			difficulties: 'Easy, Normal, Hard',
			storyDifficulties: 'Easy, Normal, Hard',
			freeplayDifficulties: 'Easy, Normal, Hard',
			section: ['storyMode', 'freeplay', 'extra']
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(weekFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
		hideStorySongs = parseHiddenStorySongs(hideStorySongs);
	}

	public static function getWeekSongName(song:Dynamic):String
	{
		if(song == null) return '';
		if(Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if(data.length > 0 && data[0] != null) return Std.string(data[0]);
		}
		return Std.string(song);
	}

	public static function parseHiddenStorySongs(value:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		if(value == null) return output;

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			for (item in array)
				addHiddenSongName(output, item);
		}
		else
		{
			for (item in Std.string(value).split(','))
				addHiddenSongName(output, item);
		}
		return output;
	}

	public static function hiddenStorySongsToText(value:Dynamic):String
	{
		return parseHiddenStorySongs(value).join(', ');
	}

	public static function setHiddenStorySongs(week:Dynamic, value:Dynamic):Array<String>
	{
		var hidden:Array<String> = parseHiddenStorySongs(value);
		if(week != null) Reflect.setField(week, 'hideStorySongs', hidden);
		return hidden;
	}

	public static function visibleStorySongs(week:Dynamic):Array<Dynamic>
	{
		var output:Array<Dynamic> = [];
		if(week == null) return output;

		var rawSongs:Dynamic = Reflect.field(week, 'songs');
		if(rawSongs == null || !Std.isOfType(rawSongs, Array)) return output;

		var songs:Array<Dynamic> = cast rawSongs;
		for (song in songs)
			if(!isStorySongHidden(week, song))
				output.push(song);
		return output;
	}

	public static function visibleStorySongNames(week:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		for (song in visibleStorySongs(week))
			output.push(getWeekSongName(song));
		return output;
	}

	public static function isStorySongHidden(week:Dynamic, song:Dynamic):Bool
	{
		var songName:String = getWeekSongName(song);
		var formattedSong:String = Paths.formatToSongPath(songName);
		for (hidden in parseHiddenStorySongs(week != null ? Reflect.field(week, 'hideStorySongs') : null))
		{
			if(Paths.formatToSongPath(hidden) == formattedSong)
				return true;
		}

		if(Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if(data.length > 3 && dynamicBool(data[3]))
				return true;
		}
		return false;
	}

	static function addHiddenSongName(list:Array<String>, value:Dynamic)
	{
		if(value == null) return;
		var name:String = Std.string(value).trim();
		if(name.length < 1) return;

		var formatted:String = Paths.formatToSongPath(name);
		for (existing in list)
			if(Paths.formatToSongPath(existing) == formatted)
				return;
		list.push(name);
	}

	static function dynamicBool(value:Dynamic):Bool
	{
		if(value == null) return false;
		if(Std.isOfType(value, Bool)) return value;

		var clean:String = Std.string(value).toLowerCase().trim();
		return clean == 'true' || clean == '1' || clean == 'yes' || clean == 'hide' || clean == 'hidden';
	}

	public static function reloadWeekFiles(section:Dynamic = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		var targetSection:String = normalizeMenuSection(section);
		reloadTargetSection = targetSection;
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + '/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('levels/WeeksList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'data/levels/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if(j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if(weekFile != null && weekMatchesSection(weekFile, targetSection)) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'data/levels/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	public static function normalizeMenuSection(value:Dynamic):String
	{
		if(value == null)
			return null;
		if(Std.isOfType(value, Bool))
			return value ? 'storyMode' : 'freeplay';

		var clean:String = Std.string(value).trim();
		if(clean.length < 1)
			return null;

		switch(clean.toLowerCase())
		{
			case 'story', 'storymode', 'story_mode':
				return 'storyMode';
			case 'free', 'freeplay', 'free_play':
				return 'freeplay';
			case 'extra', 'extras', 'extrafreeplay', 'extra_freeplay', 'extra-freeplay':
				return 'extraFreeplay';
		}
		return clean;
	}

	public static function weekMatchesSection(week:WeekData, targetSection:String):Bool
	{
		if(week == null)
			return false;
		if(targetSection == null)
			return true;

		if(targetSection == 'storyMode' && week.hideStoryMode)
			return false;

		if(targetSection == 'freeplay' && week.hideFreeplay)
			return false;

		var sections:Array<String> = getWeekSections(week);
		if(sections.length < 1)
			return targetSection != 'extraFreeplay';

		for(section in sections)
			if(normalizeMenuSection(section) == targetSection)
				return true;
		return false;
	}

	public static function getWeekSections(week:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		addWeekSections(output, week != null ? Reflect.field(week, 'section') : null);
		addWeekSections(output, week != null ? Reflect.field(week, 'sections') : null);
		return output;
	}

	static function addWeekSections(output:Array<String>, value:Dynamic):Void
	{
		if(value == null)
			return;
		if(Std.isOfType(value, Array))
		{
			for(item in (cast value:Array<Dynamic>))
				addWeekSections(output, item);
			return;
		}

		for(part in Std.string(value).split(','))
		{
			var normalized:String = normalizeMenuSection(part);
			if(normalized != null && normalized.length > 0 && !output.contains(normalized))
				output.push(normalized);
		}
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				if(weekMatchesSection(weekFile, reloadTargetSection))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingScreenState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Mods.currentModDirectory = data.folder;
		}
	}
}