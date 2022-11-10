// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:uber_rider_app/Assistants/assistantMethods.dart';
import 'package:uber_rider_app/Models/history.dart';

class HistoryItem extends StatelessWidget {
  History history;

  HistoryItem(this.history);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Row(
              children: [
                Image.asset(
                  "assets/images/pickicon.png",
                  height: 16,
                  width: 16,
                ),
                const SizedBox(
                  width: 18,
                ),
                Expanded(
                  child: Container(
                    child: Text(
                      history.pickup,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 16, fontFamily: "Brand-semibold"),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  "\$${history.fares}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Brand-semibold",
                      color: Colors.yellow[700]),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                "assets/images/desticon.png",
                height: 16,
                width: 16,
              ),
              const SizedBox(
                width: 18,
              ),
              Text(
                history.dropOff,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Text(AssistantMethods.formatTripDate(history.createdAt),
              style: const TextStyle(
                color: Colors.grey,
              ))
        ],
      ),
    );
  }
}
