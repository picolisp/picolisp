/* 10jul17abu
 * (c) Software Lab. Alexander Burger
 */

var Map;
var Sources;

function osm(id, lat, lon, z) {
   Map = new ol.Map( {
      target: id,
      view: new ol.View( {
         center: ol.proj.fromLonLat([lon, lat]),
         zoom: z
      } ),
      layers: [
         new ol.layer.Tile({source: new ol.source.OSM()}),
         new ol.layer.Vector( {
            source: Sources = new ol.source.Vector({features: []})
         } )
      ]
   } )
   Map.on("pointermove", function (evt) {
      Map.getViewport().style.cursor = "";
      Map.forEachFeatureAtPixel(evt.pixel, function (feature, layer) {
         if (feature.href)
            Map.getViewport().style.cursor = "pointer";
      } )
   } );
   Map.on("click", function(evt) {
      Map.forEachFeatureAtPixel(evt.pixel, function (feature, layer) {
         if (feature.href)
            window.location.href = feature.href;
      } )
   } );
}

function poi(lat, lon, img, x, y, txt, dy, col, url) {
   var feature = new ol.Feature( {
      geometry: new ol.geom.Point(ol.proj.fromLonLat([lon, lat]))
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
   feature.href = decodeURIComponent(url);
   Sources.addFeature(feature);
}
