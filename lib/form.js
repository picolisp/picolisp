/* 30sep06abu
 * (c) Software Lab. Alexander Burger
 */

/*** Request object ***/
var Req;

if (window.XMLHttpRequest) {
   try {Req = new XMLHttpRequest();}
   catch (e) {Req = false;}
}
else if (window.ActiveXObject) {
   try {Req = new ActiveXObject("Msxml2.XMLHTTP");}
   catch (e) {
      try {Req = new ActiveXObject("Microsoft.XMLHTTP");}
      catch (e) {Req = false;}
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
function doPost(form) {
   if (!Req || !Btn)
      return true;

   var data = Btn.name + "=" + (Btn.type == "submit"? Btn.value : Btn.src);
   var url = form.action.split("~");

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
         while (val.indexOf("&") >= 0)
            val = val.replace("&", "%26")
         while (val.indexOf("=") >= 0)
            val = val.replace("=", "%3D")
         data += "&" + fld.name + "=" + val;
      }
   }
   Req.open("POST", url[0] + "~@xmlHttp?" + url[1]);
   Req.onreadystatechange = function() {
      if (Req.readyState == 4 && Req.status == 200) {
         if (Req.responseText == "T")
            form.submit();
         else {
            var txt = Req.responseText.split("&");

            for (i = 1; i < txt.length;) {
               var nm = "*Gui(+" + txt[i] + ")";
               var val = unescape(txt[i+1]);
               var fld = false;

               for (j = 0; j < form.elements.length; ++j)
                  if (form.elements[j].name == nm)
                     fld = form.elements[j];
               if (!fld) {
                  lst = document.getElementsByName(nm);
                  for (k = 0; k < lst.length; ++k)
                     if (lst[k].form == form)
                        fld = lst[k];
               }
               if (fld) {
                  if (fld.type == "checkbox")
                     fld.checked = val != "";
                  else if (fld.type == "select-one") {
                     for (k = 0; k < fld.options.length; ++k)
                        if (fld.options[k].text == val)
                           fld.selectedIndex = k;
                  }
                  else if (fld.type == "image")
                     fld.src = val;
                  else if (fld.type)
                     fld.value = val;
               }
               if ((i+=2) == txt.length)
                  break;
               if (txt[i].charAt(0) == "+") {
                  var node = fld.parentNode.parentNode.lastChild;
                  var img = document.createElement("img");

                  node.removeChild(node.firstChild);
                  img.src = txt[i].substr(1);
                  if (!txt[i+1])
                     node.appendChild(img);
                  else {
                     fld = document.createElement("a");
                     fld.href = unescape(txt[i+1]);
                     fld.appendChild(img);
                     node.appendChild(fld);
                  }
                  i += 2;
               }
            }
         }
      }
   }
   Req.send(data + "\n");
   return Btn = false;
}
