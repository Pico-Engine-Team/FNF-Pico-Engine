package funkin.play;

import funkin.modding.Mods;
import funkin.stages.StageData;
import funkin.menus.MainMenuState;
import funkin.data.objects.game.notes.config.Note;

import haxe.Json;
import lime.utils.Assets;
using StringTools;

typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	@:optional var format:String;
	@:optional var formatChart:String;
	@:optional var generatedBy:String;

	@:optional var pauseSong:String;
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;
	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var variation:String;
	
	@:optional var artist:String;
	@:optional var charter:String;
	@:optional var album:String;
	@:optional var noteStyle:String;
	@:optional var previewStart:Float;
	@:optional var previewEnd:Float;
	@:optional var strumlines:Array<SwagStrumline>;
}

typedef SwagStrumline = {
	@:optional var characters:Array<String>;
	@:optional var type:String;
	@:optional var stagePosition:String;
	@:optional var visible:Bool;
}

typedef SwagSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var variation:String;
	public var artist:String;
	public var charter:String;
	public var pauseSong:String = 'breakfast';
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'bf-opponent';
	public var gfVersion:String = 'gf';
	public var noteStyle:String = 'funkin';
	public var format:String = 'Pico Engine Chart';
	public var formatChart:String = 'Pico Engine Chart';
	public var generatedBy:String = 'Pico Engine v${MainMenuState.PicoVersion}';

	public static inline var FORMAT_PICO_ENGINE:String = 'Pico Engine Chart';
	public static inline var FORMAT_PSYCH_V1:String = 'Psych Engine v1.0';
	public static inline var FORMAT_UNKNOWN:String = 'Unknown';

	public static function convert(songJson:Dynamic) // Convert old charts to Pico Engine v2.0 format
{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(note[3] != null && !Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static var notestyleListPath:String = 'data/notestyles-list.txt';
	public static var picoCustomNotesPath:String = 'game/custom-notes';

	public static function noteStyleList():Array<String>
	{
		var list:Array<String> = [];
		for (style in Mods.mergeAllTextsNamed(notestyleListPath))
			addNoteStyleToList(list, style);
		#if sys
		addPicoCustomNoteStylesToList(list);
		#end
		return list;
	}

	#if sys
	static function addPicoCustomNoteStylesToList(list:Array<String>)
	{
		var picoCustomNotes:String = Paths.getPicoFunkinFolder(picoCustomNotesPath);
		if(sys.FileSystem.exists(picoCustomNotes))
		{
			var listedStyles:Array<String> = [];
			var picoListPath:String = Paths.getPicoFunkinFolder('$picoCustomNotesPath/list.txt');
			if(sys.FileSystem.exists(picoListPath))
			{
				for (style in sys.io.File.getContent(picoListPath).split('\n'))
				{
					style = style.trim();
					if(style.length > 0 && sys.FileSystem.exists(Paths.getPicoFunkinFolder('$picoCustomNotesPath/$style.json')))
					{
						addNoteStyleToList(list, style);
						listedStyles.push(style);
					}
				}
			}

			for (file in sys.FileSystem.readDirectory(picoCustomNotes))
			{
				if(file.endsWith('.json'))
				{
					var style:String = file.substr(0, file.length - '.json'.length);
					if(!listedStyles.contains(style))
						addNoteStyleToList(list, style);
				}
			}
		}
	}
	#end

	static function addNoteStyleToList(list:Array<String>, value:String)
	{
		var style:String = cleanNoteStyleName(value);
		if(style.length > 0 && style != 'psych' && !list.contains(style))
			list.push(style);
	}

	public static function cleanNoteStyleName(value:String):String
	{
		if(value == null) return '';

		var skin:String = Note.normalizeNoteStyleName(value);
		var styleKey:String = Note.noteStyleKey(skin);
		return styleKey.length > 0 ? styleKey : '';
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.chartJson('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
			rawData = Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		normalizeChartInfo(songJson);
		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = chartFormatKey(songJson);

			switch(convertTo)
			{
				case 'psych_v1':
					if(!isPsychV1CompatibleFormat(fmt)) //Convert to Psych Engine v1.0 format
					{
						trace('converting chart $nameForError with format ${chartFormatDisplayName(fmt)} to ${FORMAT_PSYCH_V1} format...');
						songJson.format = 'pico_engine_chart';
						songJson.formatChart = FORMAT_PICO_ENGINE;
						songJson.generatedBy = defaultGeneratedBy();
						convert(songJson);
					}
			}
		}
		normalizeChartInfo(songJson);
		if(songJson.noteStyle == null && songJson.arrowSkin != null)
			songJson.noteStyle = songJson.arrowSkin;

		if(songJson.noteStyle != null)
			songJson.noteStyle = cleanNoteStyleName(songJson.noteStyle);
		return songJson;
	}

	static function normalizeChartInfo(songJson:SwagSong):Void
	{
		if(songJson == null) return;

		var formatKey:String = chartFormatKey(songJson);
		if(formatKey == 'unknown' || formatKey.length < 1)
			formatKey = 'psych_v1';

		if(songJson.formatChart == null || songJson.formatChart.trim().length < 1)
			songJson.formatChart = chartFormatDisplayName(formatKey);
		else
			songJson.formatChart = chartFormatDisplayName(songJson.formatChart);

		if(songJson.format == null || songJson.format.trim().length < 1)
			songJson.format = chartFormatLegacyKey(songJson.formatChart);

		if(songJson.generatedBy == null || songJson.generatedBy.trim().length < 1)
			songJson.generatedBy = defaultGeneratedBy();
	}

	static function chartFormatKey(songJson:SwagSong):String
	{
		var value:String = null;
		if(songJson != null)
		{
			if(songJson.formatChart != null && songJson.formatChart.trim().length > 0)
				value = songJson.formatChart;
			else value = songJson.format;
		}
		if(value == null) return 'unknown';
		return value.trim().toLowerCase().replace(' ', '_').replace('-', '_');
	}

	static function isPsychV1CompatibleFormat(formatKey:String):Bool
	{
		return formatKey.startsWith('psych_v1')
			|| formatKey == 'psych_engine_v1.0'
			|| formatKey == 'psych_engine_v1'
			|| formatKey == 'pico_engine_chart';
	}

	static function chartFormatDisplayName(formatValue:String):String
	{
		var key:String = formatValue == null ? 'unknown' : formatValue.trim().toLowerCase().replace(' ', '_').replace('-', '_');
		if(key.startsWith('psych_v1') || key == 'psych_engine_v1.0' || key == 'psych_engine_v1')
			return FORMAT_PSYCH_V1;
		if(key == 'pico_engine_chart' || key == 'pico_engine')
			return FORMAT_PICO_ENGINE;
		if(key == 'unknown' || key.length < 1)
			return FORMAT_UNKNOWN;
		return formatValue;
	}

	static function chartFormatLegacyKey(formatValue:String):String
	{
		var display:String = chartFormatDisplayName(formatValue);
		return switch(display)
		{
			case FORMAT_PICO_ENGINE: 'pico_engine_chart';
			case FORMAT_PSYCH_V1: 'psych_v1';
			default: 'unknown';
		}
	}

	public static function defaultGeneratedBy():String
		return 'Pico Engine v${MainMenuState.PicoVersion}';
}
