/*
GitHub uso de Polyline no Maps:
  -https://github.com/rajayogan/flutter-googlemaps-routes/blob/master/lib/main.dart
  -https://github.com/DeveloperLibs/flutter_google_map_route
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
import 'package:pcs_prj/mapping.dart';

String serverLink = 'link_do_servidor';

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
          "${place.subLocality}, ${place.country}";
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
			title: const Text("Wireless Thrash",style: TextStyle(fontSize: 25.0),),
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
            MaterialPageRoute(builder: (context) =>GPSpage()));
            },
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
            return '';
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
      'latitude': lati,                         //Desse jeito é mais fácil, ao precisar adicionar um dado
      'longitude': longi,                       //é só declarar e tá good to go
      'statusLixo': sLixo,
      'user':_userName,
    }),
  );
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

class _RecebeDadosState extends State<RecebeDados> {  //Essa página nem foi usada na real
  String _dadosRecebidos="Nada aqui, por enquanto!";
  Future<Album> futureAlbum;
  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }
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
                setState((){
                  FutureBuilder<Album>(
                    future: futureAlbum,
                    builder:  (context, snapshot) {
              if (snapshot.hasData) 
                return Text(snapshot.data.title); 
              else if (snapshot.hasError)
                return Text("${snapshot.error}");
              // CircularProgress é mostrado por padrão.
              return CircularProgressIndicator();
              }, 
                    );
                },);
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
  if(s.substring(0,7) != "https://" || s.substring(0,6) != "http://"){
    s="https://" + s;
  }
  if(!s.contains(".ngrok.io")){
    s=s+".ngrok.io";
  }
  return s;

}