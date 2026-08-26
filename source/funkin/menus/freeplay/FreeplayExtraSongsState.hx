package funkin.menus.freeplay;

import funkin.Paths;
import funkin.play.Song;
import funkin.play.Highscore;
import funkin.play.Difficulty;

import funkin.data.WeekData;
import funkin.data.objects.HealthIcon;
import funkin.stages.StageData;

import flixel.text.FlxText.FlxTextBorderStyle;
import haxe.Json;
using StringTools;

class FreeplayExtraSongsState extends MusicBeatState
{
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
	var intendedMisses:Int = 0;
	var lerpSelected:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int = 0xFF808080;
	var colorTween:FlxTween;

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	override function create()
	{
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

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		if (songs.length < 1)
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

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			songText.changeX = false;
			songText.snapToPosition();
			songText.screenCenter(X);
			// puxa um pouco pra direita pra caber o ícone à esquerda
			songText.x += 60;
			songText.scaleX = Math.min(1, 900 / songText.width);
			songText.visible = songText.active = false;
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder ?? '';
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			icon.visible = icon.active = false;
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 92, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		add(scoreText);

		if (curSelected >= songs.length) curSelected = songs.length - 1;
		if (curSelected < 0) curSelected = 0;
		lerpSelected = curSelected;

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		changeSelection(0, false);
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (songs.length < 1)
		{
			if (controls.BACK)
				returnToFreeplay();
			super.update(elapsed);
			return;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var accStr:String = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2));
		scoreText.text = 'BEST SCORE: ' + lerpScore + ' (' + accStr + '%)\nMISSES: ' + intendedMisses;
		positionHighscore();

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);
		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
			returnToFreeplay();

		if (controls.ACCEPT)
			acceptSong();

		updateTexts(elapsed);
		super.update(elapsed);
	}

	function loadExtraSongs():Void
	{
		songs = [];
		WeekData.reloadWeekFiles('extraFreeplay');

		for (i in 0...WeekData.weeksList.length)
		{
			var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (week == null || week.songs == null)
				continue;

			WeekData.setDirectoryFromWeek(week);
			for (rawSong in week.songs)
			{
				var songName:String = WeekData.getWeekSongName(rawSong);
				var pathName:String = Paths.formatToSongPath(songName);
				if (pathName.length < 1 || hasSong(pathName))
					continue;

				var character:String = getWeekSongCharacter(rawSong);
				var color:Int = getWeekSongColor(rawSong, pathName);
				var diffs:Array<String> = getWeekDifficulties(week);
				songs.push(new ExtraSongData(songName, i, character, color, diffs, week.folder));
			}
		}

		WeekData.setDirectoryFromWeek();
	}

	function getWeekSongCharacter(song:Dynamic):String
	{
		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 1 && data[1] != null)
				return Std.string(data[1]);
		}
		return 'face';
	}

	function getWeekSongColor(song:Dynamic, pathName:String):Int
	{
		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 2 && Std.isOfType(data[2], Array))
			{
				var colors:Array<Dynamic> = cast data[2];
				if (colors.length >= 3)
					return FlxColor.fromRGB(Std.int(colors[0]), Std.int(colors[1]), Std.int(colors[2]));
			}
		}
		return colorFromPathName(pathName);
	}

	function getWeekDifficulties(week:WeekData):Array<String>
	{
		var source:Dynamic = week.freeplayDifficulties;
		if (source == null || Std.string(source).length < 1)
			source = week.difficulties;
		if (source == null || Std.string(source).length < 1)
			source = 'Pico';
		return normalizeDiffs(dynamicList(source));
	}

	static function dynamicList(value:Dynamic):Array<String>
	{
		if (value == null)
			return [];
		if (Std.isOfType(value, Array))
		{
			var output:Array<String> = [];
			for (item in (cast value:Array<Dynamic>))
				output.push(Std.string(item));
			return output;
		}
		return Std.string(value).split(',');
	}

	function findExtraChartKey(song:ExtraSongData, diff:String):String
	{
		var pathName:String = Paths.formatToSongPath(song.songName);
		for (candidate in getExtraChartCandidates(pathName, diff))
		{
			if (assetTextExists(Paths.chartJson(candidate, normalizeFolder(song.folder))))
				return candidate;
		}
		return null;
	}

	function getExtraChartCandidates(pathName:String, diff:String):Array<String>
	{
		var suffix:String = Difficulty.getSuffixFilePath(diff);
		var cleanDiff:String = Paths.formatToSongPath(diff);
		if (suffix.length < 1 && cleanDiff.length > 0)
			suffix = '-' + cleanDiff;

		var candidates:Array<String> = [];
		addChartCandidate(candidates, pathName + '/' + pathName + suffix + '-extra');
		addChartCandidate(candidates, pathName + '/' + pathName + '-extra' + suffix);
		addChartCandidate(candidates, pathName + '/' + pathName + '-extra');
		addChartCandidate(candidates, pathName + '/' + pathName + suffix);
		addChartCandidate(candidates, pathName + '/' + pathName);
		return candidates;
	}

	function addChartCandidate(candidates:Array<String>, candidate:String):Void
	{
		if (candidate != null && candidate.length > 0 && !candidates.contains(candidate))
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
		var pathName:String = Paths.formatToSongPath(song.songName);
		var chartKey:String = findExtraChartKey(song, diff);
		var chartPath:String = chartKey != null
			? Paths.chartJson(chartKey, normalizeFolder(song.folder))
			: Paths.chartJson(pathName + '/' + pathName, normalizeFolder(song.folder));
		var raw:String = chartKey != null ? readText(chartPath) : null;

		if (raw == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		try
		{
			PlayState.SONG = Song.parseJSON(raw, chartKey);
			Reflect.setField(PlayState.SONG, 'extraFreeplay', true);
			Song.loadedSongName = pathName;
			Song.chartPath = chartPath;
			StageData.loadDirectory(PlayState.SONG);
		}
		catch (e:haxe.Exception)
		{
			showChartError(song, diff, e.message);
			return;
		}

		if (PlayState.SONG == null)
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
		if (songs.length < 1)
			return;

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		curDiffSelected = 0;
		var song = songs[curSelected];
		Difficulty.copyFrom(song.diffs);

		intendedColor = song.color;
		if (bg != null)
		{
			if (colorTween != null) colorTween.cancel();
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(_) colorTween = null
			});
		}

		for (i in 0...iconArray.length)
			if (iconArray[i] != null)
				iconArray[i].alpha = 0.6;
		if (iconArray[curSelected] != null)
			iconArray[curSelected].alpha = 1;

		for (i in 0...grpSongs.length)
		{
			var item:Alphabet = grpSongs.members[i];
			if (item == null) continue;
			item.targetY = i - curSelected;
			item.alpha = (i == curSelected) ? 1 : 0.6;
		}

		Mods.currentModDirectory = song.folder ?? '';
		updateDiffText();
		updateScore();
	}

	function updateDiffText()
	{
		var song = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		if (song.diffs.length > 1)
			diffText.text = '< ' + diff.toUpperCase() + ' >';
		else
			diffText.text = diff.toUpperCase();
	}

	function updateScore()
	{
		var song = songs[curSelected];
		curDifficulty = curDiffSelected;

		var weekData:WeekData = null;
		if (song.week >= 0 && song.week < WeekData.weeksList.length)
			weekData = WeekData.weeksLoaded.get(WeekData.weeksList[song.week]);

		// Highscore das músicas extras (flag extraFreeplay = true)
		intendedScore = Highscore.getScore(song.songName, curDifficulty, null, weekData, true);
		intendedRating = Highscore.getRating(song.songName, curDifficulty, null, weekData, true);
		intendedMisses = Highscore.getMisses(song.songName, curDifficulty, null, weekData, true);
	}

	function positionHighscore()
	{
		if (scoreText == null || scoreBG == null || diffText == null)
			return;

		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.setGraphicSize(Std.int(FlxG.width - scoreText.x + 6), Std.int(scoreText.height + 8));
		scoreBG.updateHitbox();
		scoreBG.x = FlxG.width - scoreBG.width;
		scoreBG.y = 0;

		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2));
		diffText.y = scoreText.y + scoreText.height + 2;
	}

	function updateTexts(elapsed:Float = 0.0)
	{
		if (grpSongs == null || songs.length < 1)
			return;

		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, Math.exp(-elapsed * 9.6));

		for (i in _lastVisibles)
		{
			if (i < 0 || i >= grpSongs.length) continue;
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			if (i < iconArray.length && iconArray[i] != null)
				iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			if (item == null) continue;

			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			// mantém centralizado horizontalmente
			item.screenCenter(X);
			item.x += 60;

			if (i < iconArray.length && iconArray[i] != null)
			{
				iconArray[i].visible = iconArray[i].active = true;
			}
			_lastVisibles.push(i);
		}
	}

	function returnToFreeplay():Void
	{
		Difficulty.resetList();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new FreeplayMenuState());
	}

	function showChartError(song:ExtraSongData, diff:String, expected:String):Void
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		trace('[ExtraSongs] Chart not found: ${song.songName} [$diff] -> $expected');

		var errTxt:FlxText = new FlxText(0, FlxG.height - 66, FlxG.width,
			'Chart not found: ${song.songName} [$diff]\n$expected', 16);
		errTxt.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errTxt.scrollFactor.set();
		add(errTxt);
		FlxTween.tween(errTxt, {alpha: 0}, 3, {
			startDelay: 2,
			onComplete: function(_) errTxt.destroy()
		});
	}

	static function readText(path:String):Null<String>
	{
		#if sys
		return FileSystem.exists(path) ? File.getContent(path) : null;
		#else
		return openfl.utils.Assets.exists(path) ? openfl.utils.Assets.getText(path) : null;
		#end
	}

	static function normalizeDiffs(raw:Array<String>):Array<String>
	{
		var diffs:Array<String> = [];
		for (diff in raw)
		{
			var clean:String = diff.trim();
			if (clean.length > 0 && !containsDiff(diffs, clean))
				diffs.push(clean);
		}
		if (diffs.length < 1)
			diffs.push('pico');
		return diffs;
	}

	static function containsDiff(diffs:Array<String>, diff:String):Bool
	{
		var clean:String = Paths.formatToSongPath(diff);
		for (existing in diffs)
			if (Paths.formatToSongPath(existing) == clean)
				return true;
		return false;
	}

	function hasSong(pathName:String):Bool
	{
		var clean:String = Paths.formatToSongPath(pathName);
		for (song in songs)
			if (Paths.formatToSongPath(song.songName) == clean)
				return true;
		return false;
	}

	static function colorFromPathName(pathName:String):Int
	{
		var hue:Float = 0;
		for (i in 0...pathName.length)
		{
			hue = hue * 31 + pathName.charCodeAt(i);
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
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -1;
	public var folder:String = "";
	public var diffs:Array<String> = ["pico"];

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?diffs:Array<String>, ?folder:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = (songCharacter != null && songCharacter.length > 0) ? songCharacter : 'face';
		this.color = color;
		this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['pico'];
		this.folder = folder ?? (Mods.currentModDirectory ?? '');
	}
}
