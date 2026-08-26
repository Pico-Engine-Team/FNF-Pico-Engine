package funkin.data.editors;

import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.config.StrumNote;

import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class NoteSkinEditorState extends MusicBeatState
{
	static inline final PREVIEW_SKIN:String = 'noteSkins/__editor_preview';

	static var lastSkin:String = 'funkin';

	var previewGroup:FlxSpriteGroup;
	var UI:PsychUIBox;

	var skinInputText:PsychUIInputText;
	var nameInputText:PsychUIInputText;
	var fallbackInputText:PsychUIInputText;
	var noteAssetInputText:PsychUIInputText;
	var holdAssetInputText:PsychUIInputText;
	var strumAssetInputText:PsychUIInputText;
	var splashAssetInputText:PsychUIInputText;

	var noteScaleStepper:PsychUINumericStepper;
	var holdScaleStepper:PsychUINumericStepper;
	var strumScaleStepper:PsychUINumericStepper;
	var noteColumnsStepper:PsychUINumericStepper;
	var noteRowsStepper:PsychUINumericStepper;
	var holdColumnsStepper:PsychUINumericStepper;
	var holdRowsStepper:PsychUINumericStepper;
	var strumColumnsStepper:PsychUINumericStepper;
	var strumRowsStepper:PsychUINumericStepper;

	var allowRGBCheckBox:PsychUICheckBox;
	var allowPixelCheckBox:PsychUICheckBox;
	var pixelModeCheckBox:PsychUICheckBox;

	var outputText:FlxText;
	var _file:FileReference;

	override function create()
	{
		FlxG.mouse.visible = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Note Skin Editor');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF4A4A4A;
		add(bg);

		previewGroup = new FlxSpriteGroup();
		add(previewGroup);

		UI = new PsychUIBox(FlxG.width - 420, 20, 400, 560, ['NoteSkin']);
		UI.canMove = UI.canMinimize = false;
		add(UI);

		outputText = new FlxText(10, FlxG.height - 44, FlxG.width - 20, '', 16);
		outputText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		outputText.borderSize = 1;
		add(outputText);

		addNoteSkinTab();
		applyNormalTemplate(false);
		reloadJsonFromAssets(false);
		updatePreview();

		super.create();
	}

	function addNoteSkinTab()
	{
		var tab = UI.getTab('NoteSkin').menu;
		var x:Float = 15;
		var y:Float = 20;
		var labelWidth:Int = 150;
		var inputWidth:Int = 160;

		addLabel(tab, x, y, 'Notestyle JSON:');
		skinInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, lastSkin, 8);
		skinInputText.onChange = function(old:String, cur:String)
		{
			lastSkin = normalizeSkinPath(cur);
		}
		tab.add(skinInputText);

		var reloadButton = new PsychUIButton(x + labelWidth + inputWidth + 8, y - 8, 'Reload', function()
		{
			reloadJsonFromAssets(true);
		}, 65, 22);
		tab.add(reloadButton);

		y += 36;
		addLabel(tab, x, y, 'Display Name:');
		nameInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, 'Funkin', 8);
		nameInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(nameInputText);

		y += 30;
		addLabel(tab, x, y, 'Fallback:');
		fallbackInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, '', 8);
		fallbackInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(fallbackInputText);

		y += 38;
		addLabel(tab, x, y, 'Note Asset:');
		noteAssetInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, 'noteSkins/NOTE_assets', 8);
		noteAssetInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(noteAssetInputText);

		y += 30;
		addLabel(tab, x, y, 'Hold Asset:');
		holdAssetInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, 'noteSkins/NOTE_assets', 8);
		holdAssetInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(holdAssetInputText);

		y += 30;
		addLabel(tab, x, y, 'Strum Asset:');
		strumAssetInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, 'noteSkins/NOTE_assets', 8);
		strumAssetInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(strumAssetInputText);

		y += 30;
		addLabel(tab, x, y, 'Splash Asset:');
		splashAssetInputText = new PsychUIInputText(x + labelWidth, y - 4, inputWidth, 'noteSplashes/noteSplashes', 8);
		splashAssetInputText.onChange = function(old:String, cur:String) updatePreview();
		tab.add(splashAssetInputText);

		y += 38;
		addLabel(tab, x, y, 'Note / Hold / Strum Scale:');
		noteScaleStepper = new PsychUINumericStepper(x + labelWidth, y - 4, 0.05, 0.7, 0.05, 10, 2, 55);
		holdScaleStepper = new PsychUINumericStepper(x + labelWidth + 60, y - 4, 0.05, 0.7, 0.05, 10, 2, 55);
		strumScaleStepper = new PsychUINumericStepper(x + labelWidth + 120, y - 4, 0.05, 0.7, 0.05, 10, 2, 55);
		noteScaleStepper.onValueChange = holdScaleStepper.onValueChange = strumScaleStepper.onValueChange = updatePreview;
		tab.add(noteScaleStepper);
		tab.add(holdScaleStepper);
		tab.add(strumScaleStepper);

		y += 38;
		pixelModeCheckBox = new PsychUICheckBox(x, y, 'Pixel style', 95);
		pixelModeCheckBox.onClick = function()
		{
			allowPixelCheckBox.checked = pixelModeCheckBox.checked;
			updatePreview();
		}
		tab.add(pixelModeCheckBox);

		allowRGBCheckBox = new PsychUICheckBox(x + 115, y, 'Allow RGB', 90);
		allowRGBCheckBox.checked = true;
		allowRGBCheckBox.onClick = updatePreview;
		tab.add(allowRGBCheckBox);

		allowPixelCheckBox = new PsychUICheckBox(x + 230, y, 'Allow Pixel', 95);
		allowPixelCheckBox.onClick = updatePreview;
		tab.add(allowPixelCheckBox);

		y += 42;
		addLabel(tab, x, y, 'Pixel Note Col/Row:');
		noteColumnsStepper = new PsychUINumericStepper(x + labelWidth, y - 4, 1, 4, 1, 64, 0, 45);
		noteRowsStepper = new PsychUINumericStepper(x + labelWidth + 55, y - 4, 1, 5, 1, 64, 0, 45);
		tab.add(noteColumnsStepper);
		tab.add(noteRowsStepper);

		y += 28;
		addLabel(tab, x, y, 'Pixel Hold Col/Row:');
		holdColumnsStepper = new PsychUINumericStepper(x + labelWidth, y - 4, 1, 4, 1, 64, 0, 45);
		holdRowsStepper = new PsychUINumericStepper(x + labelWidth + 55, y - 4, 1, 2, 1, 64, 0, 45);
		tab.add(holdColumnsStepper);
		tab.add(holdRowsStepper);

		y += 28;
		addLabel(tab, x, y, 'Pixel Strum Col/Row:');
		strumColumnsStepper = new PsychUINumericStepper(x + labelWidth, y - 4, 1, 4, 1, 64, 0, 45);
		strumRowsStepper = new PsychUINumericStepper(x + labelWidth + 55, y - 4, 1, 5, 1, 64, 0, 45);
		noteColumnsStepper.onValueChange = noteRowsStepper.onValueChange = holdColumnsStepper.onValueChange = holdRowsStepper.onValueChange = strumColumnsStepper.onValueChange = strumRowsStepper.onValueChange = updatePreview;
		tab.add(strumColumnsStepper);
		tab.add(strumRowsStepper);

		y += 48;
		var templateButton = new PsychUIButton(x, y, 'Normal Template', function()
		{
			applyNormalTemplate(true);
		}, 115, 24);
		tab.add(templateButton);

		var pixelTemplateButton = new PsychUIButton(x + 125, y, 'Pixel Template', function()
		{
			applyPixelTemplate(true);
		}, 105, 24);
		tab.add(pixelTemplateButton);

		var previewButton = new PsychUIButton(x + 240, y, 'Preview', updatePreview, 75, 24);
		tab.add(previewButton);

		y += 36;
		var saveButton = new PsychUIButton(x, y, 'Save JSON', saveNoteSkin, 100, 26);
		saveButton.normalStyle.bgColor = FlxColor.GREEN;
		tab.add(saveButton);
	}

	function addLabel(group:FlxSpriteGroup, x:Float, y:Float, text:String)
	{
		var label = new FlxText(x, y, 150, text, 8);
		group.add(label);
	}

	function applyNormalTemplate(showMessage:Bool)
	{
		skinInputText.text = normalizeSkinPath(skinInputText != null ? skinInputText.text : lastSkin);
		nameInputText.text = 'Funkin';
		fallbackInputText.text = '';
		noteAssetInputText.text = 'noteSkins/NOTE_assets';
		holdAssetInputText.text = 'noteSkins/NOTE_assets';
		strumAssetInputText.text = 'noteSkins/NOTE_assets';
		splashAssetInputText.text = 'noteSplashes/noteSplashes';
		noteScaleStepper.value = 0.7;
		holdScaleStepper.value = 0.7;
		strumScaleStepper.value = 0.7;
		pixelModeCheckBox.checked = false;
		allowRGBCheckBox.checked = true;
		allowPixelCheckBox.checked = false;
		noteColumnsStepper.value = 4;
		noteRowsStepper.value = 5;
		holdColumnsStepper.value = 4;
		holdRowsStepper.value = 2;
		strumColumnsStepper.value = 4;
		strumRowsStepper.value = 5;
		updatePreview();
		if(showMessage) showOutput('Normal note skin template loaded.');
	}

	function applyPixelTemplate(showMessage:Bool)
	{
		if(skinInputText != null && normalizeSkinPath(skinInputText.text).length < 1)
			skinInputText.text = 'noteSkins/pixel';
		nameInputText.text = 'Pixel';
		fallbackInputText.text = 'funkin';
		noteAssetInputText.text = 'weeb/pixelUI/arrows-pixels-rgb';
		holdAssetInputText.text = 'weeb/pixelUI/arrowEndsNew-rgb';
		strumAssetInputText.text = 'weeb/pixelUI/arrows-pixels-rgb';
		splashAssetInputText.text = 'noteSplashes/noteSplashes';
		noteScaleStepper.value = PlayState.daPixelZoom;
		holdScaleStepper.value = PlayState.daPixelZoom;
		strumScaleStepper.value = PlayState.daPixelZoom;
		pixelModeCheckBox.checked = true;
		allowRGBCheckBox.checked = true;
		allowPixelCheckBox.checked = true;
		noteColumnsStepper.value = 4;
		noteRowsStepper.value = 5;
		holdColumnsStepper.value = 8;
		holdRowsStepper.value = 1;
		strumColumnsStepper.value = 4;
		strumRowsStepper.value = 5;
		updatePreview();
		if(showMessage) showOutput('Pixel note skin template loaded.');
	}

	function reloadJsonFromAssets(showErrors:Bool)
	{
		var skin:String = normalizeSkinPath(skinInputText != null ? skinInputText.text : lastSkin);
		if(skin.length < 1) skin = 'funkin';
		lastSkin = skin;
		if(skinInputText != null) skinInputText.text = skin;

		var jsonText:String = readNotestyleJson(skin);
		if(jsonText == null && Paths.fileExists('images/noteSkins/$skin.json', TEXT))
			jsonText = Paths.getTextFromFile('images/noteSkins/$skin.json');
		if(jsonText == null && Paths.fileExists('images/$skin.json', TEXT))
			jsonText = Paths.getTextFromFile('images/$skin.json');

		if(jsonText == null)
		{
			if(showErrors) showOutput('data/notestyles/$skin.json not found.', true);
			return;
		}

		try
		{
			var raw:Dynamic = Json.parse(jsonText);
			if(!isRawNoteStyleJson(raw))
			{
				var fallbackText:String = null;
				if(Paths.fileExists('images/noteSkins/$skin.json', TEXT))
					fallbackText = Paths.getTextFromFile('images/noteSkins/$skin.json');
				else if(Paths.fileExists('images/$skin.json', TEXT))
					fallbackText = Paths.getTextFromFile('images/$skin.json');

				if(fallbackText != null)
					raw = Json.parse(fallbackText);
			}
			applyRawJson(raw);
			showOutput('Loaded ${Paths.notestyleJson(skin)}');
		}
		catch(e:Dynamic)
		{
			showOutput('Could not parse data/notestyles/$skin.json: $e', true);
		}
	}

	function readNotestyleJson(skin:String):String
	{
		if(skin == null || skin.length < 1) return null;
		var path:String = Paths.notestyleJson(skin);
		#if sys
		if(FileSystem.exists(path))
			return File.getContent(path);
		#end
		return Assets.exists(path) ? Assets.getText(path) : null;
	}

	function isRawNoteStyleJson(raw:Dynamic):Bool
	{
		return raw != null && !Std.isOfType(raw, Array) && Reflect.hasField(raw, 'assets');
	}

	function applyRawJson(raw:Dynamic)
	{
		if(raw == null) return;

		var assets:Dynamic = Reflect.field(raw, 'assets');
		var noteAsset:Dynamic = assets != null ? Reflect.field(assets, 'note') : null;
		var holdAsset:Dynamic = assets != null ? firstAssetField(assets, ['sustainPixel', 'pixelSustain', 'sustainNotePixel', 'sustain', 'sustainNote', 'holdNote', 'holdNotePixel', 'pixelHoldNote']) : null;
		var strumAsset:Dynamic = assets != null ? Reflect.field(assets, 'noteStrumline') : null;
		var splashAsset:Dynamic = assets != null ? Reflect.field(assets, 'noteSplash') : null;

		nameInputText.text = stringField(raw, 'name', baseName(lastSkin));
		fallbackInputText.text = stringField(raw, 'fallback', '');
		noteAssetInputText.text = assetPath(noteAsset, noteAssetInputText.text);
		holdAssetInputText.text = assetPath(holdAsset, holdAssetInputText.text);
		strumAssetInputText.text = assetPath(strumAsset, strumAssetInputText.text);
		splashAssetInputText.text = assetPath(splashAsset, splashAssetInputText.text);

		noteScaleStepper.value = floatField(noteAsset, 'scale', noteScaleStepper.value);
		holdScaleStepper.value = floatField(holdAsset, 'scale', holdScaleStepper.value);
		strumScaleStepper.value = floatField(strumAsset, 'scale', strumScaleStepper.value);

		pixelModeCheckBox.checked = boolField(noteAsset, 'isPixel', false) || boolField(holdAsset, 'isPixel', false) || boolField(strumAsset, 'isPixel', false);
		allowRGBCheckBox.checked = boolField(raw, 'allowRGB', true);
		allowPixelCheckBox.checked = boolField(raw, 'allowPixel', pixelModeCheckBox.checked);

		noteColumnsStepper.value = intField(noteAsset, 'columns', Std.int(noteColumnsStepper.value));
		noteRowsStepper.value = intField(noteAsset, 'rows', Std.int(noteRowsStepper.value));
		holdColumnsStepper.value = intField(holdAsset, 'columns', Std.int(holdColumnsStepper.value));
		holdRowsStepper.value = intField(holdAsset, 'rows', Std.int(holdRowsStepper.value));
		strumColumnsStepper.value = intField(strumAsset, 'columns', Std.int(strumColumnsStepper.value));
		strumRowsStepper.value = intField(strumAsset, 'rows', Std.int(strumRowsStepper.value));
		updatePreview();
	}

	function updatePreview()
	{
		if(previewGroup == null || noteAssetInputText == null) return;

		for(member in previewGroup.members)
		{
			if(member != null) member.destroy();
		}
		previewGroup.clear();

		var oldStageUI:String = PlayState.stageUI;
		PlayState.stageUI = pixelModeCheckBox.checked ? 'pixel' : 'normal';
		Note.noteSkinConfigs.set('images/$PREVIEW_SKIN', cast buildPreviewConfig());

		try
		{
			for(i in 0...4)
			{
				var strum = new StrumNote(120 + i * 105, 105, i, 0);
				strum.texture = PREVIEW_SKIN;
				strum.playAnim('static', true);
				previewGroup.add(strum);

				var note = new Note(0, i, null, false, true, {songSpeed: 1});
				note.texture = PREVIEW_SKIN;
				note.setPosition(125 + i * 105, 245);
				note.animation.play(Note.colArray[i] + 'Scroll', true);
				previewGroup.add(note);
			}

			var sustainBase = new Note(0, 0, null, false, true, {songSpeed: 1});
			sustainBase.texture = PREVIEW_SKIN;
			var sustain = new Note(0, 0, sustainBase, true, true, {songSpeed: 1});
			sustain.texture = PREVIEW_SKIN;
			sustain.setPosition(170, 380);
			sustain.animation.play('purplehold', true);
			previewGroup.add(sustain);

			showOutput('Preview updated.');
		}
		catch(e:Dynamic)
		{
			showOutput('Preview error: $e', true);
		}

		PlayState.stageUI = oldStageUI;
	}

	function firstAssetField(assets:Dynamic, names:Array<String>):Dynamic
	{
		if(assets == null) return null;
		for (name in names)
		{
			var value:Dynamic = Reflect.field(assets, name);
			if(value != null) return value;
		}
		return null;
	}

	function buildPreviewConfig():Dynamic
	{
		var config:Dynamic = Note.createNoteSkinConfig();
		config.animations = createAnimationMap();
		config.allowRGB = allowRGBCheckBox.checked;
		config.allowPixel = allowPixelCheckBox.checked;
		config.noteSplashAssetPath = cleanAssetPath(splashAssetInputText.text);

		if(pixelModeCheckBox.checked)
		{
			config.pixelNoteAssetPath = cleanAssetPath(noteAssetInputText.text);
			config.pixelHoldAssetPath = cleanAssetPath(holdAssetInputText.text);
			config.pixelStrumAssetPath = cleanAssetPath(strumAssetInputText.text);
			config.pixelNoteScale = noteScaleStepper.value;
			config.pixelHoldScale = holdScaleStepper.value;
			config.pixelStrumScale = strumScaleStepper.value;
			config.pixelNoteColumns = Std.int(noteColumnsStepper.value);
			config.pixelNoteRows = Std.int(noteRowsStepper.value);
			config.pixelHoldColumns = Std.int(holdColumnsStepper.value);
			config.pixelHoldRows = Std.int(holdRowsStepper.value);
			config.pixelStrumColumns = Std.int(strumColumnsStepper.value);
			config.pixelStrumRows = Std.int(strumRowsStepper.value);
		}
		else
		{
			config.noteAssetPath = cleanAssetPath(noteAssetInputText.text);
			config.holdAssetPath = cleanAssetPath(holdAssetInputText.text);
			config.strumAssetPath = cleanAssetPath(strumAssetInputText.text);
			config.noteScale = noteScaleStepper.value;
			config.holdScale = holdScaleStepper.value;
			config.strumScale = strumScaleStepper.value;
		}
		return config;
	}

	function createAnimationMap():Map<String, Dynamic>
	{
		var animations:Map<String, Dynamic> = new Map();
		if(pixelModeCheckBox.checked)
		{
			setAnimIndices(animations, 'purpleScroll', [4]);
			setAnimIndices(animations, 'blueScroll', [5]);
			setAnimIndices(animations, 'greenScroll', [6]);
			setAnimIndices(animations, 'redScroll', [7]);

			setAnimIndices(animations, 'static0', [0]);
			setAnimIndices(animations, 'pressed0', [4, 8], 12, false);
			setAnimIndices(animations, 'confirm0', [12, 16], 24, false);
			setAnimIndices(animations, 'static1', [1]);
			setAnimIndices(animations, 'pressed1', [5, 9], 12, false);
			setAnimIndices(animations, 'confirm1', [13, 17], 24, false);
			setAnimIndices(animations, 'static2', [2]);
			setAnimIndices(animations, 'pressed2', [6, 10], 12, false);
			setAnimIndices(animations, 'confirm2', [14, 18], 12, false);
			setAnimIndices(animations, 'static3', [3]);
			setAnimIndices(animations, 'pressed3', [7, 11], 12, false);
			setAnimIndices(animations, 'confirm3', [15, 19], 24, false);

			setAnimIndices(animations, 'purpleholdend', [4]);
			setAnimIndices(animations, 'purplehold', [0]);
			setAnimIndices(animations, 'blueholdend', [5]);
			setAnimIndices(animations, 'bluehold', [1]);
			setAnimIndices(animations, 'greenholdend', [6]);
			setAnimIndices(animations, 'greenhold', [2]);
			setAnimIndices(animations, 'redholdend', [7]);
			setAnimIndices(animations, 'redhold', [3]);
		}
		else
		{
			setAnimPrefix(animations, 'purpleScroll', 'purple0');
			setAnimPrefix(animations, 'blueScroll', 'blue0');
			setAnimPrefix(animations, 'greenScroll', 'green0');
			setAnimPrefix(animations, 'redScroll', 'red0');

			setAnimPrefix(animations, 'static0', 'arrowLEFT');
			setAnimPrefix(animations, 'pressed0', 'left press', 24, false);
			setAnimPrefix(animations, 'confirm0', 'left confirm', 24, false);
			setAnimPrefix(animations, 'static1', 'arrowDOWN');
			setAnimPrefix(animations, 'pressed1', 'down press', 24, false);
			setAnimPrefix(animations, 'confirm1', 'down confirm', 24, false);
			setAnimPrefix(animations, 'static2', 'arrowUP');
			setAnimPrefix(animations, 'pressed2', 'up press', 24, false);
			setAnimPrefix(animations, 'confirm2', 'up confirm', 24, false);
			setAnimPrefix(animations, 'static3', 'arrowRIGHT');
			setAnimPrefix(animations, 'pressed3', 'right press', 24, false);
			setAnimPrefix(animations, 'confirm3', 'right confirm', 24, false);

			setAnimPrefix(animations, 'green', 'arrowUP');
			setAnimPrefix(animations, 'blue', 'arrowDOWN');
			setAnimPrefix(animations, 'purple', 'arrowLEFT');
			setAnimPrefix(animations, 'red', 'arrowRIGHT');

			setAnimPrefix(animations, 'purpleholdend', 'purple hold end');
			setAnimPrefix(animations, 'purplehold', 'purple hold piece');
			setAnimPrefix(animations, 'blueholdend', 'blue hold end');
			setAnimPrefix(animations, 'bluehold', 'blue hold piece');
			setAnimPrefix(animations, 'greenholdend', 'green hold end');
			setAnimPrefix(animations, 'greenhold', 'green hold piece');
			setAnimPrefix(animations, 'redholdend', 'red hold end');
			setAnimPrefix(animations, 'redhold', 'red hold piece');
		}
		return animations;
	}

	function setAnimPrefix(map:Map<String, Dynamic>, name:String, prefix:String, fps:Int = 24, loop:Bool = true)
	{
		map.set(name, {prefix: prefix, fps: fps, loop: loop});
	}

	function setAnimIndices(map:Map<String, Dynamic>, name:String, indices:Array<Int>, fps:Int = 24, loop:Bool = true)
	{
		map.set(name, {indices: indices, fps: fps, loop: loop});
	}

	function buildSaveJson():Dynamic
	{
		var saveJson:Dynamic = {
			version: '1.1.0',
			name: nameInputText.text,
			fallback: fallbackInputText.text != null && fallbackInputText.text.trim().length > 0 ? fallbackInputText.text.trim() : null,
			assets: {
				note: makeNoteAssetJson(false),
				sustain: makeHoldAssetJson(false),
				noteStrumline: makeStrumAssetJson(false),
				noteSplash: {
					assetPath: cleanAssetPath(splashAssetInputText.text)
				},
				countdownThree: makeCountdownAssetJson(null, pixelModeCheckBox.checked ? 'intro3-pixel' : 'intro3', pixelModeCheckBox.checked),
				countdownTwo: makeCountdownAssetJson(pixelModeCheckBox.checked ? 'ui/pixel/countdown/ready-pixel' : 'ui/funkin/countdown/ready', pixelModeCheckBox.checked ? 'intro2-pixel' : 'intro2', pixelModeCheckBox.checked),
				countdownOne: makeCountdownAssetJson(pixelModeCheckBox.checked ? 'ui/pixel/countdown/set-pixel' : 'ui/funkin/countdown/set', pixelModeCheckBox.checked ? 'intro1-pixel' : 'intro1', pixelModeCheckBox.checked),
				countdownGo: makeCountdownAssetJson(pixelModeCheckBox.checked ? 'ui/pixel/countdown/date-pixel' : 'ui/funkin/countdown/go', pixelModeCheckBox.checked ? 'introGo-pixel' : 'introGo', pixelModeCheckBox.checked),
				judgementSick: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/sick' : 'ui/popup/funkin/sick', pixelModeCheckBox.checked ? PlayState.daPixelZoom * 0.85 : 0.7, pixelModeCheckBox.checked),
				judgementGood: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/good' : 'ui/popup/funkin/good', pixelModeCheckBox.checked ? PlayState.daPixelZoom * 0.85 : 0.7, pixelModeCheckBox.checked),
				judgementBad: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/bad' : 'ui/popup/funkin/bad', pixelModeCheckBox.checked ? PlayState.daPixelZoom * 0.85 : 0.7, pixelModeCheckBox.checked),
				judgementShit: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/shit' : 'ui/popup/funkin/shit', pixelModeCheckBox.checked ? PlayState.daPixelZoom * 0.85 : 0.7, pixelModeCheckBox.checked),
				combo: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/combo' : 'ui/popup/funkin/combo', pixelModeCheckBox.checked ? PlayState.daPixelZoom * 0.85 : 0.7, pixelModeCheckBox.checked),
				comboNumber0: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num0-pixel' : 'ui/popup/funkin/num0', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber1: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num1-pixel' : 'ui/popup/funkin/num1', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber2: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num2-pixel' : 'ui/popup/funkin/num2', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber3: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num3-pixel' : 'ui/popup/funkin/num3', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber4: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num4-pixel' : 'ui/popup/funkin/num4', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber5: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num5-pixel' : 'ui/popup/funkin/num5', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber6: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num6-pixel' : 'ui/popup/funkin/num6', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber7: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num7-pixel' : 'ui/popup/funkin/num7', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber8: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num8-pixel' : 'ui/popup/funkin/num8', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked),
				comboNumber9: makeUiAssetJson(pixelModeCheckBox.checked ? 'ui/popup/pixel/num9-pixel' : 'ui/popup/funkin/num9', pixelModeCheckBox.checked ? PlayState.daPixelZoom : 0.5, pixelModeCheckBox.checked)
			},
			allowRGB: allowRGBCheckBox.checked,
			allowPixel: allowPixelCheckBox.checked
		};

		if(pixelModeCheckBox.checked)
		{
			var assets:Dynamic = Reflect.field(saveJson, 'assets');
			Reflect.setField(assets, 'sustainPixel', Reflect.field(assets, 'sustain'));
			Reflect.deleteField(assets, 'sustain');
		}

		return saveJson;
	}

	function makeCountdownAssetJson(assetPath:String, audioPath:String, isPixel:Bool):Dynamic
	{
		return {
			assetPath: assetPath,
			data: {audioPath: audioPath},
			scale: isPixel ? PlayState.daPixelZoom : 1.0,
			isPixel: isPixel
		};
	}

	function makeUiAssetJson(assetPath:String, scale:Float, isPixel:Bool):Dynamic
	{
		return {
			assetPath: assetPath,
			scale: scale,
			isPixel: isPixel
		};
	}

	function makeNoteAssetJson(_:Bool):Dynamic
	{
		if(pixelModeCheckBox.checked)
		{
			return {
				assetPath: cleanAssetPath(noteAssetInputText.text),
				scale: noteScaleStepper.value,
				isPixel: true,
				columns: Std.int(noteColumnsStepper.value),
				rows: Std.int(noteRowsStepper.value),
				data: pixelNoteData()
			};
		}
		return {
			assetPath: cleanAssetPath(noteAssetInputText.text),
			scale: noteScaleStepper.value,
			data: normalNoteData()
		};
	}

	function makeHoldAssetJson(_:Bool):Dynamic
	{
		if(pixelModeCheckBox.checked)
		{
			return {
				assetPath: cleanAssetPath(holdAssetInputText.text),
				scale: holdScaleStepper.value,
				isPixel: true,
				columns: Std.int(holdColumnsStepper.value),
				rows: Std.int(holdRowsStepper.value),
				data: pixelHoldData()
			};
		}
		return {
			assetPath: cleanAssetPath(holdAssetInputText.text),
			scale: holdScaleStepper.value,
			data: normalHoldData()
		};
	}

	function makeStrumAssetJson(_:Bool):Dynamic
	{
		if(pixelModeCheckBox.checked)
		{
			return {
				assetPath: cleanAssetPath(strumAssetInputText.text),
				scale: strumScaleStepper.value,
				isPixel: true,
				columns: Std.int(strumColumnsStepper.value),
				rows: Std.int(strumRowsStepper.value),
				data: pixelStrumData()
			};
		}
		return {
			assetPath: cleanAssetPath(strumAssetInputText.text),
			scale: strumScaleStepper.value,
			data: normalStrumData()
		};
	}

	function normalNoteData():Dynamic
	{
		return {
			left: animPrefixJson('purple0'),
			down: animPrefixJson('blue0'),
			up: animPrefixJson('green0'),
			right: animPrefixJson('red0')
		};
	}

	function normalHoldData():Dynamic
	{
		return {
			leftHoldEnd: animPrefixJson('purple hold end'),
			leftHold: animPrefixJson('purple hold piece'),
			downHoldEnd: animPrefixJson('blue hold end'),
			downHold: animPrefixJson('blue hold piece'),
			upHoldEnd: animPrefixJson('green hold end'),
			upHold: animPrefixJson('green hold piece'),
			rightHoldEnd: animPrefixJson('red hold end'),
			rightHold: animPrefixJson('red hold piece')
		};
	}

	function normalStrumData():Dynamic
	{
		return {
			leftStatic: animPrefixJson('arrowLEFT'),
			leftPress: animPrefixJson('left press', 24, false),
			leftConfirm: animPrefixJson('left confirm', 24, false),
			downStatic: animPrefixJson('arrowDOWN'),
			downPress: animPrefixJson('down press', 24, false),
			downConfirm: animPrefixJson('down confirm', 24, false),
			upStatic: animPrefixJson('arrowUP'),
			upPress: animPrefixJson('up press', 24, false),
			upConfirm: animPrefixJson('up confirm', 24, false),
			rightStatic: animPrefixJson('arrowRIGHT'),
			rightPress: animPrefixJson('right press', 24, false),
			rightConfirm: animPrefixJson('right confirm', 24, false)
		};
	}

	function pixelNoteData():Dynamic
	{
		return {
			left: animIndicesJson([4]),
			down: animIndicesJson([5]),
			up: animIndicesJson([6]),
			right: animIndicesJson([7])
		};
	}

	function pixelHoldData():Dynamic
	{
		return {
			leftHold: animIndicesJson([0]),
			leftHoldEnd: animIndicesJson([1]),
			downHold: animIndicesJson([2]),
			downHoldEnd: animIndicesJson([3]),
			upHold: animIndicesJson([4]),
			upHoldEnd: animIndicesJson([5]),
			rightHold: animIndicesJson([6]),
			rightHoldEnd: animIndicesJson([7])
		};
	}

	function pixelStrumData():Dynamic
	{
		return {
			leftStatic: animIndicesJson([0]),
			leftPress: animIndicesJson([4, 8], 12, false),
			leftConfirm: animIndicesJson([12, 16], 24, false),
			downStatic: animIndicesJson([1]),
			downPress: animIndicesJson([5, 9], 12, false),
			downConfirm: animIndicesJson([13, 17], 24, false),
			upStatic: animIndicesJson([2]),
			upPress: animIndicesJson([6, 10], 12, false),
			upConfirm: animIndicesJson([14, 18], 12, false),
			rightStatic: animIndicesJson([3]),
			rightPress: animIndicesJson([7, 11], 12, false),
			rightConfirm: animIndicesJson([15, 19], 24, false)
		};
	}

	function animPrefixJson(prefix:String, frameRate:Int = 24, looped:Bool = true):Dynamic
	{
		return {prefix: prefix, frameRate: frameRate, looped: looped};
	}

	function animIndicesJson(indices:Array<Int>, frameRate:Int = 24, looped:Bool = true):Dynamic
	{
		return {indices: indices, frameRate: frameRate, looped: looped};
	}

	function saveNoteSkin()
	{
		lastSkin = normalizeSkinPath(skinInputText.text);
		if(lastSkin.length < 1)
		{
			showOutput('Notestyle JSON needs a name.', true);
			return;
		}

		var data:String = Json.stringify(buildSaveJson(), '\t');
		#if sys
		try
		{
			var savePath:String = Paths.notestyleJson(lastSkin);
			var directory:String = haxe.io.Path.directory(savePath);
			if(directory != null && directory.length > 0 && !FileSystem.exists(directory))
				FileSystem.createDirectory(directory);
			File.saveContent(savePath, data);
			Note.noteSkinConfigs.remove('data/notestyles/$lastSkin');
			showOutput('Successfully saved $savePath');
			return;
		}
		catch(e:Dynamic)
		{
			showOutput('Could not save with Paths.notestyleJson, opening file dialog.', true);
		}
		#end

		_file = new FileReference();
		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file.save(data, baseName(lastSkin) + '.json');
	}

	function onSaveComplete(_):Void
	{
		clearSaveListeners();
		showOutput('Successfully saved ${baseName(lastSkin)}.json');
	}

	function onSaveCancel(_):Void
	{
		clearSaveListeners();
	}

	function onSaveError(_):Void
	{
		clearSaveListeners();
		showOutput('Problem saving file.', true);
	}

	function clearSaveListeners()
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function showOutput(text:String, error:Bool = false)
	{
		if(outputText == null) return;
		FlxTween.cancelTweensOf(outputText);
		outputText.text = text;
		outputText.color = error ? FlxColor.RED : FlxColor.LIME;
		outputText.alpha = 1;
		FlxTween.tween(outputText, {alpha: 0}, 1, {startDelay: 2});
	}

	override function update(elapsed:Float)
	{
		if(controls.BACK)
		{
			MusicBeatState.switchState(new funkin.states.editors.EditorsMenuss());
			return;
		}
		super.update(elapsed);
	}

	override function destroy()
	{
		Note.noteSkinConfigs.remove('images/$PREVIEW_SKIN');
		super.destroy();
	}

	function normalizeSkinPath(value:String):String
	{
		if(value == null) return '';
		var skin:String = value.trim().replace('\\', '/');
		if(skin.startsWith('data/notestyles/'))
			skin = skin.substr('data/notestyles/'.length);
		if(skin.startsWith('notestyles/'))
			skin = skin.substr('notestyles/'.length);
		if(skin.startsWith('images/noteSkins/'))
			skin = skin.substr('images/noteSkins/'.length);
		if(skin.startsWith('noteSkins/'))
			skin = skin.substr('noteSkins/'.length);
		if(skin.startsWith('images/'))
			skin = skin.substr('images/'.length);
		for(extension in ['.json', '.png', '.xml'])
		{
			if(skin.endsWith(extension))
			{
				skin = skin.substr(0, skin.length - extension.length);
				break;
			}
		}
		return skin.indexOf('/') >= 0 ? baseName(skin) : skin;
	}

	function cleanAssetPath(value:String):String
	{
		if(value == null) return '';
		var clean:String = value.trim().replace('\\', '/');
		if(clean.startsWith('images/')) clean = clean.substr('images/'.length);
		for(extension in ['.png', '.xml', '.json'])
		{
			if(clean.endsWith(extension))
			{
				clean = clean.substr(0, clean.length - extension.length);
				break;
			}
		}
		return clean;
	}

	function assetPath(asset:Dynamic, fallback:String):String
	{
		if(asset == null) return fallback;
		if(Std.isOfType(asset, String)) return cleanAssetPath(cast asset);
		return cleanAssetPath(stringField(asset, 'assetPath', fallback));
	}

	function stringField(object:Dynamic, field:String, fallback:String):String
	{
		if(object == null) return fallback;
		var value:Dynamic = Reflect.field(object, field);
		if(value == null) return fallback;
		return Std.string(value);
	}

	function floatField(object:Dynamic, field:String, fallback:Float):Float
	{
		if(object == null) return fallback;
		var value:Dynamic = Reflect.field(object, field);
		if(value == null) return fallback;
		var parsed:Float = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	function intField(object:Dynamic, field:String, fallback:Int):Int
	{
		var value:Float = floatField(object, field, fallback);
		return Std.int(value);
	}

	function boolField(object:Dynamic, field:String, fallback:Bool):Bool
	{
		if(object == null) return fallback;
		var value:Dynamic = Reflect.field(object, field);
		if(value == null) return fallback;
		if(Std.isOfType(value, Bool)) return cast value;
		var text:String = Std.string(value).toLowerCase();
		return text == 'true' || text == '1' || text == 'yes';
	}

	function baseName(path:String):String
	{
		if(path == null || path.length < 1) return 'notestyle';
		var clean:String = path.replace('\\', '/');
		if(clean.endsWith('.json')) clean = clean.substr(0, clean.length - 5);
		var split:Array<String> = clean.split('/');
		return split[split.length - 1];
	}
}
