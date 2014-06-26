/* miscellaneous useful Javascript functions for event management, dom traversal, cookies... */

/* following subset of functions from Prototype JavaScript framework, version 1.5.1 (http://www.prototypejs.org/) */
var Class = {
  create: function() {
    return function() {
      this.initialize.apply(this, arguments);
    }
  }
}

Object.extend = function(destination, source) {
  for (var property in source) {
    destination[property] = source[property];
  }
  return destination;
}

Function.prototype.bind = function() {
  var __method = this, args = $A(arguments), object = args.shift();
  return function() {
    return __method.apply(object, args.concat($A(arguments)));
  }
}

Function.prototype.bindAsEventListener = function(object) {
  var __method = this, args = $A(arguments), object = args.shift();
  return function(event) {
    return __method.apply(object, [event || window.event].concat(args));
  }
}

var $A = Array.from = function(iterable) {
  if (!iterable) return [];
  if (iterable.toArray) {
    return iterable.toArray();
  } else {
    var results = [];
    for (var i = 0, length = iterable.length; i < length; i++)
      results.push(iterable[i]);
    return results;
  }
}

var Enumerable = {
  each: function(iterator) {
    var index = 0;
    try {
      this._each(function(value) {
        iterator(value, index++);
      });
    } catch (e) {
      if (e != $break) throw e;
    }
    return this;
  }
}  

Object.extend(Array.prototype, Enumerable);
Object.extend(Array.prototype, {
  _each: function(iterator) {
    for (var i = 0, length = this.length; i < length; i++)
      iterator(this[i]);
  }
});

// getElementById() shortcut
function $(element) {
  if (arguments.length > 1) {
    for (var i = 0, elements = [], length = arguments.length; i < length; i++)
      elements.push($(arguments[i]));
    return elements;
  }
  if (typeof element == 'string')
    element = document.getElementById(element);
  return element;
}

if (!window.Event) {
  var Event = new Object();
}
Object.extend(Event, {
  KEY_BACKSPACE: 8,
  KEY_TAB:       9,
  KEY_RETURN:   13,
  KEY_ESC:      27,
  KEY_LEFT:     37,
  KEY_UP:       38,
  KEY_RIGHT:    39,
  KEY_DOWN:     40,
  KEY_DELETE:   46,
  KEY_HOME:     36,
  KEY_END:      35,
  KEY_PAGEUP:   33,
  KEY_PAGEDOWN: 34,

  element: function(event) {
    return $(event.target || event.srcElement);
  },
  
  stop: function(event) {
    if (event.preventDefault) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      event.returnValue = false;
      event.cancelBubble = true;
    }
  }
});
/* end of Prototype functions */


var dom = {
	// nodetypes
	ELEMENT_NODE:1,	ATTRIBUTE_NODE:2, TEXT_NODE:3,
	
	walkTheDOM:function(node, func) {
		func(node);
		node = node.firstChild;
		while (node) {
			dom.walkTheDOM(node, func);
			node = node.nextSibling;
		} 
	},

	// crossbrowser addEvent
	addEvent: function(obj, evType, fn, useCapture) {
		if (useCapture==undefined)
			useCapture = false; // use bubbling
		if (obj.addEventListener){
			obj.addEventListener(evType, fn, useCapture);
			return true;
		} else if (obj.attachEvent){
			var r = obj.attachEvent("on"+evType, fn);
			return r;
		} else {
			alert("Handler could not be attached");
		}
	},

	// crossbrowser removeEvent
	removeEvent: function(obj, evType, fn, useCapture) {
		if (useCapture==undefined)
			useCapture = false; // use bubbling
		if (obj.removeEventListener){
			obj.removeEventListener(evType, fn, useCapture);
			return true;
		} else if (obj.detachEvent){
			var r = obj.detachEvent("on"+evType, fn);
			return r;
		} else {
			alert("Handler could not be removed");
		}
	},

	//note: ie6's garbage collector memory leak was finally patched
	purgeEventHandlers: function(node) {
		dom.walkTheDOM(node, function (e) {
			for (var n in e) {            
				if (typeof e[n] === 'function') {
					e[n] = null;
				}
			}
		});
	},
	
	/* assign an eventhandler to a list of eventtypes for given element, ex:
		delegateEvents($('mytable),['click','mouseover','mouseout'],myobj.myEventHandler.bindAsEventListener(this));
	*/
	delegateEvents: function(element, eventtypes, eventhandler)
	{
		for (var i=0;i<eventtypes.length; i++) {
			element['on'+eventtypes[i]] = eventhandler;
		}
	},

	/*  Written by Jonathan Snook, http://www.snook.ca/jonathan
	    Add-ons by Robert Nyman, http://www.robertnyman.com */
	getElementsByClassName: function(oElm, strTagName, strClassName){
	    var arrElements = (strTagName == "*" && oElm.all)? oElm.all : oElm.getElementsByTagName(strTagName);
	    var arrReturnElements = new Array();
	    strClassName = strClassName.replace(/\-/g, "\\-");
	    var oRegExp = new RegExp("(^|\\s)" + strClassName + "(\\s|$)");
	    var oElement;
	    for(var i=0; i<arrElements.length; i++){
	        oElement = arrElements[i];      
	        if(oRegExp.test(oElement.className)){
	            arrReturnElements.push(oElement);
	        }   
	    }
	    return (arrReturnElements);
	},

	/*  Copyright Robert Nyman, http://www.robertnyman.com	*/
	getElementsByAttribute: function(oElm, strTagName, strAttributeName, strAttributeValue){
	    var arrElements = (strTagName == "*" && oElm.all)? oElm.all : oElm.getElementsByTagName(strTagName);
	    var arrReturnElements = new Array();
	    var oAttributeValue = (typeof strAttributeValue != "undefined")? new RegExp("(^|\\s)" + strAttributeValue + "(\\s|$)") : null;
	    var oCurrent;
	    var oAttribute;
	    for(var i=0; i<arrElements.length; i++){
	        oCurrent = arrElements[i];
	        oAttribute = oCurrent.getAttribute && oCurrent.getAttribute(strAttributeName);
	        if(typeof oAttribute == "string" && oAttribute.length > 0){
	            if(typeof strAttributeValue == "undefined" || (oAttributeValue && oAttributeValue.test(oAttribute))){
	                arrReturnElements.push(oCurrent);
	            }
	        }
	    }
	    return arrReturnElements;
	},

	// returns parent html element of given tag, or null if not found, optional classname
	getParent: function(el, sTagName, classname)
	{
		if (el == null)
			return null;
		// gecko bug, supposed to be uppercase
		else if (el.nodeType==dom.ELEMENT_NODE && el.tagName.toLowerCase()==sTagName)
		{
			var oAttributeValue = (typeof classname !== "undefined") ? new RegExp("(^|\\s)" + classname + "(\\s|$)") : null;
			if (!oAttributeValue || oAttributeValue.test(el.className))
				return el;
		}
		return this.getParent(el.parentNode, sTagName, classname);
	},

	findPosition: function(elem) {
		if (elem.offsetParent){
			for (var posX=0, posY=0; elem.offsetParent; elem=elem.offsetParent){
				posX += elem.offsetLeft;
				posY += elem.offsetTop;
			}
			return [posX, posY];
		} else {
			return [elem.x, elem.y];
		}
	},

	// set element styles shorthand
	setStyle:function(element, oStyles)
	{
		for (var property in oStyles) {
			element.style[property] = oStyles[property];
		}
	}
}


var CssClass = {
	classnames: function(element) {
		return element.className.split(/\s+/);
	},
	
	set: function(element, s) {
		element.className = s;
	},
	
	add: function(element, s) {
		if (this.has(element,s)) return;// minimize refresh (for buggy IE)
		
		var classes = this.classnames(element);
		for (var i=0;i<classes.length;i++) {
			if (classes[i]=='s') return;
		}
		var newclasses = classes.concat(s).join(' ');
		element.className = newclasses;
	},
	
	has: function(element, className) {
	    var elementClassName = element.className;
	    return (elementClassName.length > 0 && (elementClassName == className ||
	      new RegExp("(^|\\s)" + className + "(\\s|$)").test(elementClassName)));
	},	      

	remove: function(element, s) {
		if (!this.has(element,s)) return;// minimize refresh (for buggy IE)
		
		var classes = this.classnames(element);
		var newclasses = '';
		for (var i=0;i<classes.length;i++) {
			if (classes[i]!=s) {
				newclasses += (i>0?' ':'')+classes[i];
			}
		}
		element.className = newclasses;
	},

	replace: function(element, sold, snew) {
		var classes = this.classnames(element);
		var newclasses = '';
		for (var i=0;i<classes.length;i++) {
			if (classes[i]!=sold) {
				newclasses += (i>0?' ':'')+classes[i];
			}
		}
		element.className = newclasses+' '+snew;
	}
}

var Cookies = {
	
	create: function(name,value,days) {
		if (days) {
			var date = new Date();
			date.setTime(date.getTime()+(days*24*60*60*1000));
			var expires = "; expires="+date.toGMTString();
		}
		else {
			expires = "";
		}
		document.cookie = name+"="+value+expires+"; path=/";
	},

	read: function(name) {
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' ') {
				c = c.substring(1,c.length);
			}
			if (c.indexOf(nameEQ) == 0) {
				return c.substring(nameEQ.length,c.length);
			}
		}
		return null;
	}
}


/* testing (this part can be removed) */

var KT_CONSOLE_ENABLED = true;
var KT_CONSOLE_ID = 'DBGConsole_DEBUG';

function DBGConsole() {	this.debugCounter = 0; }
DBGConsole.prototype.log = function(message)
{
	if (!KT_CONSOLE_ENABLED) return;
    this.debugCounter++;

	var found = !!document.getElementById(KT_CONSOLE_ID);
	if (!found) {
		// create the debugging div
		d = document.createElement('div');
		d.id = KT_CONSOLE_ID;
		d.style.position = "absolute";
		d.style.right = '0';
		d.style.top = '0';
		d.style.border = "2px solid #dc0000";
		d.style.background = '#fff5f5';
		d.style.padding = '5px';
		d.style.textAlign = 'left';
		d.style.color = '#000';
		d.style.font = '11px Courier New, monospace;';
		document.getElementsByTagName('body')[0].appendChild(d);
	}
	var t = document.createTextNode(''+this.debugCounter + ': ' + message);
    var br = document.createElement('br');
	d.appendChild(t);
    d.appendChild(br);
}

if (!console || (!KT_CONSOLE_ENABLED && console.log && console.assert) ) {
	var console = new DBGConsole();
}
