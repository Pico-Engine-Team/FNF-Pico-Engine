package funkin.data.objects.gane.notes;

import funkin.data.objects.game.config.Note.HoldNoteCoverConfig;
import funkin.data.objects.game.config.Note.NoteSkinConfig;
import funkin.data.objects.game.config.Note.NoteSkinUiAsset;
using StringTools;

class NoteData {
	public static var noteStyle(default, null):NoteStyleData = new NoteStyleData();
	public static var notestyles(default, null):NoteStyleData = new NoteStyleData();
	public static var noteStyles(default, null):NoteStyleData = notestyles;
	public static function songStyle(?mustPress:Bool = true):String
	return notestyles.songStyle(mustPress);
}

class NoteStyleData
{
	public function new() {}

	public function songStyle(?mustPress:Bool = true):String
	{
		var skin:String = Note.songArrowSkinForMustPress(mustPress);
		if(skin == null || skin.length < 1)
			skin = Note.defaultSongNoteStyle();
		return skin;
	}

	public function config(?style:String):NoteSkinConfig
		return Note.getNoteSkinConfig(normalizeStyle(style));

	public function note(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'notePixel' : 'note');

	public function holdNote(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'holdNotePixel' : 'holdNote');

	public function noteStrumline(?style:String, ?pixel:Bool = false):String
		return asset(style, pixel ? 'noteStrumlinePixel' : 'noteStrumline');

	public function noteSplash(?style:String, ?mustPress:Bool = true):String
	{
		var skinConfig:NoteSkinConfig = config(style);
		if(skinConfig != null && skinConfig.noteSplashAssetPath != null && skinConfig.noteSplashAssetPath.length > 0)
			return skinConfig.noteSplashAssetPath;

		var songSplash:String = Note.songSplashSkinForMustPress(mustPress);
		if(songSplash != null && songSplash.length > 0)
			return songSplash;

		return NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
	}

	public function ui(assetName:String, fallback:String):String
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		if(asset != null)
		{
			var resolved:String = resolveUiAssetPath(asset.assetPath);
			if(resolved != null)
				return resolved;
		}
		return fallback;
	}

	public function uiSound(assetName:String, fallback:String):String
	{
		var asset:NoteSkinUiAsset = getUiAsset(assetName);
		if(asset != null && asset.audioPath != null && asset.audioPath.length > 0 && Paths.fileExists('sounds/${asset.audioPath}.${Paths.SOUND_EXT}', SOUND))
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

	public function holdNoteCover(?style:String, noteData:Int = 0):String
	{
		var skinConfig:NoteSkinConfig = config(style);
		return Note.resolveHoldNoteCoverAsset(skinConfig, noteData);
	}

	public function holdNoteCoverConfig(?style:String):HoldNoteCoverConfig
	{
		var skinConfig:NoteSkinConfig = config(style);
		return skinConfig != null ? skinConfig.holdNoteCover : null;
	}

	public function holdNoteCoverEnabled(?style:String):Bool
		return Note.holdNoteCoverEnabled(config(style));

	public function holdNoteCoverScale(?style:String):Float
		return Note.holdNoteCoverScale(config(style));

	public function holdNoteCoverIsPixel(?style:String):Bool
		return Note.holdNoteCoverIsPixel(config(style));

	public function holdNoteCoverColumns(?style:String):Int
		return Note.holdNoteCoverColumns(config(style));

	public function holdNoteCoverRows(?style:String):Int
		return Note.holdNoteCoverRows(config(style));

	public function holdNoteCoverOffset(?style:String):Array<Float>
		return Note.holdNoteCoverOffset(config(style));

	public function holdNoteCoverCenterOnStrum(?style:String):Bool
		return Note.holdNoteCoverCenterOnStrum(config(style));

	public function asset(?style:String, assetType:String):String
	{
		var resolvedStyle:String = normalizeStyle(style);
		return Note.resolveNoteSkinAsset(resolvedStyle, config(resolvedStyle), assetType);
	}

	public function hasImage(assetPath:String):Bool
		return Note.noteSkinImageExists(assetPath);

	public function hasAtlas(assetPath:String):Bool
		return Note.noteSkinAtlasExists(assetPath);

	function getUiAsset(assetName:String):NoteSkinUiAsset
	{
		if(assetName == null || assetName.length < 1)
			return null;

		var config:NoteSkinConfig = Note.getSongNoteSkinConfig();
		if(config == null || config.uiAssets == null)
			return null;
		return config.uiAssets.get(assetName);
	}

	function resolveUiAssetPath(assetPath:String):String
	{
		if(assetPath == null || assetPath.length < 1)
			return null;

		for(candidate in uiAssetCandidates(assetPath))
			if(Note.noteSkinImageExists(candidate))
				return candidate;
		return null;
	}

	function uiAssetCandidates(assetPath:String):Array<String>
	{
		var candidates:Array<String> = [];
		addUiAssetCandidate(candidates, assetPath);

		var parts:Array<String> = assetPath.split('/');
		if(parts.length >= 4 && parts[0] == 'ui')
		{
			// Supports both ui/funkin/countdown/ready and ui/countdown/funkin/ready.
			addUiAssetCandidate(candidates, 'ui/${parts[2]}/${parts[1]}/' + parts.slice(3).join('/'));
		}
		return candidates;
	}

	function addUiAssetCandidate(candidates:Array<String>, candidate:String):Void
	{
		if(candidate != null && candidate.length > 0 && !candidates.contains(candidate))
			candidates.push(candidate);
	}

	public function normalizeStyle(?style:String):String
	{
		if(style == null || style.trim().length < 1)
			return Note.defaultSongNoteStyle();
		return style;
	}
}
