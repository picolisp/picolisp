/* 23nov08abu
 * (c) Software Lab. Alexander Burger
 */

/*** Request objects ***/
var FormReq = false;
var HintReq = false;

if (window.XMLHttpRequest) {
   try {
      FormReq = new XMLHttpRequest();
      HintReq = new XMLHttpRequest();
   }
   catch (e) {}
}
else if (window.ActiveXObject) {  // IE
   try {
      FormReq = new ActiveXObject("Msxml2.XMLHTTP");
      HintReq = new ActiveXObject("Msxml2.XMLHTTP");
   }
   catch (e) {
      try {
         FormReq = new ActiveXObject("Microsoft.XMLHTTP");
         HintReq = new ActiveXObject("Microsoft.XMLHTTP");
      }
      catch (e) {}
   }
}


/*** Submit buttons ***/
var Btn = new Array();
var Auto;

function doBtn(btn) {
   Btn.push(btn);
   return true;
}

/*** Handle form submit ***/
function doPost(form) {
   var i, j, url, data;

   if (!FormReq)
      return true;
   if (FormReq.readyState > 0 && FormReq.readyState < 4)
      return false;
   for (i = 0; ; ++i) {
      if (i == Btn.length)
         return true;
      if (Btn[i].form == form)
         break;
   }
   url = form.action.split("~");
   try {FormReq.open("POST", url[0] + "~@jsForm?" + url[1]);}
   catch (e) {return true;}

   FormReq.onreadystatechange = function() {
      if (FormReq.readyState == 4 && FormReq.status == 200) {
         if (FormReq.responseText == "T")
            form.submit();
         else {
            var txt = FormReq.responseText.split("&");

            if (txt[0]) {
               var r = txt[0].split(":");

               if (Auto)
                  window.clearTimeout(Auto);
               if (r[1])
                  Auto = window.setTimeout("document.getElementById(\"" + r[0] + "\").click()", r[1]);
            }
            for (var i = 1; i < txt.length;) {
               var fld = document.getElementById(txt[i++]);
               var val = decodeURIComponent(txt[i++]);

               if (!fld) {
                  window[txt[i++]](val);
                  continue;
               }
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
               else {
                  if (fld.type == "checkbox")
                     fld.checked = val != "";
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
                  if (i == txt.length)
                     break;
                  if (txt[i].charAt(0) == "=") {
                     if (fld.type == "select-one") {
                        for (j = 0; j < fld.options.length; ++j)
                           if (fld.options[j].text != val)
                              fld.options[j].disabled = true;
                     }
                     fld.disabled = true;
                     ++i;
                  }
               }
               while (i < txt.length && (j = "#*?".indexOf(txt[i].charAt(0))) >= 0) {
                  switch (j) {

                  case 0:  // '#'
                     var cls;

                     val = txt[i++].substr(1);
                     if ((cls = fld.getAttribute("class")) != null)
                        fld.setAttribute("class", val + ((j = cls.indexOf(" ")) < 0?  "" : cls.substr(j)));
                     else if ((cls = fld.getAttribute("className")) != null)  // IE
                        fld.setAttribute("className", val + ((j = cls.indexOf(" ")) < 0?  "" : cls.substr(j)));
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
      }
   }

   data = "";
   for (i = 0; i < Btn.length;)
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

         if (fld.type == "checkbox")
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
   try {FormReq.send(data);}
   catch (e) {
      FormReq.abort();
      return true;
   }
   return false;
}


/*** Hints ***/
var Hint, Pos;

function doHint(field) {
   var i, url, data;

   if (!HintReq)
      return true;
   if (HintReq.readyState > 0 && HintReq.readyState < 4)
      return false;
   if ((i = field.id.lastIndexOf("-")) < 0)
      return true;
   url = field.form.action.split("~");
   try {HintReq.open("POST", url[0] + "~@jsHint?" + field.id.substr(i+1));}
   catch (e) {return true;}
   HintReq.onreadystatechange = function() {
      if (HintReq.readyState == 4 && HintReq.status == 200) {
         Hint = HintReq.responseText.split("&");
         for (i = 0; i < Hint.length; ++i)
            Hint[i] = decodeURIComponent(Hint[i]);
      }
   }
   for (i = 0; i < field.form.elements.length; ++i) {
      var fld = field.form.elements[i];

      if (fld.name == "*Get")
         data = "*Get=" + fld.value;
      else if (fld.name == "*Form")
         data += "&*Form=" + fld.value;
   }
   try {HintReq.send(data);}
   catch (e) {HintReq.abort();}
   Pos = -1;
   return true;
}

function doKey(field, event) {
   var beg = field.selectionStart;
   var end = field.selectionEnd;
   var i;

   if (Hint.length > 0) {
      if (event.keyCode == 19) {  // Pause/Break
         if (beg != end)
            return true;
         Pos = beg;
         setHint(field, beg, end, 0);
         return false;
      }
      if (event.keyCode == 38 || event.keyCode == 40) {  // Up or Down
         if (beg == end)
            return true;
         if ((i = findHint(field.value.substring(Pos, end))) >= 0)
            setHint(field, beg, end, nextHint(field.value.substring(Pos, beg), i, event.keyCode==38? -1 : +1));
         return false;
      }
      if (Pos < 0)
         for (Pos = beg;  Pos > 0 && !field.value.charAt(Pos-1).match(/\s/);  --Pos);
      if ((i = findHint(field.value.substring(Pos, beg) + String.fromCharCode(event.charCode))) < 0)
         Pos = -1;
      else {
         setHint(field, beg+1, end, i);
         return false;
      }
   }
   return true;
}

function findHint(str) {
   var len = str.length;

   for (var i = 0; i < Hint.length; ++i)
      if (Hint[i].substr(0,len) == str)
         return i;
   return -1;
}

function nextHint(str, i, n) {
   var len = str.length;

   do {
      if (n < 0) {
         if ((i += n) < 0)
            i = Hint.length - 1;
      }
      else {
         if ((i += n) >= Hint.length)
               i = 0;
      }
   } while (Hint[i].substr(0,len) != str);
   return i;
}

function setHint(field, beg, end, i) {
   field.value = field.value.substr(0,Pos) + Hint[i] + field.value.substring(end, field.value.length);
   field.setSelectionRange(beg, Pos+Hint[i].length);
}
