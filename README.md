## Flutter的布局和绘制

本次主要讲解flutter如何实现布局和绘制，默认大家已学习过[《Flutter从加载到显示》](https://mp.weixin.qq.com/s/ncViI0KGikPUIZ7BlEHGOA)

先来看下flutter rendering pipeline，如图：
<img src="http://p0.qhimg.com/t014b88997d0c84c319.png" width="100%" /> 
当flutter接收到系统发送来的Vsync信号时，会连续执行动画、构建、布局、绘制一系列操作，最后输出Sence（layer tree）并传递给flutter engine进行后续操作，其中绿色部分是本次要讲的内容，这里说明一下，在flutter里，layout和paint阶段操作的是RenderObject tree。

### 实现流程

#### 1. drawFrame
我们首先看一下drawFrame执行了哪些操作


```dart
mixin RendererBinding on BindingBase, ServicesBinding, SchedulerBinding, GestureBinding, SemanticsBinding, HitTestable {
  ...
	
  @protected
  void drawFrame() {
    // PipelineOwner负责管理renderObject tree的渲染
    pipelineOwner.flushLayout(); // 对RenderObject进行布局操作
    pipelineOwner.flushCompositingBits(); // 对layer tree做相关处理
    pipelineOwner.flushPaint(); // 对RenderObject进行绘制操作
    renderView.compositeFrame(); // 传递sence给engine做后续操作
    pipelineOwner.flushSemantics(); // 处理语义相关操作
  }
  ...
}
```

#### 2. flushLayout
flushLayout里会遍历 _nodesNeedingLayout (当节点需要布局时会被添加到这个数组)，并调用 _layoutWithoutResize 方法。

```dart
void flushLayout() {
  while (_nodesNeedingLayout.isNotEmpty) {
	final List<RenderObject> dirtyNodes = _nodesNeedingLayout;
	_nodesNeedingLayout = <RenderObject>[];
	for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => a.depth - b.depth)) {
	  if (node._needsLayout && node.owner == this)
	    node._layoutWithoutResize();
	  }
    }
  }
}
```

_layoutWithoutResize 方法里执行performLayout，并调用markNeedsPaint标记节点dirty状态。

```dart
void _layoutWithoutResize() {
  try {
    performLayout();
    markNeedsSemanticsUpdate();
  } catch (e, stack) {
    _debugReportException('performLayout', e, stack);
  }
  _needsLayout = false;
  markNeedsPaint();
}
```

#### 3. flushPaint
跳过flushCompositingBits（不作为本次讲解内容），我们继续看flushPaint，当节点对应的layer被挂载后会调用repaintCompositedChild

```dart
void flushPaint() {
  final List<RenderObject> dirtyNodes = _nodesNeedingPaint;
  _nodesNeedingPaint = <RenderObject>[];
  for (RenderObject node in dirtyNodes..sort((RenderObject a, RenderObject b) => b.depth - a.depth)) {
    if (node._needsPaint && node.owner == this) {
      if (node._layer.attached) {
        PaintingContext.repaintCompositedChild(node);
      } else {
        node._skippedPaintingOnLayer();
      }
    }
  }
}
```

继续调用 _repaintCompositedChild

```dart
static void repaintCompositedChild(RenderObject child, { bool debugAlsoPaintedParent = false }) {
  _repaintCompositedChild(
    child,
    debugAlsoPaintedParent: debugAlsoPaintedParent,
  );
}
```

调用 _paintWithContext

```dart
static void _repaintCompositedChild(
  RenderObject child, {
  bool debugAlsoPaintedParent = false,
  PaintingContext childContext,
}) {
  if (child._layer == null) {
    child._layer = OffsetLayer();
  } else {
    child._layer.removeAllChildren();
  }
  childContext ??= PaintingContext(child._layer, child.paintBounds);
  child._paintWithContext(childContext, Offset.zero);
  childContext.stopRecordingIfNeeded();
}
```

调用了renderObject的paint方法进行绘制操作，并传入context和offset

```dart
void _paintWithContext(PaintingContext context, Offset offset) {
  if (_needsLayout)
    return;
  RenderObject debugLastActivePaint;
  _needsPaint = false;
  try {
    paint(context, offset);
  } catch (e, stack) {
    _debugReportException('paint', e, stack);
  }
}
```

### 关于布局约束

在Flutter中，布局采用的是约束（constraints）模型。父元素通过传递约束给子元素，子元素可在这些约束下调整自身大小。
<img src="http://p0.qhimg.com/t01f0cf58282f8f7192.png" width="100%" />

flutter里面有两种约束类型：

1.BoxConstraint（盒约束）

```dart
const BoxConstraints({
  this.minWidth = 0.0,
  this.maxWidth = double.infinity,
  this.minHeight = 0.0,
  this.maxHeight = double.infinity,
});
```

```dart
Size(double width, double height)
```


2.SliverConstraint（滚动相关约束）

```dart
const SliverConstraints({
  @required this.axisDirection,
  @required this.growthDirection,
  @required this.userScrollDirection,
  @required this.scrollOffset,
  @required this.precedingScrollExtent,
  @required this.overlap,
  @required this.remainingPaintExtent,
  @required this.crossAxisExtent,
  @required this.crossAxisDirection,
  @required this.viewportMainAxisExtent,
  @required this.remainingCacheExtent,
  @required this.cacheOrigin,
})
```

```dart
const SliverGeometry({
  this.scrollExtent = 0.0,
  this.paintExtent = 0.0,
  this.paintOrigin = 0.0,
  double layoutExtent,
  this.maxPaintExtent = 0.0,
  this.maxScrollObstructionExtent = 0.0,
  double hitTestExtent,
  bool visible,
  this.hasVisualOverflow = false,
  this.scrollOffsetCorrection,
  double cacheExtent,
})
```

### 自定义布局和绘制示例：

1.单Widget

实现简单居中布局，截屏如图：
<div align="center">
<img src="http://p0.qhimg.com/t01bae4861bbef9063b.png" width="400px"/>
</div>

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 继承SingleChildRenderObjectWidget并重写createRenderObject方法，返回自定义的RenderMyCenter
class MyCenter extends SingleChildRenderObjectWidget {

  MyCenter({Widget child}): super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMyCenter();
  }
}

// 继承RenderShiftedBox并重写performLayout实现布局，RenderShiftedBox最终继承自RenderObject
class RenderMyCenter extends RenderShiftedBox {
  RenderMyCenter(): super(null);

  @override
  void performLayout() {

	// 通过调用child的layout方法向子节点传递约束
    child.layout(
        BoxConstraints(
            minHeight: 0.0,
            maxHeight: this.constraints.minHeight,
            minWidth: 0.0,
            maxWidth: this.constraints.minWidth
        ),
        parentUsesSize: true
    );

    final BoxParentData childParentData = child.parentData;
    // 设置偏移量，使child居中
    childParentData.offset = Offset((constraints.maxWidth - child.size.width) / 2, (constraints.maxHeight - child.size.height) / 2);

	// 设置大小，使得其父元素可以拿到当前节点的size
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

}
```

2.多Widget

实现简单横向布局Widget，定义两个子Widget，截屏如图：
<div align="center">
<img src="http://p0.qhimg.com/t018d4d7209c11a2581.png" width="400px" />
</div>

```dart
// 实现多Widget需继承MultiChildRenderObjectWidget，重写createRenderObject
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

// 定义MyMultiChildLayoutParentData，当RenderMyRow mixins时需传入当前类型
class MyMultiChildLayoutParentData extends ContainerBoxParentData<RenderBox> {
  @override
  String toString() => '${super.toString()};';
}

class MySub extends ParentDataWidget<MyRow> {
  MySub({Key key, @required Widget child}) : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {
	// 可通过applyParentData对renderObject进行一些赋值操作，以便布局中可通过ParentData拿到相关信息，本示例未用到
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
  	// 拿到第一个子节点
    RenderBox child = firstChild;
    // 传递约束
    child.layout(BoxConstraints(
      minHeight: 0.0,
      maxHeight: constraints.maxHeight,
      minWidth: 0.0,
      maxWidth: constraints.maxWidth / 2,
    ), parentUsesSize: true);
    MyMultiChildLayoutParentData childParentData = child.parentData;
    // 定义偏移使其水平居左，垂直居中
    childParentData.offset = Offset(0, (constraints.maxHeight - child.size.height) / 2);

	// 通过nextSibling拿到第二个子节点
    child = childParentData.nextSibling;
    // 传递约束
    child.layout(BoxConstraints(
      minHeight: 0.0,
      maxHeight: constraints.maxHeight,
      minWidth: 0.0,
      maxWidth: constraints.maxWidth / 2,
    ), parentUsesSize: true);
    childParentData = child.parentData;
    // 定义偏移使其水平居右，垂直居中
    childParentData.offset = Offset(constraints.maxWidth - child.size.width, (constraints.maxHeight - child.size.height) / 2);

	// 定义大小
    size = Size(constraints.maxWidth, constraints.maxHeight);

  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    while (child != null) {
      final MyMultiChildLayoutParentData childParentData = child.parentData;
      // 直接交由子元素绘制
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }
}
```

3.自定义Button

自定义button，当被点击触发圆圈扩散动画
<div align="center">
<img src="http://p0.qhimg.com/t015c363517765f10c6.gif" width="400px" />
</div>

```dart
class Options {
  Options({
    this.radius,
    this.status,
    this.tapPosition,
    this.color,
  });

  final double radius;
  final AnimationStatus status;
  final Offset tapPosition;
  final Color color;
}

class MyButton extends StatefulWidget {
  MyButton({
    Key key,
    this.onTap,
    this.child,
    this.color,
  }) : super(key: key);

  final Widget child;

  final GestureTapCallback onTap;

  final Color color;

  @override
  _MyButtonState createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> with SingleTickerProviderStateMixin {

  AnimationController controller;
  Tween<double> radiusTween;
  Animation<double> radiusAnimation;
  AnimationStatus status;
  Offset _tapPosition;

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 400))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((AnimationStatus listener) {
        status = listener;
      });

    radiusTween = Tween<double>(begin: 0, end: 40);
    radiusAnimation = radiusTween
        .animate(CurvedAnimation(curve: Curves.ease, parent: controller));

    super.initState();
  }

  void _animate() {
    controller.forward(from: 0);
  }

  void _handleTap(TapUpDetails tapDetails) {

    final RenderBox renderBox = context.findRenderObject();

    _tapPosition = renderBox.globalToLocal(tapDetails.globalPosition);
    _animate();

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return MyBtn(
        child: GestureDetector(
          child: widget.child,
          onTapUp: _handleTap,
        ),
        options: Options(
          radius: radiusAnimation.value,
          status: status,
          tapPosition: _tapPosition,
          color: widget.color,
        )
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// 继承SingleChildRenderObjectWidget
class MyBtn extends SingleChildRenderObjectWidget {

  MyBtn({
    Widget child,
    @required this.options,
  }): super(child: child);

  final Options options;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMyBtn(
        options: options
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMyBtn renderObject) {
  	// 重新赋值options
    renderObject
      ..options = options;
  }

}

// 继承RenderProxyBox
class RenderMyBtn extends RenderProxyBox {

  RenderMyBtn({
    Options options
  }) : _options = options,
        super();

  Options get options => _options;
  Options _options;
  set options(Options value) {
    _options = value;
    // 当options被赋值时标记当前节点需要绘制
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    Paint paint = Paint()
      ..color = _options.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Canvas canvas = context.canvas;

    canvas.translate(offset.dx, offset.dy);
    // 绘制边框
    canvas.drawRect(Rect.fromLTWH(0, 0, child.size.width, child.size.height), paint);

    if (_options.status == AnimationStatus.forward) {
    	// 绘制圆
      canvas.drawCircle(_options.tapPosition, _options.radius, paint);
    }

  }

}
```

#### 问题：重布局和重绘？

1.当某个节点的size变了，整个视图树需要重新计算？

通过设置relayoutBoundary，使得边界内的节点做任何改变都不会导致边界外的节点重新布局。

2.如何避免图层内其他节点重绘？

通过RepaintBoundary组件或直接设置renderObject的isRepaintBoundary为true

有兴趣的同学可自行验证

#### demo

[https://github.com/handoing/flutter_layout_and_paint](https://github.com/handoing/flutter_layout_and_paint)





