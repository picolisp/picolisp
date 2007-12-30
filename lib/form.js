/* 23nov07abu
 * (c) Software Lab. Alexander Burger
 */

/*** Request object ***/
var FormReq;

if (window.XMLHttpRequest) {
   try {FormReq = new XMLHttpRequest();}
   catch (e) {FormReq = false;}
}
else if (window.ActiveXObject) {
   try {FormReq = new ActiveXObject("Msxml2.XMLHTTP");}
   catch (e) {
      try {FormReq = new ActiveXObject("Microsoft.XMLHTTP");}
      catch (e) {FormReq = false;}
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
   var i, btn, url, data;

   if (!FormReq)
      return true;
   for (i = 0; ; ++i) {
      if (i == Btn.length)
         return true;
      if (Btn[i].form == form) {
         btn = Btn[i];
         Btn.splice(i,1);
         break;
      }
   }
   if (FormReq.readyState > 0 && FormReq.readyState < 4) {
      window.setTimeout("document.getElementById(\"" + btn.id + "\").click()", 40);
      return false;
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
                  else if (fld.type == "image")
                     fld.src = val;
                  else
                     fld.value = val;
                  fld.disabled = fld.readOnly = false;
                  if (i == txt.length)
                     break;
                  if (txt[i].charAt(0) == "=") {
                     if (fld.type == "select-one") {
                        for (j = 0; j < fld.options.length; ++j)
                           if (fld.options[j].text != val)
                              fld.options[j].disabled = true;
                     }
                     else if (fld.type == "text" || fld.tagName == "TEXTAREA")
                        fld.readOnly = true;
                     else
                        fld.disabled = true;
                     if (++i == txt.length)
                        break;
                  }
               }
               if (txt[i].charAt(0) == "*") {
                  var node = fld.parentNode.parentNode.lastChild;
                  var img = document.createElement("IMG");

                  node.removeChild(node.firstChild);
                  img.src = txt[i].substr(1);
                  if (!txt[i+1])
                     node.appendChild(img);
                  else {
                     var a = document.createElement("A");

                     a.href = decodeURIComponent(txt[i+1]);
                     a.appendChild(img);
                     node.appendChild(a);
                  }
                  if ((i += 2) == txt.length)
                     break;
               }
               if (txt[i].charAt(0) == "?") {
                  fld.title = decodeURIComponent(txt[i].substr(1));
                  if (++i == txt.length)
                     break;
               }
               if (txt[i].charAt(0) == "#") {
                  var cls = fld.getAttribute("class");

                  fld.setAttribute("class",
                     txt[i++].substr(1) + ((j = cls.indexOf(" ")) < 0?  "" : cls.substr(j)) );
               }
            }
         }
      }
   }

   data = btn.name + "=" + encodeURIComponent(btn.type == "submit"? btn.value : btn.src);
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
   try {FormReq.send(data + "\n");}
   catch (e) {
      FormReq.abort();
      return true;
   }
   return false;
}
