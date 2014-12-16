part of sweeps;


StreamSubscription<DeviceMotionEvent> ss;
num ax, ay, az;
Timer animLoopTimer;
int numDeviceMotionEvents = 0;
List<Point>t1s, t2s; 


void startCavalieriLoop() {
  t1s = new List<Point>();
  t2s = new List<Point>();
  if (ss == null) {
    ss = window.onDeviceMotion.listen((DeviceMotionEvent e) {
        ax = e.accelerationIncludingGravity.x;
        ay = e.accelerationIncludingGravity.y;
        az = e.accelerationIncludingGravity.z;
        //querySelector("#dartGAccel")
        //     ..text = "("+ax.toString()+", "+ay.toString()+", "+az.toString()+")";
        if (numDeviceMotionEvents > 0) { print("i believe there really is an accelerometer here... "); }
        numDeviceMotionEvents++;
      });
  }
    t1s.add(s1end);
    t2s.add(s2end);
    animLoopTimer = new Timer(new Duration(milliseconds: 50), maybeFall);
}

void maybeFall( ) {
  //print("maybeFall called");
  var message = "no move";
  int cs1x, cs2x, cs1y, cs2y;
  if (ax != null && ax > 6) {
    if ( ay > 1 ) { 
      message = "fall right";
      cs1x = s1end.x + 1;
      cs2x = s2end.x + 1;
      cs1y = s1end.y + 1;
      cs2y = s2end.y + 1;
    } else if ( ay < -1 ) {
      message = "fall left";
        cs1x = s1end.x - 1;
        cs2x = s2end.x - 1;
        cs1y = s1end.y + 1;
        cs2y = s2end.y + 1;
    } else { 
      message = "fall down";
      cs1x = s1end.x;
      cs2x = s2end.x;
      cs1y = s1end.y + 1;
      cs2y = s2end.y + 1;
    }
    if ( cs1x > 0 && cs2x > 0  && cs1x < hticks * hSubTicks && cs2x < hticks * hSubTicks ) {
      if (cs1y < vticks * vSubTicks && cs2y < vticks * vSubTicks) {
        s1end = new Point(cs1x, cs1y);
        s2end = new Point(cs2x, cs2y);
        t1s.add(s1end);
        t2s.add(s2end);
      }
    }
  }
  //querySelector("#dartInfo")
   //       ..text = message;
  drawCavalieri();
  print("s1end=(" + s1end.x.toString() + ", " + s1end.y.toString() + ") and s2end=(" + s2end.x.toString() + ", " + s2end.y.toString() + ")");
  print("hst=" + hSubTicks.toString() + "; vst=" + vSubTicks.toString() );
  animLoopTimer = new Timer(new Duration(milliseconds: 500), maybeFall);
}

void drawCavalieri() {
//  ticwid = canv.width / hticks;
//   ticht = canv.height / vticks;
   
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  
  drawRulers(ctx);
  drawGrid(ctx);
  drawPath(ctx);
  drawSweeperCurrentSWEEP(ctx);
}


  
void drawPath(CanvasRenderingContext2D ctxt) {
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";
  ctxt.beginPath();
  Point init = new Point ( getXForHSubTick(t1s.first.x),  getYForVSubTick(t1s.first.y) );
  ctxt.moveTo(init.x, init.y);
  for (int i = 1; i<t1s.length; i++ ) {
    Point p = new Point ( getXForHSubTick(t1s[i].x),  getYForVSubTick(t1s[i].y) );
    ctxt.lineTo(p.x, p.y);
  }
  for (int j = t2s.length - 1; j>=0; j-- ) {
    Point p = new Point ( getXForHSubTick(t2s[j].x),  getYForVSubTick(t2s[j].y) );
    ctxt.lineTo(p.x, p.y);
  }
  ctxt.lineTo(init.x, init.y);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();
}