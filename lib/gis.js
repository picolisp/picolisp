/* 09jul17abu
 * (c) Software Lab. Alexander Burger
 */

function osm(id, lat, lon, z) {
   return new ol.Map( {
      target: id,
      view: new ol.View( {
         center: ol.proj.fromLonLat([lon, lat]),
         zoom: z
      } ),
      layers: [
         new ol.layer.Tile({source: new ol.source.OSM()})
      ]
   } )
}

function poi(map, lat, lon, img, x, y, txt, dy, col) {
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
   var v = new ol.source.Vector({features: []});
   v.addFeature(f);
   map.addLayer(new ol.layer.Vector({source: v}));
}
