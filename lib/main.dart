/*
Links importantes:
Links NGROK:  --LINKS TEMPORÁRIOS, ALTERAR TODA VEZ QUE FOR COMPILAR--
  -http://f1d30ae1.ngrok.io/ Link do servidor local
  -http://2e5dc8f9.ngrok.io  Link do servidor do Pedro
Google Maps API key:
  -
GitHub uso de Polyline no Maps:
  -https://github.com/rajayogan/flutter-googlemaps-routes/blob/master/lib/main.dart
Classe DateTime:
  -https://api.flutter.dev/flutter/dart-core/DateTime-class.html
Google API tutoriais:
  -https://pub.dev/packages/google_maps_flutter
  -https://codelabs.developers.google.com/codelabs/google-maps-in-flutter/#0 <- Parece promissor!
Flutter Navigation:
  -https://flutter.dev/docs/cookbook/navigation/navigation-basics
HTTPS POST com Album JSON no Flutter: 
  -https://flutter.dev/docs/cookbook/networking/send-data
Location lib basics:
  -https://pub.dev/packages/location
Curso Udemy Flutter e Dart:
  -https://www.udemy.com/course/curso-completo-flutter-app-android-ios
 */
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

var serverLink = 'http://2ea642b66681.ngrok.io';

void main() => runApp(MaterialApp(
	debugShowCheckedModeBanner: false,
	home: Home(),
));
//Página Home
class Home extends StatefulWidget{
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>{

  //final TextEditingController _controller = TextEditingController();
  String _status;
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Future<Album> _futureAlbum;
  static const padDist = 10.0;
  Position _currentPosition;
  String _currentAddress;
  
  
  _getAddressFromLatLng() async {                 //Função que a partir da localização, infere os detalhes
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.subLocality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  _getCurrentLocation() {             //Função que recebe do aparelho Latitude e Longitude
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }
  @override
  Widget build(BuildContext context) {
	return Scaffold(
		appBar:AppBar(
			title: const Text("Wireless Trash",style: TextStyle(fontSize: 25.0),),
			backgroundColor: Colors.green,
			centerTitle: true,
		),
		drawer: Drawer(
			child:ListView(
				padding: EdgeInsets.zero,
				children: <Widget>[
					DrawerHeader(
						decoration: BoxDecoration(
							color:Colors.green,
						),
						child: Text("Opções",
							style: TextStyle(color: Colors.white, fontSize: 20.0),
						),
					),
					ListTile(
						title: Text("GPS"),
						leading: Icon(Icons.gps_fixed),
						onTap: (){Navigator.push(context, 
            MaterialPageRoute(builder: (context) =>GPSpage())
            );},
					),
          ListTile(
            title: Text("Configurações"),
            leading: Icon(Icons.settings),
            onTap: (){
              Navigator.push(context, 
              MaterialPageRoute(builder: (context) =>Configuracoes())
              );
            },
          ),
          ListTile(
            title:Text("Dados"),
            leading: Icon(Icons.library_books),
            onTap: (){
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => RecebeDados())
              );
            }
          ),
				],
			),
		),
		backgroundColor: Colors.white,
		body: Padding(
      padding: EdgeInsets.symmetric(horizontal:110.0),
      child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
			  children: <Widget>[
        DropdownButton<String>(
          dropdownColor:Colors.green[200],
          items: <String>['Medio','Cheio','Transbordando'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          value:_status,
          onChanged: (String value) {
            setState((){
            _status = value;
            });
          },
        ),
        Image.asset("images/logo.png"),
        Padding(
        padding: EdgeInsets.only(top:20.0,bottom:20.0),
        child:RaisedButton(
        child: Text('Enviar'),
        onPressed: (){
          _getCurrentLocation();
          _getAddressFromLatLng();
          setState(() {
            _futureAlbum = createAlbum(_currentPosition.latitude, _currentPosition.longitude,_status== null?"nulo":_status);
          });
        },
      ),),
        Padding(
          padding: const EdgeInsets.all(padDist),
          child: FutureBuilder<Album>(        //Faz com que o body do app esteja adaptado a funções Future
                future: _futureAlbum,
                builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text("Enviado!");    //Text(snapshot.data.title)    
                }else if (snapshot.hasError) {
                  return Text("Enviado!");    //É mensagem de erro mas é pq deu certo
                }
                return CircularProgressIndicator();
              },
            ) 
        ),
        Text(((){
          if(_currentAddress != null){
            return (_currentAddress);
          }
          else{
            return "";
          }
        }()),textAlign: TextAlign.center,),
			],
		),),
  );
  }
}
//Classes cuidando de comunicação JSON com o servidor HTTP
class Album {
  final int id;
  final String title;

  Album({this.id, this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['data'],
    );
  }
}

Future<Album> createAlbum(double lati, double longi, String sLixo) async {
  const _userName = 'usuario4321';
  final http.Response response = await http.post(
    serverLink,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{         //Dados e estruturas em JSON
      'latitude': lati,
      'longitude': longi,
      'statusLixo': sLixo,
      'user':_userName,
    }),
  );
  debugPrint(response.statusCode.toString());
  if (response.statusCode == 200) {
    // If the server did return a 200 CREATED response,
    // then parse the JSON.
    return Album.fromJson(json.decode(response.body));
  } else {
    // If the server did not return a 200 CREATED response,
    // then throw an exception.
    return null;
  }
}

//Classes de página do GPS
class GPSpage extends StatefulWidget {
  @override
  _GPSpageState createState() => _GPSpageState();
}

class _GPSpageState extends State<GPSpage> {
  GoogleMapController mapController;
  void _onMapCreated(GoogleMapController controller){
    mapController = controller;
  }
  
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  static Position _currentPosition;

  @override
  LatLng _center = LatLng(-23.5700987,-46.8580335); //Localização padrão
  _getCurrentLocation() {             //Função que recebe do aparelho Latitude e Longitude
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:const Text("GPS"
        ,style: TextStyle(fontSize: 25.0),
        
        ),
			backgroundColor: Colors.green,
			centerTitle: true,
      actions: <Widget>[
				IconButton(
					icon: Icon(Icons.add_location),
					onPressed:(){
            setState((){
              _getCurrentLocation();
              _center=LatLng(_currentPosition.latitude,_currentPosition.longitude);
            });
          },
				),
			
      ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        compassEnabled: true,
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target:_center,
          zoom:9.0),
      )
    );
  }
}

//Classes da página de Configurações
class Configuracoes extends StatefulWidget {
  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Configurações",style: TextStyle(fontSize: 25.0)),
          centerTitle: true,
          backgroundColor: Colors.green,
        ),
        body:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(40.0),
              child: Text('O Link atual é: \n'+ serverLink,textAlign: TextAlign.center),
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Link NGROK',fillColor: Colors.green,hintStyle: TextStyle(color:Colors.green)),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child:
              RaisedButton(
                child: Text('Alterar'),
                onPressed: (){
                  String aux=retornaNgrok(_controller.text);
                  setState(() {
                    serverLink = aux;
                  });
              },
            ),),
          ],
        ),
      );
  }
}
//Classe de Página de Dados
class RecebeDados extends StatefulWidget {
  @override
  _RecebeDadosState createState() => _RecebeDadosState();
}

class _RecebeDadosState extends State<RecebeDados> {
  String _dadosRecebidos="Nada aqui, por enquanto!";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dados de envio",style: TextStyle(fontSize: 25.0)),
          centerTitle: true,
          backgroundColor: Colors.green,
      ),
      body: 
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
        <Widget>[
          Padding(
          padding: const EdgeInsets.only(left:110.0),
          child:
            Text(_dadosRecebidos),
          ),
          Padding(
          padding: const EdgeInsets.only(left:110.0,top:10.0),
          child:
            RaisedButton(
              child: Text("Receber Dados!"),
              onPressed: (){
                setState(){
                  //_dadosRecebidos=fetchAlbum();
                };
            },
          ),
          ),
        ]
      ),
    );
  }
}
//Função pra criar album a partir de um GET ao serverLink
Future<Album> fetchAlbum() async{
  final response = await http.get(serverLink);
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Album.fromJson(json.decode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}
//Função pra facilitar input do endereço NGROK
String retornaNgrok(String s){
  if(s.substring(0,7) != "https://"){
    s="https://"+s;
  }
  if(!s.contains(".ngrok.io")){
    s=s+".ngrok.io";
  }
  return s;

}