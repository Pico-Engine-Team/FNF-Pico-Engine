package funkin.data.objects.game.notes;

import haxe.Json;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.Note.NoteSkinConfig;
import funkin.data.objects.game.notes.data.Note.NoteSkinUiAsset;
import funkin.data.objects.game.notes.data.Note.HoldNoteCoverConfig;
import funkin.data.objects.game.notes.data.NoteSplash;
import funkin.data.objects.game.characters.Character;

using StringTools;

class NoteData
{
	public static var noteStyle(default, null):NoteStyleData = new NoteStyleData();
	public static var notestyles(default, null):NoteStyleData = noteStyle;
	public static var noteStyles(default, null):NoteStyleData = noteStyle;

	public static function songStyle(?mustPress:Bool = true):String
		return noteStyle.songStyle(mustPress);

	public static function clearCache():Void
		noteStyle.clearCache();
}

class NoteStyleData
{
	public var configs:Map<String, NoteSkinConfig> = new Map();

	public function new() {}

	public function clearCache():Void
		configs = new Map();

	public function songStyle(?mustPress:Bool = true):String
	{
		var charStyle:String = characterNoteStyleKey(mustPress);
		if(charStyle != null && charStyle.length > 0)
			return charStyle;

		var song:String = songNoteStyle();
		if(song != null && song.length > 0)
			return song;

		return defaultSongNoteStyle();
	}

	public function usesCharacterNoteStyle(mustPress:Bool):Bool
	{
		var key:String = characterNoteStyleKey(mustPress);
		return key != null && key.length > 0;
	}

	public function characterNoteStyleKey(mustPress:Bool):String
	{
		if(PlayState.instance == null) return null;

		var char:Character = mustPress ? PlayState.instance.boyfriend : PlayState.instance.dad;
		if(char == null) return null;

		var rawStyle:Dynamic = Reflect.field(char, 'noteStyle');
		if(rawStyle == null || Std.string(rawStyle).trim().length < 1)
			return null;

		try
		{
			if(Reflect.field(char, 'useNotestyle') == false)
				return null;
		}
		catch(e:Dynamic) {}

		var raw:String = Std.string(rawStyle).trim();
		var key:String = normalizeCharacterNoteStyleName(raw);
		return (key != null && key.length > 0) ? key : raw;
	}

	public function songNoteStyle():String
	{
		var skin:String = null;
		if(PlayState.SONG != null)
			skin = PlayState.SONG.noteStyle;
		var clean:String = normalizeSongNoteStyleName(skin);
		if(clean.length < 1 && PlayState.isPixelStage)
			clean = defaultSongNoteStyle();
		return clean;
	}

	public function defaultSongNoteStyle():String
	{
		if(PlayState.isPixelStage && textAssetExists('data/notestyles/pixel.json'))
			return 'pixel';
		if(textAssetExists('data/notestyles/funkin.json'))
			return 'funkin';
		return Note.defaultNoteSkin;
	}

	public function normalizeStyle(?style:String):String
	{
		if(style == null || style.trim().length < 1)
			return defaultSongNoteStyle();
		var song:String = normalizeSongNoteStyleName(style);
		if(song.length > 0 && textAssetExists('data/notestyles/' + song + '.json'))
			return song;
		var character:String = normalizeCharacterNoteStyleName(style);
		if(character.length > 0)
			return character;
		return song.length > 0 ? song : defaultSongNoteStyle();
	}

	public function normalizeSongNoteStyleName(skin:String):String
	{
		if(skin == null) return '';
		var clean:String = skin.trim().replace('\\', '/');
		if(clean.length < 1) return '';
		var lower:String = clean.toLowerCase();
		if(lower == 'default' || lower == 'normal') return '';

		if(clean.startsWith('images/')) clean = clean.substr(7);
		if(clean.startsWith('data/notestyles/')) clean = clean.substr(16);
		if(clean.startsWith('notestyles/')) clean = clean.substr(11);

		for (ext in ['.png', '.xml', '.json'])
			if(clean.endsWith(ext))
				clean = clean.substr(0, clean.length - ext.length);

		var styleKey:String = noteStyleKey(clean);
		if(styleKey.length > 0 && textAssetExists('data/notestyles/' + styleKey + '.json'))
			return styleKey;
		if(clean.indexOf('/') < 0 && imageAssetExists('noteSkins/' + clean))
			return 'noteSkins/' + clean;
		return styleKey.length > 0 ? styleKey : clean;
	}

	public function normalizeCharacterNoteStyleName(skin:String):String
	{
		if(skin == null) return '';
		var clean:String = skin.trim().replace('\\', '/');
		if(clean.length < 1) return '';
		var lower:String = clean.toLowerCase();
		if(lower == 'default' || lower == 'normal') return '';

		if(clean.startsWith('game/custom-notes/data/')) clean = clean.substr(23);
		if(clean.startsWith('custom-notes/data/')) clean = clean.substr(18);
		if(clean.startsWith('data/')) clean = clean.substr(5);

		for (ext in ['.png', '.xml', '.json'])
			if(clean.endsWith(ext))
				clean = clean.substr(0, clean.length - ext.length);

		var styleKey:String = noteStyleKey(clean);
		return styleKey.length > 0 ? styleKey : clean;
	}

	public function noteStyleKey(value:String):String
	{
		if(value == null) return '';
		var clean:String = value.trim().replace('\\', '/');
		if(clean.indexOf('/') >= 0)
			clean = clean.substring(clean.lastIndexOf('/') + 1);
		return clean;
	}

	public function config(?style:String, ?fromCharacter:Null<Bool> = null):NoteSkinConfig
		return getNoteSkinConfig(style, fromCharacter == true);

	/** Prefer Note's loader so JSON parsing stays in one place during transition */
	public function getNoteSkinConfig(style:String, fromCharacter:Bool = false):NoteSkinConfig
	{
		var key:String = normalizeStyle(style);
		var cacheKey:String = key + (fromCharacter ? '#char' : '#song');
		if(configs.exists(cacheKey))
			return configs.get(cacheKey);

		var cfg:NoteSkinConfig = null;
		try
			cfg = Note.getNoteSkinConfig(key, fromCharacter);
		catch(e:Dynamic)
		{
			try cfg = Note.getNoteSkinConfig(key) catch(e2:Dynamic) cfg = null;
		}
		if(cfg != null)
			configs.set(cacheKey, cfg);
		return cfg;
	}

	public function getSongNoteSkinConfig():NoteSkinConfig
	{
		var name:String = songNoteStyle();
		if(name == null || name.length < 1)
			name = defaultSongNoteStyle();
		return getNoteSkinConfig(name, false);
	}

	/** Psych: empty texture → resolve via noteStyle */
	public function psychTexture(?texture:String, ?mustPress:Bool = true):String
	{
		if(texture != null && texture.trim().length > 0)
			return texture.trim();

		var style:String = songStyle(mustPress);
		var pixel:Bool = noteStyleUsesPixel(getNoteSkinConfig(style, usesCharacterNoteStyle(mustPress)));
		try if(!pixel && PlayState.isPixelStage) pixel = true; catch(e:Dynamic) {}

		var path:String = note(style, pixel);
		return (path != null && path.length > 0) ? path : Note.defaultNoteSkin;
	}

	public function note(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'notePixel' : 'note');

	public function holdNote(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'holdNotePixel' : 'holdNote');

	public function noteStrumline(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'noteStrumlinePixel' : 'noteStrumline');

	public function noteSplash(?style:String, ?mustPress:Bool = true):String
	{
		var resolved:String = style != null ? normalizeStyle(style) : songStyle(mustPress);
		var skinConfig:NoteSkinConfig = getNoteSkinConfig(resolved, usesCharacterNoteStyle(mustPress));
		if(skinConfig != null && skinConfig.noteSplashAssetPath != null && skinConfig.noteSplashAssetPath.length > 0)
			return skinConfig.noteSplashAssetPath;
		try
			return NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		catch(e:Dynamic)
			return 'noteSplashes';
	}

	public function songSplashSkinForMustPress(mustPress:Bool):Null<String>
	{
		var style:String = songStyle(mustPress);
		if(style == null || style.length < 1) return null;
		var cfg:NoteSkinConfig = getNoteSkinConfig(style, usesCharacterNoteStyle(mustPress));
		if(cfg != null && cfg.noteSplashAssetPath != null && cfg.noteSplashAssetPath.length > 0)
			return cfg.noteSplashAssetPath;
		return null;
	}

	public function asset(?style:String, assetType:String):String
	{
		var resolvedStyle:String = normalizeStyle(style);
		var cfg:NoteSkinConfig = getNoteSkinConfig(resolvedStyle);
		try
		{
			var r:String = Note.resolveNoteSkinAsset(resolvedStyle, cfg, assetType);
			if(r != null && r.length > 0) return r;
		}
		catch(e:Dynamic) {}
		if(assetType.indexOf('Pixel') >= 0) return 'pixelUI/NOTE_assets';
		if(resolvedStyle == 'funkin') return Note.defaultNoteSkin;
		return resolvedStyle;
	}

	public function allowRGB(?style:String):Bool
	{
		var cfg:NoteSkinConfig = getNoteSkinConfig(style != null ? style : songStyle(true));
		return cfg == null || cfg.allowRGB != false;
	}

	public function allowPixel(?style:String):Bool
	{
		var cfg:NoteSkinConfig = getNoteSkinConfig(style != null ? style : songStyle(true));
		return cfg != null && cfg.allowPixel == true;
	}

	public function noteStyleUsesPixel(?cfg:NoteSkinConfig = null, ?mustPress:Null<Bool> = null):Bool
	{
		if(cfg == null)
		{
			if(mustPress != null)
				cfg = getNoteSkinConfig(songStyle(mustPress), usesCharacterNoteStyle(mustPress));
			else
				cfg = getSongNoteSkinConfig();
		}
		return cfg != null && cfg.allowPixel == true;
	}

	public function ui(assetName:String, fallback:String):String
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		if(asset != null && asset.assetPath != null && asset.assetPath.length > 0)
			return asset.assetPath;
		return fallback;
	}

	public function uiSound(assetName:String, fallback:String):String
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		if(asset != null && asset.audioPath != null && asset.audioPath.length > 0)
			return asset.audioPath;
		return fallback;
	}

	public function uiScale(assetName:String, fallback:Float):Float
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		return (asset != null && asset.scale != null) ? asset.scale : fallback;
	}

	public function uiIsPixel(assetName:String, fallback:Bool):Bool
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		return (asset != null && asset.isPixel != null) ? asset.isPixel : fallback;
	}

	public function uiHidden(assetName:String):Bool
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		return asset != null && asset.hidden == true;
	}

	function getUiAsset(assetName:String):NoteSkinUiAsset
	{
		if(assetName == null || assetName.length < 1) return null;
		var cfg:NoteSkinConfig = getSongNoteSkinConfig();
		if(cfg == null || cfg.uiAssets == null) return null;
		return cfg.uiAssets.get(assetName);
	}

	public function holdNoteCover(?style:String, noteData:Int = 0):String
	{
		try return Note.resolveHoldNoteCoverAsset(config(style), noteData);
		catch(e:Dynamic) return null;
	}

	public function holdNoteCoverConfig(?style:String):HoldNoteCoverConfig
	{
		var c:NoteSkinConfig = config(style);
		return c != null ? c.holdNoteCover : null;
	}

	public function holdNoteCoverEnabled(?style:String):Bool
	{
		try return Note.holdNoteCoverEnabled(config(style));
		catch(e:Dynamic) return false;
	}

	public function holdNoteCoverScale(?style:String):Float
	{
		try return Note.holdNoteCoverScale(config(style));
		catch(e:Dynamic) return 1;
	}

	public function holdNoteCoverIsPixel(?style:String):Bool
	{
		try return Note.holdNoteCoverIsPixel(config(style));
		catch(e:Dynamic) return false;
	}

	public function holdNoteCoverColumns(?style:String):Int
	{
		try return Note.holdNoteCoverColumns(config(style));
		catch(e:Dynamic) return 4;
	}

	public function holdNoteCoverRows(?style:String):Int
	{
		try return Note.holdNoteCoverRows(config(style));
		catch(e:Dynamic) return 2;
	}

	public function holdNoteCoverOffset(?style:String):Array<Float>
	{
		try return Note.holdNoteCoverOffset(config(style));
		catch(e:Dynamic) return [0, 0];
	}

	public function holdNoteCoverCenterOnStrum(?style:String):Bool
	{
		try return Note.holdNoteCoverCenterOnStrum(config(style));
		catch(e:Dynamic) return true;
	}

	public function hasImage(assetPath:String):Bool
		return imageAssetExists(assetPath);

	public function hasAtlas(assetPath:String):Bool
		return imageAssetExists(assetPath) && textAssetExists('images/' + assetPath + '.xml');

	public function imageAssetExists(assetPath:String):Bool
	{
		if(assetPath == null || assetPath.length < 1) return false;
		return Paths.fileExists('images/' + assetPath + '.png', IMAGE);
	}

	public function textAssetExists(key:String):Bool
	{
		if(key == null || key.length < 1) return false;
		return Paths.fileExists(key, TEXT);
	}
}