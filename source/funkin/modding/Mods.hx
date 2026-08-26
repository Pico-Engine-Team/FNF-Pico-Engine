package funkin.modding;

import openfl.utils.Assets;
import haxe.Json;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

/**
 * Normalized mod metadata (Psych pack.json + V-Slice / Polymod style aliases).
 */
typedef ModPackInfo =
{
	var folder:String;
	var name:String;
	var description:String;
	var version:String;
	var color:Array<Int>;
	var runsGlobally:Bool;
	var restart:Bool;
	var apiVersion:String;
	var format:String; // "psych" | "vslice" | "polymod" | "unknown"
	@:optional var raw:Dynamic;
};

/**
 * Pico Engine Mods API
 *
 * Load priority (highest → lowest) when resolving a file:
 *   1. currentModDirectory
 *   2. other enabled mods (modsList order, top of list = higher priority)
 *   3. global-running mods (pack.runsGlobally)
 *   4. mods/ root loose files
 *   5. base game assets
 *
 * pack.json compatibility:
 *   - Psych Engine (name, description, runsGlobally, color, restart)
 *   - V-Slice / Funkin-style (title, meta.description, etc.)
 *   - Polymod (_polymod_meta.json / mod.json)
 */
class Mods
{
	static public var currentModDirectory:String = '';

	/** If true, enabled list order is top-first (index 0 wins). */
	public static var topModHighestPriority:Bool = true;

	public static final ignoreModFolders:Array<String> =
	[
		'characters',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];
	private static var packCache:Map<String, ModPackInfo> = new Map();

	// ---------- Basic API ----------

	inline public static function getGlobalMods():Array<String>
		return globalMods;

	inline public static function getCurrent():String
		return currentModDirectory != null ? currentModDirectory : '';

	inline public static function hasCurrent():Bool
		return getCurrent().length > 0;

	inline public static function setCurrent(mod:String):Void
	{
		currentModDirectory = (mod != null) ? mod : '';
	}

	inline public static function clearCurrent():Void
		currentModDirectory = '';

	/** Temporarily switch current mod, run callback, restore previous. */
	public static function withMod(mod:String, action:Void->Void):Void
	{
		var prev:String = currentModDirectory;
		setCurrent(mod);
		try
		{
			if(action != null) action();
		}
		catch(e:Dynamic)
		{
			setCurrent(prev);
			throw e;
		}
		setCurrent(prev);
	}

	inline public static function isEnabled(mod:String):Bool
	{
		if(mod == null || mod.length < 1) return false;
		return parseList().enabled.contains(mod);
	}

	inline public static function getEnabled():Array<String>
		return parseList().enabled.copy();

	inline public static function getDisabled():Array<String>
		return parseList().disabled.copy();

	/**
	 * Full load order for overrides (highest priority first).
	 * Does not include base game — only mod folders.
	 */
	public static function getLoadOrder(?includeGlobal:Bool = true):Array<String>
	{
		var order:Array<String> = [];
		var enabled:Array<String> = parseList().enabled;

		// Current mod always on top when set
		if(hasCurrent() && !order.contains(currentModDirectory))
			order.push(currentModDirectory);

		// Enabled list: top of file = higher priority when topModHighestPriority
		var enabledOrder:Array<String> = enabled.copy();
		if(!topModHighestPriority)
			enabledOrder.reverse();

		for (mod in enabledOrder)
		{
			if(mod != null && mod.length > 0 && !order.contains(mod))
				order.push(mod);
		}

		if(includeGlobal)
		{
			for (mod in getGlobalMods())
			{
				if(mod != null && mod.length > 0 && !order.contains(mod))
					order.push(mod);
			}
		}
		return order;
	}

	/** Absolute path to a file inside a mod folder (or mods root if mod empty). */
	public static function modPath(?mod:String = null, relative:String = ''):String
	{
		if(mod == null || mod.length < 1)
			return Paths.mods(relative);
		if(relative == null || relative.length < 1)
			return Paths.mods(mod);
		return Paths.mods(mod + '/' + relative);
	}

	/**
	 * Resolve the first existing path for relativeFile using load priority.
	 * Returns null if not found in mods (caller can fall back to assets).
	 */
	public static function resolvePath(relativeFile:String, ?includeModsRoot:Bool = true):String
	{
		#if MODS_ALLOWED
		for (mod in getLoadOrder(true))
		{
			var p:String = modPath(mod, relativeFile);
			if(FileSystem.exists(p))
				return p;
		}
		if(includeModsRoot)
		{
			var root:String = Paths.mods(relativeFile);
			if(FileSystem.exists(root))
				return root;
		}
		#end
		return null;
	}

	/** Script folders to scan (current + globals + enabled), highest first. */
	public static function getScriptFolders(?subfolder:String = 'scripts'):Array<String>
	{
		var folders:Array<String> = [];
		#if MODS_ALLOWED
		for (mod in getLoadOrder(true))
		{
			var p:String = modPath(mod, subfolder);
			if(FileSystem.exists(p) && FileSystem.isDirectory(p) && !folders.contains(p))
				folders.push(p);
		}
		var rootScripts:String = Paths.mods(subfolder);
		if(FileSystem.exists(rootScripts) && FileSystem.isDirectory(rootScripts) && !folders.contains(rootScripts))
			folders.push(rootScripts);
		#end
		return folders;
	}

	// ---------- Global mods ----------

	inline public static function pushGlobalMods():Array<String>
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack:ModPackInfo = getPackInfo(mod);
			if(pack != null && pack.runsGlobally)
				globalMods.push(mod);
		}
		return globalMods;
	}

	// ---------- Directories ----------

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if(FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	// ---------- Text merge (unchanged behaviour, priority aware) ----------

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	/**
	 * Collect existing file paths. Order:
	 * base → week → global mods → mods root → enabled (low→high) → current (last = wins if consumer uses last)
	 * For "first hit wins", use resolvePath() instead.
	 */
	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		// Main / base folder
		if(FileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		// Week folder
		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if(!foldersToCheck.contains(pth) && FileSystem.exists(pth))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			// Global mods (lower than active list)
			for(mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			// mods/ root
			var folder:String = Paths.mods(fileToFind);
			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
				foldersToCheck.push(folder);

			// Enabled mods low → high so current can be pushed last
			var enabled:Array<String> = parseList().enabled.copy();
			if(topModHighestPriority)
			{
				// list top is highest: push from bottom to top so top ends last
				var i:Int = enabled.length - 1;
				while(i >= 0)
				{
					var mod:String = enabled[i];
					if(mod != null && mod.length > 0 && mod != Mods.currentModDirectory)
					{
						var modFolder:String = Paths.mods(mod + '/' + fileToFind);
						if(FileSystem.exists(modFolder) && !foldersToCheck.contains(modFolder))
							foldersToCheck.push(modFolder);
					}
					i--;
				}
			}
			else
			{
				for (mod in enabled)
				{
					if(mod != null && mod.length > 0 && mod != Mods.currentModDirectory)
					{
						var modFolder:String = Paths.mods(mod + '/' + fileToFind);
						if(FileSystem.exists(modFolder) && !foldersToCheck.contains(modFolder))
							foldersToCheck.push(modFolder);
					}
				}
			}

			// Current mod last (highest when last-wins)
			if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var curFolder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if(FileSystem.exists(curFolder) && !foldersToCheck.contains(curFolder))
					foldersToCheck.push(curFolder);
			}
		}
		#end
		return foldersToCheck;
	}

	// ---------- Pack / metadata (Psych + V-Slice + Polymod) ----------

	/** Raw pack.json Dynamic (legacy API). */
	public static function getPack(?folder:String = null):Dynamic
	{
		var info:ModPackInfo = getPackInfo(folder);
		return info != null ? info.raw : null;
	}

	public static function getPackInfo(?folder:String = null):ModPackInfo
	{
		#if MODS_ALLOWED
		if(folder == null) folder = Mods.currentModDirectory;
		if(folder == null || folder.length < 1) return null;

		if(packCache.exists(folder))
			return packCache.get(folder);

		var info:ModPackInfo = loadPackInfo(folder);
		if(info != null)
			packCache.set(folder, info);
		return info;
		#else
		return null;
		#end
	}

	public static function clearPackCache():Void
	{
		packCache = new Map();
	}

	static function loadPackInfo(folder:String):ModPackInfo
	{
		#if MODS_ALLOWED
		// Candidate meta files (Psych / V-Slice / Polymod)
		var candidates:Array<String> = [
			Paths.mods(folder + '/pack.json'),
			Paths.mods(folder + '/mod.json'),
			Paths.mods(folder + '/_polymod_meta.json'),
			Paths.mods(folder + '/meta.json')
		];

		for (path in candidates)
		{
			if(!FileSystem.exists(path)) continue;
			try
			{
				#if sys
				var rawJson:String = File.getContent(path);
				#else
				var rawJson:String = Assets.getText(path);
				#end
				if(rawJson == null || rawJson.length < 1) continue;
				var data:Dynamic = null;
				try data = tjson.TJSON.parse(rawJson) catch(e:Dynamic) data = Json.parse(rawJson);
				if(data == null) continue;
				return normalizePack(folder, data, path);
			}
			catch(e:Dynamic)
			{
				trace('[Mods] Failed to parse $path: $e');
			}
		}
		#end
		// Minimal fallback so callers always get something for existing folders
		return {
			folder: folder,
			name: folder,
			description: '',
			version: '',
			color: [255, 255, 255],
			runsGlobally: false,
			restart: false,
			apiVersion: '',
			format: 'unknown',
			raw: null
		};
	}

	static function normalizePack(folder:String, data:Dynamic, path:String):ModPackInfo
	{
		var format:String = 'unknown';
		var lowerPath:String = path != null ? path.toLowerCase() : '';
		if(StringTools.endsWith(lowerPath, 'pack.json')) format = 'psych';
		else if(StringTools.endsWith(lowerPath, '_polymod_meta.json')) format = 'polymod';
		else if(StringTools.endsWith(lowerPath, 'mod.json')) format = 'vslice';
		else if(StringTools.endsWith(lowerPath, 'meta.json')) format = 'vslice';

		var name:String = strField(data, ['name', 'title', 'modName', 'id']);
		if(name == null) name = folder;

		var description:String = strField(data, ['description', 'desc']);
		if(description == null)
		{
			var meta:Dynamic = Reflect.field(data, 'meta');
			if(meta != null) description = strField(meta, ['description', 'desc']);
		}
		if(description == null) description = '';

		var version:String = strField(data, ['version', 'modVersion', 'api_version']);
		if(version == null) version = '';

		var apiVersion:String = strField(data, ['apiVersion', 'api_version', 'compatibleWith']);
		if(apiVersion == null) apiVersion = '';

		var runsGlobally:Bool = boolField(data, ['runsGlobally', 'runs_globally', 'global', 'alwaysActive'], false);
		var restart:Bool = boolField(data, ['restart', 'requiresRestart'], false);

		var color:Array<Int> = [255, 255, 255];
		var colorRaw:Dynamic = Reflect.field(data, 'color');
		if(colorRaw == null) colorRaw = Reflect.field(data, 'badgeColor');
		if(Std.isOfType(colorRaw, Array))
		{
			var arr:Array<Dynamic> = cast colorRaw;
			color = [];
			for (i in 0...Std.int(Math.min(3, arr.length)))
				color.push(Std.parseInt(Std.string(arr[i])));
			while(color.length < 3) color.push(255);
		}

		return {
			folder: folder,
			name: name,
			description: description,
			version: version,
			color: color,
			runsGlobally: runsGlobally,
			restart: restart,
			apiVersion: apiVersion,
			format: format,
			raw: data
		};
	}

	static function strField(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return null;
		for (n in names)
		{
			var v:Dynamic = Reflect.field(obj, n);
			if(v == null) continue;
			var s:String = Std.string(v).trim();
			if(s.length > 0 && s.toLowerCase() != 'null') return s;
		}
		return null;
	}

	static function boolField(obj:Dynamic, names:Array<String>, def:Bool):Bool
	{
		if(obj == null) return def;
		for (n in names)
		{
			if(!Reflect.hasField(obj, n)) continue;
			var v:Dynamic = Reflect.field(obj, n);
			if(v == true || v == false) return v;
			if(v != null)
			{
				var s:String = Std.string(v).toLowerCase();
				if(s == 'true' || s == '1') return true;
				if(s == 'false' || s == '0') return false;
			}
		}
		return def;
	}

	// ---------- modsList.txt ----------

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList
	{
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				if(mod.trim().length < 1) continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		}
		catch(e)
		{
			trace(e);
		}
		#end
		return list;
	}

	private static function updateModList()
	{
		#if MODS_ALLOWED
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		}
		catch(e)
		{
			trace(e);
		}

		for (folder in getModDirectories())
		{
			if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]);
			}
		}

		var fileStr:String = '';
		for (values in list)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		File.saveContent('modsList.txt', fileStr);
		updatedOnState = true;
		clearPackCache();
		#end
	}

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if(list != null && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end
	}
}
