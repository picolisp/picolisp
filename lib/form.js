/* 07mar12abu
 * (c) Software Lab. Alexander Burger
 */

var FormReq = false;
var HintReq = false;
var Hint, Hints, Item, Beg, End;

try {
   FormReq = new XMLHttpRequest();
   HintReq = new XMLHttpRequest();
   FormReq.upload.addEventListener("progress", dropProgress, false);
   FormReq.upload.addEventListener("load", dropLoad, false);
}
catch (e) {}

var Queue = new Array();
var Btn = new Array();
var Key, InBtn, Auto, Drop;

function inBtn(flg) {InBtn = flg;}

function formKey(event) {
   Key = event.keyCode;
   if (Hint  &&  Hint.style.visibility == "visible") {
      if ((Item >= 0 && Key == 13) || Key == 38 || Key == 40)
         return false;
      if (event.keyCode == 27) {
         Hint.style.visibility = "hidden";
         return false;
      }
   }
   return true;
}

function fldChg(field) {
   if (!InBtn && Key != 13)
      post(field.form, null);
   return true;
}

function doBtn(btn) {
   Btn.push(btn);
   return true;
}

function doDrag(event) {
   event.stopPropagation();
   event.preventDefault();
}

function doDrop(btn, event) {
   doDrag(event);
   if (event.dataTransfer.files.length != 0) {
      Btn.push(Drop = btn);
      btn.value = "0 %";
      post(btn.form, event.dataTransfer.files[0]);
   }
}

function dropProgress(event) {
   if (Drop)
      Drop.value = event.lengthComputable?
         Math.round((event.loaded * 100) / event.total) + " %" : "(?) %";
}

function dropLoad(event) {
   Drop = null;
}

function hasElement(form, name) {
   for (var i = 0; i < form.elements.length; ++i)
      if (form.elements[i].name == name)
         return true;
   return false;
}

/*** Form submit ***/
function doPost(form) {
   for (var i = 0; ; ++i) {
      if (i == Btn.length)
         return true;
      if (Btn[i].form == form)
         break;
   }
   return post(form, null);
}

function post(form, file) {
   var i;

   if (!FormReq || !hasElement(form,"*Get") || (i = form.action.indexOf("~")) <= 0)
      return true;
   if (FormReq.readyState > 0 && FormReq.readyState < 4) {
      Queue.push(form);
      return false;
   }
   form.style.cursor = "wait";
   try {FormReq.open("POST", form.action.substr(0,i) + "~!jsForm?" + form.action.substr(i+1));}
   catch (e) {return true;}
   FormReq.onreadystatechange = function() {
      if (FormReq.readyState == 4 && FormReq.status == 200) {
         var i, j;

         if (FormReq.responseText == "T") {
            Queue.length = 0;
            form.submit();
         }
         else {
            var txt = FormReq.responseText.split("&");

            if (txt[0]) {
               var r = txt[0].split(":");

               if (Auto)
                  window.clearTimeout(Auto);
               if (r[1])
                  Auto = window.setTimeout("document.getElementById(\"" + r[0] + "\").click()", r[1]);
            }
            for (i = 1; i < txt.length;) {
               var fld = txt[i++];
               var val = decodeURIComponent(txt[i++]);

               if (!fld) {
                  window[txt[i++]](val);
                  continue;
               }
               if (!(fld = document.getElementById(fld)))
                  continue;
               if (fld.tagName == "SPAN") {
                  if (i != txt.length && txt[i].charAt(0) == "=")
                     ++i;
                  if (i == txt.length || txt[i].charAt(0) != "+") {
                     if (fld.firstChild.tagName != "A")
                        fld.firstChild.data = val? val : "\u00A0";
                     else
                        fld.replaceChild(document.createTextNode(val? val : "\u00A0"), fld.firstChild);
                  }
                  else {
                     var a = document.createElement("A");

                     a.href = decodeURIComponent(txt[i++].substr(1));
                     a.appendChild(document.createTextNode(val));
                     fld.replaceChild(a, fld.firstChild);
                  }
               }
               else if (fld.tagName == "A") {
                  if (i != txt.length && txt[i].charAt(0) == "=")
                     ++i;
                  if (i == txt.length || txt[i].charAt(0) != "+") {
                     fld.replaceChild(document.createTextNode(val? val : "\u00A0"), fld.firstChild);
                     fld.removeAttribute("href");
                  }
                  else {
                     fld.firstChild.data = val;
                     fld.href = decodeURIComponent(txt[i++].substr(1));
                  }
               }
               else if (fld.tagName == "IMG")
                  fld.src = val;
               else {
                  if (fld.custom != null)
                     putCustom(fld.custom, val);
                  else if (fld.type == "checkbox") {
                     fld.checked = val != "";
                     document.getElementsByName(fld.name)[0].value = "";
                  }
                  else if (fld.type == "select-one") {
                     for (j = 0; j < fld.options.length; ++j) {
                        if (fld.options[j].text == val)
                           fld.selectedIndex = j;
                        fld.options[j].disabled = false;
                     }
                  }
                  else if (fld.type == "radio") {
                     fld.value = val;
                     fld.checked = txt[i++].charAt(0) != "";
                  }
                  else if (fld.type == "image")
                     fld.src = val;
                  else if (fld.value != val) {
                     fld.value = val;
                     fld.scrollTop = fld.scrollHeight;
                  }
                  fld.disabled = false;
                  if (i < txt.length && txt[i].charAt(0) == "=") {
                     if (fld.type == "select-one") {
                        for (j = 0; j < fld.options.length; ++j)
                           if (fld.options[j].text != val)
                              fld.options[j].disabled = true;
                     }
                     fld.disabled = true;
                     InBtn = 0;  // 'onblur' on won't come when disabled
                     if (fld.type == "checkbox"  &&  fld.checked)
                        document.getElementsByName(fld.name)[0].value = "T";
                     ++i;
                  }
                  if (fld.custom != null)
                     ableCustom(fld.custom);
               }
               while (i < txt.length && (j = "#*?".indexOf(txt[i].charAt(0))) >= 0) {
                  switch (j) {

                  case 0:  // '#'
                     var cls;

                     val = txt[i++].substr(1);
                     if ((cls = fld.getAttribute("class")) != null  &&  (j = cls.indexOf(" ")) >= 0)
                        val += cls.substr(j);
                     fld.setAttribute("class", val);
                     break;

                  case 1:  // '*'
                     var node = fld.parentNode.parentNode.lastChild;
                     var img = document.createElement("IMG");

                     if (!node.firstChild)
                        node = fld.parentNode.parentNode.parentNode.lastChild;
                     node.removeChild(node.firstChild);
                     img.src = txt[i++].substr(1);
                     if (!txt[i])
                        node.appendChild(img);
                     else {
                        var a = document.createElement("A");

                        a.href = decodeURIComponent(txt[i]);
                        a.appendChild(img);
                        node.appendChild(a);
                     }
                     ++i;
                     break;

                  case 2:  // '?'
                     fld.title = decodeURIComponent(txt[i++].substr(1));
                     break;
                  }
               }
            }
         }
         form.style.cursor = "";
         if (Queue.length > 0)
            post(Queue.shift(), null);
      }
   }
   var data = "";
   for (var i = 0; i < Btn.length;)
      if (Btn[i].form != form)
         ++i;
      else {
         data += (data? "&":"") + Btn[i].name + "=" + encodeURIComponent(Btn[i].type == "submit"? Btn[i].value : Btn[i].src);
         Btn.splice(i,1);
      }
   for (i = 0; i < form.elements.length; ++i) {
      var fld = form.elements[i];

      if (fld.name  &&  fld.type != "submit") {   // "image" won't come :-(
         var val;

         if (fld.custom != null)
            val = getCustom(fld.custom);
         else if (fld.type == "checkbox")
            val = fld.checked? "T" : "";
         else if (fld.type == "select-one")
            val = fld.options[fld.selectedIndex].text;
         else if (fld.type == "radio" && !fld.checked)
            continue;
         else
            val = fld.value;
         data += "&" + fld.name + "=" + encodeURIComponent(val);
      }
   }
   try {
      if (!file)
         FormReq.send(data);
      else {
         var rd = new FileReader();
         rd.readAsBinaryString(file);
         rd.onload = function() {
            FormReq.setRequestHeader("X-Pil", "*ContLen=");
            FormReq.sendAsBinary(data + "&*Drop=" +
               encodeURIComponent(file.name) + "=" +
               file.size + "\n" + rd.result );
         }
      }
   }
   catch (e) {
      FormReq.abort();
      return true;
   }
   return false;
}

/*** Hints ***/
function doHint(field) {
   if (HintReq) {
      if (!Hint) {
         Hint = document.createElement("div");
         Hint.setAttribute("class", "hint");
         Hint.style.visibility = "hidden";
         Hint.style.position = "absolute";
         Hints = document.createElement("div");
         Hints.setAttribute("class", "hints");
         Hints.style.position = "relative";
         Hints.style.top = "-2px";
         Hints.style.left = "-3px";
         Hint.appendChild(Hints);
      }
      field.parentNode.appendChild(Hint);
      field.onblur = function() {
         Hint.style.visibility = "hidden";
      }
      var top = field.offsetHeight + 2;
      var left = 3;
      for (var obj = field;  obj.id != "main" && obj.id != "menu";  obj = obj.offsetParent) {
         top += obj.offsetTop;
         left += obj.offsetLeft;
      }
      Hint.style.top = top + "px";
      Hint.style.left = left + "px";
   }
}

function hintKey(field, event, tok, coy) {
   var i, data;

   if (!HintReq)
      return true;
   if (event.keyCode == 9 || event.keyCode == 27)
      return false;
   if (Hint.style.visibility == "visible") {
      if (Item >= 0 && event.keyCode == 13) {
         setHint(field, Hints.childNodes[Item]);
         return false;
      }
      if (event.keyCode == 38) {  // Up
         if (Item > 0) {
            hintOff(Item);
            hintOn(--Item);
         }
         return false;
      }
      if (event.keyCode == 40) {  // Down
         if (Item < (lst = Hints.childNodes).length-1) {
            if (Item >= 0)
               hintOff(Item);
            hintOn(++Item);
         }
         return false;
      }
   }
   if (event.keyCode == 13)
      return true;
   if (HintReq.readyState > 0 && HintReq.readyState < 4)
      return false;
   if (tok) {
      for (Beg = field.selectionStart;  Beg > 0 && !field.value.charAt(Beg-1).match(/\s/);  --Beg);
      End = field.selectionEnd;
   }
   else {
      Beg = 0;
      End = field.value.length;
   }
   if (event.keyCode != 45) {  // INS
      if (Beg == End) {
         Hint.style.visibility = "hidden";
         return false;
      }
      if (coy && Hint.style.visibility == "hidden")
         return false;
   }
   try {
      HintReq.open("POST",
         ((i = field.form.action.indexOf("~")) <= 0?
            "" : field.form.action.substr(0, i+1) ) +
         ((i = field.id.lastIndexOf("-")) < 0?
            "!jsHint?$" + field.id : "!jsHint?+" + field.id.substr(i+1) ) );
   }
   catch (e) {return true;}
   HintReq.onreadystatechange = function() {
      if (HintReq.readyState == 4 && HintReq.status == 200) {
         var i, n, lst, str;

         if ((str = HintReq.responseText).length == 0)
            Hint.style.visibility = "hidden";
         else {
            lst = str.split("&");
            while (Hints.hasChildNodes())
               Hints.removeChild(Hints.firstChild);
            for (i = 0, n = 7; i < lst.length; ++i) {
               addHint(i, field, str = decodeURIComponent(lst[i]));
               if (str.length > n)
                  n = str.length;
            }
            Hints.style.width = n + 3 + "ex";
            Hint.style.width = n + 4 + "ex";
            Hint.style.visibility = "visible";
            Item = -1;
         }
      }
   }
   var data = "*JsHint=" + encodeURIComponent(field.value.substring(Beg,End));
   for (i = 0; i < field.form.elements.length; ++i) {
      var fld = field.form.elements[i];

      if (fld.name == "*Get")
         data += "&*Get=" + fld.value;
      else if (fld.name == "*Form")
         data += "&*Form=" + fld.value;
   }
   try {HintReq.send(data);}
   catch (e) {HintReq.abort();}
   return (event.keyCode != 45);  // INS
}

function addHint(i, field, str) {
   var item = document.createElement("div");
   item.appendChild(document.createTextNode(str));
   item.onmouseover = function() {
      if (Item >= 0)
         hintOff(Item);
      hintOn(i);
      field.onblur = false;
      field.onchange = false;
      Item = i;
   }
   item.onmouseout = function() {
      hintOff(Item);
      field.onblur = function() {
         Hint.style.visibility = "hidden";
      }
      field.onchange = function() {
         return fldChg(field, item);
      };
      Item = -1;
   }
   item.onclick = function() {
      setHint(field, item);
   }
   Hints.appendChild(item);
}

function setHint(field, item) {
   Hint.style.visibility = "hidden";
   field.value = field.value.substr(0,Beg) + item.firstChild.nodeValue + field.value.substr(End);
   post(field.form, null);
   field.setSelectionRange(Beg + item.firstChild.nodeValue.length, field.value.length);
   field.focus();
   field.onchange = function() {
      return fldChg(field)
   };
}

function hintOn(i) {
   var s = Hints.childNodes[i].style;
   s.background = "black";
   s.color= "white";
}

function hintOff(i) {
   var s = Hints.childNodes[i].style;
   s.background = "white";
   s.color= "black";
}
