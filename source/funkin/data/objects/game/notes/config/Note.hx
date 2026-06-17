package funkin.data.objects.game.notes.data;

import funkin.data.shaders.RGBPalette;
import funkin.data.objects.game.notes.data.StrumNote;
import funkin.data.objects.game.notes.config.NoteTypesConfig;
import funkin.data.shaders.RGBPalette.RGBShaderReference;
import funkin.utils.engines.psych.PsychAnimationController;

import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool,
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

typedef NoteSkinAnim = {
	@:optional var prefix:String;
	@:optional var fps:Null<Int>;
	@:optional var loop:Null<Bool>;
	@:optional var indices:Array<Int>;
}

typedef NoteSkinUiAsset = {
	@:optional var assetPath:Null<String>;
	@:optional var audioPath:Null<String>;
	@:optional var scale:Null<Float>;
	@:optional var isPixel:Null<Bool>;
}

typedef HoldNoteCoverConfig = {
	var enabled:Bool;
	var isPixel:Bool;
	var assetPaths:Array<Null<String>>;
	var startAnims:Array<Null<NoteSkinAnim>>;
	var holdAnims:Array<Null<NoteSkinAnim>>;
	var endAnims:Array<Null<NoteSkinAnim>>;
	var offsets:Array<Float>;
	var scale:Float;
	var centerOnStrum:Bool;
	var columns:Int;
	var rows:Int;
}

typedef NoteSkinConfig = {
	var animations:Map<String, NoteSkinAnim>;
	var uiAssets:Map<String, NoteSkinUiAsset>;
	var scale:Float;
	var noteScale:Float;
	var holdScale:Float;
	var strumScale:Float;
	var pixelNoteScale:Float;
	var pixelHoldScale:Float;
	var pixelStrumScale:Float;
	var allowRGB:Bool;
	var allowPixel:Bool;
	var noteAssetPath:Null<String>;
	var holdAssetPath:Null<String>;
	var strumAssetPath:Null<String>;
	var pixelNoteAssetPath:Null<String>;
	var pixelHoldAssetPath:Null<String>;
	var pixelStrumAssetPath:Null<String>;
	var noteSplashAssetPath:Null<String>;
	var holdNoteCover:HoldNoteCoverConfig;
	var pixelNoteColumns:Int;
	var pixelNoteRows:Int;
	var pixelHoldColumns:Int;
	var pixelHoldRows:Int;
	var pixelStrumColumns:Int;
	var pixelStrumRows:Int;
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public static var noteSkinConfigs:Map<String, NoteSkinConfig> = new Map();
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = songSplashSkinForMustPress(mustPress);
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public static function songArrowSkinForMustPress(mustPress:Bool):String
	{
		return songNoteStyle();
	}

	public static function songNoteStyle():String
	{
		var skin:String = null;
		if(PlayState.SONG != null)
		{
			skin = PlayState.SONG.noteStyle;
			if(skin == null || skin.trim().length < 1)
				skin = PlayState.SONG.arrowSkin;
		}
		var clean:String = normalizeNoteStyleName(skin);
		if(clean.length < 1 && PlayState.isPixelStage)
			clean = defaultSongNoteStyle();
		return clean;
	}

	public static function normalizeNoteStyleName(skin:String):String
	{
		if(skin == null) return '';

		var clean:String = skin.trim().replace('\\', '/');
		if(clean.length < 1) return '';

		var lower:String = clean.toLowerCase();
		if(lower == 'default' || lower == 'normal')
			return '';

		if(clean.startsWith('images/'))
			clean = clean.substr('images/'.length);
		if(clean.startsWith('data/notestyles/'))
			clean = clean.substr('data/notestyles/'.length);
		if(clean.startsWith('notestyles/'))
			clean = clean.substr('notestyles/'.length);
		if(clean.startsWith('assets/images/'))
			clean = clean.substr('assets/images/'.length);
		if(clean.startsWith('assets/shared/data/notestyles/'))
			clean = clean.substr('assets/shared/data/notestyles/'.length);

		for (extension in ['.png', '.xml', '.json'])
		{
			if(clean.endsWith(extension))
			{
				clean = clean.substr(0, clean.length - extension.length);
				break;
			}
		}

		var styleKey:String = noteStyleKey(clean);
		if(styleKey.length > 0 && textAssetExists('data/notestyles/$styleKey.json'))
			return styleKey;

		if(clean.indexOf('/') < 0 && (imageAssetExists('noteSkins/$clean') || textAssetExists('images/noteSkins/$clean.json')))
			clean = 'noteSkins/$clean';

		return clean;
	}

	public static function defaultSongNoteStyle():String
	{
		if(PlayState.isPixelStage && textAssetExists('data/notestyles/pixel.json'))
			return 'pixel';
		if(PlayState.isPixelStage && textAssetExists('images/noteSkins/pixel.json'))
			return 'noteSkins/pixel';
		if(textAssetExists('data/notestyles/funkin.json'))
			return 'funkin';
		return defaultNoteSkin;
	}

	public static function songSplashSkinForMustPress(mustPress:Bool):Null<String>
	{
		var skin:String = null;
		if(PlayState.SONG != null)
		{
			skin = PlayState.SONG.splashSkin;
			if(skin == null || skin.trim().length < 1)
			{
				var noteStyle:String = songNoteStyle();
				if(noteStyle != null && noteStyle.length > 0)
				{
					var noteSkinConfig:NoteSkinConfig = getNoteSkinConfig(noteStyle);
					if(noteSkinConfig != null)
						skin = noteSkinConfig.noteSplashAssetPath;
				}
			}
		}
		return skin;
	}

	public static function getSongNoteSkinConfig():NoteSkinConfig
	{
		var noteStyle:String = songNoteStyle();
		if(noteStyle == null || noteStyle.length < 1)
			noteStyle = defaultSongNoteStyle();
		return getNoteSkinConfig(noteStyle);
	}

	public static function resolveNoteStyleUiAsset(assetName:String, fallback:String):String
	{
		return NoteData.noteStyle.ui(assetName, fallback);
	}

	public static function resolveNoteStyleUiSound(assetName:String, fallback:String):String
	{
		return NoteData.noteStyle.uiSound(assetName, fallback);
	}

	public static function noteStyleUiScale(assetName:String, fallback:Float):Float
	{
		return NoteData.noteStyle.uiScale(assetName, fallback);
	}

	public static function noteStyleUiIsPixel(assetName:String, fallback:Bool):Bool
	{
		return NoteData.noteStyle.uiIsPixel(assetName, fallback);
	}

	static function getNoteStyleUiAsset(assetName:String):NoteSkinUiAsset
	{
		if(assetName == null || assetName.length < 1) return null;
		var config:NoteSkinConfig = getSongNoteSkinConfig();
		if(config == null || config.uiAssets == null) return null;
		return config.uiAssets.get(assetName);
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	var noteSkinConfig:NoteSkinConfig;
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayState.SONG != null ? songNoteStyle() : null;
			if(skin == null || skin.length < 1)
				skin = defaultSongNoteStyle() + postfix;
		}
		else rgbShader.enabled = false;

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		if(customSkin == _lastValidChecked || Paths.fileExists('images/$customSkin.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		noteSkinConfig = getNoteSkinConfig(skin);
		if(PlayState.isPixelStage) {
			var assetType:String = isSustainNote ? 'holdNotePixel' : 'notePixel';
			var pixelAsset:String = resolveNoteSkinAsset(skin, noteSkinConfig, assetType);
			if(noteSkinAtlasExists(pixelAsset))
			{
				frames = getNoteSkinAtlas(pixelAsset);
			}
			else
			{
				if(!noteSkinImageExists(pixelAsset))
				{
					var fallbackAsset:String = fallbackNoteSkinAsset(skin, assetType);
					if(noteSkinImageExists(fallbackAsset))
						pixelAsset = fallbackAsset;
				}

				var graphic = getNoteSkinGraphic(pixelAsset);
				if(graphic == null)
				{
					var defaultPixelAsset:String = isSustainNote ? 'noteSkins/pixel/NOTE_assetsENDS' : 'noteSkins/pixel/NOTE_assets';
					graphic = getNoteSkinGraphic(defaultPixelAsset);
					if(graphic != null)
						pixelAsset = defaultPixelAsset;
				}
				if(graphic == null)
					return;

				var columns:Int = noteSkinColumns(noteSkinConfig, assetType);
				var rows:Int = noteSkinRows(noteSkinConfig, assetType);
				if(columns < 1) columns = 1;
				if(rows < 1) rows = 1;
				loadGraphic(graphic, true, Math.floor(graphic.width / columns), Math.floor(graphic.height / rows));
				if(isSustainNote)
					originalHeight = graphic.height / rows;
			}
			loadNoteAnims(assetType);
			antialiasing = false;
			if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
				rgbShader.enabled = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			var noteAsset:String = resolveNoteSkinAsset(skin, noteSkinConfig, isSustainNote ? 'sustain' : 'note');
			if(!noteSkinAtlasExists(noteAsset))
				noteAsset = 'noteSkins/NOTE_assets';
			frames = noteSkinAtlasExists(noteAsset) ? getNoteSkinAtlas(noteAsset) : null;
			if(frames == null)
				return;
			loadNoteAnims(isSustainNote ? 'sustain' : 'note');
			if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
				rgbShader.enabled = false;
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims(assetType:String) {
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			addAnimationFromConfig(animation, colArray[noteData] + 'holdend', noteSkinConfig, colArray[noteData] + 'holdend');
			addAnimationFromConfig(animation, colArray[noteData] + 'hold', noteSkinConfig, colArray[noteData] + 'hold');
		}
		else addAnimationFromConfig(animation, colArray[noteData] + 'Scroll', noteSkinConfig, colArray[noteData] + 'Scroll');

		setGraphicSize(Std.int(width * noteSkinScale(noteSkinConfig, assetType)));
		updateHitbox();
	}

	public static function getNoteSkinConfig(texture:String):NoteSkinConfig
	{
		if(texture == null || texture.length < 1) return createNoteSkinConfig();

		var styleKey:String = noteStyleKey(texture);
		var styleJsonPath:String = 'data/notestyles/$styleKey.json';
		var picoJsonPath:String = styleKey.length > 0 ? picoCustomNoteJsonPath(styleKey) : null;
		var hasPicoJson:Bool = picoJsonPath != null && textAssetExists(picoJsonPath);
		var hasStyleJson:Bool = styleKey.length > 0 && textAssetExists(styleJsonPath);
		var cachePath:String = hasPicoJson ? picoJsonPath : (hasStyleJson ? 'data/notestyles/$styleKey' : 'images/$texture');
		if(noteSkinConfigs.exists(cachePath))
			return noteSkinConfigs.get(cachePath);

		var config:NoteSkinConfig = createNoteSkinConfig();
		var loadedPath:String = null;
		if(hasPicoJson)
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(readNoteSkinText(picoJsonPath));
				if(isNoteStyleJson(raw))
				{
					config = parseNoteSkinConfig(raw);
					loadedPath = picoJsonPath;
				}
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse $picoJsonPath: $e');
			}
		}

		if(loadedPath == null && hasStyleJson)
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(Paths.getTextFromFile(styleJsonPath));
				if(isNoteStyleJson(raw))
				{
					config = parseNoteSkinConfig(raw);
					loadedPath = 'data/notestyles/$styleKey';
				}
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse data/notestyles/$styleKey.json: $e');
			}
		}

		var imagePath:String = 'images/$texture';
		if(loadedPath == null && styleKey.length > 0 && texture.indexOf('/') < 0 && textAssetExists('images/noteSkins/$styleKey.json'))
			imagePath = 'images/noteSkins/$styleKey';
		if(loadedPath == null && textAssetExists('$imagePath.json'))
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$imagePath.json'));
				config = parseNoteSkinConfig(raw);
				loadedPath = imagePath;
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse $imagePath.json: $e');
			}
		}

		noteSkinConfigs.set(loadedPath != null ? loadedPath : cachePath, config);
		return config;
	}

	public static function noteStyleKey(texture:String):String
	{
		if(texture == null) return '';
		var key:String = texture.trim().replace('\\', '/');
		if(key.length < 1) return '';
		if(key.startsWith('images/noteSkins/'))
			key = key.substr('images/noteSkins/'.length);
		else if(key.startsWith('noteSkins/'))
			key = key.substr('noteSkins/'.length);
		else if(key.startsWith('data/notestyles/'))
			key = key.substr('data/notestyles/'.length);
		else if(key.startsWith('notestyles/'))
			key = key.substr('notestyles/'.length);

		for (extension in ['.json', '.png', '.xml'])
		{
			if(key.endsWith(extension))
			{
				key = key.substr(0, key.length - extension.length);
				break;
			}
		}
		return key.indexOf('/') >= 0 ? '' : key;
	}

	static function isNoteStyleJson(raw:Dynamic):Bool
	{
		return raw != null && !Std.isOfType(raw, Array) && (Reflect.hasField(raw, 'assets') || Reflect.hasField(raw, 'animations'));
	}

	public static function createNoteSkinConfig():NoteSkinConfig
	{
		return {
			animations: new Map(),
			uiAssets: new Map(),
			scale: 0.7,
			noteScale: 0.7,
			holdScale: 0.7,
			strumScale: 0.7,
			pixelNoteScale: PlayState.daPixelZoom,
			pixelHoldScale: PlayState.daPixelZoom,
			pixelStrumScale: PlayState.daPixelZoom,
			allowRGB: true,
			allowPixel: true,
			noteAssetPath: null,
			holdAssetPath: null,
			strumAssetPath: null,
			pixelNoteAssetPath: null,
			pixelHoldAssetPath: null,
			pixelStrumAssetPath: null,
			noteSplashAssetPath: null,
			holdNoteCover: createHoldNoteCoverConfig(),
			pixelNoteColumns: 4,
			pixelNoteRows: 5,
			pixelHoldColumns: 4,
			pixelHoldRows: 2,
			pixelStrumColumns: 4,
			pixelStrumRows: 5
		};
	}

	static function createHoldNoteCoverConfig():HoldNoteCoverConfig
	{
		return {
			enabled: false,
			isPixel: false,
			assetPaths: [null, null, null, null],
			startAnims: [null, null, null, null],
			holdAnims: [null, null, null, null],
			endAnims: [null, null, null, null],
			offsets: [0, 0],
			scale: 1,
			centerOnStrum: true,
			columns: 1,
			rows: 1
		};
	}

	static function parseNoteSkinConfig(raw:Dynamic):NoteSkinConfig
	{
		var config:NoteSkinConfig = createNoteSkinConfig();
		if(raw == null) return config;

		config.scale = noteSkinFloat(Reflect.field(raw, 'scale'), config.scale);
		config.noteScale = config.scale;
		config.holdScale = config.scale;
		config.strumScale = config.scale;
		config.pixelNoteScale = PlayState.daPixelZoom;
		config.pixelHoldScale = PlayState.daPixelZoom;
		config.pixelStrumScale = PlayState.daPixelZoom;
		config.allowRGB = noteSkinBool(Reflect.field(raw, 'allowRGB'), config.allowRGB);
		config.allowPixel = noteSkinBool(Reflect.field(raw, 'allowPixel'), config.allowPixel);
		parseNoteSplashAsset(config, firstNoteSkinField(raw, ['noteSplashes', 'noteSplash', 'splashSkin']));

		var assets:Dynamic = Reflect.field(raw, 'assets');
		if(assets != null)
		{
			parseFunkinNoteStyleAsset(config, Reflect.field(assets, 'note'), 'note');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['sustain', 'sustainNote', 'holdNote']), 'sustain');
			parseFunkinNoteStyleAsset(config, Reflect.field(assets, 'noteStrumline'), 'noteStrumline');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['notePixel', 'pixelNote']), 'notePixel');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['holdNotePixel', 'pixelHoldNote', 'sustainPixel', 'pixelSustain', 'sustainNotePixel']), 'holdNotePixel');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['noteStrumlinePixel', 'pixelNoteStrumline']), 'noteStrumlinePixel');
			parseNoteSplashAsset(config, firstNoteSkinField(assets, ['noteSplashes', 'noteSplash', 'splash']));
			var holdNoteCoverPixel:Dynamic = firstNoteSkinField(assets, ['holdNoteCoverPixel', 'pixelHoldNoteCover', 'holdCoverPixel', 'pixelHoldCover']);
			if(holdNoteCoverPixel != null)
				parseHoldNoteCoverAsset(config, holdNoteCoverPixel, true);
			else
				parseHoldNoteCoverAsset(config, firstNoteSkinField(assets, ['holdNoteCover', 'holdCover']));
			parseNoteStyleUiAssets(config, assets);

			if(config.strumAssetPath == null && config.noteAssetPath != null)
				config.strumAssetPath = config.noteAssetPath;
			if(config.strumScale == config.scale)
				config.strumScale = config.noteScale;
			if(config.holdAssetPath == null && config.noteAssetPath != null)
				config.holdAssetPath = config.noteAssetPath;
			if(config.holdScale == config.scale)
				config.holdScale = config.noteScale;
		}

		var animations:Dynamic = Reflect.field(raw, 'animations');
		if(animations != null)
		{
			for (key in Reflect.fields(animations))
			{
				var anim = parseNoteSkinAnim(Reflect.field(animations, key));
				if(anim != null)
					config.animations.set(key, anim);
			}
		}
		return config;
	}

	static function parseNoteStyleUiAssets(config:NoteSkinConfig, assets:Dynamic)
	{
		var keys:Array<String> = [
			'countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo',
			'judgementMarvelous', 'judgementPerfect', 'judgementSick', 'judgementGood', 'judgementBad', 'judgementShit',
			'combo'
		];
		for (i in 0...10)
			keys.push('comboNumber$i');

		for (key in keys)
			parseNoteStyleUiAsset(config, key, Reflect.field(assets, key));
	}

	static function parseNoteStyleUiAsset(config:NoteSkinConfig, key:String, raw:Dynamic)
	{
		if(raw == null) return;

		var assetPath:String = null;
		var audioPath:String = null;
		var scale:Null<Float> = null;
		var isPixel:Null<Bool> = null;

		if(Std.isOfType(raw, String))
		{
			assetPath = cleanFunkinAssetPath(raw);
		}
		else
		{
			assetPath = cleanFunkinAssetPath(firstNoteSkinField(raw, ['assetPath', 'path', 'texture']));
			var data:Dynamic = Reflect.field(raw, 'data');
			audioPath = cleanFunkinSoundPath(firstNoteSkinField(raw, ['audioPath', 'soundPath', 'sound']));
			if(audioPath == null && data != null)
				audioPath = cleanFunkinSoundPath(firstNoteSkinField(data, ['audioPath', 'soundPath', 'sound']));

			var rawScale:Dynamic = Reflect.field(raw, 'scale');
			if(rawScale != null)
				scale = noteSkinFloat(rawScale, 1);

			var rawIsPixel:Dynamic = Reflect.field(raw, 'isPixel');
			if(rawIsPixel != null)
				isPixel = noteSkinBool(rawIsPixel, false);
		}

		if(assetPath != null || audioPath != null || scale != null || isPixel != null)
		{
			config.uiAssets.set(key, {
				assetPath: assetPath,
				audioPath: audioPath,
				scale: scale,
				isPixel: isPixel
			});
		}
	}

	static function parseFunkinNoteStyleAsset(config:NoteSkinConfig, asset:Dynamic, assetType:String)
	{
		if(asset == null) return;
		assetType = normalizeNoteSkinAssetType(assetType);

		var isPixel:Bool = noteSkinBool(Reflect.field(asset, 'isPixel'), false);
		if(isPixel)
		{
			switch(assetType)
			{
				case 'note':
					parseFunkinNoteStyleAsset(config, asset, 'notePixel');
					return;
				case 'holdNote':
					parseFunkinNoteStyleAsset(config, asset, 'holdNotePixel');
					return;
				case 'noteStrumline':
					parseFunkinNoteStyleAsset(config, asset, 'noteStrumlinePixel');
					return;
			}
		}

		var assetPath = cleanFunkinAssetPath(Reflect.field(asset, 'assetPath'));
		var assetScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.scale);
		switch(assetType)
		{
			case 'note':
				config.noteAssetPath = assetPath;
				config.noteScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['left', 'purpleScroll'],
					['down', 'blueScroll'],
					['up', 'greenScroll'],
					['right', 'redScroll'],
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold'],
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'holdNote':
				config.holdAssetPath = assetPath;
				config.holdScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold']
				]);
			case 'noteStrumline':
				config.strumAssetPath = assetPath;
				config.strumScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'notePixel':
				config.pixelNoteAssetPath = assetPath;
				config.pixelNoteScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelNoteScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['left', 'purpleScroll'],
					['down', 'blueScroll'],
					['up', 'greenScroll'],
					['right', 'redScroll'],
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'holdNotePixel':
				config.pixelHoldAssetPath = assetPath;
				config.pixelHoldScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelHoldScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold']
				]);
			case 'noteStrumlinePixel':
				config.pixelStrumAssetPath = assetPath;
				config.pixelStrumScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelStrumScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
		}
	}

	static function parseNoteSplashAsset(config:NoteSkinConfig, asset:Dynamic)
	{
		if(asset == null) return;

		var path:String = null;
		if(Std.isOfType(asset, String))
			path = cleanFunkinAssetPath(asset);
		else
			path = cleanFunkinAssetPath(firstNoteSkinField(asset, ['assetPath', 'path', 'texture']));

		if(path != null && path.length > 0)
			config.noteSplashAssetPath = path;
	}

	static function parseHoldNoteCoverAsset(config:NoteSkinConfig, asset:Dynamic, defaultIsPixel:Bool = false)
	{
		if(asset == null) return;

		var cover:HoldNoteCoverConfig = createHoldNoteCoverConfig();
		var data:Dynamic = Reflect.field(asset, 'data');
		cover.enabled = noteSkinBool(firstNoteSkinField(asset, ['enabled']), noteSkinBool(data != null ? Reflect.field(data, 'enabled') : null, true));
		cover.isPixel = noteSkinBool(firstNoteSkinField(asset, ['isPixel', 'pixel']), defaultIsPixel);
		cover.scale = noteSkinFloat(Reflect.field(asset, 'scale'), cover.scale);
		cover.offsets = noteSkinFloatArray(firstNoteSkinField(asset, ['offsets', 'offset']), cover.offsets, 2);
		cover.centerOnStrum = noteSkinBool(firstNoteSkinField(asset, ['centerOnStrum', 'centered', 'center']), cover.centerOnStrum);
		cover.columns = noteSkinInt(firstNoteSkinField(asset, ['columns', 'cols', 'frameColumns']), cover.columns);
		cover.rows = noteSkinInt(firstNoteSkinField(asset, ['rows', 'frameRows']), cover.rows);

		var defaultAsset:String = cleanFunkinAssetPath(firstNoteSkinField(asset, ['assetPath', 'path', 'texture']));
		var directionFields:Array<String> = ['left', 'down', 'up', 'right'];
		var fallbackAssets:Array<String> = cover.isPixel ? [null, null, null, null] : ['holdCover/holdCoverPurple', 'holdCover/holdCoverBlue', 'holdCover/holdCoverGreen', 'holdCover/holdCoverRed'];

		for (i in 0...directionFields.length)
		{
			var rawDirection:Dynamic = data != null ? Reflect.field(data, directionFields[i]) : null;
			var directionAsset:String = rawDirection != null ? cleanFunkinAssetPath(firstNoteSkinField(rawDirection, ['assetPath', 'path', 'texture'])) : null;
			cover.assetPaths[i] = directionAsset != null && directionAsset.length > 0 ? directionAsset : (defaultAsset != null && defaultAsset.length > 0 ? defaultAsset : fallbackAssets[i]);

			if(rawDirection != null)
			{
				cover.startAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'start'));
				cover.holdAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'hold'));
				cover.endAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'end'));
			}
		}

		config.holdNoteCover = cover;
	}

	static function readPixelGrid(config:NoteSkinConfig, asset:Dynamic, assetType:String)
	{
		var columns:Int = noteSkinInt(firstNoteSkinField(asset, ['columns', 'cols', 'frameColumns']), noteSkinColumns(config, assetType));
		var rows:Int = noteSkinInt(firstNoteSkinField(asset, ['rows', 'frameRows']), noteSkinRows(config, assetType));
		switch(assetType)
		{
			case 'notePixel':
				config.pixelNoteColumns = columns;
				config.pixelNoteRows = rows;
			case 'holdNotePixel':
				config.pixelHoldColumns = columns;
				config.pixelHoldRows = rows;
			case 'noteStrumlinePixel':
				config.pixelStrumColumns = columns;
				config.pixelStrumRows = rows;
		}
	}

	static function mapFunkinAnimations(config:NoteSkinConfig, data:Dynamic, keys:Array<Array<String>>)
	{
		if(data == null) return;
		for (pair in keys)
		{
			var raw = Reflect.field(data, pair[0]);
			var anim = parseNoteSkinAnim(raw);
			if(anim != null)
				config.animations.set(pair[1], anim);
		}
	}

	static function parseNoteSkinAnim(raw:Dynamic):NoteSkinAnim
	{
		if(raw == null) return null;

		var prefixValue:Dynamic = Reflect.field(raw, 'prefix');
		var indices:Array<Int> = noteSkinIntArray(firstNoteSkinField(raw, ['indices', 'frameIndices', 'frames']));
		if(prefixValue == null && indices.length < 1) return null;

		var fps:Null<Int> = null;
		var rawFps:Dynamic = firstNoteSkinField(raw, ['fps', 'frameRate', 'framerate']);
		if(rawFps != null)
		{
			if(Std.isOfType(rawFps, Array))
			{
				var fpsArray:Array<Dynamic> = cast rawFps;
				if(fpsArray.length > 0) fps = noteSkinInt(fpsArray[0], 24);
			}
			else fps = noteSkinInt(rawFps, 24);
		}

		return {
			prefix: prefixValue != null ? Std.string(prefixValue) : null,
			fps: fps,
			loop: firstNoteSkinField(raw, ['loop', 'looped']) != null ? noteSkinBool(firstNoteSkinField(raw, ['loop', 'looped']), true) : null,
			indices: indices
		};
	}

	static function firstNoteSkinField(raw:Dynamic, names:Array<String>):Dynamic
	{
		for (name in names)
		{
			var value = Reflect.field(raw, name);
			if(value != null) return value;
		}
		return null;
	}

	public static function resolveNoteSkinAsset(texture:String, config:NoteSkinConfig, assetType:String):String
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config != null)
		{
			var assetPath:String = switch(assetType)
			{
				case 'note': config.noteAssetPath;
				case 'holdNote': config.holdAssetPath != null ? config.holdAssetPath : config.noteAssetPath;
				case 'noteStrumline': config.strumAssetPath != null ? config.strumAssetPath : config.noteAssetPath;
				case 'notePixel': config.pixelNoteAssetPath != null ? config.pixelNoteAssetPath : config.noteAssetPath;
				case 'holdNotePixel': config.pixelHoldAssetPath != null ? config.pixelHoldAssetPath : (config.holdAssetPath != null ? config.holdAssetPath : config.noteAssetPath);
				case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumAssetPath : (config.pixelNoteAssetPath != null ? config.pixelNoteAssetPath : config.strumAssetPath);
				default: null;
			}

			if(imageAssetExists(assetPath))
				return assetPath;

			var relativeAsset:String = resolveStyleRelativeNoteSkinAsset(texture, assetPath, assetType);
			if(relativeAsset != null)
				return relativeAsset;
		}
		var fallbackAsset:String = fallbackNoteSkinAsset(texture, assetType);
		if(fallbackAsset != null)
			return fallbackAsset;
		return texture;
	}

	static function resolveStyleRelativeNoteSkinAsset(texture:String, assetPath:String, assetType:String):String
	{
		if(assetPath == null || assetPath.length < 1)
			return null;

		assetType = normalizeNoteSkinAssetType(assetType);
		var styleKey:String = noteStyleKey(texture);
		var cleanAsset:String = cleanFunkinAssetPath(assetPath);
		if(cleanAsset == null || cleanAsset.length < 1)
			return null;

		var candidates:Array<String> = [];
		if(cleanAsset.indexOf('/') < 0)
		{
			if(styleKey == 'pixel' || assetType == 'notePixel' || assetType == 'holdNotePixel' || assetType == 'noteStrumlinePixel')
				candidates.push('noteSkins/pixel/$cleanAsset');
			if(styleKey.length > 0 && styleKey != 'funkin' && styleKey != 'pixel')
				candidates.push('noteSkins/$styleKey/$cleanAsset');
			candidates.push('noteSkins/$cleanAsset');
		}

		for(candidate in candidates)
		{
			if(imageAssetExists(candidate))
				return candidate;
		}
		return null;
	}

	static function fallbackNoteSkinAsset(texture:String, assetType:String):String
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		var styleKey:String = noteStyleKey(texture);
		var cleanTexture:String = texture == null ? '' : texture.trim().replace('\\', '/');
		var isPixelStyle:Bool = styleKey == 'pixel' || cleanTexture == 'pixel' || cleanTexture.endsWith('/pixel');
		var candidates:Array<String> = [];

		switch(assetType)
		{
			case 'notePixel', 'noteStrumlinePixel':
				if(isPixelStyle)
					candidates = ['noteSkins/pixel/NOTE_assets', 'weeb/pixelUI/arrows-pixels-rgb', 'weeb/pixelUI/arrows-pixels', 'pixelUI/noteSkins/NOTE_assets'];
				else if(styleKey.length > 0)
					candidates = ['noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
			case 'holdNotePixel':
				if(isPixelStyle)
					candidates = ['noteSkins/pixel/NOTE_assetsENDS', 'weeb/pixelUI/arrowEndsNew-rgb', 'weeb/pixelUI/arrowEndsNew', 'pixelUI/noteSkins/NOTE_assetsENDS'];
				else if(styleKey.length > 0)
					candidates = ['noteSkins/$styleKey/NOTE_assetsENDS', 'noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
			case 'note', 'holdNote', 'noteStrumline':
				if(styleKey.length > 0 && styleKey != 'funkin')
					candidates = ['noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
				else if(styleKey == 'funkin' || cleanTexture == 'funkin')
					candidates = ['noteSkins/NOTE_assets'];
			default:
		}

		for(candidate in candidates)
		{
			if(imageAssetExists(candidate))
				return candidate;
		}
		return null;
	}

	static function imageAssetExists(assetPath:String):Bool
	{
		if(assetPath == null || assetPath.length < 1)
			return false;

		#if sys
		var picoImage:String = picoNoteSkinAssetPath(assetPath, 'png');
		if(picoImage != null && sys.FileSystem.exists(picoImage))
			return true;
		#end

		var key:String = 'images/$assetPath.png';
		if(Paths.fileExists(key, IMAGE))
			return true;
		#if sys
		if(sys.FileSystem.exists(Paths.getPath(key, IMAGE, null, true)))
			return true;
		#end
		return false;
	}

	public static function noteSkinImageExists(assetPath:String):Bool
	{
		return imageAssetExists(assetPath);
	}

	public static function noteSkinAtlasExists(assetPath:String):Bool
	{
		return imageAssetExists(assetPath) && textAssetExists('images/$assetPath.xml');
	}

	static function textAssetExists(key:String):Bool
	{
		if(key == null || key.length < 1)
			return false;

		#if sys
		if(key.startsWith('assets/') && sys.FileSystem.exists(key))
			return true;
		#end

		if(Paths.fileExists(key, TEXT))
			return true;
		#if sys
		if(sys.FileSystem.exists(Paths.getPath(key, TEXT, null, true)))
			return true;
		#end
		return false;
	}

	public static function getNoteSkinGraphic(assetPath:String):FlxGraphic
	{
		#if sys
		var picoImage:String = picoNoteSkinAssetPath(assetPath, 'png');
		if(picoImage != null && sys.FileSystem.exists(picoImage))
		{
			var bitmap:BitmapData = BitmapData.fromFile(picoImage);
			if(bitmap != null)
				return Paths.cacheBitmap(picoImage, null, bitmap);
		}
		#end
		return Paths.image(assetPath);
	}

	public static function getNoteSkinAtlas(assetPath:String):FlxAtlasFrames
	{
		#if sys
		var picoXml:String = picoNoteSkinAssetPath(assetPath, 'xml');
		if(picoXml != null && sys.FileSystem.exists(picoXml))
		{
			var graphic:FlxGraphic = getNoteSkinGraphic(assetPath);
			if(graphic != null)
				return FlxAtlasFrames.fromSparrow(graphic, sys.io.File.getContent(picoXml));
		}
		#end
		return Paths.getSparrowAtlas(assetPath);
	}

	static function picoCustomNoteJsonPath(styleKey:String):String
	{
		if(styleKey == null || styleKey.length < 1)
			return null;
		return Paths.getPicoFunkinPath('game/custom-notes/$styleKey.json');
	}

	static function picoNoteSkinAssetPath(assetPath:String, extension:String):String
	{
		var clean:String = cleanFunkinAssetPath(assetPath);
		if(clean == null || clean.length < 1)
			return null;

		if(clean.startsWith('game/'))
			return Paths.getPicoFunkinPath('$clean.$extension');
		if(clean.startsWith('ui/notes/'))
			return Paths.getPicoFunkinPath('game/$clean.$extension');
		return null;
	}

	static function readNoteSkinText(key:String):String
	{
		#if sys
		if(key != null && key.startsWith('assets/') && sys.FileSystem.exists(key))
			return sys.io.File.getContent(key);
		#end
		return Paths.getTextFromFile(key, true);
	}

	public static function holdNoteCoverEnabled(config:NoteSkinConfig):Bool
	{
		return config != null && config.holdNoteCover != null && config.holdNoteCover.enabled;
	}

	public static function resolveHoldNoteCoverAsset(config:NoteSkinConfig, noteData:Int):String
	{
		if(!holdNoteCoverEnabled(config))
			return null;

		var id:Int = FlxMath.wrap(noteData, 0, 3);
		var assetPath:String = config.holdNoteCover.assetPaths[id];
		if(imageAssetExists(assetPath))
			return assetPath;

		var cleanAsset:String = cleanFunkinAssetPath(assetPath);
		if(cleanAsset != null && cleanAsset.indexOf('/') < 0)
		{
			if(config.holdNoteCover.isPixel)
			{
				var pixelCandidate:String = 'noteSkins/pixel/$cleanAsset';
				if(imageAssetExists(pixelCandidate))
					return pixelCandidate;
			}

			var candidate:String = 'holdCover/$cleanAsset';
			if(imageAssetExists(candidate))
				return candidate;
		}

		if(config.holdNoteCover.isPixel)
			return null;

		var fallback:Array<String> = ['holdCover/holdCoverPurple', 'holdCover/holdCoverBlue', 'holdCover/holdCoverGreen', 'holdCover/holdCoverRed'];
		return imageAssetExists(fallback[id]) ? fallback[id] : null;
	}

	public static function holdNoteCoverScale(config:NoteSkinConfig):Float
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.scale : 1;
	}

	public static function holdNoteCoverIsPixel(config:NoteSkinConfig):Bool
	{
		return holdNoteCoverEnabled(config) && config.holdNoteCover.isPixel;
	}

	public static function holdNoteCoverColumns(config:NoteSkinConfig):Int
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.columns : 1;
	}

	public static function holdNoteCoverRows(config:NoteSkinConfig):Int
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.rows : 1;
	}

	public static function holdNoteCoverOffset(config:NoteSkinConfig):Array<Float>
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.offsets : [0, 0];
	}

	public static function holdNoteCoverCenterOnStrum(config:NoteSkinConfig):Bool
	{
		return holdNoteCoverEnabled(config) && config.holdNoteCover.centerOnStrum;
	}

	public static function addHoldNoteCoverAnimation(controller:FlxAnimationController, animName:String, config:NoteSkinConfig, noteData:Int, coverPart:String):Bool
	{
		if(!holdNoteCoverEnabled(config))
			return false;

		var id:Int = FlxMath.wrap(noteData, 0, 3);
		var anim:NoteSkinAnim = switch(coverPart)
		{
			case 'start': config.holdNoteCover.startAnims[id];
			case 'end': config.holdNoteCover.endAnims[id];
			default: config.holdNoteCover.holdAnims[id];
		}

		var fallbackColors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];
		var fallbackPrefix:String = switch(coverPart)
		{
			case 'start': 'holdCoverStart${fallbackColors[id]}';
			case 'end': 'holdCoverEnd${fallbackColors[id]}';
			default: 'holdCover${fallbackColors[id]}';
		}

		if(anim == null)
			return addAnimationFromConfig(controller, animName, null, '', fallbackPrefix, 24, coverPart == 'hold');

		var tempConfig:NoteSkinConfig = createNoteSkinConfig();
		tempConfig.animations.set(animName, anim);
		return addAnimationFromConfig(controller, animName, tempConfig, animName, fallbackPrefix, 24, coverPart == 'hold');
	}

	public static function noteSkinScale(config:NoteSkinConfig, assetType:String):Float
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return 0.7;
		return switch(assetType)
		{
			case 'note': config.noteScale;
			case 'holdNote': config.holdScale;
			case 'noteStrumline': config.strumScale;
			case 'notePixel': config.pixelNoteScale;
			case 'holdNotePixel': config.pixelHoldScale;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumScale : config.pixelNoteScale;
			default: config.scale;
		}
	}

	public static function noteSkinColumns(config:NoteSkinConfig, assetType:String):Int
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return assetType == 'holdNotePixel' ? 4 : 4;
		return switch(assetType)
		{
			case 'notePixel': config.pixelNoteColumns;
			case 'holdNotePixel': config.pixelHoldColumns;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumColumns : config.pixelNoteColumns;
			default: 1;
		}
	}

	public static function noteSkinRows(config:NoteSkinConfig, assetType:String):Int
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return assetType == 'holdNotePixel' ? 2 : 5;
		return switch(assetType)
		{
			case 'notePixel': config.pixelNoteRows;
			case 'holdNotePixel': config.pixelHoldRows;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumRows : config.pixelNoteRows;
			default: 1;
		}
	}

	public static function normalizeNoteSkinAssetType(assetType:String):String
	{
		if(assetType == 'sustain' || assetType == 'sustainNote')
			return 'holdNote';
		if(assetType == 'sustainPixel' || assetType == 'pixelSustain' || assetType == 'sustainNotePixel')
			return 'holdNotePixel';
		return assetType;
	}

	static function cleanFunkinAssetPath(value:Dynamic):String
	{
		if(value == null) return null;
		var path = Std.string(value).trim();
		if(path.length < 1 || path == 'null') return null;

		if(path.contains(':'))
			path = path.substr(path.indexOf(':') + 1);

		if(path.startsWith('images/'))
			path = path.substr('images/'.length);
		if(path.startsWith('assets/images/'))
			path = path.substr('assets/images/'.length);
		for (extension in ['.png', '.xml', '.json'])
		{
			if(path.endsWith(extension))
			{
				path = path.substr(0, path.length - extension.length);
				break;
			}
		}

		return path;
	}

	static function cleanFunkinSoundPath(value:Dynamic):String
	{
		if(value == null) return null;
		var path = Std.string(value).trim();
		if(path.length < 1 || path == 'null') return null;

		if(path.contains(':'))
			path = path.substr(path.indexOf(':') + 1);

		if(path.startsWith('sounds/'))
			path = path.substr('sounds/'.length);
		if(path.startsWith('assets/sounds/'))
			path = path.substr('assets/sounds/'.length);
		for (extension in ['.ogg', '.mp3', '.wav'])
		{
			if(path.endsWith(extension))
			{
				path = path.substr(0, path.length - extension.length);
				break;
			}
		}

		return path;
	}

	public static function addAnimationFromConfig(controller:FlxAnimationController, animName:String, config:NoteSkinConfig, configKey:String, ?fallbackPrefix:String, fallbackFps:Int = 24, fallbackLoop:Bool = true):Bool
	{
		var prefix:String = fallbackPrefix;
		var fps:Int = fallbackFps;
		var loop:Bool = fallbackLoop;
		var indices:Array<Int> = null;

		var anim:NoteSkinAnim = config != null ? config.animations.get(configKey) : null;
		if(anim != null)
		{
			if(anim.prefix != null && anim.prefix.length > 0) prefix = anim.prefix;
			if(anim.fps != null) fps = anim.fps;
			if(anim.loop != null) loop = anim.loop;
			if(anim.indices != null && anim.indices.length > 0) indices = anim.indices;
		}

		if(indices != null && indices.length > 0 && (prefix == null || prefix.length < 1))
			controller.add(animName, indices, fps, loop);
		else if(indices != null && indices.length > 0)
			controller.addByIndices(animName, prefix, indices, '', fps, loop);
		else if(prefix != null && prefix.length > 0)
			controller.addByPrefix(animName, prefix, fps, loop);
		else return false;

		return true;
	}

	static function noteSkinFloat(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function noteSkinFloatArray(value:Dynamic, fallback:Array<Float>, minimumLength:Int = 0):Array<Float>
	{
		var result:Array<Float> = [];
		if(value != null)
		{
			if(Std.isOfType(value, Array))
			{
				var array:Array<Dynamic> = cast value;
				for (item in array)
				{
					var parsed:Float = Std.parseFloat(Std.string(item));
					if(!Math.isNaN(parsed)) result.push(parsed);
				}
			}
			else
			{
				for (item in Std.string(value).split(','))
				{
					var parsed:Float = Std.parseFloat(item.trim());
					if(!Math.isNaN(parsed)) result.push(parsed);
				}
			}
		}

		for (i in result.length...minimumLength)
			result.push(fallback != null && i < fallback.length ? fallback[i] : 0);
		return result.length > 0 ? result : fallback.copy();
	}

	static function noteSkinInt(value:Dynamic, fallback:Int):Int
	{
		if(value == null) return fallback;
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	static function noteSkinBool(value:Dynamic, fallback:Bool):Bool
	{
		if(value == null) return fallback;
		if(Std.isOfType(value, Bool)) return value;

		var text = Std.string(value).trim().toLowerCase();
		if(text == 'true' || text == '1') return true;
		if(text == 'false' || text == '0') return false;
		return fallback;
	}

	static function noteSkinIntArray(value:Dynamic):Array<Int>
	{
		var result:Array<Int> = [];
		if(value == null) return result;

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			for (item in array)
			{
				var parsed:Null<Int> = Std.parseInt(Std.string(item));
				if(parsed != null) result.push(parsed);
			}
		}
		else
		{
			for (item in Std.string(value).split(','))
			{
				var parsed:Null<Int> = Std.parseInt(item.trim());
				if(parsed != null) result.push(parsed);
			}
		}
		return result;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}