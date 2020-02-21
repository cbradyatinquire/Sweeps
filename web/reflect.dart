part of sweeps;

Point vflips = new Point(hoff - 10, voff);
Point hflips = new Point(hoff, voff - 10);
var flipGrabbed = "none";
var activeDragging = flipGrabbed;

var flipFlavor = "selected";

void setFlipPoints() {
  vflips = new Point(hoff - 20, getYForVSubTick(-1 + vticks.round() * vSubTicks));
  hflips = new Point(getXForHSubTick(-1 + hticks * hSubTicks), voff - 20);
}

//FLIP MODE HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragFLIP(MouseEvent event) {
    clickLogicFLIP(event.offset);
}

void startTouchFLIP(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;

    clickLogicFLIP(initPoint);
}


void flipAlongX(int xc)
{
  //List<Piece> newPcs = new List<Piece>();
  //pieces.forEach((piece) => newPcs.addAll(piece.flipVertical(xc)));
  //pieces = newPcs;
  //flipOverX
}

void flipAlongY(int yc)
{
  //List<Piece> newPcs = new List<Piece>();
  //pieces.forEach((piece) => newPcs.addAll(piece.flipHorizontal(yc)));
  //pieces = newPcs;
  //flipOverY
}


//only will be called outside of rotations
void clickLogicFLIP(Point pt) { // inputted point is where the mouse clicked; logic for mouse DOWN only
  if (flipFlavor == "all") {
    if (!hasFlip) { // logic for the first click only
      hasFlip = true;
      doFlip();
      drawFLIP();
    }
    else { // logic for all times pieces are moving
      drawFLIP();
      dragFirstPieceClickedOn(pt);
    }
  }
  else { // logic for flipting a piece yourself, when flipFlavor == "select" (dragThreshold is the error tolerance for a click)
    if (sqPixelDistance(pt, vflips) < dragThreshold) {
       if ( activeDragging == "none" ) { flipGrabbed = "vertical"; }
       else {activeDragging = "none"; }

      drawFLIP();
    } else if (sqPixelDistance(pt, hflips) < dragThreshold) {
      if ( activeDragging == "none" ) { flipGrabbed = "horizontal"; }
      else {activeDragging = "none"; }

      drawFLIP();
    } else if (pt.y < 50 && pt.x < 50) { // this does not trigger flip yet, only makes screen change color to show it is flipting, flip happens when mouse lifts UP, in either stopTouchFLIP or stopDragFLIP
      flipGrabbed = "scissors";
      drawFLIP();
    } else {
      drawFLIP();
      dragFirstPieceClickedOn(pt);
    }
  }
}









void doFlip() {
  if (flipFlavor == "all") // called only at the beginning for "all"
      {
    for (int yc = 0; yc < vticks * vSubTicks; yc++)
    {
      flipAlongY(yc);
    }
    for (int xc = 0; xc < hticks * hSubTicks; xc++)
    {
      flipAlongX(xc);
    }
  }
  else // if flipting along selected lines
      {
    num cx = getSubTickCoordForPixelH(hflips.x);
    num cy = getSubTickCoordForPixelV(vflips.y);

    flipAlongX(cx);
    flipAlongY(cy);
  }
}


void drawFLIP() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (flipFlavor == "selected") {

    /*if (flipGrabbed == "scissors" ) {
      ctx.drawImageScaled(flipSelectedClosedButton, 0, 0, 58, 58);
      canv.style.backgroundColor = "#aaaacc";
    } else {
      ctx.drawImageScaled(flipSelectedButton, 0, 0, 58, 58);
      canv.style.backgroundColor = "#fff8ff";
    }*/


  }

  drawGridAndRulers(canv);

  drawOriginalPieceFLIP(ctx);
 //print(flipGrabbed);

  /*
  num cx = getSubTickCoordForPixelH(hcuts.x);
    num cy = getSubTickCoordForPixelV(vcuts.y);

    cutAlongX(cx);
    cutAlongY(cy);

   */
  int i = 0;
  //print( flipGrabbed + " " + activeDragging );
  while (i < pieces.length) {
    if (flipGrabbed == "vertical" || activeDragging == "vertical") {
      num cor = getSubTickCoordForPixelV(vflips.y);
      pieces.forEach((piece) => piece.drawFlipped(ctx, "vertical", cor));
    }
    if (flipGrabbed == "horizontal" || activeDragging == "horizontal") {
      num cor = getSubTickCoordForPixelH(hflips.x);
      pieces.forEach((piece) => piece.drawFlipped(ctx, "horizontal", cor));
    }
    i++;
  }

  /*if (wasInCavalieri) { drawCavalieriPath(ctx); }
  else { drawSweeperSweptSWEEP(ctx); }*/

  //if (hasFlip) { pieces.forEach((piece) => piece.draw(ctx)); }

  /*
  if (doingRotation && indexSelectedForRotation != -1) {

    bool allowed = pieces[indexSelectedForRotation].possibleCenter(currentPossibleCenter, vticks * vSubTicks, hticks * hSubTicks);

    drawRotationCenter(ctx);
    //drawRotationConnection(shapeRotationPoint, currentPossibleCenter, allowed);
    pieces[indexSelectedForRotation].drawRotatedCopiesEveryNDegrees(ctx, currentPossibleCenter, 45, allowed);

    pieces[indexSelectedForRotation].rotate180Degrees(currentPossibleCenter).drawInsubstantialForRotate(ctx, allowed);


    pieces[indexSelectedForRotation].drawAsDragging(ctx);
  }
  */

  if (hasFlip) {
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


void touchDragFLIP(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;
  if (draggingPiece != null) {
    draggingFLIP(currPoint);
  } else if ( flipGrabbed != "none"   ) {
    dragFlipHotSpots( currPoint );
  }
}

void mouseDragFLIP(MouseEvent event) {
  //print("got to flip mouse");
  if (draggingPiece != null) {
    draggingFLIP(event.offset);
  } else if ( flipGrabbed != "none"  ) {
    dragFlipHotSpots( event.offset );
  }
}


void dragFlipHotSpots( Point currentPt ) {
  //print("dragging " + flipGrabbed );
  if (flipGrabbed == "horizontal") {
    hflips = new Point(  getXForHSubTick( getSubTickCoordForPixelH(currentPt.x) )  , hflips.y);
  } else if ( flipGrabbed == "vertical") {
    vflips = new Point( vflips.x,  getYForVSubTick( getSubTickCoordForPixelV(currentPt.y) ) );
  }
  drawFLIP();
}

void draggingFLIP(Point currentPt) {

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

  drawFLIP();
  CanvasRenderingContext2D ctx = canv.context2D;
  draggingPiece.drawAsDragging(ctx);
  // draggingPiece.vertices.forEach((vertex) => print("  ]--> " + getXForHSubTick(vertex.x).toString() + ", " + getYForVSubTick(vertex.y).toString() ) );

}



void stopDragFLIP(MouseEvent event) {
  //draggingPiece = null;
  //print(draggingPiece);
  if (flipGrabbed == "scissors") {
    doFlip(); // triggers flip when flipFlavor == "select"
  }

  if (draggingPiece == null ) {
    activeDragging = flipGrabbed;
    flipGrabbed = "none"; } // resets flipGrabbed (from where it was set in clickLogicFlip)
  else {
    print("would do the flip for the dragging piece NOW");
    doTheActualFlip();
  }
  draggingPiece = null;

  drawFLIP();
}

void stopTouchFLIP(TouchEvent evt) {
  //draggingPiece = null;
  if (flipGrabbed == "scissors") {
    doFlip(); // triggers flip when flipFlavor == "select"
  }
  //activeDragging = flipGrabbed;
  if (draggingPiece == null ) {
    activeDragging = flipGrabbed;
    flipGrabbed = "none"; } // resets flipGrabbed (from where it was set in clickLogicFlip)
  else {
    print("would do the flip for the dragging piece NOW");
    doTheActualFlip();
  }
  draggingPiece = null;

  drawFLIP();

}


void doTheActualFlip() {
  int i = 0;
  //print( flipGrabbed + " " + activeDragging );
  while (i < pieces.length) {
    print("TAAAAADAAAA");
    if (pieces[i] == draggingPiece) {
      if (flipGrabbed == "vertical" || activeDragging == "vertical") {
        num cor = getSubTickCoordForPixelV(vflips.y);
        pieces[i].actuallyFlip("vertical", cor);
      }
      if (flipGrabbed == "horizontal" || activeDragging == "horizontal") {
        num cor = getSubTickCoordForPixelH(hflips.x);
        pieces[i].actuallyFlip("horizontal", cor);
      }
    }
    i++;
  }
  drawFLIP();

}

void drawOutlineFLIP(CanvasRenderingContext2D ctxt, Piece piece) {
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
  if (!hasFlip) {
    ctxt.fill();
  }
  ctxt.stroke();
}

drawOriginalPieceFLIP(CanvasRenderingContext2D ctxt) {
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";
  ctxt.beginPath();
  originalPieces.forEach((piece) => drawOutlineFLIP(ctxt, piece));

  if (MODEAfterSetup != 7 && MODEAfterSetup != 5 && !wasInCavalieri) { // if it came from the sweeper
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