part of sweeps;


void startDragSWEEP(MouseEvent event) {
  initInteractionSWEEP(event.offset);
}

void startTouchSWEEP(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  initInteractionSWEEP(initPoint);
}

void touchDragSWEEP(TouchEvent evt) {
  if (grabbed == "body") {
    Point currPoint = evt.changedTouches[0].client;
    draggingSWEEP(currPoint);
  }
}

void mouseDragSWEEP(MouseEvent event) {
  if (grabbed == "body") {
    draggingSWEEP(event.offset);
  }
}


/*
 * TODO: idea -- change 'wantToDragUnits to wantToDragSubdivisions'
 * to do it, multiply  by vSubTicks or hSubTicks before rounding
 * then, make the draggedUnits be draggedSubUnits
 * and draw accordingly.
 * deal with perfect integers, probably.
 * 
 */
void draggingSWEEP(Point currentPt) {
  int delx = currentPt.x - dragOrigin.x;
  int dely = currentPt.y - dragOrigin.y;

  bool changedDirection = false;
  if (delx.abs() > dely.abs()) {
    if (dragIsVertical) {
      changedDirection = true;
    }
    dragIsVertical = false;
  } else {
    if (!dragIsVertical) {
      changedDirection = true;
    }
    dragIsVertical = true;
  }

  //exceptional logic ---> if the sweeper is vertical, all sweeps should be horizontal;
  //and if the sweeper is horizontal, all sweeps should be vertical.

  if (olds1.x == olds2.x) {
    if (olds1.y != olds2.y) {
      dragIsVertical = false;
      }
  }
  else if (olds1.y == olds2.y) {
    if (olds1.x != olds2.x) {
      dragIsVertical = true;
      }
  }

  Point new1, new2;
  //int wantToDragUnits;
  int wantToDragSubUnits;
  if (dragIsVertical) {
    //wantToDragUnits = (dely / ticht).round();
    wantToDragSubUnits = (vSubTicks * dely / ticht).round();
    new1 = new Point(olds1.x, olds1.y + wantToDragSubUnits);
    new2 = new Point(olds2.x, olds2.y + wantToDragSubUnits);
  } else {
    //wantToDragUnits = (delx / ticwid).round();
    wantToDragSubUnits = (hSubTicks * delx / ticwid).round();
    new1 = new Point(olds1.x + wantToDragSubUnits, olds1.y);
    new2 = new Point(olds2.x + wantToDragSubUnits, olds2.y);
  }

  if (new1.x >= 0 && new1.x <= hticks * hSubTicks && new1.y >= 0 && new1.y <= vticks * vSubTicks) {
    if (new2.x >= 0 && new2.x <= hticks * hSubTicks && new2.y >= 0 && new2.y <= vticks * vSubTicks) {
      s1end = new1;
      s2end = new2;
      draggedUnits = wantToDragSubUnits;
    }
    else {
      if (changedDirection) {
        dragIsVertical = !dragIsVertical;
      }
    }
  }
  else {
    if (changedDirection) {
      dragIsVertical = !dragIsVertical;
    }
  }
  drawSWEEP();
}


void stopDragSWEEP(MouseEvent event) {
  grabbed = "done";
  drawSWEEP();
}

void stopTouchSWEEP(TouchEvent evt) {
  grabbed = "done";
  //overrideFontsForIPAD();
  drawSWEEP();
}





//TODO: remove comments when it works.
void drawSweeperSweptSWEEP(CanvasRenderingContext2D ctxt) {
//  Point strt = new Point(getXForHTick(s1end.x), getYForVTick(s1end.y));
//  Point end = new Point(getXForHTick(s2end.x), getYForVTick(s2end.y));
  Point strt = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
  Point end = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));

  Point strt2, end2;
  if (dragIsVertical) {
    //strt2 = new Point(getXForHTick(s1end.x), getYForVTick(s1end.y - draggedUnits));
    //end2 = new Point(getXForHTick(s2end.x), getYForVTick(s2end.y - draggedUnits));
    strt2 = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y - draggedUnits));
    end2 = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y - draggedUnits));
  } else {
    //strt2 = new Point(getXForHTick(s1end.x - draggedUnits), getYForVTick(s1end.y));
    //end2 = new Point(getXForHTick(s2end.x - draggedUnits), getYForVTick(s2end.y));
    strt2 = new Point(getXForHSubTick(s1end.x - draggedUnits), getYForVSubTick(s1end.y));
    end2 = new Point(getXForHSubTick(s2end.x - draggedUnits), getYForVSubTick(s2end.y));
  }

  ctxt.beginPath();
  ctxt.strokeStyle = "#555";
  ctxt.fillStyle = "#88F";

  if (hasCut) {
    ctxt.lineWidth = 3;
    ctxt.setLineDash([3]);
    ctxt.strokeStyle = "#44F";
  }
  ctxt.moveTo(strt.x, strt.y);
  ctxt.lineTo(strt2.x, strt2.y);
  ctxt.lineTo(end2.x, end2.y);
  ctxt.lineTo(end.x, end.y);
  ctxt.lineTo(strt.x, strt.y);
  ctxt.closePath();
  if (!hasCut) {
    ctxt.fill();
  }
  ctxt.stroke();

  if (hasCut) {
    ctxt.setLineDash([]);
    ctxt.lineWidth = 1;
  }

  //ADD MARKINGS TO RULER
  if (draggedUnits != 0) {
    if (dragIsVertical) {
      if (strt.x > end.y) {
        if (draggedUnits > 0) {
          drawRulerMarkings(end2, end, strt, ctxt);
        }
        else {
          drawRulerMarkings(end, end2, strt2, ctxt);
        }
      }
      else {
        if (draggedUnits > 0) {
          drawRulerMarkings(strt2, strt, end, ctxt);
        }
        else {
          drawRulerMarkings(strt, strt2, end2, ctxt);
        }
      }
    }
    else {
      if (strt.y > end.y) {
        if (draggedUnits > 0) {
          drawRulerMarkings(strt, end, end2, ctxt);
        }
        else {
          drawRulerMarkings(strt2, end2, end, ctxt);
        }
      }
      else {
        if (draggedUnits > 0) {
          drawRulerMarkings(end, strt, strt2, ctxt);
        }
        else {
          drawRulerMarkings(end2, strt2, strt, ctxt);
        }
      }
    }
  }
}

void drawRulerMarkings(Point BottomLeft, Point TopLeft, Point TopRight, CanvasRenderingContext2D ctxt) {

  // Draw the boxes
  ctxt.fillStyle = "rgba(255, 0, 0, 0.15)";

  ctxt.fillRect(0, BottomLeft.y, hoff, TopLeft.y - BottomLeft.y);
  ctxt.fillRect(TopRight.x, 0, TopLeft.x - TopRight.x, voff);


  //Draw the text
  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#000";
  ctxt.font = littleCanvasFont;
  ctxt.textAlign = 'center';


  //Vertical text
  String ifFractions = ' ';
  String numToDraw = (getSubTickCoordForPixelV(BottomLeft.y) - getSubTickCoordForPixelV(TopLeft.y)).abs().toString();
  if (vSubTicks > 1) {
    ifFractions = " / " + vSubTicks.toString() + " ";
  }
  String toDraw = numToDraw + ifFractions + vunits_abbreviated;
  int ycor = ((BottomLeft.y + TopLeft.y) / 2).round();
  drawVerticalText(ctxt, toDraw, 28, ycor);

  // Horizontal text
  ifFractions = ' ';
  numToDraw = (getSubTickCoordForPixelH(TopRight.x) - getSubTickCoordForPixelH(TopLeft.x)).abs().toString();
  if (hSubTicks > 1) {
    ifFractions = " / " + vSubTicks.toString() + " ";
  }
  toDraw = numToDraw + ifFractions + hunits_abbreviated;
  ctxt.fillText(toDraw, ((TopLeft.x + TopRight.x) / 2).round(), 28);
}


void drawSweeperCurrentSWEEP(CanvasRenderingContext2D ctxt) {

  Point strt = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
  Point end = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));

  ctxt.strokeStyle = "#000";

  ctxt.lineWidth = 10;
  ctxt.beginPath();
  ctxt.moveTo(strt.x, strt.y);
  ctxt.lineTo(end.x, end.y);
  ctxt.closePath();
  ctxt.stroke();

  drawPoint(ctxt, strt, "#222", 10);
  drawPoint(ctxt, end, "#222", 10);

  Point mid = new Point(((strt.x + end.x) / 2).round(), ((strt.y + end.y) / 2).round());
  if (grabbed == "body") {
    drawPoint(ctxt, mid, "#4C4", 10);
  } else {
    drawPoint(ctxt, mid, "#999", 10);
  }
}

void drawPoint(CanvasRenderingContext2D ctxt, Point point, String style, int radius) {
  ctxt.lineWidth = 1;
  ctxt.beginPath();
  ctxt.arc(point.x, point.y, radius, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  ctxt.fillStyle = style;
  ctxt.fill();
}



//************************************************************************************
//SWEEP MODE VERSIONS OF METHODS
