package funkin.data.objects.game.notes;

import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.Note.NoteSkinConfig;
import funkin.data.objects.game.notes.data.Note.NoteSkinUiAsset;
import funkin.data.objects.game.notes.data.Note.HoldNoteCoverConfig;
import funkin.data.objects.game.notes.data.NoteSplash;
import funkin.data.objects.game.characters.Character;
using StringTools;

/**
 * noteStyle controller (Pico Engine).
 *
 * Song / chart styles  → data/notestyles/<name>.json
 * Character styles     → pico_assets custom-notes
 *
 * Note.hx keeps Psych-style reloadNote (texture / NOTE_assets / frames)
 * and calls into NoteData for style name + flags.
 */

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
	public function new() {}

	public function clearCache():Void
	{
		try { Note.noteSkinConfigs.clear(); } catch(e:Dynamic) {}
	}

	// ---------- Style resolution ----------

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
		if(PlayState.instance == null)
			return null;

		var char:Character = mustPress ? PlayState.instance.boyfriend : PlayState.instance.dad;
		if(char == null)
			return null;

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
		if(PlayState.isPixelStage && textExists('data/notestyles/pixel.json'))
			return 'pixel';
		if(textExists('data/notestyles/funkin.json'))
			return 'funkin';
		return Note.defaultNoteSkin;
	}

	/** Chart / SONG.noteStyle → data/notestyles only */
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
		if(clean.startsWith('assets/shared/data/notestyles/')) clean = clean.substr(30);

		for (ext in ['.png', '.xml', '.json'])
			if(clean.endsWith(ext))
				clean = clean.substr(0, clean.length - ext.length);

		var styleKey:String = noteStyleKey(clean);
		if(styleKey.length > 0 && textExists('data/notestyles/' + styleKey + '.json'))
			return styleKey;
		if(clean.indexOf('/') < 0 && imageExists('noteSkins/' + clean))
			return 'noteSkins/' + clean;
		return styleKey.length > 0 ? styleKey : clean;
	}

	/** Character noteStyle → pico custom-notes */
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

	public function normalizeStyle(?style:String):String
	{
		if(style == null || style.trim().length < 1)
			return defaultSongNoteStyle();
		var song:String = normalizeSongNoteStyleName(style);
		if(song.length > 0 && textExists('data/notestyles/' + song + '.json'))
			return song;
		var character:String = normalizeCharacterNoteStyleName(style);
		if(character.length > 0)
			return character;
		return song.length > 0 ? song : defaultSongNoteStyle();
	}

	// ---------- Config (delegates parse/cache to Note) ----------

	public function config(?style:String, ?fromCharacter:Null<Bool> = null):NoteSkinConfig
		return getNoteSkinConfig(style, fromCharacter == true);

	public function getNoteSkinConfig(style:String, fromCharacter:Bool = false):NoteSkinConfig
	{
		var key:String = normalizeStyle(style);
		try { return Note.getNoteSkinConfig(key, fromCharacter); } catch(e:Dynamic)
		{
			try { return Note.getNoteSkinConfig(key); } catch(e2:Dynamic) { return null; }
		}
	}

	public function getSongNoteSkinConfig():NoteSkinConfig
	{
		var name:String = songNoteStyle();
		if(name == null || name.length < 1)
			name = defaultSongNoteStyle();
		return getNoteSkinConfig(name, false);
	}

	/**
	 * Psych reloadNote: empty texture → resolve via noteStyle.
	 * Usage: texture = NoteData.noteStyle.psychTexture(texture, mustPress);
	 */
	public function psychTexture(?texture:String, ?mustPress:Bool = true):String
	{
		if(texture != null && texture.trim().length > 0)
			return texture.trim();
		return songStyle(mustPress);
	}

	// ---------- Assets / flags ----------

	public function note(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'notePixel' : 'note');

	public function holdNote(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'holdNotePixel' : 'holdNote');

	public function noteStrumline(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'noteStrumlinePixel' : 'noteStrumline');

	public function asset(?style:String, assetType:String):String
	{
		var resolvedStyle:String = normalizeStyle(style);
		var cfg:NoteSkinConfig = getNoteSkinConfig(resolvedStyle, false);
		try
		{
			var r:String = Note.resolveNoteSkinAsset(resolvedStyle, cfg, assetType);
			if(r != null && r.length > 0) return r;
		}
		catch(e:Dynamic) {}
		if(assetType.indexOf('Pixel') >= 0)
			return 'noteSkins/pixel/NOTE_assets';
		return Note.defaultNoteSkin;
	}

	public function noteSplash(?style:String, ?mustPress:Bool = true):String
	{
		var resolved:String = style != null ? normalizeStyle(style) : songStyle(mustPress);
		var cfg:NoteSkinConfig = getNoteSkinConfig(resolved, usesCharacterNoteStyle(mustPress));
		if(cfg != null && cfg.noteSplashAssetPath != null && cfg.noteSplashAssetPath.length > 0)
			return cfg.noteSplashAssetPath;
		try { return NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix(); } catch(e:Dynamic) { return 'noteSplashes'; }
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

	// ---------- UI ----------

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

	// ---------- Hold cover (delegate Note) ----------

	public function holdNoteCover(?style:String, noteData:Int = 0):String
	{
		try { return Note.resolveHoldNoteCoverAsset(config(style), noteData); } catch(e:Dynamic) { return null; }
	}

	public function holdNoteCoverEnabled(?style:String):Bool
	{
		try { return Note.holdNoteCoverEnabled(config(style)); } catch(e:Dynamic) { return false; }
	}

	public function holdNoteCoverScale(?style:String):Float
	{
		try { return Note.holdNoteCoverScale(config(style)); } catch(e:Dynamic) { return 1; }
	}

	public function holdNoteCoverIsPixel(?style:String):Bool
	{
		try { return Note.holdNoteCoverIsPixel(config(style)); } catch(e:Dynamic) { return false; }
	}

	public function holdNoteCoverColumns(?style:String):Int
	{
		try { return Note.holdNoteCoverColumns(config(style)); } catch(e:Dynamic) { return 4; }
	}

	public function holdNoteCoverRows(?style:String):Int
	{
		try { return Note.holdNoteCoverRows(config(style)); } catch(e:Dynamic) { return 2; }
	}

	public function holdNoteCoverOffset(?style:String):Array<Float>
	{
		try { return Note.holdNoteCoverOffset(config(style)); } catch(e:Dynamic) { return [0, 0]; }
	}

	public function holdNoteCoverCenterOnStrum(?style:String):Bool
	{
		try { return Note.holdNoteCoverCenterOnStrum(config(style)); } catch(e:Dynamic) { return true; }
	}

	public function holdNoteCoverConfig(?style:String):HoldNoteCoverConfig
	{
		var c:NoteSkinConfig = config(style);
		return c != null ? c.holdNoteCover : null;
	}

	function textExists(key:String):Bool
	{
		try { return Paths.fileExists(key, TEXT); } catch(e:Dynamic) { return false; }
	}

	function imageExists(key:String):Bool
	{
		try { return Paths.fileExists('images/' + key + '.png', IMAGE); } catch(e:Dynamic) { return false; }
	}
}
