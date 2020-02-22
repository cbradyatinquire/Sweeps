part of sweeps;

bool rotationInProgress = false;
var cutFlavor = "all";
Point vcuts = new Point(hoff - 10, voff);
Point hcuts = new Point(hoff, voff - 10);
var cutGrabbed = "none";

var flipGrabbed = "none";
var activeDragging = "none";

// for rotation animations
int numSubdivisions = 30;
int numIterations = 0;
Point currentCenter = null;
Point currentPossibleCenter = null; // in canvas coordinates
Point shapeRotationPoint = null;
int radiusOfRotationPoints = 5;
Piece rotatedPiece = null;
bool rotationAllowed = false;

void setCutPoints() {
  vcuts = new Point(hoff - 20, getYForVSubTick(-1 + vticks.round() * vSubTicks));
  hcuts = new Point(getXForHSubTick(-1 + hticks * hSubTicks), voff - 20);
}

//CUT MODE HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragCUT(MouseEvent event) {
  if (!doingRotation) {
    clickLogicCUT(event.offset);
  }
  else {
    clickLogicROTATE(event.offset, true);
  }
}

void startTouchCUT(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;

  if (!doingRotation) {
    clickLogicCUT(initPoint);
  }
  else {
    clickLogicROTATE(initPoint, false);
  }
}


void cutAlongX(int xc)
{
  List<Piece> newPcs = new List<Piece>();
  pieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xc)));
  pieces = newPcs;
}

void cutAlongY(int yc)
{
  List<Piece> newPcs = new List<Piece>();
  pieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
  pieces = newPcs;
}

void dragFirstPieceClickedOn(Point pt)
{
  for (Piece test in pieces)
  {
    num gridX = getGridCoordForPixelH(pt.x);
    num gridY = getGridCoordForPixelV(pt.y);

    if (test.containsGridPoint(gridX, gridY)) // if test is the piece clicked on
        {
      draggingPiece = test;
      pieceDragOrigin = pt;
      break;
    }
  }

  if (draggingPiece != null) {
    CanvasRenderingContext2D ctx = canv.context2D;
    draggingPiece.drawAsDragging(ctx);
  }
}

//only will be called outside of rotations
void clickLogicCUT(Point pt) { // inputted point is where the mouse clicked; logic for mouse DOWN only
  if (cutFlavor == "all") {
    if (!hasCut) { // logic for the first click only
      hasCut = true;
      doCut();
      drawCUT();
    }
    else { // logic for all times pieces are moving
      drawCUT();
      dragFirstPieceClickedOn(pt);
    }
  }
  else { // logic for cutting a piece yourself, when cutFlavor == "select" (dragThreshold is the error tolerance for a click)
    if (sqPixelDistance(pt, vcuts) < dragThreshold) {
      cutGrabbed = "vertical";
      drawCUT();
    } else if (sqPixelDistance(pt, hcuts) < dragThreshold) {
      cutGrabbed = "horizontal";
      drawCUT();
    } else if (pt.y < 50 && pt.x < 50 && !doingReflection) { // this does not trigger cut yet, only makes screen change color to show it is cutting, cut happens when mouse lifts UP, in either stopTouchCUT or stopDragCUT
      cutGrabbed = "scissors";
      drawCUT();
    } else {
      drawCUT();
      dragFirstPieceClickedOn(pt);
    }
  }
}

void drawRotationConnection(Point shapePoint, Point rotationPoint, bool allowed) {

  CanvasRenderingContext2D ctxt = canv.context2D;

  if (allowed) {
    ctxt.strokeStyle = "rgba(0, 255, 0, 0.8)";
    ctxt.fillStyle = "rgba(0, 255, 0, .2)";
  }
  else {
    ctxt.strokeStyle = "rgba(255, 0, 0, 0.8)";
    ctxt.fillStyle = "rgba(255, 0, 0, .2)";
  }

  num centerx = getXForHSubTick(rotationPoint.x);
  num centery = getYForVSubTick(rotationPoint.y);

  num dispx = getXForHSubTick(shapePoint.x) - centerx;
  num dispy = getYForVSubTick(shapePoint.y) - centery;
  ctxt.moveTo(dispx + centerx, dispy + centery);
  ctxt.lineTo(centerx, centery);
  ctxt.stroke();

  if (indexSelectedForRotation != -1) // shouldn't be, but just checking to be safe
      {
    pieces[indexSelectedForRotation].rotate180Degrees(rotationPoint).drawInsubstantialForRotate(ctxt, allowed);
  }

  num length = sqrt( dispx * dispx + dispy * dispy );

  // want to rotate by 15 degrees and make a new line that's somewhat more transparent
  num disp2x = length * ( (dispx / length) * cos(15 * 2 * PI / 360 ) - (dispy / length) * sin(15 * 2 * PI / 360));
  num disp2y = length * ( (dispx / length) * sin(15 * 2 * PI / 360 ) + (dispy / length) * cos(15 * 2 * PI / 360));

  if (allowed) {
    ctxt.strokeStyle = "rgba(0, 255, 0, 0.6)";
  }
  else {
    ctxt.strokeStyle = "rgba(255, 0, 0, 0.6)";
  }

  ctxt.moveTo(disp2x + centerx, disp2y + centery);
  ctxt.lineTo(centerx, centery);
  ctxt.stroke();

  // repeating this:
  num disp3x = length * ((disp2x / length) * cos(15 * 2 * PI / 360 ) - (disp2y / length) * sin(15 * 2 * PI / 360));
  num disp3y = length * ((disp2x / length) * sin(15 * 2 * PI / 360 ) + (disp2y / length) * cos(15 * 2 * PI / 360));

  if (allowed) {
    ctxt.strokeStyle = "rgba(0, 255, 0, 0.4)";
  }
  else {
    ctxt.strokeStyle = "rgba(255, 0, 0, 0.4)";
  }

  ctxt.moveTo(disp3x + centerx, disp3y + centery);
  ctxt.lineTo(centerx, centery);
  ctxt.stroke();

  // and again:
  num disp4x = length * ((disp3x / length) * cos(15 * 2 * PI / 360 ) - (disp3y / length) * sin(15 * 2 * PI / 360));
  num disp4y = length * ((disp3x / length) * sin(15 * 2 * PI / 360 ) + (disp3y / length) * cos(15 * 2 * PI / 360));

  if (allowed) {
    ctxt.strokeStyle = "rgba(0, 255, 0, 0.2)";
  }
  else {
    ctxt.strokeStyle = "rgba(255, 0, 0, 0.2)";
  }

  ctxt.moveTo(disp4x + centerx, disp4y + centery);
  ctxt.lineTo(centerx, centery);
  ctxt.stroke();


  //drawing an arrow
  if (allowed) {
    ctxt.strokeStyle = "rgba(0, 255, 0, 1)";
    ctxt.fillStyle = "rgba(0, 255, 0, .1)";
  }
  else {
    ctxt.strokeStyle = "rgba(255, 0, 0, 1)";
    ctxt.fillStyle = "rgba(255, 0, 0, .1)";
  }

  ctxt.moveTo(centerx + (disp3x / 3), centery + (disp3y / 3));
  ctxt.lineTo(centerx + (disp4x / 2), centery + (disp4y / 2));
  ctxt.lineTo(centerx + (2 * disp3x / 3), centery + (2 * disp3y / 3));
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();

  num angle;

  if (dispy > 0) {
    angle = acos(dispx / length);
  }
  else {
    angle = 2 * PI - acos(dispx / length);
  }

  ctxt.moveTo(centerx + (dispx / 2), centery + (dispy / 2));
  ctxt.arc(centerx, centery, length/2, angle, angle + (2 * PI / 360 * (15 * 3)));
  ctxt.stroke();

  //TODO draw arc showing rotation direction

}




void clickLogicROTATE(Point pt, bool isMouse) {
  if (indexSelectedForRotation == -1) { // haven't selected a piece yet
    num i = getFirstIndex(pt);
    if (i == -1) {
      doingRotation = false;
    }
    else {
      indexSelectedForRotation = i;
      currentPossibleCenter = new Point( 0.5 * (2.0 * getGridCoordForPixelH(pt.x)).round(), 0.5 * (2.0 * getGridCoordForPixelV(pt.y)).round());
      shapeRotationPoint = new Point( 0.5 * (2.0 * getGridCoordForPixelH(pt.x)).round(), 0.5 * (2.0 * getGridCoordForPixelV(pt.y)).round());
      CUTMouseGetRotationPoint.resume();
      CUTTouchGetRotationPoint.resume();
    }
  }
  else if (isMouse && !rotationInProgress) {
    Point p = new Point( 0.5 * (2.0 * getGridCoordForPixelH(pt.x)).round(), 0.5 * (2.0 * getGridCoordForPixelV(pt.y)).round());
    rotationInProgress = true;
    rotatePiece(p);
    CUTMouseGetRotationPoint.pause();
    CUTTouchGetRotationPoint.pause();
  }
}




num getFirstIndex(Point pt) {
  num i = 0;

  while (i < pieces.length) {
    num gridX = getGridCoordForPixelH(pt.x);
    num gridY = getGridCoordForPixelV(pt.y);

    if (pieces[i].containsGridPoint(gridX, gridY))
      return i;

    i++;
  }

  return -1; // if has clicked on no piece
}



void doCut() {
  if (cutFlavor == "all") // called only at the beginning for "all"
  {
    for (int yc = 0; yc < vticks * vSubTicks; yc++)
    {
      cutAlongY(yc);
    }
    for (int xc = 0; xc < hticks * hSubTicks; xc++)
    {
      cutAlongX(xc);
    }
  }
  else // if cutting along selected lines
  {
    num cx = getSubTickCoordForPixelH(hcuts.x);
    num cy = getSubTickCoordForPixelV(vcuts.y);

    cutAlongX(cx);
    cutAlongY(cy);
  }
}


void drawCUT() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (cutFlavor == "selected") {
    if (cutGrabbed == "scissors" ) {
      ctx.drawImageScaled(cutSelectedClosedButton, 0, 0, 58, 58);
      canv.style.backgroundColor = "#aaaacc";
    } else {
      ctx.drawImageScaled(cutSelectedButton, 0, 0, 58, 58);
      canv.style.backgroundColor = "#fff8ff";
    }
    
  }

  drawGridAndRulers(canv);

  drawOriginalPieceCUT(ctx);
  /*if (wasInCavalieri) { drawCavalieriPath(ctx); }
  else { drawSweeperSweptSWEEP(ctx); }*/

  //if (hasCut) { pieces.forEach((piece) => piece.draw(ctx)); }

  if (doingRotation && indexSelectedForRotation != -1) {

    bool allowed = pieces[indexSelectedForRotation].possibleCenter(currentPossibleCenter, vticks * vSubTicks, hticks * hSubTicks);

    drawRotationCenter(ctx);
    //drawRotationConnection(shapeRotationPoint, currentPossibleCenter, allowed);
    pieces[indexSelectedForRotation].drawRotatedCopiesEveryNDegrees(ctx, currentPossibleCenter, 45, allowed);

    pieces[indexSelectedForRotation].rotate180Degrees(currentPossibleCenter).drawInsubstantialForRotate(ctx, allowed);


    pieces[indexSelectedForRotation].drawAsDragging(ctx);
  }

  if (hasCut) {
    int i = 0;
    while (i < pieces.length) {
      if (i != indexSelectedForRotation) {
        pieces[i].draw(ctx);
      }
      i++;
    }
  }



  drawTools();

  //for testing
  //print("Drawing Grid");
  // drawPointGrid(ctx); 
}

void touchGetRotationPoint(TouchEvent e) {
  if (e.touches.length > 0) {
    Point pt = e.touches[e.touches.length - 1].client;

    currentPossibleCenter = new Point(
        0.5 * (2.0 * getGridCoordForPixelH(pt.x)).round(),
        0.5 * (2.0 * getGridCoordForPixelV(pt.y)).round());

    drawCUT();
  }
}

void mouseGetRotationPoint(MouseEvent e) {
  Point pt = e.client;
  currentPossibleCenter = new Point(
      0.5 * (2.0 * getGridCoordForPixelH(pt.x)).round(),
      0.5 * (2.0 * getGridCoordForPixelV(pt.y)).round());


  drawCUT();

}

void drawRotationCenter(CanvasRenderingContext2D ctx) {
  Point p = new Point(getXForHSubTick(currentPossibleCenter.x), getYForVSubTick(currentPossibleCenter.y));
  if (pieces[indexSelectedForRotation].possibleCenter(currentPossibleCenter, vticks * vSubTicks, hticks * hSubTicks)) {
    drawPoint(ctx, p, "#222", radiusOfRotationPoints);
  }
  else {
    drawPoint(ctx, p, "#999", radiusOfRotationPoints);
  }
}

void drawPointGrid(CanvasRenderingContext2D ctx) {
  for (num x = 0; x<(hticks*hSubTicks); x=x+.2) {
    for (num y = 0; y<(vticks*vSubTicks); y=y+.2) {
      bool inside = false;
      for (Piece p in pieces ) {
        if (p.containsGridPoint(x+.1, y+.1)) {
          inside = true;
        }
      }
      if (inside) {
        ctx.fillStyle="#F00";
        ctx.strokeStyle ="#F00";
      } else {
        ctx.fillStyle="#00F";
        ctx.strokeStyle="#00F";
      }
      ctx.beginPath();
      ctx.arc(getXForHSubTick(x + .1), getYForVSubTick(y + .1), 2, 0, 2*PI);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      
    }
  }
  
}


void touchDragCUT(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;
  if (draggingPiece != null) {
    draggingCUT(currPoint);
  } else if ( cutGrabbed != "none") {
    dragCutHotSpots( currPoint );
  }
}

void mouseDragCUT(MouseEvent event) {
  if (draggingPiece != null) {
    draggingCUT(event.offset);
  } else if ( cutGrabbed != "none") {
    dragCutHotSpots( event.offset );
  }
}


void dragCutHotSpots( Point currentPt ) {
  //print("dragging " + cutGrabbed );
  if (cutGrabbed == "horizontal") {
    hcuts = new Point(  getXForHSubTick( getSubTickCoordForPixelH(currentPt.x) )  , hcuts.y);
  } else if ( cutGrabbed == "vertical") {
    vcuts = new Point( vcuts.x,  getYForVSubTick( getSubTickCoordForPixelV(currentPt.y) ) );
  }
  drawCUT();
}

void draggingCUT(Point currentPt) {

    if (draggingPiece == null) {
      print("null dragging piece?!");
      return;
    }
    num dx = currentPt.x - pieceDragOrigin.x;
    num dy = currentPt.y - pieceDragOrigin.y;
    // print("DX=" + dx.toString() + "; DY=" + dy.toString() + "; originx=" + pieceDragOrigin.x.toString() + "originy="+pieceDragOrigin.y.toString());
    num wantToDragUnitsX = (hSubTicks * (dx / ticwid)).round();
    num wantToDragUnitsY = (vSubTicks * (dy / ticht)).round();
  
    num delx = wantToDragUnitsX; //need to prevent dragging off screen
    num dely = wantToDragUnitsY; //need to prevent dragging off screen
    
    //prevent dragging offscreen
    if (draggingPiece.xmin + delx < 0) { delx = 0; }
    if (draggingPiece.xmax + delx > hticks * hSubTicks) { delx = 0; }
    if (draggingPiece.ymin + dely < 0 ) { dely = 0; }
    if (draggingPiece.ymax + dely > vticks * vSubTicks) { dely = 0; }

    if (delx.abs() + dely.abs() > 0) {
      pieceDragOrigin = new Point(pieceDragOrigin.x + (delx * ticwid / hSubTicks), pieceDragOrigin.y + (dely * ticht / vSubTicks));
      //print("before shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
      draggingPiece.shiftBy(delx, dely);
      //print("after shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
    }
  
    drawCUT();
    CanvasRenderingContext2D ctx = canv.context2D;
    draggingPiece.drawAsDragging(ctx);
   // draggingPiece.vertices.forEach((vertex) => print("  ]--> " + getXForHSubTick(vertex.x).toString() + ", " + getYForVSubTick(vertex.y).toString() ) );
  
}



void stopDragCUT(MouseEvent event) {
  draggingPiece = null;
  if (cutGrabbed == "scissors") {
    doCut(); // triggers cut when cutFlavor == "select"
  }
  cutGrabbed = "none";  // resets cutGrabbed (from where it was set in clickLogicCut)
  drawCUT();
}

void stopTouchCUT(TouchEvent evt) {
  draggingPiece = null;
  if (cutGrabbed == "scissors") {
    doCut(); // triggers cut when cutFlavor == "select"
  }
  cutGrabbed = "none"; // resets cutGrabbed (from where it was set in clickLogicCut)
  drawCUT();

  if (indexSelectedForRotation != -1){
    rotationInProgress = true;
    rotatePiece(currentPossibleCenter);
    CUTMouseGetRotationPoint.pause();
    CUTTouchGetRotationPoint.pause();
  }
}


void drawOutlineCUT(CanvasRenderingContext2D ctxt, Piece piece) {
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";
  ctxt.beginPath();

  List<Point> vertices = piece.vertices;

  Point init = new Point(getXForHSubTick(vertices.first.x), getYForVSubTick(vertices.first.y));
  ctxt.moveTo(init.x, init.y);
  for (int i = 1; i < vertices.length; i++) {
    Point p = new Point(getXForHSubTick(vertices[i].x), getYForVSubTick(vertices[i].y));
    ctxt.lineTo(p.x, p.y);
  }
  ctxt.lineTo(init.x, init.y);
  ctxt.closePath();
  if (!hasCut) {
    ctxt.fill();
  }
  ctxt.stroke();
}

drawOriginalPieceCUT(CanvasRenderingContext2D ctxt) {
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";
  ctxt.beginPath();
  originalPieces.forEach((piece) => drawOutlineCUT(ctxt, piece));

  if (MODEAfterSetup != 3 && MODEAfterSetup != 5 && !wasInCavalieri) { // if it came from the sweeper
    List x = originalPieces[0].vertices;


    int indexOfTop = 0;
    int i = 0;
    num errorTol = .1;
    while (i < x.length) {
      if (x[i].y < x[indexOfTop].y + errorTol) {
        indexOfTop = i;
      }
      i++;
    }

    Point BottomLeft, TopLeft, TopRight;

    if (x[((indexOfTop + 1) % 4)].y <
        x[indexOfTop].y + errorTol) { // these are the top two
      if (x[((indexOfTop + 1) % 4)].x <
          x[indexOfTop].x) { // top left & right points respectively
        BottomLeft = x[((indexOfTop + 2) % 4)];
        TopLeft = x[((indexOfTop + 1) % 4)];
        TopRight = x[indexOfTop];
      }
      else { // top right and left points respectively
        BottomLeft = x[((indexOfTop - 1) % 4)];
        TopLeft = x[indexOfTop];
        TopRight = x[((indexOfTop + 1) % 4)];
      }
    }

    if (x[((indexOfTop - 1) % 4)].y <
        x[indexOfTop].y + errorTol) { // these are the top two
      if (x[((indexOfTop - 1) % 4)].x <
          x[indexOfTop].x) { // top left & right points respectively
        BottomLeft = x[((indexOfTop - 2) % 4)];
        TopLeft = x[((indexOfTop - 1) % 4)];
        TopRight = x[indexOfTop];
      }
      else { // top right and left points respectively
        BottomLeft = x[((indexOfTop + 1) % 4)];
        TopLeft = x[indexOfTop];
        TopRight = x[((indexOfTop - 1) % 4)];
      }
    }

    // Then the drag must have been vertical
    if ((x[((indexOfTop + 1) % 4)].x - x[indexOfTop].x).abs() <
        errorTol) { // these are one vertical side
      if (x[((indexOfTop - 1) % 4)].x <
          x[indexOfTop].x) { // top left & right points respectively
        BottomLeft = x[((indexOfTop - 2) % 4)];
        TopLeft = x[((indexOfTop - 1) % 4)];
        TopRight = x[indexOfTop];
      }
      else { // top right and left points respectively
        BottomLeft = x[((indexOfTop + 1) % 4)];
        TopLeft = x[indexOfTop];
        TopRight = x[((indexOfTop - 1) % 4)];
      }
    }
    if ((x[((indexOfTop - 1) % 4)].x - x[indexOfTop].x).abs() <
        errorTol) { // these are one vertical side
      if (x[((indexOfTop + 1) % 4)].x <
          x[indexOfTop].x) { // top left & right points respectively
        BottomLeft = x[((indexOfTop + 2) % 4)];
        TopLeft = x[((indexOfTop + 1) % 4)];
        TopRight = x[indexOfTop];
      }
      else { // top right and left points respectively
        BottomLeft = x[((indexOfTop - 1) % 4)];
        TopLeft = x[indexOfTop];
        TopRight = x[((indexOfTop + 1) % 4)];
      }
    }

    drawRulerMarkings(convertFromTickCoordinates(BottomLeft), convertFromTickCoordinates(TopLeft), convertFromTickCoordinates(TopRight), ctxt);
  }
}


void drawRotateCUT() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);

  drawGridAndRulers(canv);

  drawOriginalPieceCUT(ctx);

  pieces.forEach((piece) => piece.draw(ctx));
  pieces[indexSelectedForRotation].drawAsDragging(ctx);

  drawTools();
  drawPoint(ctx, new Point(getXForHSubTick(currentCenter.x), getYForVSubTick(currentCenter.y)), "#4C4", radiusOfRotationPoints);
}

void rotationAnimation(Timer t) {
  numIterations++;
  pieces[indexSelectedForRotation].rotateCounterclockwiseBy(PI * 1 / numSubdivisions, currentCenter);
  drawRotateCUT();

  if (numIterations >= numSubdivisions) {
    t.cancel();
    pieces[indexSelectedForRotation] = rotatedPiece;
    drawCUT();

    numIterations = 0;
    rotatedPiece = null;
    currentCenter = null;
    indexSelectedForRotation = -1;
    doingRotation = false;
    rotationInProgress = false;
    drawCUT();
  }
}


startRotationAnimation(int msec){
  return new Timer.periodic( new Duration(milliseconds: msec), rotationAnimation);
}

void rotatePiece(Point center) {
  if (pieces[indexSelectedForRotation].possibleCenter(center, vticks * vSubTicks, hticks * hSubTicks)) {
    currentCenter = center;
    rotatedPiece = pieces[indexSelectedForRotation].rotate180Degrees(currentCenter);
    startRotationAnimation(10);
  }
  else {
    rotationInProgress = false;
    doingRotation = false;
    drawCUT();
    indexSelectedForRotation = -1;
    currentPossibleCenter = null;
  }
}

//(old method for finding a good-enough rotation center
// need a point that is on the lattice grid; otherwise it will make
// lattice points stop being lattice points, which is confusing/frustrating
Point getRotationCenter(Piece p)
{
  num worldX = hticks * hSubTicks;
  num worldY = vticks * vSubTicks;

  Point v = new Point(p.xmin, p.ymin);
  if (p.possibleCenter(v, worldY, worldX))
    return v;

  v = new Point(p.xmin, p.ymax);
  if (p.possibleCenter(v, worldY, worldX))
    return v;

  v = new Point(p.xmax, p.ymin);
  if (p.possibleCenter(v, worldY, worldX))
    return v;

  v = new Point(p.xmax, p.ymax);
  if (p.possibleCenter(v, worldY, worldX))
    return v;

  return null;
}