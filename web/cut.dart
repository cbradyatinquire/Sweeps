part of sweeps;


var cutFlavor = "all";
Point vcuts = new Point(hoff - 10, voff);
Point hcuts = new Point(hoff, voff - 10);
var cutGrabbed = "none";

// for rotation animations
int numSubdivisions = 30;
int numIterations = 0;
Point currentCenter = null;
int currentIndex = null;
Piece rotatedPiece = null;

void setCutPoints() {
  vcuts = new Point(hoff - 20, getYForVSubTick(-1 + vticks * vSubTicks));
  hcuts = new Point(getXForHSubTick(-1 + hticks * hSubTicks), voff - 20);
}

//CUT MODE HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragCUT(MouseEvent event) {
  clickLogicCUT(event.offset);
}

void startTouchCUT(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  clickLogicCUT(initPoint);
}


void cutAlongX(int xc)
{
  List<Piece> newPcs = new List<Piece>();

  if (wasInCavalieri) // Cavalieri allows for convexity on the vertical sides, but is more complex
  {
    pieces.forEach((piece) => newPcs.addAll(piece.cutVerticalCavalieri(xc)));
  }
  else
  {
    pieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xc)));
  }

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
    } else if (pt.y < 50 && pt.x < 50) { // this does not trigger cut yet, only makes screen change color to show it is cutting, cut happens when mouse lifts UP, in either stopTouchCUT or stopDragCUT
      cutGrabbed = "scissors";
      drawCUT();
    } else {
      drawCUT();
      dragFirstPieceClickedOn(pt);
    }
  }
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

  drawRulers(ctx);
  drawGrid(ctx);

  if (wasInCavalieri) { drawCavalieriPath(ctx); }
  else { drawSweeperSweptSWEEP(ctx); }

  if (hasCut) { pieces.forEach((piece) => piece.draw(ctx)); }

  drawTools();

  //for testing
  //print("Drawing Grid");
  // drawPointGrid(ctx); 
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
}

void drawRotateCUT() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);

  drawRulers(ctx);
  drawGrid(ctx);

  if (wasInCavalieri) { drawCavalieriPath(ctx); }
  else { drawSweeperSweptSWEEP(ctx); }

  pieces.forEach((piece) => piece.draw(ctx));


  drawTools();
  // TODO: draw the center of the rotation
}

void rotationAnimation(Timer t){
  numIterations++;
  pieces[currentIndex].rotateCounterclockwiseBy(PI * 1 / numSubdivisions, currentCenter);

  drawRotateCUT();
  if (numIterations >= numSubdivisions)
    {
      t.cancel();
      pieces[currentIndex] = rotatedPiece;
      drawCUT();

      numIterations = 0;
      rotatedPiece = null;
      currentCenter = null;
      currentIndex = null;
    }
}

startRotationAnimation(int msec){
  return new Timer.periodic( new Duration(milliseconds: msec), rotationAnimation);
}

void rotatePiece(int index) {
  Point center = getRotationCenter(pieces[index]);

  if (center != null) {
    currentCenter = center;
    currentIndex = index;
    rotatedPiece = pieces[index].rotate180Degrees(currentCenter);
    // TODO: figure out what went wrong before; letting piece = pieces[index] and changing piece was changing the list pieces.

    startRotationAnimation(10);
  }
}

// TODO: get a better center point system later
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