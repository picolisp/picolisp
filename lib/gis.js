/* 28jul17abu
 * (c) Software Lab. Alexander Burger
 */

var Map;
var Sources;

function osm(id, lat, lon, zoom, click, drag) {
   Map = new ol.Map( {
      target: id,
      view: new ol.View( {
         center: ol.proj.fromLonLat([lon/1000000-180, lat/1000000-90]),
         zoom: zoom
      } ),
      layers: [
         new ol.layer.Tile({source: new ol.source.OSM()}),
         new ol.layer.Vector( {
            source: Sources = new ol.source.Vector({features: []})
         } )
      ]
   } );

   Map.on("pointermove", function (evt) {
      Map.getViewport().style.cursor = "";
      Map.forEachFeatureAtPixel(evt.pixel, function (feature, layer) {
         if (feature.href)
            Map.getViewport().style.cursor = "pointer";
      } )
   } );

   Map.on("click", function(evt) {
      var flg = false;

      Map.forEachFeatureAtPixel(evt.pixel, function (feature, layer) {
         if (feature.href) {
            window.location.href = feature.href;
            flg = true;
         }
      } )
      if (click && !flg) {
         var pt = ol.proj.toLonLat(evt.coordinate);

         lisp(document.getElementById(id).parentNode.parentNode, "osmClick",
            (pt[1] + 90) * 1000000, (pt[0] + 180) * 1000000 );
      }
   } );

   if (drag) {
      Map.drag = true;
      Map.on("moveend", function() {
         var view = Map.getView().calculateExtent(Map.getSize());
         var a = ol.proj.toLonLat([view[0], view[1]]);
         var b = ol.proj.toLonLat([view[2], view[3]]);
         lisp(document.getElementById(id).parentNode.parentNode, "osmView",
            (a[1] + 90) * 1000000, (a[0] + 180) * 1000000,
            (b[1] + 90) * 1000000, (b[0] + 180) * 1000000,
            Map.getView().getZoom() );
      } );
   }
}

function poi(id, lat, lon, img, x, y, txt, dy, col, url) {
   var feature = new ol.Feature( {
      geometry: new ol.geom.Point(ol.proj.fromLonLat([lon/1000000-180, lat/1000000-90]))
   } );

   feature.setStyle( [
      new ol.style.Style( {
         image: new ol.style.Icon( {
            src: img,
            anchor: [x, y]
         } )
      } ),
      new ol.style.Style( {
         text: new ol.style.Text( {
            text: txt,
            offsetY: dy,
            fill: new ol.style.Fill({color: col})
         } )
      } )
   ] );

   if (Map.drag) {
      Map.addInteraction(new ol.interaction.Translate( {
         features: new ol.Collection([feature])
      } ) );
      feature.on('change', function() {
            var pt = ol.proj.toLonLat(this.getGeometry().getCoordinates());

            lisp(document.getElementById(id).parentNode.parentNode, "osmDrag",
               (pt[1] + 90) * 1000000, (pt[0] + 180) * 1000000 );
         },
         feature );
   }
   feature.href = decodeURIComponent(url);
   Sources.addFeature(feature);
}
