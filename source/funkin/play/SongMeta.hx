package funkin.play;

import haxe.Json;

/**
 * Song metadata (meta.json / meta.txt).
 * Describes the song for Freeplay / Pause / chart fill-in.
 * Highscores stay Psych Engine (Highscore) — meta never saves scores.
 *
 * Preferred format: ClientPrefs.data.songMetaFormat = "auto" | "json" | "txt"
 */
class SongMeta
{
	public static inline var FORMAT_AUTO:String = 'auto';
	public static inline var FORMAT_JSON:String = 'json';
	public static inline var FORMAT_TXT:String = 'txt';

	public var songName:String = null;
	public var displayName:String = null;
	public var artist:String = null;
	public var charter:String = null;
	public var album:String = null;
	public var stage:String = null;
	public var noteStyle:String = null;
	public var player:String = null;
	public var opponent:String = null;
	public var girlfriend:String = null;
	public var difficulties:Array<String> = null;
	public var variations:Array<String> = null;
	public var bpm:Null<Float> = null;
	public var pauseSong:String = null;
	public var enableSongScripts:Null<Bool> = null;
	public var useModcharts:Null<Bool> = null;

	public var loadedFormat:String = null;
	public var loadedPath:String = null;

	public function new() {}

	public static function getPreferredFormat():String
	{
		try
		{
			var value:Dynamic = Reflect.field(ClientPrefs.data, 'songMetaFormat');
			if(value == null && ClientPrefs.data.gameplaySettings != null)
				value = ClientPrefs.data.gameplaySettings.get('songMetaFormat');
			if(value != null)
			{
				var s:String = Std.string(value).trim().toLowerCase();
				if(s == FORMAT_JSON || s == FORMAT_TXT || s == FORMAT_AUTO)
					return s;
			}
		}
		catch(e:Dynamic) {}
		return FORMAT_AUTO;
	}

	/** Load meta for song folder id (e.g. "bopeebo"). */
	public static function load(songFolder:String, ?formatOverride:String = null):SongMeta
	{
		if(songFolder == null || songFolder.trim().length < 1)
			return null;

		var folder:String = Paths.formatToSongPath(songFolder);
		var preferred:String = formatOverride != null ? formatOverride.trim().toLowerCase() : getPreferredFormat();
		if(preferred != FORMAT_JSON && preferred != FORMAT_TXT)
			preferred = FORMAT_AUTO;

		var order:Array<String> = (preferred == FORMAT_TXT)
			? [FORMAT_TXT, FORMAT_JSON]
			: [FORMAT_JSON, FORMAT_TXT];

		for (fmt in order)
		{
			var meta:SongMeta = (fmt == FORMAT_JSON) ? loadJson(folder) : loadTxt(folder);
			if(meta != null)
				return meta;
		}
		return null;
	}

	static function loadJson(folder:String):SongMeta
	{
		for (path in jsonPaths(folder))
		{
			var raw:String = readText(path);
			if(raw == null || raw.trim().length < 1) continue;
			try
			{
				var meta:SongMeta = fromDynamic(Json.parse(raw));
				if(meta != null)
				{
					meta.loadedFormat = FORMAT_JSON;
					meta.loadedPath = path;
					return meta;
				}
			}
			catch(e:Dynamic)
			{
				trace('[SongMeta] Failed to parse $path: $e');
			}
		}
		return null;
	}

	static function loadTxt(folder:String):SongMeta
	{
		for (path in txtPaths(folder))
		{
			var raw:String = readText(path);
			if(raw == null || raw.trim().length < 1) continue;
			try
			{
				var meta:SongMeta = fromTxt(raw);
				if(meta != null)
				{
					meta.loadedFormat = FORMAT_TXT;
					meta.loadedPath = path;
					return meta;
				}
			}
			catch(e:Dynamic)
			{
				trace('[SongMeta] Failed to parse $path: $e');
			}
		}
		return null;
	}

	static function jsonPaths(folder:String):Array<String>
	{
		return [
			'data/songs/$folder/meta.json',
			'data/$folder/meta.json',
			'data/songs/$folder/$folder-metadata.json',
			'data/$folder/$folder-metadata.json'
		];
	}

	static function txtPaths(folder:String):Array<String>
	{
		return [
			'data/songs/$folder/meta.txt',
			'data/$folder/meta.txt'
		];
	}

	static function readText(path:String):String
	{
		if(path == null) return null;
		#if MODS_ALLOWED
		try
		{
			var full:String = Paths.modFolders(path);
			if(full != null && sys.FileSystem.exists(full))
				return sys.io.File.getContent(full);
		}
		catch(e:Dynamic) {}
		try
		{
			if(sys.FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch(e:Dynamic) {}
		#end
		try
		{
			if(openfl.utils.Assets.exists(path))
				return openfl.utils.Assets.getText(path);
		}
		catch(e:Dynamic) {}
		try
		{
			return Paths.getTextFromFile(path);
		}
		catch(e:Dynamic) {}
		return null;
	}

	/** Parse V-Slice-like or flat JSON. */
	public static function fromDynamic(data:Dynamic):SongMeta
	{
		if(data == null) return null;
		var meta:SongMeta = new SongMeta();

		meta.songName = strField(data, ['songName', 'song', 'name']);
		meta.displayName = strField(data, ['displayName', 'display', 'title']);
		meta.artist = strField(data, ['artist', 'composer']);
		meta.charter = strField(data, ['charter', 'chartAuthor', 'author']);
		meta.album = strField(data, ['album']);
		meta.bpm = floatField(data, ['bpm']);
		meta.pauseSong = strField(data, ['pauseSong', 'pauseMusic']);
		meta.enableSongScripts = boolField(data, ['enableSongScripts']);
		meta.useModcharts = boolField(data, ['useModcharts']);

		var playData:Dynamic = Reflect.field(data, 'playData');
		if(playData != null)
		{
			meta.stage = strField(playData, ['stage']);
			meta.noteStyle = strField(playData, ['noteStyle', 'noteSkin']);
			meta.difficulties = stringArrayField(playData, ['difficulties']);
			meta.variations = stringArrayField(playData, ['songVariations', 'variations']);
			if(meta.album == null) meta.album = strField(playData, ['album']);

			var chars:Dynamic = Reflect.field(playData, 'characters');
			if(chars != null)
			{
				meta.player = strField(chars, ['player', 'bf', 'player1']);
				meta.opponent = strField(chars, ['opponent', 'dad', 'player2']);
				meta.girlfriend = strField(chars, ['girlfriend', 'gf', 'gfVersion']);
			}
		}

		if(meta.stage == null) meta.stage = strField(data, ['stage']);
		if(meta.noteStyle == null) meta.noteStyle = strField(data, ['noteStyle', 'noteSkin']);
		if(meta.player == null) meta.player = strField(data, ['player1', 'player', 'bf']);
		if(meta.opponent == null) meta.opponent = strField(data, ['player2', 'opponent', 'dad']);
		if(meta.girlfriend == null) meta.girlfriend = strField(data, ['gfVersion', 'girlfriend', 'gf']);
		if(meta.difficulties == null) meta.difficulties = stringArrayField(data, ['difficulties']);
		if(meta.variations == null) meta.variations = stringArrayField(data, ['variations', 'songVariations']);

		if(meta.bpm == null)
		{
			var timeChanges:Dynamic = Reflect.field(data, 'timeChanges');
			if(Std.isOfType(timeChanges, Array))
			{
				var arr:Array<Dynamic> = cast timeChanges;
				if(arr.length > 0)
					meta.bpm = floatField(arr[0], ['bpm', 'b']);
			}
		}

		return meta;
	}

	/**
	 * meta.txt: key=value per line (# comments)
	 * displayName=My Song
	 * difficulties=easy,normal,hard
	 * variations=erect,pico
	 */
	public static function fromTxt(raw:String):SongMeta
	{
		if(raw == null) return null;
		var map:Map<String, String> = new Map();
		for (line in raw.split('\n'))
		{
			var text:String = StringTools.trim(line);
			if(text.length < 1 || text.startsWith('#') || text.startsWith('//'))
				continue;
			var eq:Int = text.indexOf('=');
			if(eq < 1) continue;
			var key:String = StringTools.trim(text.substr(0, eq)).toLowerCase();
			var value:String = StringTools.trim(text.substr(eq + 1));
			if(key.length > 0)
				map.set(key, value);
		}
		if(!map.keys().hasNext())
			return null;

		var meta:SongMeta = new SongMeta();
		meta.songName = mapGet(map, ['songname', 'song', 'name']);
		meta.displayName = mapGet(map, ['displayname', 'display', 'title']);
		meta.artist = mapGet(map, ['artist', 'composer']);
		meta.charter = mapGet(map, ['charter', 'chartauthor', 'author']);
		meta.album = mapGet(map, ['album']);
		meta.stage = mapGet(map, ['stage']);
		meta.noteStyle = mapGet(map, ['notestyle', 'noteskin']);
		meta.player = mapGet(map, ['player1', 'player', 'bf']);
		meta.opponent = mapGet(map, ['player2', 'opponent', 'dad']);
		meta.girlfriend = mapGet(map, ['gfversion', 'girlfriend', 'gf']);
		meta.pauseSong = mapGet(map, ['pausesong', 'pausemusic']);

		var bpmStr:String = mapGet(map, ['bpm']);
		if(bpmStr != null)
		{
			var bpm:Float = Std.parseFloat(bpmStr);
			if(!Math.isNaN(bpm)) meta.bpm = bpm;
		}

		var diffStr:String = mapGet(map, ['difficulties', 'difficulty']);
		if(diffStr != null) meta.difficulties = splitList(diffStr);
		var varStr:String = mapGet(map, ['variations', 'songvariations']);
		if(varStr != null) meta.variations = splitList(varStr);

		var scripts:String = mapGet(map, ['enablesongscripts']);
		if(scripts != null) meta.enableSongScripts = (scripts.toLowerCase() == 'true' || scripts == '1');
		var mods:String = mapGet(map, ['usemodcharts']);
		if(mods != null) meta.useModcharts = (mods.toLowerCase() == 'true' || mods == '1');

		return meta;
	}

	/** Build meta snapshot from a loaded chart. */
	public static function fromSong(song:Dynamic):SongMeta
	{
		if(song == null) return new SongMeta();
		var meta:SongMeta = new SongMeta();
		meta.songName = strVal(Reflect.field(song, 'song'));
		meta.displayName = strVal(Reflect.field(song, 'displayName'));
		meta.artist = strVal(Reflect.field(song, 'artist'));
		meta.charter = strVal(Reflect.field(song, 'charter'));
		meta.stage = strVal(Reflect.field(song, 'stage'));
		meta.noteStyle = strVal(Reflect.field(song, 'noteStyle'));
		meta.player = strVal(Reflect.field(song, 'player1'));
		meta.opponent = strVal(Reflect.field(song, 'player2'));
		meta.girlfriend = strVal(Reflect.field(song, 'gfVersion'));
		meta.pauseSong = strVal(Reflect.field(song, 'pauseSong'));
		meta.bpm = floatField(song, ['bpm']);
		meta.enableSongScripts = boolField(song, ['enableSongScripts']);
		meta.useModcharts = boolField(song, ['useModcharts']);
		meta.difficulties = stringArrayField(song, ['freeplayDifficulties', 'difficulties']);
		meta.variations = stringArrayField(song, ['songVariations', 'variations']);
		return meta;
	}

	/**
	 * Apply meta onto Psych chart fields.
	 * overwriteExisting = false keeps values already set on the chart.
	 */
	public static function applyToSong(song:Dynamic, meta:SongMeta, overwriteExisting:Bool = false):Void
	{
		if(song == null || meta == null) return;

		setIf(song, 'displayName', meta.displayName, overwriteExisting);
		// Do NOT overwrite chart song id with display name
		setIf(song, 'artist', meta.artist, overwriteExisting);
		setIf(song, 'charter', meta.charter, overwriteExisting);
		setIf(song, 'stage', meta.stage, overwriteExisting);
		if(meta.noteStyle != null && meta.noteStyle.length > 0)
		{
			if(overwriteExisting || emptyField(Reflect.field(song, 'noteStyle')))
				Reflect.setField(song, 'noteStyle', Song.cleanNoteStyleName(meta.noteStyle));
		}
		setIf(song, 'player1', meta.player, overwriteExisting);
		setIf(song, 'player2', meta.opponent, overwriteExisting);
		setIf(song, 'gfVersion', meta.girlfriend, overwriteExisting);
		setIf(song, 'pauseSong', meta.pauseSong, overwriteExisting);

		if(meta.bpm != null && !Math.isNaN(meta.bpm) && meta.bpm > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'bpm') == null)
				Reflect.setField(song, 'bpm', meta.bpm);
		}
		if(meta.enableSongScripts != null)
		{
			if(overwriteExisting || Reflect.field(song, 'enableSongScripts') == null)
				Reflect.setField(song, 'enableSongScripts', meta.enableSongScripts);
		}
		if(meta.useModcharts != null)
		{
			if(overwriteExisting || Reflect.field(song, 'useModcharts') == null)
				Reflect.setField(song, 'useModcharts', meta.useModcharts);
		}
		if(meta.difficulties != null && meta.difficulties.length > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'freeplayDifficulties') == null)
				Reflect.setField(song, 'freeplayDifficulties', meta.difficulties.copy());
		}
		if(meta.variations != null && meta.variations.length > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'songVariations') == null)
				Reflect.setField(song, 'songVariations', meta.variations.copy());
		}
	}

	public function getDisplayName(?fallback:String = null):String
	{
		if(displayName != null && displayName.trim().length > 0)
			return displayName.trim();
		if(songName != null && songName.trim().length > 0)
			return songName.trim();
		if(fallback != null) return fallback;
		return '';
	}

	public function getDifficulties(?fallback:Array<String> = null):Array<String>
	{
		if(difficulties != null && difficulties.length > 0)
			return difficulties.copy();
		return fallback != null ? fallback.copy() : [];
	}

	public function getVariations():Array<String>
	{
		if(variations != null && variations.length > 0)
			return variations.copy();
		return [];
	}

	public function toJsonString():String
	{
		var playData:Dynamic = {};
		if(stage != null) Reflect.setField(playData, 'stage', stage);
		if(noteStyle != null) Reflect.setField(playData, 'noteStyle', noteStyle);
		if(difficulties != null) Reflect.setField(playData, 'difficulties', difficulties);
		if(variations != null) Reflect.setField(playData, 'songVariations', variations);
		if(album != null) Reflect.setField(playData, 'album', album);

		var chars:Dynamic = {};
		if(player != null) Reflect.setField(chars, 'player', player);
		if(opponent != null) Reflect.setField(chars, 'opponent', opponent);
		if(girlfriend != null) Reflect.setField(chars, 'girlfriend', girlfriend);
		if(Reflect.fields(chars).length > 0)
			Reflect.setField(playData, 'characters', chars);

		var root:Dynamic = { version: '1.0.0' };
		if(songName != null) Reflect.setField(root, 'songName', songName);
		if(displayName != null) Reflect.setField(root, 'displayName', displayName);
		if(artist != null) Reflect.setField(root, 'artist', artist);
		if(charter != null) Reflect.setField(root, 'charter', charter);
		if(bpm != null) Reflect.setField(root, 'bpm', bpm);
		if(pauseSong != null) Reflect.setField(root, 'pauseSong', pauseSong);
		if(enableSongScripts != null) Reflect.setField(root, 'enableSongScripts', enableSongScripts);
		if(useModcharts != null) Reflect.setField(root, 'useModcharts', useModcharts);
		Reflect.setField(root, 'playData', playData);
		return Json.stringify(root, null, '\t');
	}

	public function toTxtString():String
	{
		var lines:Array<String> = ['# Song meta (txt)'];
		function add(key:String, value:String)
		{
			if(value != null && value.trim().length > 0)
				lines.push(key + '=' + value.trim());
		}
		add('songName', songName);
		add('displayName', displayName);
		add('artist', artist);
		add('charter', charter);
		add('album', album);
		add('stage', stage);
		add('noteStyle', noteStyle);
		add('player1', player);
		add('player2', opponent);
		add('gfVersion', girlfriend);
		if(difficulties != null) add('difficulties', difficulties.join(','));
		if(variations != null) add('variations', variations.join(','));
		if(bpm != null) add('bpm', Std.string(bpm));
		add('pauseSong', pauseSong);
		if(enableSongScripts != null) add('enableSongScripts', enableSongScripts ? 'true' : 'false');
		if(useModcharts != null) add('useModcharts', useModcharts ? 'true' : 'false');
		return lines.join('\n') + '\n';
	}

	// ---- helpers ----

	static function setIf(song:Dynamic, field:String, value:String, overwrite:Bool):Void
	{
		if(value == null || value.length < 1) return;
		if(overwrite || emptyField(Reflect.field(song, field)))
			Reflect.setField(song, field, value);
	}

	static function emptyField(current:Dynamic):Bool
	{
		if(current == null) return true;
		return Std.string(current).trim().length < 1;
	}

	static function strVal(v:Dynamic):String
	{
		if(v == null) return null;
		var s:String = Std.string(v).trim();
		return (s.length > 0 && s.toLowerCase() != 'null') ? s : null;
	}

	static function strField(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			var s:String = strVal(v);
			if(s != null) return s;
		}
		return null;
	}

	static function floatField(obj:Dynamic, names:Array<String>):Null<Float>
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			var f:Float = Std.parseFloat(Std.string(v));
			if(!Math.isNaN(f)) return f;
		}
		return null;
	}

	static function boolField(obj:Dynamic, names:Array<String>):Null<Bool>
	{
		if(obj == null) return null;
		for (name in names)
		{
			if(!Reflect.hasField(obj, name)) continue;
			var v:Dynamic = Reflect.field(obj, name);
			if(v == true || v == false) return v;
			if(v != null)
			{
				var s:String = Std.string(v).toLowerCase();
				if(s == 'true' || s == '1') return true;
				if(s == 'false' || s == '0') return false;
			}
		}
		return null;
	}

	static function stringArrayField(obj:Dynamic, names:Array<String>):Array<String>
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			if(Std.isOfType(v, Array))
			{
				var out:Array<String> = [];
				for (item in (cast v:Array<Dynamic>))
				{
					var s:String = strVal(item);
					if(s != null) out.push(s);
				}
				return out.length > 0 ? out : null;
			}
			var asStr:String = strVal(v);
			if(asStr != null) return splitList(asStr);
		}
		return null;
	}

	static function mapGet(map:Map<String, String>, keys:Array<String>):String
	{
		for (k in keys)
		{
			if(map.exists(k))
			{
				var v:String = map.get(k);
				if(v != null && v.trim().length > 0)
					return v.trim();
			}
		}
		return null;
	}

	static function splitList(value:String):Array<String>
	{
		var out:Array<String> = [];
		for (part in value.split(','))
		{
			var s:String = StringTools.trim(part);
			if(s.length > 0) out.push(s);
		}
		return out.length > 0 ? out : null;
	}
}
