part of sweeps;


var cutFlavor = "all";
Point vcuts = new Point(hoff - 10, voff);
Point hcuts = new Point(hoff, voff - 10);
var cutGrabbed = "none";

/*
 * if (sqPixelDistance(initPoint, vhots) < dragThreshold) {
    grabbed = "vertical";
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSETUP();
  } else if (sqPixelDistance(initPoint, hhots) < dragThreshold) {
    grabbed = "horizontal";
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSETUP();
//  } else if (sqPixelDistance(initPoint, new Point(getXForHTick(s1end.x), getYForVTick(s1end.y))) < dragThreshold) {
  }
 */

void setDummyCutPoints() {
  vcuts = new Point( hoff-10, getYForVSubTick( 4) );
  hcuts = new Point( getXForHSubTick(3), voff-10 );
}

//CUT MODE HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragCUT(MouseEvent event) {
  clickLogicCUT(event.offset);
}

void startTouchCUT(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  clickLogicCUT(initPoint);
}

void clickLogicCUT(Point pt) {
  if ( cutFlavor == "all" ) {
    if (!hasCut) {
      hasCut = true;
      doCut();
      drawCUT();
    } else {
      drawCUT();
      for (int i = 0; i < pieces.length; i++) {
        Piece test = pieces[i];
        if (test.hitTest(pt)) {
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
  } else {
    print("got to selected cut mode");
    print(sqPixelDistance(pt, vcuts));
    if (sqPixelDistance(pt, vcuts) < dragThreshold) {
      cutGrabbed = "vertical";
      drawCUT();
    } else if (sqPixelDistance(pt, hcuts) < dragThreshold) {
      cutGrabbed = "horizontal";
      drawCUT();
    } else if (pt.y < 50 && pt.x < 50 ) {
      print("would actually cut");
      doCut();
      drawCUT();
      hasCut = true;  //TODO: make sure that this was needed
    } else {
      drawCUT();
      for (int i = 0; i < pieces.length; i++) {
        Piece test = pieces[i];
        if (test.hitTest(pt)) {
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
  }
}

void doCut() {
  
  if (cutFlavor == "all") {
  for (int xc = 0; xc < hticks * hSubTicks; xc++) {
    List<Piece> newPcs = new List<Piece>();
    pieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xc)));
    pieces = newPcs;
  }

// print(pieces.length.toString() + " PIECES. with vertices...");
// pieces.forEach( (piece) => print( piece.vertices.length.toString() + piece.verticesAsString() ) );

  for (int yc = 0; yc < vticks * vSubTicks; yc++) {
    List<Piece> newPcs = new List<Piece>();
    pieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
    pieces = newPcs;
  }

//  print(pieces.length.toString() + " PIECES. with vertices...");
//  pieces.forEach( (piece) => print( piece.vertices.length.toString() + piece.verticesAsString() ) );
  } else {
    print("actually cut in selected flavor");
    num cx = getSubTickCoordForPixelH(hcuts.x);
    num cy = getSubTickCoordForPixelV(vcuts.y);
    List<Piece> newPcs = new List<Piece>();
    pieces.forEach( (piece) => newPcs.addAll(piece.cutVertical(cx)) );
    pieces = newPcs;
    List<Piece> newPcsH = new List<Piece>();
    pieces.forEach( (piece) => newPcsH.addAll(piece.cutHorizontal(cy)) );
    pieces = newPcsH;
  }
}


void drawCUT() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (hasCut) {
    drawRulers(ctx);
    drawSweeperSweptSWEEP(ctx);
    pieces.forEach((piece) => piece.draw(ctx));
    drawGrid(ctx);
    drawTools();
  } else {
    drawRulers(ctx);
    drawGrid(ctx);
    drawSweeperSweptSWEEP(ctx);
    drawTools();
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
  print("dragging " + cutGrabbed );
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
    //print("DelX=" + delx.toString() + "; DelY=" + dely.toString() );
    num neworiginx = pieceDragOrigin.x;
    num neworiginy = pieceDragOrigin.y;
    if (delx.abs() > 0) {
      neworiginx = currentPt.x;
    }
    if (dely.abs() > 0) {
      neworiginy = currentPt.y;
    }
    if (delx.abs() + dely.abs() > 0) {
      pieceDragOrigin = new Point(pieceDragOrigin.x + (delx * ticwid / hSubTicks), pieceDragOrigin.y + (dely * ticht / vSubTicks));
      //print("before shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
      draggingPiece.shiftBy(delx, dely);
      //print("after shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
    }
  
    drawCUT();
    CanvasRenderingContext2D ctx = canv.context2D;
    draggingPiece.drawAsDragging(ctx);
    
  
}



void stopDragCUT(MouseEvent event) {
  draggingPiece = null;
  cutGrabbed = "none";
  drawCUT();
}

void stopTouchCUT(TouchEvent evt) {
  draggingPiece = null;
  cutGrabbed = "none";
  drawCUT();
}
