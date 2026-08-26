package funkin.states.achievements.data;

#if ACHIEVEMENTS_ALLOWED
import haxe.Exception;
import haxe.Json;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLuaProgramming;
#end

typedef Achievement =
{
	var name:String;
	var description:String;
	@:optional var hidden:Bool;
	@:optional var maxScore:Float;
	@:optional var maxDecimals:Int;

	/**
	 * Menu page category for AchievementsMenuState:
	 * "psych" | "pico" | "default"
	 */
	@:optional var category:String;

	// handled automatically
	@:optional var mod:String;
	@:optional var ID:Int;
}

enum abstract AchievementOp(String)
{
	var GET = 'get';
	var SET = 'set';
	var ADD = 'add';
}

class Achievements {
	public static function init()
	{
		createAchievement('friday_night_play',		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true, category: "psych"});
		createAchievement('ur_bad',					{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%.", category: "psych"});
		createAchievement('ur_good',				{name: "Perfectionist", description: "Complete a Song with a rating of 100%.", category: "psych"});
		createAchievement('oversinging', 			{name: "Oversinging Much...?", description: "Sing for 10 seconds without going back to Idle.", category: "psych"});
		createAchievement('hype',					{name: "Hyperactive", description: "Finish a Song without going back to Idle.", category: "psych"});
		createAchievement('two_keys',				{name: "Just the Two of Us", description: "Finish a Song pressing only two keys.", category: "psych"});
		createAchievement('toastie',				{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?", category: "psych"});
		createAchievement('roadkill_enthusiast',	{name: "Roadkill Enthusiast", description: "Watch the Henchmen die 50 times.", maxScore: 50, maxDecimals: 0, category: "psych"});
		createAchievement('debugger',				{name: "Debugger", description: "Beat the \"Test\" Stage from the Chart Editor.", hidden: true, category: "psych"});
		#if (TITLE_SCREEN_EASTER_EGG || PSYCH_WATERMARKS)
		createAchievement('pessy_easter_egg',		{name: "Engine Gal Pal", description: "Teehee, you found me~!", hidden: true, category: "psych"});
		#end

		createAchievement('pico_first_play',		{name: "Pico Starter", description: "Play a song on Pico Engine.", category: "pico"});
		createAchievement('pico_opponent_mode',		{name: "Role Reversal", description: "Clear a song in Opponent Mode.", category: "pico"});
		createAchievement('pico_rank_s',			{name: "S Rank Sweep", description: "Get an S Rank or higher on any song.", category: "pico"});
		createAchievement('pico_custom_notes',		{name: "Style Points", description: "Play a song using a custom noteStyle.", category: "pico"});

		// ----- Default Achievements (weeks / base story) -----
		createAchievement('week1_nomiss',			{name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses.", category: "default"});
		createAchievement('week2_nomiss',			{name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses.", category: "default"});
		createAchievement('week3_nomiss',			{name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses.", category: "default"});
		createAchievement('week4_nomiss',			{name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses.", category: "default"});
		createAchievement('week5_nomiss',			{name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses.", category: "default"});
		createAchievement('week6_nomiss',			{name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses.", category: "default"});
		createAchievement('week7_nomiss',			{name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses.", category: "default"});
		createAchievement('weekend1_nomiss',		{name: "Just a Friendly Sparring", description: "Beat Weekend 1 on Hard with no Misses.", category: "default"});

		_originalLength = _sortID + 1;
	}

	public static var achievements:Map<String, Achievement> = new Map<String, Achievement>();
	public static var variables:Map<String, Float> = [];
	public static var achievementsUnlocked:Array<String> = [];
	private static var _firstLoad:Bool = true;

	public static function get(name:String):Achievement
		return achievements.get(name);
	public static function exists(name:String):Bool
		return achievements.exists(name);

	public static function load():Void
	{
		if(!_firstLoad) return;

		if(_originalLength < 0) init();

		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsUnlocked != null)
				achievementsUnlocked = FlxG.save.data.achievementsUnlocked;

			var savedMap:Map<String, Float> = cast FlxG.save.data.achievementsVariables;
			if(savedMap != null)
			{
				for (key => value in savedMap)
				{
					variables.set(key, value);
				}
			}
			#end
			_firstLoad = false;
		}
	}

	public static function save():Void
	{
		FlxG.save.data.achievementsUnlocked = achievementsUnlocked;
		FlxG.save.data.achievementsVariables = variables;
	}
	
	public static function getScore(name:String):Float
		return _scoreFunc(name, GET);

	public static function setScore(name:String, value:Float, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, ADD, value, saveIfNotUnlocked);

	static function _scoreFunc(name:String, mode:AchievementOp, addOrSet:Float = 1, saveIfNotUnlocked:Bool = true):Float
	{
		if(!variables.exists(name))
			variables.set(name, 0);

		if(achievements.exists(name))
		{
			var achievement:Achievement = achievements.get(name);
			if(achievement.maxScore < 1) throw new Exception('Achievement has score disabled or is incorrect: "$name" (score must be > 0)');

			var max:Float = achievement.maxScore;

			var val = addOrSet;
			switch(mode)
			{
				case GET: return variables.get(name);
				case ADD: val += variables.get(name);
				default:
			}

			if(val >= max)
			{
				unlock(name);
				val = max;
			}
			variables.set(name, val);

			Achievements.save();
			if(saveIfNotUnlocked || val >= max) FlxG.save.flush();
			return val;
		}
		return -1;
	}

	static var _lastUnlock:Int = -999;
	public static function unlock(name:String, autoStartPopup:Bool = true):String {
		if(!achievements.exists(name))
		{
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if(Achievements.isUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		achievementsUnlocked.push(name);

		var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}

		Achievements.save();
		FlxG.save.flush();

		if(autoStartPopup) startPopup(name);
		return name;
	}

	inline public static function isUnlocked(name:String)
		return achievementsUnlocked.contains(name);

	#if ACHIEVEMENTS_ALLOWED
	@:allow(funkin.data.objects.AchievementPopup)
	private static var _popups:Array<Dynamic> = [];
	#else
	private static var _popups:Array<Dynamic> = [];
	#end

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null) {
		for (popup in _popups)
		{
			if(popup == null) continue;
			try Reflect.setProperty(popup, 'intendedY', Reflect.getProperty(popup, 'intendedY') + 150) catch(e:Dynamic) {}
		}

		try
		{
			// AchievementPopup class path may differ per fork
			var newPop:Dynamic = Type.createInstance(Type.resolveClass('funkin.data.objects.AchievementPopup'), [achieve, endFunc]);
			if(newPop == null)
				newPop = Type.createInstance(Type.resolveClass('objects.AchievementPopup'), [achieve, endFunc]);
			if(newPop != null) _popups.push(newPop);
		}
		catch(e:Dynamic)
		{
			trace('[Achievements] Popup failed: $e');
		}
	}

	static var _sortID = 0;
	static var _originalLength = -1;
	public static function createAchievement(name:String, data:Achievement, ?mod:String = null)
	{
		data.ID = _sortID;
		data.mod = mod;
		// Auto category for mod achievements
		if((data.category == null || data.category.length < 1) && mod != null && mod.length > 0)
			data.category = 'default';
		if(data.category == null || data.category.length < 1)
			data.category = 'psych';
		data.category = normalizeCategory(data.category);
		achievements.set(name, data);
		_sortID++;
	}

	public static function normalizeCategory(value:String):String
	{
		if(value == null) return 'psych';
		var v:String = value.trim().toLowerCase();
		if(v.indexOf('pico') >= 0) return 'pico';
		if(v.indexOf('default') >= 0 || v.indexOf('base') >= 0 || v.indexOf('mod') >= 0) return 'default';
		if(v.indexOf('psych') >= 0) return 'psych';
		return 'psych';
	}

	#if MODS_ALLOWED
	public static function reloadList()
	{
		if((_sortID + 1) > _originalLength)
			for (key => value in achievements)
				if(value.mod != null)
					achievements.remove(key);

		_sortID = _originalLength-1;

		var modLoaded:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAchievementJson(Paths.mods('data/achievements.json'));
		for (i => mod in Mods.parseList().enabled)
		{
			Mods.currentModDirectory = mod;
			loadAchievementJson(Paths.mods('$mod/data/achievements.json'));
		}
		Mods.currentModDirectory = modLoaded;
	}

	inline static function loadAchievementJson(path:String, addMods:Bool = true)
	{
		var retVal:Array<Dynamic> = null;
		if(FileSystem.exists(path)) {
			try {
				var rawJson:String = File.getContent(path).trim();
				if(rawJson != null && rawJson.length > 0) retVal = tjson.TJSON.parse(rawJson);
				
				if(addMods && retVal != null)
				{
					for (i in 0...retVal.length)
					{
						var achieve:Dynamic = retVal[i];
						if(achieve == null)
						{
							trace('Achievement #${i+1} is invalid.');
							continue;
						}

						var key:String = achieve.save;
						if(key == null || key.trim().length < 1)
						{
							trace('Missing valid "save" value on achievement #${i+1}');
							continue;
						}
						key = key.trim();
						if(achievements.exists(key)) continue;

						// JSON can set "category": "pico" | "psych" | "default"
						if(achieve.category == null && Mods.currentModDirectory != null)
							achieve.category = 'default';

						createAchievement(key, achieve, Mods.currentModDirectory);
					}
				}
			} catch(e:Dynamic) {
				trace('Error loading achievements.json: $e');
			}
		}
		return retVal;
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getAchievementScore", function(name:String):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLuaProgramming.luaTrace('getAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return getScore(name);
		});
		Lua_helper.add_callback(lua, "setAchievementScore", function(name:String, ?value:Float = 0, ?saveIfNotUnlocked:Bool = true):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLuaProgramming.luaTrace('setAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return setScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "addAchievementScore", function(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		{
			if(!achievements.exists(name))
			{
				FunkinLuaProgramming.luaTrace('addAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return addScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "unlockAchievement", function(name:String):Dynamic
		{
			if(!achievements.exists(name))
			{
				FunkinLuaProgramming.luaTrace('unlockAchievement: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return unlock(name);
		});
		Lua_helper.add_callback(lua, "isAchievementUnlocked", function(name:String):Dynamic
		{
			if(!achievements.exists(name))
			{
				FunkinLuaProgramming.luaTrace('isAchievementUnlocked: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return isUnlocked(name);
		});
		Lua_helper.add_callback(lua, "achievementExists", function(name:String) return achievements.exists(name));
	}
	#end
}