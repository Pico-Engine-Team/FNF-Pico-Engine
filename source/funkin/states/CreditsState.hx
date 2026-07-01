package funkin.states;

import funkin.data.objects.AttachedSprite;

class CreditsState extends MusicBeatState
{
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];
	private var creditsPages:Array<Array<Array<String>>> = [];

	var curSelected:Int = -1;
	var curPage:Int = 0;
	var bg:FlxSprite;
	var descText:FlxText;
	var pageText:FlxText;
	var intendedColor:FlxColor;
	var descBox:AttachedSprite;
	var offsetThing:Float = -75;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In Credits Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		// Name - Icon name - Description - Link - BG Color
		var defaultList:Array<Array<String>> =
		[
			["Pico Engine Team"],
			["Lucas Sanches",		"null",				"Main Programmer and Head of Pico Engine",					"https://github.com/Pico-Engine-Team",	"F9393F"],
			[""],
			["Psych Engine Team"],
			["Shadow Mario",		"psychEngine/shadowmario",		"Main Programmer and Head of Psych Engine",					"https://ko-fi.com/shadowmario",	"444444"],
			["Riveren",				"psychEngine/riveren",			"Main Artist/Animator of Psych Engine",						"https://x.com/riverennn",			"14967B"],
			["Join the Psych Ward!", "discord",						"",																				"https://discord.gg/2ka77eMXDv", 	"5165F6"],
			[""],
			["P Slice Engine Team"],
			['Mikolka9144',			'P Slice Engine/mikolka',						'Main Programmer and Head of P Slice Engine',						'https://gamebanana.com/members/3329541','2ebcfa'],
			["Derpy The Hedgeone",	'P Slice Engine/contributors/derpy',			'Made a lot of PRs to the repo',									'https://github.com/DerpyTheHedgeone',	'd86b00'],
			["Mykarm",				'P Slice Engine/contributors/mykarm',			'Made the new icon and promational art for P Slice',				'https://x.com/cronviersmeat/status/1849059676467417311?s=46&t=4dcTT7PAMkRJ8zYd4LgTow',	'29170a'],
			["Fazecarl",			'P Slice Engine/contributors/fazecarl',			'Made the new logo for P Slice',									'https://gamebanana.com/members/2121406',	'29170a'],
			["Join our community", 	"P Slice Engine/discord/ppslice", 				"",																	"https://discord.gg/2ka77eMXDv", 			"5165F6"],
			[""],
			["The Funkin' Crew Inc"],
			["ninjamuffin99",		"the Funkin'/ninjamuffin99",	"Programmer of Friday Night Funkin'",						"https://x.com/ninja_muffin99",		"CF2D2D"],
			["PhantomArcade",		"the Funkin'/phantomarcade",	"Animator of Friday Night Funkin'",							"https://x.com/PhantomArcade3K",	"FADC45"],
			["evilsk8r",			"the Funkin'/evilsk8r",			"Artist of Friday Night Funkin'",							"https://x.com/evilsk8r",			"5ABD4B"],
			["kawaisprite",			"the Funkin'/kawaisprite",		"Composer of Friday Night Funkin'",							"https://x.com/kawaisprite",		"378FC7"],
		];
		
		for(i in defaultList)
			creditsStuff.push(i);

		creditsPages = buildCreditPages(creditsStuff);
		creditsStuff = [];
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		pageText = new FlxText(0, 10, FlxG.width, "", 18);
		pageText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		pageText.scrollFactor.set();
		add(pageText);

		intendedColor = bg.color;
		changePage(0, false);
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		if(!quitting)
		{
			if(creditsPages.length > 1)
			{
				if(FlxG.keys.justPressed.Q)
				{
					changePage(-1);
					holdTime = 0;
				}
				if(FlxG.keys.justPressed.E)
				{
					changePage(1);
					holdTime = 0;
				}
			}

			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			var selectedLink:String = getSelectedLink();
			if(controls.ACCEPT && selectedLink != null) {
				CoolUtil.browserLoad(selectedLink);
			}
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new funkin.menus.MainMenuState());
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if(item != null && !item.bold)
			{
				var lerpVal:Float = Math.exp(-elapsed * 12);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(item.x - 70, lastX, lerpVal);
				}
				else
				{
					item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changePage(change:Int = 0, playSound:Bool = true)
	{
		if(creditsPages.length < 1)
			return;

		curPage = FlxMath.wrap(curPage + change, 0, creditsPages.length - 1);
		rebuildPageItems();
		updatePageText();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function rebuildPageItems()
	{
		for (item in grpOptions.members)
		{
			if(item != null) item.destroy();
		}
		grpOptions.clear();

		for (icon in iconArray)
		{
			if(icon == null) continue;
			remove(icon, true);
			icon.destroy();
		}
		iconArray = [];

		creditsStuff = creditsPages[curPage];
		curSelected = -1;

		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, getCreditField(i, 0, ''), !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable)
			{
				if(credit[5] != null)
					Mods.currentModDirectory = credit[5];

				var str:String = 'credits/picoEngine/default/missing_icon';
				if(credit[1] != null && credit[1].length > 0)
				{
					var fileName = 'credits/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if(str.endsWith('-pixel')) icon.antialiasing = false;
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;

				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}

		if(curSelected > -1)
			changeSelection(0, false);
		else
		{
			descText.visible = descBox.visible = false;
			curSelected = 0;
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(creditsStuff.length < 1 || curSelected < 0)
			return;

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		}
		while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(getCreditField(curSelected, 4, '444444'));
		//trace('The BG color is: $newColor');
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = getCreditField(curSelected, 2, '');
		if(descText.text.trim().length > 0)
		{
			descText.visible = descBox.visible = true;
			descText.y = FlxG.height - descText.height + offsetThing - 60;
	
			if(moveTween != null) moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
	
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
		else descText.visible = descBox.visible = false;
	}

	function updatePageText()
	{
		if(pageText != null)
			pageText.text = creditsPages.length > 1 ? 'Q < PAGE ${curPage + 1}/${creditsPages.length} > E' : '';
	}

	function getSelectedLink():String
	{
		if(curSelected < 0 || curSelected >= creditsStuff.length)
			return null;

		var link:String = getCreditField(curSelected, 3, '');
		return link != null && link.length > 4 ? link : null;
	}

	function getCreditField(index:Int, field:Int, fallback:String):String
	{
		if(index < 0 || index >= creditsStuff.length || creditsStuff[index] == null)
			return fallback;

		if(field < 0 || field >= creditsStuff[index].length)
			return fallback;

		var value:String = creditsStuff[index][field];
		return value != null ? value : fallback;
	}

	function buildCreditPages(source:Array<Array<String>>):Array<Array<Array<String>>>
	{
		var pages:Array<Array<Array<String>>> = [];
		var current:Array<Array<String>> = [];

		for (credit in source)
		{
			if(credit == null) continue;

			if(credit.length <= 1 && (credit[0] == null || credit[0].trim().length < 1))
			{
				pushCreditPage(pages, current);
				current = [];
				continue;
			}

			if(credit.length <= 1 && current.length > 0 && pageHasSelectable(current))
			{
				pushCreditPage(pages, current);
				current = [];
			}

			current.push(credit);
		}

		pushCreditPage(pages, current);
		if(pages.length < 1)
			pages.push([["Credits"]]);
		return pages;
	}

	function pushCreditPage(pages:Array<Array<Array<String>>>, page:Array<Array<String>>)
	{
		if(page.length < 1 || !pageHasSelectable(page))
			return;
		pages.push(page.copy());
	}

	function pageHasSelectable(page:Array<Array<String>>):Bool
	{
		for (credit in page)
			if(credit != null && credit.length > 1)
				return true;
		return false;
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		
		#if TRANSLATIONS_ALLOWED
		//trace('/data/credits-${ClientPrefs.data.language}.txt');
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num] == null || creditsStuff[num].length <= 1;
	}
}
