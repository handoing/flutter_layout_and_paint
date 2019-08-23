import 'package:flutter/material.dart';
import 'package:flutter_layout_and_paint/widget/my_center.dart';
import 'package:flutter_layout_and_paint/widget/my_row.dart';
import 'package:flutter_layout_and_paint/widget/my_button.dart';

Widget mySingleWidget = MyCenter(
  child: Container(
      width: 100,
      height: 100,
      color: Colors.red
  ),
);

Widget myMultipleWidget = MyRow(
  children: <Widget>[
    MySub(
      child: Container(
          width: 100,
          height: 100,
          color: Colors.red
      ),
    ),
    MySub(
      child: Container(
          width: 100,
          height: 100,
          color: Colors.green
      ),
    ),
  ],
);

Widget myCustomButton = MaterialApp(
  home: Scaffold(
    body: Center(
      child: MyButton(
        color: Colors.red,
        onTap: () {
          print('click');
        },
        child: Container(
          width: 100,
          height: 80,
          color: Colors.blue,
          child: MyCenter(
            child: Text(
              'button',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget myMultipleTestWidget = MyRow(
  children: <Widget>[
    MySub(
      child: MyRow(
        children: <Widget>[
          MySub(
            child: Container(
              width: 80,
              height: 80,
              color: Colors.red,
              child: MyCenter(
                child: Text('1'),
              ),
            ),
          ),
          MySub(
            child: Container(
              width: 80,
              height: 80,
              color: Colors.green,
              child: MyCenter(
                child: Text('2'),
              ),
            ),
          ),
        ],
      ),
    ),
    MySub(
      child: Container(
        width: 100,
        height: 100,
        color: Colors.green,
        child: MyCenter(
          child: Text('3'),
        ),
      ),
    ),
  ],
);

void main() => runApp(myCustomButton);
