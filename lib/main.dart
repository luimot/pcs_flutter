/*
Links importantes:
Links NGROK:
  -http://f1d30ae1.ngrok.io/ Link do servidor local
  -http://2e5dc8f9.ngrok.io  Link do servidor do Pedro
Google Maps API key:
  -
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
import 'package:location/location.dart';

const serverLink = 'http://2e5dc8f9.ngrok.io';

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
  
  final TextEditingController _controller = TextEditingController();
  Future<Album> _futureAlbum;
  static const padDist = 10.0;
  
  @override
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
        Padding(
          padding: const EdgeInsets.all(8.0),
        child: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Comunicação',fillColor: Colors.green,hintStyle: TextStyle(color:Colors.green)),
        )
        ),
        Padding(padding: EdgeInsets.zero,
					child: Image.asset("images/logo.png",alignment: Alignment.center,),
				),
        RaisedButton(
        child: Text('Enviar'),
        onPressed: (){
          setState(() {
            _futureAlbum = createAlbum(_controller.text);
          });
        },
      ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<Album>(
                future: _futureAlbum,
                builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data.title);    
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
//Classes cuidando de comunicação JSON com o servidor http
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

Future<Album> createAlbum(String title) async {
  final http.Response response = await http.post(
    serverLink,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'data': title,
    }),
  );
  debugPrint(response.statusCode.toString());
  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Album.fromJson(json.decode(response.body));
  } else {
    // If the server did not return a 201 CREATED response,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title:const Text("GPS",style: TextStyle(fontSize: 25.0),),
			backgroundColor: Colors.green,
			centerTitle: true,

      ),
    );
  }
}

Future <LocationData> checaPermissaoLocation() async{
  Location location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  _serviceEnabled = await location.serviceEnabled();
  if(!_serviceEnabled)
    _serviceEnabled = await location.serviceEnabled();

  _permissionGranted = await location.hasPermission();
  if(_permissionGranted == PermissionStatus.denied)
    _permissionGranted = await location.hasPermission();
  _locationData = await location.getLocation();
  return _locationData;
}