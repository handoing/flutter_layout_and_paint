import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

class MyRow extends MultiChildRenderObjectWidget {
  MyRow({
    Key key,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMyRow();
  }
}

class MyMultiChildLayoutParentData extends ContainerBoxParentData<RenderBox> {
  @override
  String toString() => '${super.toString()};';
}

class MySub extends ParentDataWidget<MyRow> {
  MySub({Key key, @required Widget child}) : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {

  }

}

class RenderMyRow extends RenderBox with ContainerRenderObjectMixin<RenderBox, MyMultiChildLayoutParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, MyMultiChildLayoutParentData> {

  RenderMyRow({ List<RenderBox> children }) {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MyMultiChildLayoutParentData)
      child.parentData = MyMultiChildLayoutParentData();
  }

  @override
  void performLayout() {
    RenderBox child = firstChild;
    child.layout(BoxConstraints(
      minHeight: 0.0,
      maxHeight: constraints.maxHeight,
      minWidth: 0.0,
      maxWidth: constraints.maxWidth / 2,
    ), parentUsesSize: true);
    MyMultiChildLayoutParentData childParentData = child.parentData;
    childParentData.offset = Offset(0, (constraints.maxHeight - child.size.height) / 2);

    child = childParentData.nextSibling;
    child.layout(BoxConstraints(
      minHeight: 0.0,
      maxHeight: constraints.maxHeight,
      minWidth: 0.0,
      maxWidth: constraints.maxWidth / 2,
    ), parentUsesSize: true);
    childParentData = child.parentData;
    childParentData.offset = Offset(constraints.maxWidth - child.size.width, (constraints.maxHeight - child.size.height) / 2);

    size = Size(constraints.maxWidth, constraints.maxHeight);

  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    while (child != null) {
      final MyMultiChildLayoutParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }
}
