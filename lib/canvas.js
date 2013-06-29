/* 27may13abu
 * (c) Software Lab. Alexander Burger
 */

function drawCanvas(id, dly) {
   var req = new XMLHttpRequest();

   try {
      req.open("POST",
         document.getElementsByTagName("BASE")[0].href + SesId +
         "!jsDraw?" + id );
      req.responseType = "arraybuffer";
   }
   catch (e) {return true;}
   req.onload = function() {
      var lst = plio(new Uint8Array(req.response));
      var cmd, i;

      if (lst) {
         var ctx = document.getElementById(id).getContext("2d");

         for (i = 0; i < lst.length; ++i) {
            switch ((cmd = lst[i])[0]) {  // In sync with "@lib/canvas.l"
            /*** Functions ***/
            case 1:
               ctx.fillText(cmd[1], cmd[2], cmd[3]);
               break;
            case 2:
               ctx.beginPath();
               ctx.moveTo(cmd[1], cmd[2]);
               ctx.lineTo(cmd[3], cmd[4]);
               ctx.closePath();
               ctx.stroke();
               break;
            case 3:
               ctx.clearRect(cmd[1], cmd[2], cmd[3], cmd[4]);
               break;
            case 4:
               ctx.strokeRect(cmd[1], cmd[2], cmd[3], cmd[4]);
               break;
            case 5:
               ctx.fillRect(cmd[1], cmd[2], cmd[3], cmd[4]);
               break;
            case 6:
               ctx.beginPath();
               break;
            case 7:
               ctx.closePath();
               break;
            case 8:
               ctx.moveTo(cmd[1], cmd[2]);
               break;
            case 9:
               ctx.lineTo(cmd[1], cmd[2]);
               break;
            case 10:
               ctx.bezierCurveTo(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6]);
               break;
            case 11:
               ctx.moveTo(cmd[1], cmd[2]);
               ctx.lineTo(cmd[3], cmd[4]);
               break;
            case 12:
               ctx.rect(cmd[1], cmd[2], cmd[3], cmd[4]);
               break;
            case 13:
               ctx.arc(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6]);
               break;
            case 14:
               ctx.stroke();
               break;
            case 15:
               ctx.fill();
               break;
            case 16:
               ctx.clip()
               break;
            case 17:
               ctx.drawImage(cmd[1], cmd[2], cmd[3]);
               break;
            case 18:
               ctx.translate(cmd[1], cmd[2]);
               break;
            case 19:
               ctx.rotate(cmd[1]);
               break;
            case 20:
               ctx.scale(cmd[1], cmd[2]);
               break;
            case 21:
               ctx.save();
               break;
            case 22:
               ctx.restore();
               break;
            /*** Variables ***/
            case 23:
               ctx.fillStyle = cmd[1];
               break;
            case 24:
               ctx.strokeStyle = cmd[1];
               break;
            case 25:
               ctx.globalAlpha = cmd[1];
               break;
            case 26:
               ctx.lineWidth = cmd[1];
               break;
            case 27:
               ctx.lineCap = cmd[1];
               break;
            case 28:
               ctx.lineJoin = cmd[1];
               break;
            case 29:
               ctx.miterLimit = cmd[1];
               break;
            case 30:
               ctx.globalCompositeOperation = cmd[1];
               break;
            }
         }
      }
      if (dly >= 0)
         setTimeout(function() {drawCanvas(id, dly)}, dly);
   }
   try {req.send(null);}
   catch (e) {
      req.abort();
      return true;
   }
   return false;
}
