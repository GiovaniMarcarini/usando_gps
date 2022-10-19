
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget{
  const HomePage ({Key? key}) : super(key: key);

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  final _linhas = <String>[];
  StreamSubscription<Position>?  _subiscription;
  Position? _ultimaLocalizacaoObtida;
  double distanciaPercorida = 0;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
    timeLimit: Duration(seconds: 2)
  );

  bool get _monitorandoLocalizacao => _subiscription != null;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
      title: Text('Usando GPS'),
      ),
      body: _criarBody(),
    );
  }

  Widget _criarBody() => Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          ElevatedButton(
              onPressed: _obterUltimaLocalizacao,
              child: const Text('Obter a ultima localização conhecida (cache)')),
          ElevatedButton(
              onPressed: _obterLocalizacaoAtual,
              child: Text('Obter localização Atual')),
          ElevatedButton(
              onPressed: _monitorandoLocalizacao ? _pararMonitoramento : _iniciarMonitoramento,
              child: Text(_monitorandoLocalizacao ? 'Parar Monitoramento' : 'Iniciar Monitoramento')),
          ElevatedButton(
              onPressed: _limparLog,
              child: const Text('Limpar Log')),
          const Divider(),
          Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _linhas.length,
                  itemBuilder: (_, index) => Padding(
                    padding:  const EdgeInsets.all(5),
                    child: Text(_linhas[index]),
                  ),
              ),
          ),
        ],
      ),
  );
  void _obterUltimaLocalizacao() async {
    bool permissoesPermitidas = await _permissoesPermitidas();
    if(!permissoesPermitidas){
      return;
    }
    Position? position  = await Geolocator.getLastKnownPosition();
    setState(() {
      if(position == null){
        _linhas.add('Nenhuma localização registrada');
      }else {
        _linhas.add('Latitude: ${position?.latitude} | Longitude: ${position
            ?.longitude}');
      }
    });
  }

  void _obterLocalizacaoAtual() async {
    bool servicoHabilitado = await _servicoHabilitado();
    if(!servicoHabilitado){
      return;
    }
    bool permissoesPermitidas = await _permissoesPermitidas();
    if(!permissoesPermitidas){
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _linhas.add('Latitude: ${position?.latitude} | Longitude: ${position?.longitude}');
    });
  }

  void _iniciarMonitoramento(){
    _subiscription = Geolocator.getPositionStream(
        locationSettings: locationSettings
    ).listen((Position position) {
      setState(() {
        _linhas.add('Latitude: ${position?.latitude} | Longitude: ${position?.longitude}');
      });
      if(_ultimaLocalizacaoObtida != null){
        final distancia = Geolocator.distanceBetween(
            _ultimaLocalizacaoObtida!.latitude,
           _ultimaLocalizacaoObtida!.longitude,
            position.latitude,
           position.longitude);
        distanciaPercorida += distancia;
        _linhas.add('Distancia percorrida: ${distanciaPercorida.toInt()}m');
      }
      _ultimaLocalizacaoObtida = position;
    });
  }

  void _pararMonitoramento(){
    _subiscription?.cancel();
    setState(() {
      _subiscription = null;
      distanciaPercorida = 0;
    });
  }

  Future<bool> _servicoHabilitado() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if(!servicoHabilitado){
      await _mostrarDialogMensagem('Para utilizar este recurso, você deverá habilitar'
              ' o serviço de localização do dispostivo');
      Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }

  Future<bool> _permissoesPermitidas() async{
    LocationPermission permissao = await Geolocator.checkPermission();
    if(permissao == LocationPermission.denied){
      permissao = await Geolocator.checkPermission();
      if(permissao == LocationPermission.denied){
        _mostrarMensagem(''
            'Não será possível utilizar o serviço de localização por falta de permissão');
        return false;
      }
    }
    if(permissao == LocationPermission.deniedForever){
      await _mostrarDialogMensagem(
        'Para utilizar esse recurso, você deverá acessar as configurações '
            'do app e permitir a utilização do serviço de localização');
      Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  void _mostrarMensagem(String mensagem){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text(mensagem),
    ));
  }
  Future<void> _mostrarDialogMensagem(String mensagem) async{
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Atenção'),
          content: Text(mensagem),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        )
    );
  }
  void _limparLog(){
    setState(() {
      _linhas.clear();
    });
  }
}