/**
 * sorttable.js - client-side table sorting
 * 
 * This is a modified version of Stuart Langridge's "sorttable" script.
 *
 * Changes :
 * - Functions moved inside an object, using "this"
 * - Replaced the arrow character with CSS (class "sortup" or "sortdown" on the links)
 * - Added row highlight code
 * 
 * @author  Denis Fabrice (changes)
 * @author  Stuart Langridge (original code)
 * @link    http://www.kryogenix.org/code/browser/sorttable/
 */

var sortables =
{
	SORT_COLUMN_INDEX:0,

	initialize:function() {
	    // Find all tables with class sortable and make them sortable
	    if (!document.getElementsByTagName) return;
	    tbls = document.getElementsByTagName("table");
	    for (ti=0;ti<tbls.length;ti++) {
	        thisTbl = tbls[ti];
	        if (((' '+thisTbl.className+' ').indexOf("sortable") != -1)) {
	            //initTable(thisTbl.id);
	            this.ts_makeSortable(thisTbl);
	        }
	    }
	},
	
	ts_makeSortable:function(table) {
	    if (table.rows && table.rows.length > 0) {
	        var firstRow = table.rows[0];
	    }
	    if (!firstRow) return;
	    
	    // We have a first row: assume it's the header, and make its contents clickable links
	    for (var i=0;i<firstRow.cells.length;i++)
	    {
	        var cell = firstRow.cells[i];
	        var txt = this.ts_getInnerText(cell);
	        cell.innerHTML = '<a href="#" class="sort" onclick="sortables.ts_resortTable(this, '+i+');return false;">'+txt+'</a>';
	    }
	},

	ts_getInnerText:function(el) {
		if (typeof el == "string") return el;
		if (typeof el == "undefined") { return el };
		if (el.innerText) return el.innerText;	//Not needed but it is faster
		var str = "";
		
		var cs = el.childNodes;
		var l = cs.length;
		for (var i = 0; i < l; i++) {
			switch (cs[i].nodeType) {
				case 1: //ELEMENT_NODE
					str += this.ts_getInnerText(cs[i]);
					break;
				case 3:	//TEXT_NODE
					str += cs[i].nodeValue;
					break;
			}
		}
		return str;
	},
	
	ts_resortTable:function(lnk, clid)
	{
	//console.time('ts_resortTable');
	
	    var td = lnk.parentNode;
	    var column = clid || td.cellIndex;
	    var table = this.getParent(td,'TABLE');
	    
	    // Work out a type for the column
	    if (table.rows.length <= 1) return;
	    var itm = this.ts_getInnerText(table.rows[1].cells[column]);
	    sortfn = this.ts_sort_caseinsensitive;
	    if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d\d\d$/)) sortfn = this.ts_sort_date;
	    if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d$/)) sortfn = this.ts_sort_date;
	    if (itm.match(/^[�$]/)) sortfn = this.ts_sort_currency;
	    if (itm.match(/^[\d\.]+$/)) sortfn = this.ts_sort_numeric;
	    this.SORT_COLUMN_INDEX = column;
	    var firstRow = new Array();
	    var newRows = new Array();
	    for (i=0;i<table.rows[0].length;i++) { firstRow[i] = table.rows[0][i]; }
	    for (j=1;j<table.rows.length;j++) { newRows[j-1] = table.rows[j]; }
	
	    newRows.sort(sortfn);
	
	   
	    if (lnk.className && lnk.className == 'sortdown') {
	    	newRows.reverse();
	    	lnk.className = 'sortup';
	    } else {
	    	lnk.className = 'sortdown';
	    }
	    
	    // We appendChild rows that already exist to the tbody, so it moves them rather than creating new ones
	    // don't do sortbottom rows
	    for (i=0;i<newRows.length;i++) { if (!newRows[i].className || (newRows[i].className && (newRows[i].className.indexOf('sortbottom') == -1))) table.tBodies[0].appendChild(newRows[i]);}
	    // do sortbottom rows only
	    for (i=0;i<newRows.length;i++) { if (newRows[i].className && (newRows[i].className.indexOf('sortbottom') != -1)) table.tBodies[0].appendChild(newRows[i]);}
	    
	    // Delete any other arrows there may be showing
	
		var aTags = document.getElementsByTagName('a');
		for (var i=0; i < aTags.length; i++) {
			if (aTags[i].className == 'sortup' || aTags[i].className == 'sortdown') {
				if (aTags[i] != lnk) {
					aTags[i].className = 'sort';
				}
			}
		}
	//console.timeEnd('ts_resortTable');
	},
	
	ts_sort_date:function(a,b) {
	    // y2k notes: two digit years less than 50 are treated as 20XX, greater than 50 are treated as 19XX
	    aa = sortables.ts_getInnerText(a.cells[sortables.SORT_COLUMN_INDEX]);
	    bb = sortables.ts_getInnerText(b.cells[sortables.SORT_COLUMN_INDEX]);
	    if (aa.length == 10) {
	        dt1 = aa.substr(6,4)+aa.substr(3,2)+aa.substr(0,2);
	    } else {
	        yr = aa.substr(6,2);
	        if (parseInt(yr) < 50) { yr = '20'+yr; } else { yr = '19'+yr; }
	        dt1 = yr+aa.substr(3,2)+aa.substr(0,2);
	    }
	    if (bb.length == 10) {
	        dt2 = bb.substr(6,4)+bb.substr(3,2)+bb.substr(0,2);
	    } else {
	        yr = bb.substr(6,2);
	        if (parseInt(yr) < 50) { yr = '20'+yr; } else { yr = '19'+yr; }
	        dt2 = yr+bb.substr(3,2)+bb.substr(0,2);
	    }
	    if (dt1==dt2) return 0;
	    if (dt1<dt2) return -1;
	    return 1;
	},
	
	ts_sort_currency:function(a,b) { 
	    aa = sortables.ts_getInnerText(a.cells[sortables.SORT_COLUMN_INDEX]).replace(/[^0-9.]/g,'');
	    bb = sortables.ts_getInnerText(b.cells[sortables.SORT_COLUMN_INDEX]).replace(/[^0-9.]/g,'');
	    return parseFloat(aa) - parseFloat(bb);
	},
	
	ts_sort_numeric:function(a,b) { 
	    aa = parseFloat(sortables.ts_getInnerText(a.cells[sortables.SORT_COLUMN_INDEX]));
	    if (isNaN(aa)) aa = 0;
	    bb = parseFloat(sortables.ts_getInnerText(b.cells[sortables.SORT_COLUMN_INDEX])); 
	    if (isNaN(bb)) bb = 0;
	    return aa-bb;
	},
	
	ts_sort_caseinsensitive:function(a,b) {
	    aa = sortables.ts_getInnerText(a.cells[sortables.SORT_COLUMN_INDEX]).toLowerCase();
	    bb = sortables.ts_getInnerText(b.cells[sortables.SORT_COLUMN_INDEX]).toLowerCase();
	    if (aa==bb) return 0;
	    if (aa<bb) return -1;
	    return 1;
	},
	
	ts_sort_default:function(a,b) {
	    aa = sortables.ts_getInnerText(a.cells[sortables.SORT_COLUMN_INDEX]);
	    bb = sortables.ts_getInnerText(b.cells[sortables.SORT_COLUMN_INDEX]);
	    if (aa==bb) return 0;
	    if (aa<bb) return -1;
	    return 1;
	},
	
	getParent:function(el, pTagName) {
		if (el == null) return null;
		else if (el.nodeType == 1 && el.tagName.toLowerCase() == pTagName.toLowerCase())	// Gecko bug, supposed to be uppercase
			return el;
		else
			return this.getParent(el.parentNode, pTagName);
	}
}

/*
var tableRowHighlight = {

	HIGHLIGHT_CLASS: 'hover',

	initialize:function()
	{
		var table = dom.getElementsByClassName(document,'table','sortable')[0];
		if (table) {
			dom.delegateEvents(table, ['mouseover','mouseout'], this.rowEvent.bindAsEventListener(this));
		}
	},
	
	rowEvent:function(e)
	{
		var elem = Event.element(e);
		var tr = dom.getParent(elem,'tr');
		if (!tr)
			return;
		switch(e.type){
			case 'mouseover': CssClass.add(tr,this.HIGHLIGHT_CLASS); break;
			case 'mouseout': CssClass.remove(tr,this.HIGHLIGHT_CLASS); break;
			default: break;
		}
	}
}
*/
