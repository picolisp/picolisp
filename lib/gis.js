/* 08jul17abu
 * (c) Software Lab. Alexander Burger
 */

function newMap(id, lat, lon, zoom) {
   return new ol.Map( {
      target: id,
      layers: [new ol.layer.Tile({source: new ol.source.OSM()})],
      view: new ol.View( {
         center: ol.proj.fromLonLat([lon, lat]),
         zoom: zoom
      } )
   } )
}
