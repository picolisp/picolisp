/* 10dec10abu
 * (c) Software Lab. Alexander Burger
 */

tinyMCE.init({
   mode : "textareas",
   theme : "advanced",

   plugins : "safari,table,preview,inlinepopups,searchreplace,print,contextmenu,paste,fullscreen",

   theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
   theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,cleanup,preview,|,forecolor,backcolor",
   theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,|,sub,sup,|,print,|,fullscreen",
   theme_advanced_toolbar_location : "top",
   theme_advanced_toolbar_align : "left",
   theme_advanced_statusbar_location : "bottom",
   theme_advanced_resizing : true,
   language : "en",

   setup : function(ed) {
      ed.onInit.add(function(ed) {
         ed.getElement().custom = ed;
         ableCustom(ed);
      });
      ed.onChange.add(function(ed) {
         fldChg(ed.getElement());
      });
   }
});

function putCustom(ed, val) {
   ed.setContent(val);
}

function getCustom(ed) {
   return ed.getContent();
}

function ableCustom(ed) {
   var flg = ed.getElement().disabled;
   var tb = ["toolbar1", "toolbar2", "toolbar3"];
   ed.execCommand("contentReadOnly", false, flg);
   for (var i in tb) {
      var ct = ed.controlManager.get(tb[i]).controls;
      for (var j in ct)
         ct[j].setDisabled(flg);
   }
}
