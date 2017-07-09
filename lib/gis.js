/* 09jul17abu
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
}

function poi(lat, lon, img, x, y, txt, dy, col) {
   var f = new ol.Feature( {
      geometry: new ol.geom.Point(ol.proj.fromLonLat([lon, lat]))
   } );
   f.setStyle( [
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
   Sources.addFeature(f);
}
