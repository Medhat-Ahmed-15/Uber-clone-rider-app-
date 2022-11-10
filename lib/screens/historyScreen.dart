// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_rider_app/DataHandler/appData.dart';
import 'package:uber_rider_app/widgets/historyItem.dart';

class HistoryScreen extends StatefulWidget {
  static String routeName = "/HistoryScreen";
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trip History"),
        backgroundColor: Colors.yellow[700],
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(0),
        // ignore: missing_return
        separatorBuilder: (BuildContext context, int index) => const Divider(
          thickness: 3.0,
          height: 3.0,
        ),

        itemCount: Provider.of<AppData>(context, listen: false)
            .tripHistoryDataList
            .length,
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return HistoryItem(Provider.of<AppData>(context, listen: false)
              .tripHistoryDataList[index]);
        },
      ),
    );
  }
}
