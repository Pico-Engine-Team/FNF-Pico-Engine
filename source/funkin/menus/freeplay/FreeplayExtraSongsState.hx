#if PICO_ALLOWED
package funkin.menus.freeplay;

import funkin.Paths;
import funkin.play.Song;
import funkin.play.Highscore;

import funkin.play.Difficulty;
import funkin.data.WeekData;
import funkin.data.editors.ChartingState;

import funkin.data.objects.HealthIcon;
import funkin.data.objects.story.MenuItem;
import funkin.stages.StageData;

import flixel.text.FlxText.FlxTextBorderStyle;
import haxe.Json;
using StringTools;

class FreeplayExtraSongsState extends MusicBeatState {
	private var songs:Array<ExtraSongData> = [];
	private static var curSelected:Int = 0;
	private static var curDiffSelected:Int = 0;

	var curDifficulty:Int = -1;
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var noSongsText:FlxText;

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int = 0xFF808080;
	var colorTween:FlxTween;

	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		PlayState.storyWeek = 0;
		loadExtraSongs();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Freeplay Extra Song", "Selecting An Extra Song");
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<FlxSprite>();
		add(grpSongs);

		if(songs.length < 1)
		{
			noSongsText = new FlxText(60, 0, FlxG.width - 120,
				'NO EXTRA SONGS FOUND\n\nAdd songs to data/levels/*.json with section "extraFreeplay".\nCharts should live in data/songs/<song>/<song>-<diff>-extra.json.\nPress BACK to return to Freeplay.',
				24);
			noSongsText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noSongsText.screenCenter(Y);
			add(noSongsText);
			super.create();
			return;
		}

		for(i in 0...songs.length)
		{
			var songText:FlxSprite = createSongMenuItem(songs[i], i);
			Reflect.setField(songText, 'targetY', i);
			grpSongs.add(songText);

			var maxWidth:Float = 980;
			if(songText.width > maxWidth)
				songText.scale.x = maxWidth / songText.width;

			Mods.currentModDirectory = songs[i].folder ?? '';
			createIconItem(songs[i].songCharacter, songText);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		add(scoreText);

		if(curSelected >= songs.length) curSelected = songs.length - 1;
		if(curSelected < 0) curSelected = 0;
		changeSelection(0, false);
		super.create();
	}

	function createIconItem(character:String, tracker:FlxSprite):HealthIcon
	{
		var icon:HealthIcon = new HealthIcon(character);
		icon.sprTracker = tracker;
		iconArray.push(icon);
		add(icon);
		return icon;
	}

	override function update(elapsed:Float)
	{
		if(songs.length < 1)
		{
			if(controls.BACK)
				returnToFreeplay();
			super.update(elapsed);
			return;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));
		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + Math.floor(lerpRating * 100) + '%)';
		positionHighscore();

		if(controls.UI_UP_P)    changeSelection(-1);
		if(controls.UI_DOWN_P)  changeSelection(1);
		if(controls.UI_LEFT_P)  changeDiff(-1);
		if(controls.UI_RIGHT_P) changeDiff(1);

		if(controls.BACK)
			returnToFreeplay();

		if(controls.ACCEPT)
			acceptSong();

		super.update(elapsed);
	}

	function loadExtraSongs():Void
	{
		songs = [];
		WeekData.reloadWeekFiles('extraFreeplay');

		for(i in 0...WeekData.weeksList.length)
		{
			var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(week == null || week.songs == null)
				continue;

			WeekData.setDirectoryFromWeek(week);
			for(rawSong in week.songs)
			{
				var songName:String = WeekData.getWeekSongName(rawSong);
				var songId:String = Paths.formatToSongPath(songName);
				if(songId.length < 1 || hasSong(songId))
					continue;

				var character:String = getWeekSongCharacter(rawSong);
				var color:Int = getWeekSongColor(rawSong, songId);
				var diffs:Array<String> = getWeekDifficulties(week);
				var song = new ExtraSongData(songName, i, character, color, diffs, songId, week.folder);
				song.menuImage = getWeekSongMenuImage(rawSong, songId);
				songs.push(song);
			}
		}

		WeekData.setDirectoryFromWeek();
	}

	function createSongMenuItem(song:ExtraSongData, index:Int):FlxSprite
	{
		var imageKey:String = 'storymenu/titles/' + song.menuImage;
		if(Paths.fileExists('images/$imageKey.png', IMAGE))
		{
			var item:MenuItem = new MenuItem(0, (70 * index) + 30, song.menuImage);
			item.antialiasing = ClientPrefs.data.antialiasing;
			return item;
		}

		var text:Alphabet = new Alphabet(0, (70 * index) + 30, song.songName, true);
		text.isMenuItem = true;
		return text;
	}

	function getWeekSongCharacter(song:Dynamic):String
	{
		if(Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if(data.length > 1 && data[1] != null)
				return Std.string(data[1]);
		}
		return 'face';
	}

	function getWeekSongColor(song:Dynamic, songId:String):Int
	{
		if(Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if(data.length > 2 && Std.isOfType(data[2], Array))
			{
				var colors:Array<Dynamic> = cast data[2];
				if(colors.length >= 3)
					return FlxColor.fromRGB(Std.int(colors[0]), Std.int(colors[1]), Std.int(colors[2]));
			}
		}
		return colorFromSongId(songId);
	}

	function getWeekSongMenuImage(song:Dynamic, songId:String):String
	{
		if(Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if(data.length > 4 && data[4] != null && Std.string(data[4]).length > 0)
				return Std.string(data[4]);
		}
		return songId;
	}

	function getWeekDifficulties(week:WeekData):Array<String>
	{
		var source:Dynamic = week.freeplayDifficulties;
		if(source == null || Std.string(source).length < 1)
			source = week.difficulties;
		if(source == null || Std.string(source).length < 1)
			source = 'Pico';
		return normalizeDiffs(dynamicList(source));
	}

	static function dynamicList(value:Dynamic):Array<String>
	{
		if(value == null)
			return [];
		if(Std.isOfType(value, Array))
		{
			var output:Array<String> = [];
			for(item in (cast value:Array<Dynamic>))
				output.push(Std.string(item));
			return output;
		}
		return Std.string(value).split(',');
	}

	function findExtraChartKey(song:ExtraSongData, diff:String):String
	{
		for(candidate in getExtraChartCandidates(song.songId, diff))
		{
			if(assetTextExists(Paths.chartJson(candidate, normalizeFolder(song.folder))))
				return candidate;
		}
		return null;
	}

	function getExtraChartCandidates(songId:String, diff:String):Array<String>
	{
		var suffix:String = Difficulty.getSuffixFilePath(diff);
		var cleanDiff:String = Paths.formatToSongPath(diff);
		if(suffix.length < 1 && cleanDiff.length > 0)
			suffix = '-' + cleanDiff;

		var candidates:Array<String> = [];
		addChartCandidate(candidates, songId + '/' + songId + suffix + '-extra');
		addChartCandidate(candidates, songId + '/' + songId + '-extra' + suffix);
		addChartCandidate(candidates, songId + '/' + songId + '-extra');
		addChartCandidate(candidates, songId + '/' + songId + suffix);
		addChartCandidate(candidates, songId + '/' + songId);
		return candidates;
	}

	function addChartCandidate(candidates:Array<String>, candidate:String):Void
	{
		if(candidate != null && candidate.length > 0 && !candidates.contains(candidate))
			candidates.push(candidate);
	}

	static function assetTextExists(path:String):Bool
	{
		#if sys
		return FileSystem.exists(path);
		#else
		return openfl.utils.Assets.exists(path);
		#end
	}

	function acceptSong():Void
	{
		var song:ExtraSongData = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		var chartKey:String = findExtraChartKey(song, diff);
		var chartPath:String = chartKey != null ? Paths.chartJson(chartKey, normalizeFolder(song.folder)) : Paths.chartJson(song.songId + '/' + song.songId, normalizeFolder(song.folder));
		var raw:String = chartKey != null ? readText(chartPath) : null;

		if(raw == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		try
		{
			PlayState.SONG = Song.parseJSON(raw, chartKey);
			Reflect.setField(PlayState.SONG, 'extraFreeplay', true);
			Song.loadedSongName = song.songId;
			Song.chartPath = chartPath;
			StageData.loadDirectory(PlayState.SONG);
		}
		catch(e:haxe.Exception)
		{
			showChartError(song, diff, e.message);
			return;
		}

		if(PlayState.SONG == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDiffSelected;
		Difficulty.copyFrom(song.diffs);
		Mods.currentModDirectory = song.folder ?? '';

		FlxG.sound.music.volume = 0;
		LoadingScreenState.prepareToSong();

		if(FlxG.keys.pressed.SHIFT)
			LoadingScreenState.loadAndSwitchState(new ChartingState());
		else
			LoadingScreenState.loadAndSwitchState(new PlayState());
	}

	function changeDiff(change:Int = 0)
	{
		var song = songs[curSelected];
		curDiffSelected = FlxMath.wrap(curDiffSelected + change, 0, song.diffs.length - 1);
		updateDiffText();
		updateScore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(songs.length < 1)
			return;

		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		curDiffSelected = 0;
		var song = songs[curSelected];
		Difficulty.copyFrom(song.diffs);

		intendedColor = song.color;
		if(bg != null)
		{
			if(colorTween != null) colorTween.cancel();
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {onComplete: function(_) colorTween = null});
		}

		for(i in 0...iconArray.length)
			if(iconArray[i] != null)
				iconArray[i].alpha = 0.6;
		if(iconArray[curSelected] != null)
			iconArray[curSelected].alpha = 1;

		var bullShit:Int = 0;
		for(item in grpSongs.members)
		{
			if(item == null)
				continue;
			var targetY:Int = bullShit - curSelected;
			Reflect.setField(item, 'targetY', targetY);
			bullShit++;
			item.alpha = targetY == 0 ? 1 : 0.6;
		}
		Mods.currentModDirectory = song.folder ?? '';

		updateDiffText();
		updateScore();
	}

	function updateDiffText()
	{
		var song = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		if(song.diffs.length > 1)
			diffText.text = '< ' + diff.toUpperCase() + ' >';
		else
			diffText.text = diff.toUpperCase();
	}

	function updateScore()
	{
		var song = songs[curSelected];
		curDifficulty = curDiffSelected;
		var weekData:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[song.week]);
		intendedScore  = Highscore.getScore(song.songName, curDifficulty, null, weekData, true);
		intendedRating = Highscore.getRating(song.songName, curDifficulty, null, weekData, true);
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	function returnToFreeplay():Void {
		Difficulty.resetList();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new funkin.menus.freeplay.FreeplayMenuState());
	}

	function showChartError(song:ExtraSongData, diff:String, expected:String):Void
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		trace('[ExtraSongsState] Chart not found for: ${song.songName} (diff: $diff)');
		trace('[ExtraSongsState] Tried path: $expected');

		var errTxt:FlxText = new FlxText(0, FlxG.height - 66, FlxG.width,
			'Chart not found: ${song.songName} [$diff]\n$expected', 16);
		errTxt.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errTxt.scrollFactor.set();
		add(errTxt);
		FlxTween.tween(errTxt, {alpha: 0}, 3, {startDelay: 2, onComplete: function(_) errTxt.destroy()});
	}

	static function readText(path:String):Null<String>
	{
		#if sys
		return FileSystem.exists(path) ? File.getContent(path) : null;
		#else
		return openfl.utils.Assets.exists(path) ? openfl.utils.Assets.getText(path) : null;
		#end
	}

	static function readChartMetadata(raw:String):Dynamic
	{
		try
		{
			var data:Dynamic = Json.parse(raw);
			if(Reflect.hasField(data, 'song'))
			{
				var subSong:Dynamic = Reflect.field(data, 'song');
				if(subSong != null && Type.typeof(subSong) == TObject)
					data = subSong;
			}
			return data;
		}
		catch(e:Dynamic) {}
		return null;
	}

	static function getStringField(data:Dynamic, field:String):String
	{
		if(data == null || !Reflect.hasField(data, field))
			return null;

		var value:Dynamic = Reflect.field(data, field);
		return value == null ? null : Std.string(value);
	}

	static function diffFromChartName(songId:String, baseName:String):String
	{
		var lowerBase:String = baseName.toLowerCase();
		if(lowerBase == 'events' || lowerBase.startsWith('events-') || lowerBase == 'eventsb')
			return null;
		if(lowerBase == 'metadata' || lowerBase == 'preload' || lowerBase == 'notetypes')
			return null;

		var lowerSong:String = songId.toLowerCase();
		if(!lowerBase.startsWith(lowerSong))
			return null;

		var suffix:String = baseName.substr(songId.length);
		while(suffix.startsWith('-') || suffix.startsWith('_') || suffix.startsWith(' '))
			suffix = suffix.substr(1);

		if(suffix.length < 1)
			return Difficulty.getDefault();

		var cleanSuffix:String = Paths.formatToSongPath(suffix);
		if(cleanSuffix == 'dialogue' || cleanSuffix == 'events' || cleanSuffix == 'metadata')
			return null;

		return suffix;
	}

	static function normalizeDiffs(raw:Array<String>):Array<String>
	{
		var diffs:Array<String> = [];
		for(diff in raw)
		{
			var clean:String = diff.trim();
			if(clean.length > 0 && !containsDiff(diffs, clean))
				diffs.push(clean);
		}
		if(diffs.length < 1)
			diffs.push('pico');
		return diffs;
	}

	static function containsDiff(diffs:Array<String>, diff:String):Bool
	{
		return findMatchingDiff(diffs, diff) != null;
	}

	static function findMatchingDiff(diffs:Array<String>, diff:String):String
	{
		var clean:String = Paths.formatToSongPath(diff);
		for(existing in diffs)
			if(Paths.formatToSongPath(existing) == clean)
				return existing;
		return null;
	}

	static function readableSongName(songId:String):String
	{
		var words:Array<String> = [];
		for(part in songId.split('-'))
		{
			if(part.length < 1)
				continue;
			words.push(part.substr(0, 1).toUpperCase() + part.substr(1));
		}
		return words.length > 0 ? words.join(' ') : songId;
	}

	function hasSong(songId:String):Bool
	{
		var clean:String = Paths.formatToSongPath(songId);
		for(song in songs)
			if(Paths.formatToSongPath(song.songId) == clean)
				return true;
		return false;
	}

	static function parseIntOr(value:String, fallback:Int):Int
	{
		var parsed:Null<Int> = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	static function parseColor(value:String, fallback:Int):Int
	{
		var clean:String = value.replace('#', '').replace('0x', '').replace('0X', '').trim();
		if(clean.length == 6)
			clean = 'FF' + clean;

		var parsed:Null<Int> = Std.parseInt('0x' + clean);
		return parsed == null ? fallback : parsed;
	}

	static function colorFromSongId(songId:String):Int
	{
		var hue:Float = 0;
		for(i in 0...songId.length)
		{
			hue = hue * 31 + songId.charCodeAt(i);
			hue -= Math.floor(hue / 360) * 360;
		}

		return FlxColor.fromHSB(hue, 0.65, 0.75);
	}

	static function normalizeFolder(folder:Null<String>):Null<String>
	{
		return (folder == null || folder.length < 1) ? null : folder;
	}
}

class ExtraSongData
{
	public var songName:String = "";
	public var songId:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -1;
	public var folder:String = "";
	public var menuImage:String = "";
	public var diffs:Array<String> = ["pico"];
	public var chartKeys:Map<String, String> = [];

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?diffs:Array<String>, ?songId:String, ?folder:String)
	{
		this.songName = song;
		this.songId = (songId != null && songId.length > 0) ? songId : Paths.formatToSongPath(song);
		this.week = week;
		this.songCharacter = (songCharacter != null && songCharacter.length > 0) ? songCharacter : 'face';
		this.color = color;
		this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['pico'];
		this.folder = folder ?? (Mods.currentModDirectory ?? '');
		this.menuImage = this.songId;

		for(diff in this.diffs)
			if(!chartKeys.exists(diff))
				chartKeys.set(diff, this.songId + '/' + this.songId + Difficulty.getSuffixFilePath(diff));
	}

	public function getChartKey(diff:String):String
	{
		if(chartKeys.exists(diff))
			return chartKeys.get(diff);

		var clean:String = Paths.formatToSongPath(diff);
		for(key in chartKeys.keys())
			if(Paths.formatToSongPath(key) == clean)
				return chartKeys.get(key);

		return songId + '/' + songId + Difficulty.getSuffixFilePath(diff);
	}
	#end
}
