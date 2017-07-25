part of sweeps;


StreamSubscription<DeviceMotionEvent> ss;
num ax, ay, az;
Timer animLoopTimer;
int numDeviceMotionEvents = 0;
List<Point> t1s, t2s;
num slopeCalc;
bool canGoRight, canGoLeft;
num cavalieriLength;
num cavalieriArea;
num cavalieriLeftAdd, cavalieriRightAdd, cavalieriA, cavalieriB;
num cavalieriHeight = 0.0;


//for support of non-tablet cavalieri.
int fallCounter = 0;
int cavClickCenterX, cavClickCenterY;
num threshold = 4000;
bool cavIsDragging = false;
Point cavDragPoint;
String cavArrowDraw = "none";

var mouseDownSubscription = null;
var mouseMoveSubscription = null;
var mouseUpSubscription = null;


void initAndCheckForConstraints() {
  canGoLeft = true;
  canGoRight = true;
  cavalieriLength = (s1end.x - s2end.x).abs();
  cavalieriArea = 0.0;
  cavalieriHeight = 0.0;
  cavalieriA = (s1end.x - s2end.x).abs();
  cavalieriB = (s1end.y - s2end.y).abs();
  slopeCalc = (s1end.y - s2end.y) / (s1end.x - s2end.x);
  if (slopeCalc >= 0) {
    cavalieriRightAdd = cavalieriA - cavalieriB;
    cavalieriLeftAdd = cavalieriA + cavalieriB;
    if (slopeCalc >= 1) {
        canGoRight = false; 
    }
  } else {
    cavalieriRightAdd = cavalieriA + cavalieriB;
    cavalieriLeftAdd = cavalieriA - cavalieriB;
    if (slopeCalc <= -1) {
      canGoLeft = false; 
    }
  }
}

void startCavalieriLoop() {
  initAndCheckForConstraints();
  t1s = new List<Point>();
  t2s = new List<Point>();
  if (ss == null) {
    ss = window.onDeviceMotion.listen((DeviceMotionEvent e) {
      ax = e.accelerationIncludingGravity.x;
      ay = e.accelerationIncludingGravity.y;
      az = e.accelerationIncludingGravity.z;
      //querySelector("#dartGAccel")
      //     ..text = "("+ax.toString()+", "+ay.toString()+", "+az.toString()+")";
      if (numDeviceMotionEvents > 0) {
        print("i believe there really is an accelerometer here... ");
      }
      numDeviceMotionEvents++;
    });
  }
  t1s.add(s1end);
  t2s.add(s2end);
  animLoopTimer = new Timer(new Duration(milliseconds: 50), maybeFall);
}


num distancexy(Point p, num xv, num yv) {
  return p.distanceTo(new Point(xv, yv));
}

void getMouseDown(MouseEvent me) {
  if (distancexy(me.client, cavClickCenterX, cavClickCenterY) < threshold) {
    cavIsDragging = true;
    cavDragPoint = me.client;
  }
}

void getMouseUp(MouseEvent me) {
  cavIsDragging = false;
  cavArrowDraw = "none";
}

void getMouseMove(MouseEvent me) {
  if (cavIsDragging) {
    double delx = (me.client.x - cavDragPoint.x) / 1.0;
    double dely = (me.client.y - cavDragPoint.y) / 1.0;
    if (dely < 40) {
      cavArrowDraw = "none";
    } else {
      double slope = (dely / delx);
      if (slope > 1 && slope < 4) {
        cavArrowDraw = "right";
      } else if (slope < -1 && slope > -4) {
        cavArrowDraw = "left";
      } else if (slope.abs() > 4) {
        cavArrowDraw = "straight";
      }
    }
  }
}


void maybeFall() {
  //print("maybeFall called");
  var message = "no move";
  int cs1x = s1end.x;
  int cs2x = s2end.x;
  int cs1y = s1end.y;
  int cs2y = s2end.y;
  if ((ax != null && ax > 6) || (cavIsDragging)) {
    if ((ay != null && ay > 1) || cavArrowDraw == "right") {
      message = "fall right";
      if (canGoRight) {
        cs1x = s1end.x + 1;
        cs2x = s2end.x + 1;
        cs1y = s1end.y + 1;
        cs2y = s2end.y + 1;
      } else {
        cs1x = s1end.x;
        cs2x = s2end.x;
        cs1y = s1end.y + 1;
        cs2y = s2end.y + 1;
      }
    } else if ((ay != null && ay < -1) || cavArrowDraw == "left") {
      message = "fall left";
      if (canGoLeft) {
        cs1x = s1end.x - 1;
        cs2x = s2end.x - 1;
        cs1y = s1end.y + 1;
        cs2y = s2end.y + 1;
      } else {
        cs1x = s1end.x;
        cs2x = s2end.x;
        cs1y = s1end.y + 1;
        cs2y = s2end.y + 1;
      }
    } else if (ax != null || cavArrowDraw == "straight") {
      message = "fall down";
      cs1x = s1end.x;
      cs2x = s2end.x;
      cs1y = s1end.y + 1;
      cs2y = s2end.y + 1;
    }
    if (cs1x >= 0 && cs2x >= 0 && cs1x <= hticks * hSubTicks && cs2x <= hticks * hSubTicks) {
      if (cs1y < vticks * vSubTicks && cs2y < vticks * vSubTicks) {
        if (cs1y != s1end.y || cs2y != s2end.y ) {
          s1end = new Point(cs1x, cs1y);
          s2end = new Point(cs2x, cs2y);
          t1s.add(s1end);
          t2s.add(s2end);
          cavalieriHeight += 1;
          if (message == "fall down") {
            cavalieriArea += cavalieriA;
          } else if (message == "fall right") {
            cavalieriArea += cavalieriRightAdd;                            
          } else if (message == "fall left"){
            cavalieriArea += cavalieriLeftAdd; 
          }
        }
      }
    }
  }
  //querySelector("#dartInfo")
  //       ..text = message;
  drawCavalieri();
  fallCounter++;
  // print("s1end=(" + s1end.x.toString() + ", " + s1end.y.toString() + ") and s2end=(" + s2end.x.toString() + ", " + s2end.y.toString() + ")");
  // print("hst=" + hSubTicks.toString() + "; vst=" + vSubTicks.toString() );
  animLoopTimer = new Timer(new Duration(milliseconds: 500), maybeFall);
}

void drawCavalieri() {
//  ticwid = canv.width / hticks;
//   ticht = canv.height / vticks;


  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);

  drawRulers(ctx);
  drawGrid(ctx);
  drawCavalieriPath(ctx);
  drawSweeperCurrentSWEEP(ctx);

 // print("drawCavalieri - " + fallCounter.toString() + " times to fallcounter " );
  if (numDeviceMotionEvents < 2 && fallCounter > 0) {  // TODO figure out why my computer always hits this part (Workaround, to test: Replace with < 20000 and >= 0)
    if (mouseMoveSubscription == null || mouseMoveSubscription.isPaused ) {
      initializeMouseEventListening();
    }
    drawMouseBullseye(ctx);
  }


  drawTools();
}



void drawCavalieriPath(CanvasRenderingContext2D ctxt) {
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";
  ctxt.beginPath();
  Point init = new Point(getXForHSubTick(t1s.first.x), getYForVSubTick(t1s.first.y));
  ctxt.moveTo(init.x, init.y);
  for (int i = 1; i < t1s.length; i++) {
    Point p = new Point(getXForHSubTick(t1s[i].x), getYForVSubTick(t1s[i].y));
    ctxt.lineTo(p.x, p.y);
  }
  for (int j = t2s.length - 1; j >= 0; j--) {
    Point p = new Point(getXForHSubTick(t2s[j].x), getYForVSubTick(t2s[j].y));
    ctxt.lineTo(p.x, p.y);
  }
  ctxt.lineTo(init.x, init.y);
  ctxt.closePath();
  if (!hasCut) {
    ctxt.fill();
  }
  ctxt.stroke();
}





void initializeMouseEventListening() {
  mouseDownSubscription = canv.onMouseDown.listen(getMouseDown);
  mouseUpSubscription = canv.onMouseUp.listen(getMouseUp);
  mouseMoveSubscription = canv.onMouseMove.listen(getMouseMove);
}

void drawMouseBullseye(CanvasRenderingContext2D ctxt) {
  cavClickCenterX = (2 * canv.width / 3).round();
  cavClickCenterY = (canv.height / 3).round();
  ctxt.strokeStyle = "#229";
  ctxt.fillStyle = "rgba(200, 255, 200, 0.6)"; //"#AFA9";
  ctxt.lineWidth = 1;
  ctxt.moveTo(cavClickCenterX, cavClickCenterY);
  ctxt.beginPath();
  ctxt.lineTo(cavClickCenterX - 90 * cos(5 * PI / 4), cavClickCenterY - 90 * sin(5 * PI / 4));
  ctxt.arc(cavClickCenterX, cavClickCenterY, 90, PI / 4, 3 * PI / 4, false);
  ctxt.lineTo(cavClickCenterX - 90 * cos(7 * PI / 4), cavClickCenterY - 90 * sin(7 * PI / 4));
  ctxt.lineTo(cavClickCenterX, cavClickCenterY);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();
  ctxt.fillStyle = "#229";
  ctxt.beginPath();
  ctxt.arc(cavClickCenterX, cavClickCenterY, 15, 0, 2 * PI);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();
  ctxt.moveTo(cavClickCenterX, cavClickCenterY);
  ctxt.beginPath();
  ctxt.lineTo(cavClickCenterX - 60 * cos(5 * PI / 4), cavClickCenterY - 60 * sin(5 * PI / 4));
  ctxt.arc(cavClickCenterX, cavClickCenterY, 60, PI / 4, 3 * PI / 4, false);
  ctxt.lineTo(cavClickCenterX, cavClickCenterY);
  ctxt.closePath();
  ctxt.stroke();

  ctxt.moveTo(cavClickCenterX, cavClickCenterY);
  ctxt.beginPath();
  ctxt.lineTo(cavClickCenterX - 90 * cos(19 * PI / 12), cavClickCenterY - 90 * sin(19 * PI / 12));
  ctxt.lineTo(cavClickCenterX, cavClickCenterY);
  ctxt.lineTo(cavClickCenterX - 90 * cos(17 * PI / 12), cavClickCenterY - 90 * sin(17 * PI / 12));
  ctxt.lineTo(cavClickCenterX, cavClickCenterY);
  ctxt.closePath();
  ctxt.stroke();
  if (cavIsDragging) {
    ctxt.strokeStyle = "rgba(255, 0, 0, 0.7)";
    ctxt.fillStyle = "rgba(255, 0, 0, 0.7)";
    ctxt.lineWidth = 2;
    if (cavArrowDraw == "straight") {
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.beginPath();
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.lineTo(cavClickCenterX, cavClickCenterY + 85);
      ctxt.arc(cavClickCenterX, cavClickCenterY + 85, 5, PI / 2, 5 * PI / 2);
      ctxt.closePath();
      ctxt.fill();
      ctxt.stroke();
    } else if (cavArrowDraw == "left") {
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.beginPath();
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.lineTo(cavClickCenterX - 45, cavClickCenterY + 72);
      ctxt.arc(cavClickCenterX - 45, cavClickCenterY + 72, 5, -PI / 3, 7 * PI / 3);
      ctxt.closePath();
      ctxt.fill();
      ctxt.stroke();
    } else if (cavArrowDraw == "right") {
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.beginPath();
      ctxt.moveTo(cavClickCenterX, cavClickCenterY);
      ctxt.lineTo(cavClickCenterX + 45, cavClickCenterY + 72);
      ctxt.arc(cavClickCenterX + 45, cavClickCenterY + 72, 5, -2 * PI / 3, 9 * PI / 3);
      ctxt.closePath();
      ctxt.fill();
      ctxt.stroke();
    }
    ctxt.lineWidth = 1;
  }
}
