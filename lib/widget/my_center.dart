import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


class MyCenter extends SingleChildRenderObjectWidget {

  MyCenter({Widget child}): super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMyCenter();
  }
}

class RenderMyCenter extends RenderShiftedBox {
  RenderMyCenter(): super(null);

  @override
  void performLayout() {

    this.child.layout(
        BoxConstraints(
            minHeight: 0.0,
            maxHeight: this.constraints.minHeight,
            minWidth: 0.0,
            maxWidth: this.constraints.minWidth
        ),
        parentUsesSize: true
    );

    final BoxParentData childParentData = this.child.parentData;
    childParentData.offset = Offset((this.constraints.maxWidth - this.child.size.width) / 2, (this.constraints.maxHeight - this.child.size.height) / 2);

    this.size = Size(this.constraints.maxWidth, this.constraints.maxHeight);
  }

}