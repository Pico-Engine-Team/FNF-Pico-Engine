package funkin.data.objects.game.notes;

import funkin.data.notes.Note;
import funkin.data.notes.NoteSplash;
import funkin.data.notes.Note.HoldNoteCoverConfig;
import funkin.data.notes.Note.NoteSkinConfig;
using StringTools;

class NoteData
{
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
		var resolvedStyle:String = normalizeStyle(style);
		var skinConfig:NoteSkinConfig = config(resolvedStyle);

		if(skinConfig != null && skinConfig.noteSplashAssetPath != null && skinConfig.noteSplashAssetPath.length > 0)
			return skinConfig.noteSplashAssetPath;

		var songSplash:String = Note.songSplashSkinForMustPress(mustPress);
		if(songSplash != null && songSplash.length > 0)
			return songSplash;

		return NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
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

	public function normalizeStyle(?style:String):String
	{
		if(style == null || style.trim().length < 1)
			return Note.defaultSongNoteStyle();
		return style;
	}
}
