/* 31dec06abu
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
var Btn;

function doSubmit(btn) {
   Btn = btn;
   return true;
}

function doImage(btn) {
   Btn = btn;
   return true;
}


/*** Handle form submit ***/
function enc2(val) {
   return val.replace(/&/g, "%26").replace(/=/g, "%3D");
}

function doPost(form) {
   if (!FormReq || !Btn)
      return true;
   if (FormReq.readyState > 0 && FormReq.readyState < 4)
      return Btn = false;

   var url = form.action.split("~");
   try {FormReq.open("POST", url[0] + "~@jsForm?" + url[1]);}
   catch (e) {return Btn = false;}

   FormReq.onreadystatechange = function() {
      if (FormReq.readyState == 4 && FormReq.status == 200) {
         if (FormReq.responseText == "T")
            form.submit();
         else {
            var txt = FormReq.responseText.split("&");

            for (var i = 1; i < txt.length;) {
               var fld = document.getElementById(txt[i++]);
               var val = unescape(txt[i++]);

               if (!fld)
                  window[unescape(txt[i++])](val);
               else if (fld.tagName == "SPAN") {
                  if (i != txt.length && txt[i].charAt(0) == "=")
                     ++i;
                  if (i == txt.length || txt[i].charAt(0) != "+")
                     fld.firstChild.data = val? val : "\u00A0";
                  else {
                     var a = document.createElement("A");

                     a.href = unescape(txt[i++].substr(1));
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
                     fld.href = unescape(txt[i++].substr(1));
                  }
               }
               else {
                  if (fld.type == "checkbox")
                     fld.checked = val != "";
                  else if (fld.type == "select-one") {
                     for (j = 0; j < fld.options.length; ++j)
                        if (fld.options[j].text == val)
                           fld.selectedIndex = j;
                  }
                  else if (fld.type == "image")
                     fld.src = val;
                  else
                     fld.value = val;
                  fld.disabled = fld.readonly = false;
                  if (i == txt.length)
                     break;
                  if (txt[i].charAt(0) == "=") {
                     if (fld.type == "text" || fld.tagName == "TEXTAREA")
                        fld.readonly = true;
                     else
                        fld.disabled = true;
                     if (++i == txt.length)
                        break;
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

                        a.href = unescape(txt[i+1]);
                        a.appendChild(img);
                        node.appendChild(a);
                     }
                     i += 2;
                  }
               }
            }
         }
      }
   }

   var data = Btn.name + "=" + enc2(Btn.type == "submit"? Btn.value : Btn.src);
   for (var i = 0; i < form.elements.length; ++i) {
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
         data += "&" + fld.name + "=" + enc2(val);
      }
   }
   try {FormReq.send(data + "\n");}
   catch (e) {FormReq.abort();}
   return Btn = false;
}
