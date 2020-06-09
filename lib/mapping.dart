/*Links Importantes:
Vídeo muito bom do YT sobre Flutter Google Maps:
  -https://www.youtube.com/watch?v=N0NfbhF2A3g
Visualizadores da estrutura JSON
  -http://chris.photobooks.com/json/default.htm -> Para ver no modo geral
  -http://jsonviewer.stack.hu/                  -> Para ver no modo de árvore
*/
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pcs_prj/main.dart';
import 'package:permission/permission.dart';
const gmApi = 'AIzaSyBwxya-OarYHNjXHXKSiTn_gNUHw9AYlcc';

class GPSpage extends StatefulWidget {
  @override
  _GPSpageState createState() => _GPSpageState();
}

class _GPSpageState extends State<GPSpage> {
  Set<Polyline> polyline = HashSet<Polyline>();
  Set<Marker> _markers = HashSet<Marker>();
  GoogleMapController _controller;
  List<LatLng> routeCoords = List<LatLng>();
  List<LatLng> _rotasColeta = List<LatLng>();
  //TODO: Lista provisória, trocar com o que receber por GET
  void _setaColetas() async{
    List<LatLng> aux = await _recebeCoords();
  _rotasColeta.add(LatLng(-25.5463171,-49.3436507));
  _rotasColeta.add(LatLng(-25.46535,-49.2993802));
  _rotasColeta.add(LatLng(-25.4600758,-49.2883522));
  _rotasColeta.add(LatLng(-25.4613263,-49.2933112));
  for(var i=0;i<aux.length;i++){
  _rotasColeta.add(aux[i]);
    }
  }
  //Lista provisória, trocar com o que receber por GET
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey:gmApi);

  _pegaCoordenadas() async {
    List<LatLng> aux;
    var permissions =
        await Permission.getPermissionsStatus([PermissionName.Location]);
    if (permissions[0].permissionStatus == PermissionStatus.notAgain) {
      var askpermissions =
          await Permission.requestPermissions([PermissionName.Location]);
    } else {
      for(var c=0;c<_rotasColeta.length-1;c++){
      aux = await googleMapPolyline.getCoordinatesWithLocation(
          origin: _rotasColeta[c],
          destination: _rotasColeta[c+1],
          mode: RouteMode.driving);
        routeCoords.addAll(aux);
        _markers.add(Marker(
          markerId: MarkerId("m${c+2}"),
          position: _rotasColeta[c+1],
          infoWindow: InfoWindow(title:"Lixeira Cheia!",snippet:"${c+2} ª Lixeira a ser coletada")
        ));
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _markers.add(Marker(
        markerId: MarkerId("m0"),
        position: LatLng(-25.5463171,-49.3436507),
        infoWindow: InfoWindow(
          title:"Local inicial",
          snippet: "Vá até lá!"
        ),
      ));
    });
  }

  void setPolylines(){
    polyline.add(Polyline(
          polylineId: PolylineId("p0"),
          visible: true,
          points: routeCoords,
          width: 6,
          color: Colors.blue,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap));
  }
  @override
  void initState() {
    super.initState();
    _setaColetas();
    _pegaCoordenadas();
    setPolylines();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wireless Trash",style: TextStyle(fontSize: 25.0),),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            onPressed: (){
              setState((){
                _setaColetas();
              });
            },
            child: Icon(Icons.add_location,color: Colors.white,size:25.0),
          ),
        ]
      ),
      body: GoogleMap(
      onMapCreated: onMapCreated,
      polylines: polyline,
      markers: _markers,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      initialCameraPosition:
        CameraPosition(target: LatLng(-25.4950501,-49.4298855), zoom: 9.0),
      mapType: MapType.normal,
    ));
  }
}
//TODO: Implementar código para ler do GET
Future<List<LatLng>> _recebeCoords() async{
  http.Response _resposta = await http.get(serverLink);
  if(_resposta.statusCode == 200){
    var data = json.decode(_resposta.body) as List;
  }
}

class DadosCelulares{
  double latitude;
  double longitude;
  int id;
  DadosCelulares({this.latitude,this.longitude,this.id});
  factory DadosCelulares.fromJson(Map<String,dynamic> json){
    return DadosCelulares(
      latitude:json['latitude'],
      longitude:json['longitude'],
      id:json['id'],
    );
  }
}