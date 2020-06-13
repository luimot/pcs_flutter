/*Links Importantes:
Vídeo muito bom do YT sobre Flutter Google Maps:
  -https://www.youtube.com/watch?v=N0NfbhF2A3g
Visualizadores da estrutura JSON
  -http://chris.photobooks.com/json/default.htm -> Para ver no modo geral
  -http://jsonviewer.stack.hu/                  -> Para ver no modo de árvore
Git muito bom sobre parsear JSONs mais complexos:
  -https://github.com/PoojaB26/ParsingJSON-Flutter
*/
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pcs_prj/main.dart';
import 'package:permission/permission.dart';

const gmApi = 'sua_chave_aqui';

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
  DadosList cGeral;
  void _setaColetas(){
    List<LatLng> temp = List<LatLng>();
    for(var i=0;i<cGeral.dados.length;i++){
      temp.add(LatLng(cGeral.dados[i].latitude,cGeral.dados[i].longitude));
      _rotasColeta=temp.toSet().toList();
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
        markerId: MarkerId("m${c+1}"),
        position: _rotasColeta[c+1],
        infoWindow: InfoWindow(title:"Lixeira ${cGeral.dados[c].status}!",snippet:"${c+1} ª Lixeira a ser coletada")
        ));
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  void setPolylines() async {
    Set<Polyline> temp = HashSet<Polyline>();
    temp.add(Polyline(
      polylineId: PolylineId("p"),
      visible: true,
      points: routeCoords,
      width: 6,
      color: Colors.blue,
      startCap: Cap.roundCap,
      endCap: Cap.buttCap));
    polyline=temp.toSet();
  }
  @override
  void initState(){
    super.initState();
    _pegaCoordenadas();
    setPolylines();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS",style: TextStyle(fontSize: 25.0),),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            onPressed: (){
              setState((){
                _setaColetas();
                setPolylines();
                _pegaCoordenadas();
              });
            },
            child: Icon(Icons.add_location,color: Colors.white,size:25.0),
          ),
        ]
      ),
      body:
      FutureBuilder<DadosList>(
        future: _recebeCoords(),
        builder: (BuildContext context,AsyncSnapshot<DadosList> snapshot){
          List<Widget> children;
          Widget child;
          if(snapshot.hasData){
            cGeral=snapshot.data;
            child= GoogleMap(
              onMapCreated: onMapCreated,
              polylines: polyline,
              markers: _markers,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition:
                CameraPosition(target: LatLng(-23.5614355,-46.732825), zoom: 15.0),
              mapType: MapType.normal,
            );
            return Scaffold(body:child);
          }
          else if (snapshot.hasError) {
            children = <Widget>[
              Icon(
                Icons.error,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          }
          else{
            children=<Widget>[
              Padding(
                padding: EdgeInsets.only(left: 80.0),
                child:
                SizedBox(
                  child:CircularProgressIndicator(),
                  width: 200,
                  height: 200,
              ))
            ];
          }
          return Column(mainAxisAlignment: MainAxisAlignment.center,children: children);
        }
      ), 
    );
  }
}
//Função que recebe os dados do servidor por método GET
Future<DadosList> _recebeCoords() async{
  http.Response _resposta = await http.get(serverLink);
    return DadosList.fromJson(json.decode(_resposta.body));
}
//Classes organizando as informações passadas pelo servidor
class DadosCelulares{
  double latitude;
  double longitude;
  String id;
  String status;
  DadosCelulares({this.latitude,this.longitude,this.id,this.status});
  factory DadosCelulares.fromJson(Map<String,dynamic> json){
    return new DadosCelulares(
      id:json['id'].toString(),
      latitude:json['latitude'].toDouble(),
      longitude:json['longitude'].toDouble(),
      status:json['status'],
    );
  }
}

class DadosList{
  final List<DadosCelulares> dados;
  DadosList({this.dados});
  factory DadosList.fromJson(List<dynamic> json){
    List<DadosCelulares> dados = new List<DadosCelulares>();
    dados = json.map((i)=>DadosCelulares.fromJson(i)).toList(); 
    return new DadosList(dados:dados);
  }

}