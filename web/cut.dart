part of sweeps;


var cutFlavor = "all";
Point vcuts = new Point(hoff - 10, voff);
Point hcuts = new Point(hoff, voff - 10);
var cutGrabbed = "none";

void setCutPoints() {
  vcuts = new Point( hoff-20, getYForVSubTick( -1 + vticks * vSubTicks ) );
  hcuts = new Point( getXForHSubTick( -1 + hticks * hSubTicks ), voff-20 );
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
      
      if (wasInCavalieri) { doCut(); } 
      else {doCut();}
      
      drawCUT();
    } else {
      drawCUT();
      for (int i = 0; i < pieces.length; i++) {
        Piece test = pieces[i];
        /*if (test.hitTest(pt)) {
          draggingPiece = test;
          pieceDragOrigin = pt;
          break;
        }*/
        num gridX = getGridCoordForPixelH(pt.x);
        num gridY = getGridCoordForPixelV(pt.y);
        if ( test.containsGridPoint( gridX, gridY ) ) {
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
    if (sqPixelDistance(pt, vcuts) < dragThreshold) {
      cutGrabbed = "vertical";
      drawCUT();
    } else if (sqPixelDistance(pt, hcuts) < dragThreshold) {
      cutGrabbed = "horizontal";
      drawCUT();
    } else if (pt.y < 50 && pt.x < 50 ) {
      //doCut();
      cutGrabbed = "scissors";
      drawCUT();
      //hasCut = true;  //TODO: make sure that this was needed
    } else {
      drawCUT();
      for (int i = 0; i < pieces.length; i++) {
        Piece test = pieces[i];
        
       // if (test.hitTest(pt)) {
       //   draggingPiece = test;
       //   pieceDragOrigin = pt;
       //   break;
       // }
        
        num gridX = getGridCoordForPixelH(pt.x);
        num gridY = getGridCoordForPixelV(pt.y);
        if ( test.containsGridPoint( gridX, gridY ) ) {
          draggingPiece = test;
          pieceDragOrigin = pt;
          break;
        }
        
      }
      
      if (draggingPiece != null) {
     //   print("hit piece " + draggingPiece.vertices.toString() );
        CanvasRenderingContext2D ctx = canv.context2D;
        draggingPiece.drawAsDragging(ctx);
      } else {
      //  print("miss");
      }
      
      
    }
  }
}

void doCut() {
  
  if (cutFlavor == "all") {
    if (wasInCavalieri) {
      
      for (int yc = 0; yc < vticks * vSubTicks; yc++) {
        List<Piece> newPcs = new List<Piece>();
        pieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
        pieces = newPcs;
      }
      for (int xc = 0; xc < hticks * hSubTicks; xc++) {
        List<Piece> newPcs = new List<Piece>();
        pieces.forEach((piece) => newPcs.addAll(piece.cutVerticalCavalieri(xc)));
        pieces = newPcs;
      }
      
      
    } else {
      for (int xc = 0; xc < hticks * hSubTicks; xc++) {
        List<Piece> newPcs = new List<Piece>();
        pieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xc)));
        pieces = newPcs;
      }
    
     //print(pieces.length.toString() + " PIECES. with vertices...");
     //pieces.forEach( (piece) => print( piece.vertices.length.toString() + piece.verticesAsString() ) );
    
      for (int yc = 0; yc < vticks * vSubTicks; yc++) {
        List<Piece> newPcs = new List<Piece>();
        pieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
        pieces = newPcs;
      }
    }
  //print(pieces.length.toString() + " PIECES. with vertices...");
  //pieces.forEach( (piece) => print( piece.vertices.length.toString() + piece.verticesAsString() ) );
  } else {
    num cx = getSubTickCoordForPixelH(hcuts.x);
    num cy = getSubTickCoordForPixelV(vcuts.y);
    List<Piece> newPcs = new List<Piece>();
    if (wasInCavalieri) {
      pieces.forEach( (piece) => newPcs.addAll(piece.cutVerticalCavalieri(cx)) );
      //print("*****END DEBUGGING****");
      //pieces.forEach( (piece) => newPcs.addAll(piece.cutVerticalCavalieri(cx)) );
    } else {
      pieces.forEach( (piece) => newPcs.addAll(piece.cutVertical(cx)) );
    }
    pieces = newPcs;
    //print("pieces after cut");
    //pieces.forEach( (piece) => print(piece.vertices) );   
    
    List<Piece> newPcsH = new List<Piece>();
    pieces.forEach( (piece) => newPcsH.addAll(piece.cutHorizontal(cy)) );
    pieces = newPcsH;
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
  if (hasCut) {
    drawRulers(ctx);
    if (wasInCavalieri) { drawCavalieriPath(ctx); }
    else { drawSweeperSweptSWEEP(ctx); }
    pieces.forEach((piece) => piece.draw(ctx));
    drawGrid(ctx);
    drawTools();
  } else {
    drawRulers(ctx);
    drawGrid(ctx);
    if (wasInCavalieri) { drawCavalieriPath(ctx); }
    else { drawSweeperSweptSWEEP(ctx); }
    drawTools();
  }
  
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
    if (draggingPiece.minimumX() + delx < 0) { 
      delx = 0; }
    if (draggingPiece.maximumX() + delx > hticks * hSubTicks) {
      delx = 0;}
    if (draggingPiece.minimumY() + dely < 0 ) {
      dely = 0; }
    if (draggingPiece.maximumY() + dely > vticks * vSubTicks) {
      dely = 0;}
    
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
   // draggingPiece.vertices.forEach((vertex) => print("  ]--> " + getXForHSubTick(vertex.x).toString() + ", " + getYForVSubTick(vertex.y).toString() ) );
  
}



void stopDragCUT(MouseEvent event) {
  draggingPiece = null;
  if (cutGrabbed == "scissors") {
    doCut();
    //if (wasInCavalieri) { doCut(); }
  }
  cutGrabbed = "none";
  drawCUT();
}

void stopTouchCUT(TouchEvent evt) {
  draggingPiece = null;
  if (cutGrabbed == "scissors") {
    doCut();
  }
  cutGrabbed = "none";
  drawCUT();
}
