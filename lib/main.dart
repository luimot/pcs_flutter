/*
Links importantes:
Links NGROK:  --LINKS TEMPORÁRIOS, ALTERAR TODA VEZ QUE FOR COMPILAR--
  -http://f1d30ae1.ngrok.io/ Link do servidor local
  -http://2e5dc8f9.ngrok.io  Link do servidor do Pedro
Google Maps API key:
  -
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
import 'package:google_maps_flutter/google_maps_flutter.dart';

const serverLink = 'http://7965ebfd.ngrok.io';

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
  
  @override
  _getAddressFromLatLng() async {                 //Função que a partir da localização, infere os detalhes
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
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
  Widget build(BuildContext context) {
	return Scaffold(
		appBar:AppBar(
			title: const Text("Wireless Trash",style: TextStyle(fontSize: 25.0),),
			backgroundColor: Colors.green,
			centerTitle: true,
			actions: <Widget>[
				IconButton(
					icon: Icon(Icons.refresh),
					onPressed:(){},
				),
			
      ],
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
				],
			),
		),
		backgroundColor: Colors.white,
		body: SingleChildScrollView(
      child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
			  children: <Widget>[
        new DropdownButton<String>(
          dropdownColor:Colors.green[200],
          items: <String>['Medio','Cheio','Transbordando'].map((String value) {
            return new DropdownMenuItem<String>(
              value: value,
              child: new Text(value),
            );
          }).toList(),
          value:_status,
          onChanged: (String value) {
            setState((){
            _status = value;
            });
          },
        ),
        Padding(padding: EdgeInsets.zero,
					child: Image.asset("images/logo.png",alignment: Alignment.center,),
				),
        RaisedButton(
        child: Text('Enviar'),
        onPressed: (){
          _getCurrentLocation();
          setState(() {
            _futureAlbum = createAlbum(_currentPosition.latitude, _currentPosition.longitude,_status== null?"nulo":_status);
          });
        },
      ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<Album>(        //Faz com que o body do app esteja adaptado a funções Future
                future: _futureAlbum,
                builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text("Enviado!");    //Text(snapshot.data.title)    
                }else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              },
            ) 
        )
			],
		),
	));
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
  const _userName = 'usuario1234';
  DateTime now =new DateTime.now();
  DateTime currentTime = new DateTime(now.year, now.month, now.day, now.hour, now.minute);
  //String currentTime = DateFormat('kk:mm').format(now);
  final http.Response response = await http.post(
    serverLink,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'latitude': lati,
      'longitude': longi,
      'statusLixo': sLixo,
      'user':_userName,
      'timestamp':currentTime.toString(),
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
    throw Exception('Failed to load album');
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
  LatLng _center = LatLng(-25.5464631,-49.3411338); //Localização padrão
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

        initialCameraPosition: CameraPosition(
          target:_center,
          zoom:10.0),
      )
    );
  }
}