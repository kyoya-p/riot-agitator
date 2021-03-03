import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketConsoleWidget extends StatefulWidget {
  WebSocketChannel? channel;

  WebsocketConsoleWidget({Key? key}) : super(key: key);

  @override
  _WebsocketConsoleWidgetState createState() => _WebsocketConsoleWidgetState();
}

class _WebsocketConsoleWidgetState extends State<WebsocketConsoleWidget> {
  TextEditingController uri = TextEditingController(text: "ws://");
  TextEditingController msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Websocket Console"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: [
              Expanded(
                  child: Form(
                child: TextFormField(
                  controller: uri,
                  decoration: InputDecoration(labelText: 'URI'),
                ),
              )),
              TextButton(
                child: (widget.channel == null)
                    ? Text("Connect")
                    : Text("Disconnect"),
                onPressed: () {
                  setState(() {
                    if (widget.channel == null) {
                      widget.channel =
                          WebSocketChannel.connect(Uri.parse(uri.text));
                    } else {
                      widget.channel?.sink.close();
                      widget.channel = null;
                    }
                  });
                },
              )
            ]),
            Form(
              child: TextFormField(
                controller: msg,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: widget.channel?.stream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    if (msg.text.isNotEmpty) {
      widget.channel?.sink.add(msg.text);
    }
  }

  @override
  void dispose() {
    widget.channel?.sink.close();
    super.dispose();
  }
}
