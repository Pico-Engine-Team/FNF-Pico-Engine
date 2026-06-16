package funkin.data.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flash.net.FileFilter;
import haxe.Json;

import funkin.data.objects.story.MenuCharacter;
import funkin.data.editors.content.Prompt;
import funkin.utils.engines.psych.PsychJsonPrinter;

class MenuCharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;
	var unsavedProgress:Bool = false;

	override function create()
	{
		characterFile = {
			position: [0, 0],
			idle_anim: 'M Dad Idle',
			confirm_anim: 'M Dad Idle',
			image: 'Menu_Dad',
			scale: 1,
			flipX: false,
			antialiasing: true
		};
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width,
			"Arrow Keys - Change Offset (Hold shift for 10x speed)
			\nSpace - Play \"Start Press\" animation (Boyfriend Character Type)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharacters();

		super.create();
	}

	var UI_typebox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	function addEditorBox() {
		UI_typebox = new PsychUIBox(100, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		// UI_mainbox com duas abas: Character + Animations
		UI_mainbox = new PsychUIBox(FlxG.width - 340, FlxG.height - 265, 240, 215, ['Character', 'Animations']);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		addAnimationUI();
		add(UI_mainbox);

		var loadButton:PsychUIButton = new PsychUIButton(0, 480, "Load", function() {
			loadCharacter();
		});
		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:PsychUIButton = new PsychUIButton(0, 480, "Save", function() {
			saveCharacter();
		});
		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	var characterTypeRadio:PsychUIRadioGroup;
	function addTypeUI() {
		var tab_group = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new PsychUIRadioGroup(10, 20, ['Opponent', 'Boyfriend', 'Girlfriend'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = updateCharacters;
		tab_group.add(characterTypeRadio);
	}

	var animationTypeDropDown:PsychUIDropDownMenu;
	var animationPrefixInput:PsychUIInputText;
	function addAnimationUI() {
		var tab_group = UI_mainbox.getTab('Animations').menu;
		var lx:Int = 10;
		var ly:Int = 10;

		animationTypeDropDown = new PsychUIDropDownMenu(lx, ly + 12, ['idle', 'confirm'], function(id:Int, selected:String)
		{
			refreshAnimationInput();
		});
		animationTypeDropDown.selectedLabel = 'idle';
		tab_group.add(new FlxText(animationTypeDropDown.x, animationTypeDropDown.y - 18, 120, 'Animations:'));
		tab_group.add(animationTypeDropDown);

		ly += 60;
		animationPrefixInput = new PsychUIInputText(lx, ly + 12, 210, characterFile.idle_anim, 8);
		animationPrefixInput.name = 'idle_anim';
		tab_group.add(new FlxText(animationPrefixInput.x, animationPrefixInput.y - 18, 170, 'Prefix:'));
		tab_group.add(animationPrefixInput);

		ly += 55;
		var addUpdateButton:PsychUIButton = new PsychUIButton(lx, ly, 'Add/Update', function()
		{
			applySelectedAnimation(animationPrefixInput.text.trim());
			reloadSelectedCharacter();
			unsavedProgress = true;
		}, 100);
		tab_group.add(addUpdateButton);

		var removeButton:PsychUIButton = new PsychUIButton(lx + 110, ly, 'Remove', function()
		{
			applySelectedAnimation('');
			refreshAnimationInput();
			reloadSelectedCharacter();
			unsavedProgress = true;
		}, 100);
		tab_group.add(removeButton);
	}

	function getSelectedAnimationName():String
	{
		if(animationTypeDropDown == null || animationTypeDropDown.selectedLabel == null)
			return 'idle';
		return animationTypeDropDown.selectedLabel.toLowerCase().trim();
	}

	function getSelectedAnimationPrefix():String
	{
		return getSelectedAnimationName() == 'confirm' ? characterFile.confirm_anim : characterFile.idle_anim;
	}

	function getSelectedAnimationFieldName():String
	{
		return getSelectedAnimationName() == 'confirm' ? 'confirm_anim' : 'idle_anim';
	}

	function applySelectedAnimation(prefix:String)
	{
		if(getSelectedAnimationName() == 'confirm')
			characterFile.confirm_anim = prefix;
		else
			characterFile.idle_anim = prefix;
	}

	function refreshAnimationInput()
	{
		if(animationPrefixInput != null)
		{
			animationPrefixInput.name = getSelectedAnimationFieldName();
			animationPrefixInput.text = getSelectedAnimationPrefix();
		}
	}

	var imageInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var flipXCheckbox:PsychUICheckBox;
	var antialiasingCheckbox:PsychUICheckBox;
	function addCharacterUI() {
		var tab_group = UI_mainbox.getTab('Character').menu;
		
		imageInputText = new PsychUIInputText(10, 20, 80, characterFile.image, 8);

		flipXCheckbox = new PsychUICheckBox(10, imageInputText.y + 50, "Flip X", 100);
		flipXCheckbox.onClick = function()
		{
			grpWeekCharacters.members[characterTypeRadio.checked].flipX = flipXCheckbox.checked;
			characterFile.flipX = flipXCheckbox.checked;
		};

		antialiasingCheckbox = new PsychUICheckBox(10, flipXCheckbox.y + 30, "Antialiasing", 100);
		antialiasingCheckbox.checked = grpWeekCharacters.members[characterTypeRadio.checked].antialiasing;
		antialiasingCheckbox.onClick = function()
		{
			grpWeekCharacters.members[characterTypeRadio.checked].antialiasing = antialiasingCheckbox.checked;
			characterFile.antialiasing = antialiasingCheckbox.checked;
		};

		var reloadImageButton:PsychUIButton = new PsychUIButton(140, flipXCheckbox.y, "Reload Char", function() {
			reloadSelectedCharacter();
		});
		
		scaleStepper = new PsychUINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(antialiasingCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(imageInputText);
		tab_group.add(scaleStepper);
	}

	function updateCharacters() {
		for (i in 0...3) {
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}
		reloadSelectedCharacter();
	}
	
	function reloadSelectedCharacter() {
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('storymenu/props/characters/' + characterFile.image);
		if(characterFile.idle_anim != null && characterFile.idle_anim.length > 0)
			char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		if(characterTypeRadio.checked == 1 && characterFile.confirm_anim != null && characterFile.confirm_anim.length > 0)
			char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);
		char.flipX = (characterFile.flipX == true);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		if(char.animation.exists('idle'))
			char.animation.play('idle');
		updateOffset();
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if(sender == imageInputText) {
				characterFile.image = imageInputText.text;
				unsavedProgress = true;
			} else if(sender == animationPrefixInput) {
				applySelectedAnimation(animationPrefixInput.text);
				unsavedProgress = true;
			}
		} else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			if (sender == scaleStepper) {
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
				unsavedProgress = true;
			}
		}
	}

	override function update(elapsed:Float) {
		if(PsychUIInputText.focusOn == null)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new funkin.utils.EditorsMenus());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt());
			}

			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 10;

			if(FlxG.keys.justPressed.LEFT) {
				characterFile.position[0] += shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.RIGHT) {
				characterFile.position[0] -= shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.UP) {
				characterFile.position[1] += shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.DOWN) {
				characterFile.position[1] -= shiftMult;
				updateOffset();
			}

			if(FlxG.keys.justPressed.SPACE && characterTypeRadio.checked == 1 && grpWeekCharacters.members[characterTypeRadio.checked].animation.exists('confirm')) {
				grpWeekCharacters.members[characterTypeRadio.checked].animation.play('confirm', true);
			}
		}
		else ClientPrefs.toggleVolumeKeys(false);

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if(char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished)
			char.animation.play('idle', true);

		super.update(elapsed);
	}

	function updateOffset()
	{
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
		char.offset.set(characterFile.position[0], characterFile.position[1]);
		txtOffsets.text = '' + characterFile.position;
	}

	var _file:FileReference = null;
	function loadCharacter() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson);
				if(loadedChar.idle_anim != null && loadedChar.confirm_anim != null) //Make sure it's really a character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					characterFile = loadedChar;
					reloadSelectedCharacter();
					imageInputText.text  = characterFile.image;
					refreshAnimationInput();
					scaleStepper.value   = characterFile.scale;
					updateOffset();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveCharacter() {
		// Garante que os prefixes estão atualizados antes de salvar
		if(animationPrefixInput != null)
			applySelectedAnimation(animationPrefixInput.text.trim());

		var data:String = PsychJsonPrinter.print(characterFile, ['position']);
		if (data.length > 0)
		{
			// Nome do arquivo baseado na imagem (ex: Menu_Dad → dad.json)
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var fileName:String = splittedImage[splittedImage.length - 1].toLowerCase().replace(' ', '');
			if (fileName.length < 1) fileName = 'character';

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, fileName + '.json');
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
