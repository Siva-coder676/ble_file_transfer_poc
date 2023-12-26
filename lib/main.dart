import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth File Transfer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DeviceListScreen(),
    );
  }
}

class DeviceListScreen extends StatefulWidget {
  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    _getDevices();
    super.initState();
  }

   @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  void _getDevices() async {
    try {
      await flutterBlue.startScan(timeout: Duration(seconds: 4));
      flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          if (!devices.contains(result.device)) {
            devices.add(result.device);
            setState(() {});
          }
        }
        print(devices.length.toString());
      });
    } catch (e) {
      print("Error scanning for devices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth File Transfer'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devices[index].name),
            subtitle: Text(devices[index].id.toString()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FileTransferScreen(device: devices[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

 
}

class FileTransferScreen extends StatefulWidget {
  final BluetoothDevice device;

  FileTransferScreen({required this.device});

  @override
  _FileTransferScreenState createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    device = widget.device;
    _connectToDevice();
    super.initState();
  }

  @override
  void dispose() {
    device!.disconnect();
    super.dispose();
  }

  void _connectToDevice() async {
    try {
      await device!.connect();
      List<BluetoothService> services = await device!.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.write) {
            Logger().i(c.uuid);
            characteristic = c;
            break;
          }
        }
      }
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  Future<void> _sendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        List<int> fileBytes = await file.readAsBytes();
        // Logger().e(fileBytes);

        // Send the file bytes in chunks
        for (int i = 0; i < fileBytes.length; i += 20) {
          int end = (i + 20 < fileBytes.length) ? i + 20 : fileBytes.length;
          List<int> chunk = fileBytes.sublist(i, end);
          await characteristic
              ?.write(Uint8List.fromList(chunk))
              .then((value) => Logger().f("file bytes value: $value"));
          Logger().t("file upload");
          // await Future.delayed(
          //     Duration(milliseconds: 50)); // Delay between chunks
        }

        print('File sent successfully!');
      }
    } catch (e) {
      print("Error sending file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Transfer'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _sendFile,
          child: Text('Send File'),
        ),
      ),
    );
  }
}


/* for flutter Blue Plus Package
class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const ScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState);

    return MaterialApp(
      color: Colors.lightBlue,
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}*/
