package funkin.states.options.data;

import funkin.states.options.config.*;

class PicoEngineSubState extends BaseOptionsMenu {
	public function new() {
    title = Language.getPhrase("pico_menu","Pico Engine (W.I.P Settings)");
    rpcTitle = "Pico Engine Settings Menu (W.I.P)"; {

		var option:Option = new Option('Characters Note Skins',
			"If checked, Enables NoteSkins In Songs (Character Specific)",
			'noteskinsCharacters',
			STRING,
			['Disabled', 'Both', 'Player', 'Opponent']);
		addOption(option);

        var option:Option = new Option('Max Combo',
		'Enable/Disable Max Combo on the game screen.',
		'comboEnabled',
		BOOL);
	    addOption(option);

		var option:Option = new Option('V Slice Hub',
		'If checked, uses the V-Slice styled HUD and health bar.',
		'SliceHub',
		BOOL);
		addOption(option);

		var option:Option = new Option('Hold Note',
		'Enable/Disable to prevent characters from performing hold animations during music.',
		'noteHold',
		BOOL);
		addOption(option);

		var option:Option = new Option('Use Mod Charts',
		'If unchecked, it will not use the Mod Chart in the Songs.',
		'modcharts',
		BOOL);
		addOption(option);
		super();
		}
	}
}