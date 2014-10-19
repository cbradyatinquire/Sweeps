part of sweeps;


//CUT MODE HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragCUT(MouseEvent event) {
  clickLogicCUT(event.offset);
}

void startTouchCUT(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  clickLogicCUT(initPoint);
}

void clickLogicCUT(Point pt) {
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
}

void doCut() {
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
  if (draggingPiece != null) {
    Point currPoint = evt.changedTouches[0].client;
    draggingCUT(currPoint);
  }
}

void mouseDragCUT(MouseEvent event) {
  if (draggingPiece != null) {
    draggingCUT(event.offset);
  }
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
  drawCUT();
}

void stopTouchCUT(TouchEvent evt) {
  draggingPiece = null;
  drawCUT();
}
