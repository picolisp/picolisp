/* 19apr14abu
 * (c) Software Lab. Alexander Burger
 */

function csMouseDn(cvs, event) {
   var r = cvs.getBoundingClientRect();

   cvs.csDn = true;
   cvs.csDnX = event.clientX - r.left;
   cvs.csDnY = event.clientY - r.top;
   cvs.csMv = false;
   return false;
}

function csMouseMv(cvs, event) {
   var r = cvs.getBoundingClientRect();

   if (cvs.curs)
      csCursor(cvs, event.clientX - r.left, event.clientY - r.top);
   if (!cvs.csDn)
      return true;
   if (drawCanvas(cvs.id, -1, cvs.csMv? -1 : 0, cvs.csDnX, cvs.csDnY,
         event.clientX - r.left, event.clientY - r.top ) )
      return true;
   cvs.csMv = true;
   return false;
}

function csMouseOut(cvs) {
   cvs.style.cursor = "";
   cvs.csDn = cvs.csMv = false;
   if (cvs.clicked) {
      clearTimeout(cvs.clicked);
      cvs.clicked = false;
   }
   return drawCanvas(cvs.id, -1);
}

function csMouseUp(cvs) {
   cvs.csDn = false;
   if (cvs.clicked) {
      clearTimeout(cvs.clicked);
      cvs.clicked = false;
      return drawCanvas(cvs.id, -1, 2, cvs.csDnX, cvs.csDnY);
   }
   if (cvs.csMv)
      return drawCanvas(cvs.id, -1);
   cvs.clicked = setTimeout(
      function() {
         cvs.clicked = false;
         drawCanvas(cvs.id, -1, 1, cvs.csDnX, cvs.csDnY);
      },
      200 );
   return false;
}

function drawCanvas(id, dly) {
   var req = new XMLHttpRequest();
   var url = document.getElementsByTagName("BASE")[0].href + SesId + "!jsDraw?" + id + "&+" + dly;
   var len = arguments.length;

   for (var i = 2; i < len; ++i)
      if (typeof arguments[i] === "number")
         url += "&+" + arguments[i];
      else
         url += "&" + arguments[i];
   try {req.open("POST", url);}
   catch (e) {return true;}
   req.responseType = "arraybuffer";
   req.onload = function() {
      var ele = document.getElementById(id);

      renderCanvas(ele, plio(new Uint8Array(req.response)));
      if (ele.post) {
         ele.post = false;
         while (ele = ele.parentNode) {
            if (ele.tagName == "FORM") {
               post(ele, false, null, null);
               break;
            }
         }
      }
      if (dly == 0)
         requestAnimationFrame(function() {drawCanvas(id, 0)});
      else if (dly > 0)
         setTimeout(function() {drawCanvas(id, dly)}, dly);
   }
   try {req.send(null);}
   catch (e) {
      req.abort();
      return true;
   }
   return false;
}

function renderCanvas(cvs, lst) {
   var ctx = cvs.getContext("2d");
   var cmd, i, j;

   for (i = 0; i < lst.length; ++i) {
      switch ((cmd = lst[i])[0]) {  // Sync with "@lib/canvas.l"
      /*** Functions ***/
      case 1:  // (csFillText Str X Y)
         ctx.fillText(cmd[1], cmd[2], cmd[3]);
         break;
      case 2:  // (csStrokeLine X1 Y1 X2 Y2)
         ctx.beginPath();
         ctx.moveTo(cmd[1], cmd[2]);
         ctx.lineTo(cmd[3], cmd[4]);
         ctx.closePath();
         ctx.stroke();
         break;
      case 3:  // (csClearRect X Y DX DY)
         ctx.clearRect(cmd[1], cmd[2], cmd[3], cmd[4]);
         break;
      case 4:  // (csStrokeRect X Y DX DY)
         ctx.strokeRect(cmd[1], cmd[2], cmd[3], cmd[4]);
         break;
      case 5:  // (csFillRect X Y DX DY)
         ctx.fillRect(cmd[1], cmd[2], cmd[3], cmd[4]);
         break;
      case 6:  // (csBeginPath)
         ctx.beginPath();
         break;
      case 7:  // (csClosePath)
         ctx.closePath();
         break;
      case 8:  // (csMoveTo X Y)
         ctx.moveTo(cmd[1], cmd[2]);
         break;
      case 9:  // (csLineTo X Y)
         ctx.lineTo(cmd[1], cmd[2]);
         break;
      case 10:  // (csBezierCurveTo X1 Y1 X2 Y2 X Y)
         ctx.bezierCurveTo(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6]);
         break;
      case 11:  // (csLine X1 Y1 X2 Y2)
         ctx.moveTo(cmd[1], cmd[2]);
         ctx.lineTo(cmd[3], cmd[4]);
         break;
      case 12:  // (csRect X Y DX DY)
         ctx.rect(cmd[1], cmd[2], cmd[3], cmd[4]);
         break;
      case 13:  // (csArc X Y R A B F)
         ctx.arc(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6]);
         break;
      case 14:  // (csStroke)
         ctx.stroke();
         break;
      case 15:  // (csFill)
         ctx.fill();
         break;
      case 16:  // (csClip)
         ctx.clip();
         break;
      case 17:  // (csDef Key DX DY Lst), (csDef Key)
         if (!cvs.pre)
            cvs.pre = new Array();
         var buf = cvs.pre[cmd[1]] = document.createElement('canvas');
         if (cmd[2]) {
            buf.width = cmd[2];
            buf.height = cmd[3];
            renderCanvas(buf, cmd[4]);
         }
         else {
            buf.width = cvs.width;
            buf.height = cvs.height;
            buf.getContext("2d").drawImage(cvs, 0, 0);
         }
         break;
      case 18:  // (csDraw Key X Y)
         ctx.drawImage(cvs.pre[cmd[1]], cmd[2], cmd[3]);
         break;
      case 19:  // (csDrawDots DX DY Lst)
         if (cmd[3])
            for (j = 0; j < cmd[3].length; j += 2)
               ctx.fillRect(cmd[3][j], cmd[3][j+1], cmd[1], cmd[2]);
         break;
      case 20:  // (csDrawImage Img X Y Lst DX DY)
         var img = new Image();
         img.src = cmd[1];
         (function (img, cmd) {
            img.onload = function () {
               if (cmd[5])
                  ctx.drawImage(img, cmd[2], cmd[3], cmd[5], cmd[6]);
               else
                  ctx.drawImage(img, cmd[2], cmd[3]);
               if (cmd[4])
                  renderCanvas(cvs, cmd[4]);
            } } )(img, cmd);
         break;
      case 21:  // (csTranslate X Y)
         ctx.translate(cmd[1], cmd[2]);
         break;
      case 22:  // (csRotate A)
         ctx.rotate(cmd[1]);
         break;
      case 23:  // (csScale X Y)
         ctx.scale(cmd[1], cmd[2]);
         break;
      case 24:  // (csSave)
         ctx.save();
         break;
      case 25:  // (csRestore)
         ctx.restore();
         break;
      /*** Variables ***/
      case 26:  // (csCursor Lst)
         cvs.curs = cmd[1];
         break;
      case 27:  // (csFillStyle V)
         ctx.fillStyle = cmd[1];
         break;
      case 28:  // (csStrokeStyle V)
         ctx.strokeStyle = cmd[1];
         break;
      case 29:  // (csGlobalAlpha V)
         ctx.globalAlpha = cmd[1];
         break;
      case 30:  // (csLineWidth V)
         ctx.lineWidth = cmd[1];
         break;
      case 31:  // (csLineCap V)
         ctx.lineCap = cmd[1];
         break;
      case 32:  // (csLineJoin V)
         ctx.lineJoin = cmd[1];
         break;
      case 33:  // (csMiterLimit V)
         ctx.miterLimit = cmd[1];
         break;
      case 34:  // (csGlobalCompositeOperation V)
         ctx.globalCompositeOperation = cmd[1];
         break;
      case 35:  // (csPost)
         cvs.post = true;
         break;
      }
   }
}

function csCursor(cvs, x, y) {
   var a;

   for (var i = 0; i < cvs.curs.length; ++i) {
      if (typeof (a = cvs.curs[i]) === "string") {
         cvs.style.cursor = a;
         return;
      }
      for (var j = 1; j < a.length; j += 4) {
         if (a[j] <= x && x <= a[j+2] && a[j+1] <= y && y <= a[j+3]) {
            cvs.style.cursor = a[0];
            return;
         }
      }
   }
   cvs.style.cursor = "";
}
