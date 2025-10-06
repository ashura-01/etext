import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class BluMessenger extends StatefulWidget {
  const BluMessenger({super.key});

  @override
  State<BluMessenger> createState() => _BluMessengerState();
}

class _BluMessengerState extends State<BluMessenger> {
  final Strategy strategy = Strategy.P2P_STAR;

  String deviceName = '';
  String? connectedId;
  String? connectedDeviceName;

  bool isAdvertising = false;
  bool isDiscovering = false;

  List<Endpoint> discoveredDevices = [];
  List<String> messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    deviceName = Platform.localHostname.isNotEmpty
        ? 'Device_${Platform.localHostname}'
        : 'Device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> startAdvertising() async {
    await _requestPermissions();
    try {
      await Nearby().startAdvertising(
        deviceName,
        strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED && mounted) {
            setState(() => connectedId = id);
          }
        },
        onDisconnected: (id) {
          if (mounted) {
            setState(() {
              connectedId = null;
              connectedDeviceName = null;
            });
          }
        },
      );
      setState(() => isAdvertising = true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
    setState(() => isAdvertising = false);
  }

  Future<void> startDiscovery() async {
    await _requestPermissions();
    discoveredDevices.clear();
    try {
      await Nearby().startDiscovery(
        deviceName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          if (!discoveredDevices.any((e) => e.id == id)) {
            setState(() {
              discoveredDevices.add(Endpoint(id: id, name: name));
            });
          }
        },
        onEndpointLost: (id) {
          setState(() {
            discoveredDevices.removeWhere((e) => e.id == id);
          });
        },
      );
      setState(() => isDiscovering = true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
    setState(() => isDiscovering = false);
  }

  void _onConnectionInit(String id, ConnectionInfo info) {
    setState(() => connectedDeviceName = info.endpointName);

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) {
        if (payload.type == PayloadType.BYTES) {
          String msg = String.fromCharCodes(payload.bytes!);
          setState(() {
            messages.add("🟢 ${connectedDeviceName ?? 'Friend'}: $msg");
          });
        }
      },
      onPayloadTransferUpdate: (endid, update) {},
    );
  }

  Future<void> connectToDevice(Endpoint device) async {
    try {
      await Nearby().requestConnection(
        deviceName,
        device.id,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED && mounted) {
            setState(() => connectedId = id);
          }
        },
        onDisconnected: (id) {
          setState(() {
            connectedId = null;
            connectedDeviceName = null;
          });
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _sendMessage(String msg) async {
    if (connectedId != null && msg.isNotEmpty) {
      try {
        await Nearby().sendBytesPayload(
          connectedId!,
          Uint8List.fromList(msg.codeUnits),
        );
        setState(() => messages.add("🔵 Me: $msg"));
      } catch (e) {
         Get.snackbar(
        'Error',
        'try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      }
    }
  }

  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Select a Device",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = discoveredDevices[index];
                return ListTile(
                  title: Text(
                    device.name,
                    style: const TextStyle(color: Colors.green),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    connectToDevice(device);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("War Mode", style: TextStyle( color:Color.fromARGB(255, 212, 228, 255), fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isAdvertising ? Icons.stop : Icons.campaign),
            tooltip: isAdvertising ? 'Stop Advertising' : 'Start Advertising',
            onPressed: () =>
                isAdvertising ? stopAdvertising() : startAdvertising(),
          ),
          IconButton(
            icon: Icon(isDiscovering ? Icons.stop_circle : Icons.search),
            tooltip: isDiscovering ? 'Stop Discovery' : 'Start Discovery',
            onPressed: () => isDiscovering ? stopDiscovery() : startDiscovery(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (connectedDeviceName != null)
            Container(
              width: double.infinity,
              color: Colors.black12,
              padding: const EdgeInsets.all(12),
              child: Text(
                "🔗 Connected to: $connectedDeviceName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          if (connectedId == null && discoveredDevices.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 12, 53),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: _showDeviceSelectionDialog,
                  child: const Text("Select Device"),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (_, i) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  alignment: messages[i].startsWith("🔵")
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: messages[i].startsWith("🔵")
                          ? Colors.blue[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      messages[i].replaceFirst(RegExp(r'^🔵 |^🟢 '), ''),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 142, 184, 255),
                        ), // change this to any color
                      ),
                      fillColor: const Color.fromARGB(255, 55, 72, 78),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 0, 131, 238),
                  radius: 29,
                  child: IconButton(
                    icon: const Icon(Icons.send_outlined),
                    color: const Color.fromARGB(255, 0, 0, 0),
                    onPressed: () {
                      _sendMessage(_controller.text.trim());
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Endpoint {
  final String id;
  final String name;

  Endpoint({required this.id, required this.name});
}
