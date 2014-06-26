/**
 * Runewizard
 *
 * @author   Denis Fabrice
 * @version  1.1 2008/07/17
 * @license  Creative Commons Attribution-Noncommercial-Share Alike
 *           http://creativecommons.org/licenses/by-nc-sa/2.0/be/
 *           See additional conditions at footer of the html page.
 *
 * Tested with Firefox 3, Opera 9.5, Safari 3.1.2 (Windows), IE6, IE7 (beta).
 * 
 * This script was written for readability, and to make it easy for others
 * to modify (for example to adapt to Runewords featured in Diablo II mods).
 *
 * The layer code is kept really simple, it doesn't account for clipping at
 * the bottom of the screen, that's why I added some padding after the main
 * table so the description of the last runewords remains visible in its entirety.
 * 
 * If you change MAX_RUNES, you need to adapt the number of table heads, as
 * well as table cells in the "template" row in the html file.
 */

var Runewords = [
	/* 1.09 */
	{ title: "Ancient's Pledge", runes: ['Ral','Ort','Tal'], ttype:"Shields" },
	{ title: "Black", runes: ['Thul','Io','Nef'], ttype:"Clubs/Hammers/Maces" },
	{ title: "Fury", runes: ['Jah','Gul','Eth'], ttype:"Melee&nbsp;Weapons" },
	{ title: "Holy Thunder", runes: ['Eth','Ral','Ort','Tal'], ttype:"Scepters" },
	{ title: "Honor", runes: ['Amn','El','Ith','Tir','Sol'], ttype:"Melee Weapons" },
	{ title: "King's Grace", runes: ['Amn','Ral','Thul'], ttype:"Swords/Scepters" },
	{ title: "Leaf", runes: ['Tir','Ral'], ttype:"Staves<span class=\"small\">(Not Orbs/Wands)<span>" },
	{ title: "Lionheart", runes: ['Hel','Lum','Fal'], ttype:"Body Armor" },
	{ title: "Lore", runes: ['Ort','Sol'], ttype:"Helms" },
	{ title: "Malice", runes: ['Ith','El','Eth'], ttype:"Melee Weapons" },
	{ title: "Melody", runes: ['Shael','Ko','Nef'], ttype:"Missile Weapons" },
	{ title: "Memory", runes: ['Lum','Io','Sol','Eth'], ttype:"Staves<span class=\"small\">(Not Orbs)<span>" },
	{ title: "Nadir", runes: ['Nef','Tir'], ttype:"Helms" },
	{ title: "Radiance", runes: ['Nef','Sol','Ith'], ttype:"Helms" },
	{ title: "Rhyme", runes: ['Shael','Eth'], ttype:"Shields" },
	{ title: "Silence", runes: ['Dol','Eld','Hel','Ist','Tir','Vex'], ttype:"Weapons" },
	{ title: "Smoke", runes: ['Nef','Lum'], ttype:"Body Armor" },
	{ title: "Stealth", runes: ['Tal','Eth'], ttype:"Body Armor" },
	{ title: "Steel", runes: ['Tir','El'], ttype:"Swords/Axes/Maces" },
	{ title: "Strength", runes: ['Amn','Tir'], ttype:"Melee Weapons" },
	{ title: "Venom", runes: ['Tal','Dol','Mal'], ttype:"Weapons" },
	{ title: "Wealth", runes: ['Lem','Ko','Tir'], ttype:"Body Armor" },
	{ title: "White", runes: ['Dol','Io'], ttype:"Wand" },
	{ title: "Zephyr", runes: ['Ort','Eth'], ttype:"Missile Weapons" },
	/* 1.10 */
	{ title: "Beast", runes: ['Ber','Tir','Um','Mal','Lum'], ttype:"Axes/Scepters/Hammers" },
	{ title: "Bramble", runes: ['Ral','Ohm','Sur','Eth'], ttype:"Body Armor" },
	{ title: "Breath of the Dying", runes: ['Vex','Hel','El','Eld','Zod','Eth'], ttype:"Weapons" },
	{ title: "Call To Arms", runes: ['Amn','Ral','Mal','Ist','Ohm'], ttype:"Weapons" },
	{ title: "Chaos", runes: ['Fal','Ohm','Um'], ttype:"Claws" },
	{ title: "Chains of Honor", runes: ['Dol','Um','Ber','Ist'], ttype:"Body Armor" },
	{ title: "Crescent Moon", runes: ['Shael','Um','Tir'], ttype:"Axes/Swords/Polearms" },
	{ title: "Delirium", runes: ['Lem','Ist','Io'], ttype:"Helms" },
	{ title: "Doom", runes: ['Hel','Ohm','Um','Lo','Cham'], ttype:"Axes/Polearms/Hammers" },
	{ title: "Duress", runes: ['Shael','Um','Thul'], ttype:"Body Armor" },
	{ title: "Enigma", runes: ['Jah','Ith','Ber'], ttype:"Body Armor" },
	{ title: "Eternity", runes: ['Amn','Ber','Ist','Sol','Sur'], ttype:"Melee Weapons" },
	{ title: "Exile", runes: ['Vex','Ohm','Ist','Dol'], ttype:"Paladin Shields (only)" },
	{ title: "Famine", runes: ['Fal','Ohm','Ort','Jah'], ttype:"Axes/Hammers" },
	{ title: "Gloom", runes: ['Fal','Um','Pul'], ttype:"Body Armor" },
	{ title: "Hand of Justice", runes: ['Sur','Cham','Amn','Lo'], ttype:"Weapons" },
	{ title: "Heart of the Oak", runes: ['Ko','Vex','Pul','Thul'], ttype:"Staves*/Maces" },
	{ title: "Kingslayer", runes: ['Mal','Um','Gul','Fal'], ttype:"Swords/Axes" },
	{ title: "Passion", runes: ['Dol','Ort','Eld','Lem'], ttype:"Weapons" },
	{ title: "Prudence", runes: ['Mal','Tir'], ttype:"Body Armor" },
	{ title: "Sanctuary", runes: ['Ko','Ko','Mal'], ttype:"Shields" },
	{ title: "Splendor", runes: ['Eth','Lum'], ttype:"Shields" },
	{ title: "Stone", runes: ['Shael','Um','Pul','Lum'], ttype:"Body Armor" },
	{ title: "Wind", runes: ['Sur','El'], ttype:"Melee Weapons" },
	/* 1.10 LADDER */
	{ title: "Brand", runes: ['Jah','Lo','Mal','Gul'], ttype:"Missile Weapons", ladder:true },
	{ title: "Death", runes: ['Hel','El','Vex','Ort','Gul'], ttype:"Swords/Axes", ladder:true },
	{ title: "Destruction", runes: ['Vex','Lo','Ber','Jah','Ko'], ttype:"Polearms/Swords", ladder:true },
	{ title: "Dragon", runes: ['Sur','Lo','Sol'], ttype:"Body Armor/Shields", ladder:true },
	{ title: "Dream", runes: ['Io','Jah','Pul'], ttype:"Helms/Shields", ladder:true },
	{ title: "Edge", runes: ['Tir','Tal','Amn'], ttype:"Missile Weapons", ladder:true },
	{ title: "Faith", runes: ['Ohm','Jah','Lem','Eld'], ttype:"Missile Weapons", ladder:true },
	{ title: "Fortitude", runes: ['El','Sol','Dol','Lo'], ttype:"Weapons/Body Armor", ladder:true },
	{ title: "Grief", runes: ['Eth','Tir','Lo','Mal','Ral'], ttype:"Swords/Axes", ladder:true },
	{ title: "Harmony", runes: ['Tir','Ith','Sol','Ko'], ttype:"Missile Weapons", ladder:true },
	{ title: "Ice", runes: ['Amn','Shael','Jah','Lo'], ttype:"Missile Weapons", ladder:true },
	{ title: "Infinity", runes: ['Ber','Mal','Ber','Ist'], ttype:"Polearms", ladder:true },
	{ title: "Insight", runes: ['Ral','Tir','Tal','Sol'], ttype:"Polearms/Staves", ladder:true },
	{ title: "Last Wish", runes: ['Jah','Mal','Jah','Sur','Jah','Ber'], ttype:"Swords/Hammers/Axes", ladder:true },
	{ title: "Lawbringer", runes: ['Amn','Lem','Ko'], ttype:"Swords/Hammers/Scepter", ladder:true },
	{ title: "Oath", runes: ['Shael','Pul','Mal','Lum'], ttype:"Swords/Axes/Maces", ladder:true },
	{ title: "Obedience", runes: ['Hel','Ko','Thul','Eth','Fal'], ttype:"Polearms", ladder:true },
	{ title: "Phoenix", runes: ['Vex','Vex','Lo','Jah'], ttype:"Weapons/Shields", ladder:true },
	{ title: "Pride", runes: ['Cham','Sur','Io','Lo'], ttype:"Polearms", ladder:true },
	{ title: "Rift", runes: ['Hel','Ko','Lem','Gul'], ttype:"Polearms/Scepters", ladder:true },
	{ title: "Spirit", runes: ['Tal','Thul','Ort','Amn'], ttype:"Swords/Shields", ladder:true },
	{ title: "Voice of Reason", runes: ['Lem','Ko','El','Eld'], ttype:"Swords/Maces", ladder:true },
	{ title: "Wrath", runes: ['Pul','Lum','Ber','Mal'], ttype:"Missile Weapons", ladder:true },
	/* 1.11 */
	{ title: "Bone", runes: ['Sol','Um','Um'], ttype:"Body Armor<span class=\"small\">(Necromancer)</span>", tclass:"Necromancer" },
	{ title: "Enlightenment", runes: ['Pul','Ral','Sol'], ttype:"Body Armor<span class=\"small\">(Sorceress)</span>", tclass:"Sorceress" },
	{ title: "Myth", runes: ['Hel','Amn','Nef'], ttype:"Body Armor<span class=\"small\">(Barbarian)</span>", tclass:"Barbarian" },
	{ title: "Peace", runes: ['Shael','Thul','Amn'], ttype:"Body Armor<span class=\"small\">(Amazon)</span>", tclass:"Amazon" },
	{ title: "Principle", runes: ['Ral','Gul','Eld'], ttype:"Body Armor<span class=\"small\">(Paladin)</span>", tclass:"Paladin" },
	{ title: "Rain", runes: ['Ort','Mal','Ith'], ttype:"Body Armor<span class=\"small\">(Druid)</span>", tclass:"Druid" },
	{ title: "Treachery", runes: ['Shael','Thul','Lem'], ttype:"Body Armor<span class=\"small\">(Assassin)</span>", tclass:"Assassin" }
];

var Runes = {
	El:   { },
	Eld:  { },
	Tir:  { },
	Nef:  { },
	Eth:  { },
	Ith:  { },
	Tal:  { },
	Ral:  { },
	Ort:  { },
	Thul: { },
	Amn:  { },
	
	Sol:  { },
	Shael:{ },
	Dol:  { },
	Hel:  { },
	Io:   { },
	Lum:  { },
	Ko:   { },
	Fal:  { },
	Lem:  { },
	Pul:  { },
	Um:   { },
	
	Mal:  { },
	Ist:  { },
	Gul:  { },
	Vex:  { },
	Ohm:  { },
	Lo:   { },
	Sur:  { },
	Ber:  { },
	Jah:  { },
	Cham: { },
	Zod:  { }
};

var App =
{
	MAX_RUNES:      6,
	TEMPLATE_ROW:   'template', // template row class
	
	COOKIE_NAME:    'runes',
	COOKIE_DAYS:    120, // days
	COOKIE_SPLIT:   '.',
	
	haveRunes:       {},
	descriptionDivs: {},
	map_ids: 		 {},

	init:function()
	{
		this.initHaveRunes();
		this.initRunewordsTable();

		this.updateRunewords();
		this.initEvents();
		
		this.displayRunes();
		
		this.initHelp();
	},
	
	initHelp:function()
	{
		var fn = this.helpEventHandler.bindAsEventListener(this);
		dom.addEvent($('JsHelpOpen'), 'click', fn);
		dom.addEvent($('JsHelpClose'), 'click', fn);
	},

	resetRunes:function()
	{
		for (var rune_name in Runes){
			this.haveRunes[rune_name] = false;
		}
	},
	
	initHaveRunes:function()
	{
		this.resetRunes();

		this.loadRunes();
		
		if (this.countRunes()) {
			$('JsClearRunes').style.display = 'block';
		}
	},
	
	loadRunes:function()
	{
		var cookie_str = Cookies.read(this.COOKIE_NAME);
		if (cookie_str!==null)
		{
			var loadedRunes = cookie_str.split(this.COOKIE_SPLIT);
			for (var i=0; i<loadedRunes.length; i++)
			{
				var rune_id = loadedRunes[i];
				if (typeof Runes[rune_id] !=='undefined') {
					this.haveRunes[rune_id] = true;
				}
			}
		}
	},
	
	saveRunes:function()
	{
		var cookie_str = '';
		var runes = [];
		for (var rune_id in Runes)
		{
			if (this.haveRunes[rune_id]) {
				runes.push(rune_id);
			}
		}
		cookie_str = runes.join(this.COOKIE_SPLIT);
		Cookies.create(this.COOKIE_NAME, cookie_str, this.COOKIE_DAYS);
	},
	
	countRunes:function()
	{
		var count = 0;
		for (var rune_id in this.haveRunes) {
			count += this.haveRunes[rune_id] ? 1 : 0;
		}
		return count;
	},
	
	displayRunes:function()
	{
		for (rune_id in Runes)
		{
			this.updateRune(rune_id, this.haveRunes[rune_id]);
		}
	},
	
	initEvents:function()
	{
		// runes : add event handler and map links to ids
		var runesDiv = dom.getElementsByClassName(document,'div','runes')[0];
		var links = runesDiv.getElementsByTagName('a');
		for (i=0; i<links.length; i++)
		{
			var rune_id = /Rune-(\w+)/.test(links[i].id) ? RegExp.$1 : 'error';
			if (typeof Runes[rune_id] !== 'undefined') {
				Runes[rune_id].elem = links[i];
			}
		}
		
		dom.addEvent(runesDiv, ['click'], this.runesEventHandler.bindAsEventListener(this));

		// runeword description
		var table = this.runewordsTable;
		dom.delegateEvents(table, ['mouseover', 'mouseout','click'], this.tableEvents.bindAsEventListener(this));
	},

	initRunewordsTable:function()
	{
		var table = dom.getElementsByClassName(document,'table','runewords')[0];
		if (table)
		{
			this.runewordsTable = table;
			//this.map_rows = {};
			
			var tbody = table.tBodies[0];
			var rowTemplate = dom.getElementsByClassName(tbody,'tr',this.TEMPLATE_ROW)[0];
			
			var sImgLadder = '<img src='+this.ICON_LADDER+' />';
			
			for (r=0; r<Runewords.length; r++)
			{
				var runeword = Runewords[r];
				
				var newRow = rowTemplate.cloneNode(true);
				
				runeword.tableRow = newRow;
				
				tbody.appendChild(newRow);

				// runes
				for (i=0; i<this.MAX_RUNES; i++)
				{
					if (i<runeword.runes.length) {
						newRow.cells[i+1].innerHTML = runeword.runes[i];
					}
				}
				
				// description layer id
				sLayerId = runeword.title.replace(/[^a-zA-Z0-9]/g, '_');
				/* Detect missing div
				if (!$(sLayerId)) {
					alert('woops '+sLayerId);
				}
				*/
				// lookup for later
				this.map_ids[sLayerId] = runeword;
				
				// title
				newRow.cells[0].innerHTML = '<a href="#" class="'+(runeword.ladder ? 'icon-ladder ' : '')+'ShowLayer" rel="'+sLayerId+'">' + runeword.title + '</a>';
				
				// item type
				newRow.cells[this.MAX_RUNES+1].innerHTML = this.autoNbsp(runeword.ttype);

				newRow.style.display = '';
			}
		}
	},
	
	tableEvents:function(e)
	{
		var elem = Event.element(e);
		if (elem.nodeName.toLowerCase()=='a' && /ShowLayer/.test(elem.className))
		{
			// the rel attribute of the link is the id of the corresponding div to show
			var descrDivId = elem.getAttribute('rel');

			var layerDiv = $('JsLayer');

			if (e.type==='mouseover')
			{
				var layerPos = dom.findPosition(elem);
				layerPos[0] += 50;
				layerPos[1] += elem.offsetHeight+1;  // dont overlap the link to keep mouse events simple
				
				this.setLayerContents(descrDivId);

				dom.setStyle(layerDiv,{
					display:	'block',
					position:	'absolute',
					left:		layerPos[0]+'px',
					top:		layerPos[1]+'px'
				});
			}
			else if (e.type==='mouseout')
			{
				dom.setStyle(layerDiv,{
					display:	'none'
				});
			}
			else if (e.type==='click')
			{
				Event.stop(e);
				return false;
			}
		}
		return true;
	},
	
	runesEventHandler:function(e)
	{
		var elem = Event.element(e);
		
		// clickable runes
		if (elem.nodeName.toLowerCase()==='a')
		{
			if (elem.id==='JsClearRunes')
			{
				$('JsClearRunes').style.display = 'none';
				this.resetRunes();
				this.displayRunes();
				this.updateRunewords();
				this.saveRunes();
			}
			else if (/Rune-(\w+)/.test(elem.id))
			{
				var rune_id =  RegExp.$1;
				var state = !this.haveRunes[rune_id];
				this.haveRunes[rune_id] = state;
				this.updateRune(rune_id, state);
				this.updateRunewords();
				
				// clear selection link
				$('JsClearRunes').style.display = this.countRunes() ? '' : 'none';
				
				// update cookie
				this.saveRunes();
			}
		
			Event.stop(e);
			return false;
		}

		return true;
	},
	
	helpEventHandler:function(e)
	{
		var elem = Event.element(e);
		var helpDiv = $('JsHelpBody');
		if (elem.id==='JsHelpOpen')
		{
			// allow toggle on/off
			this.helpOpened = !this.helpOpened;
			helpDiv.style.display = this.helpOpened ? 'block' : 'none';
		}
		else /* JsHelpClose */
		{
			helpDiv.style.display = 'none';
			this.helpOpened = false;
		}
	},
	
	setLayerContents:function(descrDivId)
	{
		var runeword = this.map_ids[descrDivId];
		var descrDiv = this.descriptionDivs[descrDivId];	
		if (!descrDiv)
		{
			descrDiv = $(descrDivId);
			descrDiv.parentNode.removeChild(descrDiv);
			this.descriptionDivs[descrDivId] = descrDiv;
		}
		
		// set title part
		$('JsLayerTitle').innerHTML = runeword.title;
		$('JsLayerType').innerHTML = runeword.ttype;
		
		// set description
		var layerContentsDiv = $('JsLayerContents');
		layerContentsDiv.replaceChild(descrDiv, layerContentsDiv.firstChild);
		descrDiv.style.display = 'block';
	},


	autoNbsp:function(s)
	{
		if (s!='')
			return s;
		else
			return '&nbsp;';
	},

	updateRunewords:function()
	{
		var numComplete = 0;
		var moverows = [];
		for (i=0; i<Runewords.length; i++)
		{
			var runeword = Runewords[i];
			var row = runeword.tableRow;
			var runes = runeword.runes;
			var haveAll = 0;
			for (j=0; j<runes.length; j++)
			{
				if (this.haveRunes[runes[j]]) {
					haveAll++;
					cssClass = 'y';
				}
				else {
					cssClass = 'n';
				}
				row.cells[j+1].className = cssClass;
			}
			
			var bComplete = haveAll==j;
			
			row.className = bComplete ? 'complete' : 'incomplete';
			
			// number of runes missing
			row.cells[this.MAX_RUNES+2].innerHTML = runes.length - haveAll;
						
			// completed runewords
			if (bComplete) {
				numComplete++;
				/* mod.1.
				moverows.push(row);
				*/
			}
		}

		// move complete runewords to top of list
		/* mod.1.
		var tbody = this.runewordsTable.tBodies[0];
		for (i=0; i<numComplete; i++)
		{
			tbody.insertBefore(moverows[i], tbody.rows[i]);
		}*/
		
		// sort table on the Missing Runes column (i.e. by "completeness")
		var lnk = this.runewordsTable.tHead.rows[0].cells[this.MAX_RUNES+2].getElementsByTagName('a')[0];
		lnk.className = 'sortup'; //always sort down
		sortables.ts_resortTable(lnk, 8);

		if (numComplete) {
			this.setRunewordCount(' ('+numComplete+' available)');
		}
		else {
			this.setRunewordCount('');
		}
	},
	
	setRunewordCount:function(s)
	{
		$('runewords-count').innerHTML = s;
	},
	
	updateRune:function(rune_id, state)
	{
		Runes[rune_id].elem.className = state ? 'have' : 'have_not';
	}
}

dom.addEvent(window,'load',
	function(){
		sortables.initialize();
		App.init();
	}
);
