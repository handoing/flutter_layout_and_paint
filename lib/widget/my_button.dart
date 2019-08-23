import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    renderObject
      ..options = options;
  }

}

class RenderMyBtn extends RenderProxyBox {

  RenderMyBtn({
    Options options
  }) : _options = options,
        super();

  Options get options => _options;
  Options _options;
  set options(Options value) {
    _options = value;
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
    canvas.drawRect(Rect.fromLTWH(0, 0, child.size.width, child.size.height), paint);

    if (_options.status == AnimationStatus.forward) {
      canvas.drawCircle(_options.tapPosition, _options.radius, paint);
    }

  }

}