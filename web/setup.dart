part of sweeps;


//dialog contents & logic for the measurement changing dialog.
void displayUnitDialogH() {
//TextInputElement tie = document.querySelector("#unitname");
//tie.value = hunits_full;
  TextInputElement tie2 = document.querySelector("#unitshort");
  tie2.value = hunits_abbreviated;
  RangeInputElement rie = document.querySelector("#subdiv");
  rie.value = hSubTicks.toString();
  SpanElement se = document.querySelector("#sliderval");
  se.innerHtml = hSubTicks.toString();
  
  CheckboxInputElement ce = document.querySelector("#sameUnit");
  if (unitsLocked) { //( ticwid == ticht ) 
    ce.checked = true; }
  else { ce.checked = false; }
  
  document.querySelector("#oppDirection").innerHtml = "Vertical";

  document.querySelector("#popupDiv").style.visibility = "visible";

  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  listenForHorizontalUnitsSubmit.resume();
  pauseEventsForScreenCapsWindow();
}

void makeHEqualToV() {
  ticwid = ticht;
  hticks = (hrulerwidth / ticwid);
}

void makeVEqualToH() {
  ticht = ticwid;
  vticks = (vrulerheight / ticht);
}

void ensureAllPointsAreOnscreen() {
  if (s1end.x >= hticks * hSubTicks ) { s1end = new Point((hticks.floor() * hSubTicks), s1end.y); }
  if (s2end.x >= hticks * hSubTicks  ) { s2end = new Point((hticks.floor() * hSubTicks), s2end.y); }
  if (s1end.y >= vticks * vSubTicks ) { s1end = new Point(s1end.x, (vticks.floor() * vSubTicks)); }
  if (s2end.y >= vticks * vSubTicks ) { s2end = new Point(s2end.x, (vticks.floor() * vSubTicks)); }
}

void getHorizUnits(MouseEvent me) {
  //String oldAbbrev = hunits_abbreviated;
//TextInputElement tie = document.querySelector("#unitname");
  TextInputElement tie2 = document.querySelector("#unitshort");
//String proposedUnits = tie.value;
  String proposedAbbrev = tie2.value;
  RangeInputElement rie = document.querySelector("#subdiv");
  int proposedSubDivs = rie.valueAsNumber.round();
//if (proposedUnits.length > 0 && proposedAbbrev.length > 0) {
  if (proposedAbbrev.length > 0) {
    //hunits_full = proposedUnits;
    hunits_abbreviated = proposedAbbrev;
  } 
  
  CheckboxInputElement ce = document.querySelector("#sameUnit");
  if (ce.checked || hunits_abbreviated == vunits_abbreviated) {
    makeHEqualToV();
    if (s1end.x >= hticks * hSubTicks ) { s1end = new Point((hticks * hSubTicks), s1end.y); }
    if (s2end.x >= hticks * hSubTicks  ) { s2end = new Point((hticks * hSubTicks), s2end.y); }
    vunits_abbreviated = hunits_abbreviated;
    unitsLocked = true;
    ensureAllPointsAreOnscreen();
  } else {
    if (unitsLocked == true) {
      unitsLocked = false;
    }
  }
  /*
   * if (hunits_abbreviated == vunits_abbreviated) {
      makeHEqualToV();
      if (s1end.x >= hticks * hSubTicks ) { s1end = new Point((hticks * hSubTicks), s1end.y); }
      if (s2end.x >= hticks * hSubTicks  ) { s2end = new Point((hticks * hSubTicks), s2end.y); }
    }
   */
    int oldHSubTicks = hSubTicks;
    hSubTicks = proposedSubDivs;
    updateSweeperHPoints(oldHSubTicks, hSubTicks);
    document.querySelector("#popupDiv").style.visibility = "hidden";

    drawSETUP();
  
  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
  
  resumeEventsForScreenCapsWindow();
}


void getVerticalUnits(MouseEvent me) {
  //String oldAbbrev = vunits_abbreviated;

  TextInputElement tie2 = document.querySelector("#unitshort");
  String proposedAbbrev = tie2.value;

  RangeInputElement rie = document.querySelector("#subdiv");
  int proposedSubDivs = rie.valueAsNumber.round();

  if (proposedAbbrev.length > 0) {
    //vunits_full = proposedUnits;
    vunits_abbreviated = proposedAbbrev;
  }


  CheckboxInputElement ce = document.querySelector("#sameUnit");

    if (ce.checked || hunits_abbreviated == vunits_abbreviated) {
      makeVEqualToH();
      if (s1end.y >= vticks * vSubTicks ) { s1end = new Point(s1end.x, (vticks * vSubTicks)); }
      if (s2end.y >= vticks * vSubTicks ) { s2end = new Point(s2end.x, (vticks * vSubTicks)); }
      hunits_abbreviated = vunits_abbreviated;
      unitsLocked = true;
      ensureAllPointsAreOnscreen();
    } else {
      if (unitsLocked == true) {
        unitsLocked = false;
      }
    }

  
    int oldVSubTicks = vSubTicks;
    vSubTicks = proposedSubDivs;
    updateSweeperVPoints(oldVSubTicks, vSubTicks);

    document.querySelector("#popupDiv").style.visibility = "hidden";

   
    drawSETUP();
  
  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
  
  resumeEventsForScreenCapsWindow();
}

void displayUnitDialogV() {
  //TextInputElement tie = document.querySelector("#unitname");
  //tie.value = vunits_full;
  TextInputElement tie2 = document.querySelector("#unitshort");
  tie2.value = vunits_abbreviated;
  RangeInputElement rie = document.querySelector("#subdiv");
  rie.value = vSubTicks.toString();
  SpanElement se = document.querySelector("#sliderval");
  se.innerHtml = vSubTicks.toString();
  
  document.querySelector("#oppDirection").innerHtml = "Horizontal";
  
  CheckboxInputElement ce = document.querySelector("#sameUnit");
    if ( unitsLocked ) { //(ticwid == ticht ) 
      ce.checked = true; }
    else { ce.checked = false; }
  
  document.querySelector("#popupDiv").style.visibility = "visible";
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
  listenForVerticalUnitsSubmit.resume();
  pauseEventsForScreenCapsWindow();
}

bool userChangesUnits(Point clickSpot) {
  bool toGoOn = false;
  if (sqPixelDistance(clickSpot, new Point((hrulerwidth + hoff / 2).round(), 20)) < 1100) {
    displayUnitDialogH();
    toGoOn = true;
  } else if (sqPixelDistance(clickSpot, new Point(20, (vrulerheight + voff / 2).round())) < 1100) {
    displayUnitDialogV();
    toGoOn = true;
  }
  return toGoOn;
}



//**************************************************************************
//SETUP MODE FLAVORS OF METHODS
void startDragSETUP(MouseEvent event) {
  if (!userChangesUnits(event.offset)) {
    initInteractionSETUP(event.offset);
  }
}

void startTouchSETUP(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  initInteractionSETUP(initPoint);
}

void initInteractionSETUP(Point initPoint) {
  readyToGoOn = true;
  if (unitsLocked == false && sqPixelDistance(initPoint, vhots) < dragThreshold) {
    grabbed = "vertical";
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSETUP();
  } else if (sqPixelDistance(initPoint, hhots) < dragThreshold) {
    grabbed = "horizontal";
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSETUP();
//  } else if (sqPixelDistance(initPoint, new Point(getXForHTick(s1end.x), getYForVTick(s1end.y))) < dragThreshold) {
  } else if (sqPixelDistance(initPoint, new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y))) < dragThreshold) {
    grabbed = "s1end";
    drawSETUP();
    //} else if (sqPixelDistance(initPoint, new Point(getXForHTick(s2end.x), getYForVTick(s2end.y))) < dragThreshold) {
  } else if (sqPixelDistance(initPoint, new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y))) < dragThreshold) {
    grabbed = "s2end";
    drawSETUP();
  } else if (inMiddle(initPoint)) {
    grabbed = "middle";
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSETUP();
  } else if (initPoint.x < 2 * hoff / 3 && initPoint.y < 2 * voff / 3) {
    comparingRulers = true;
    compareRulerAngle = 0;
    compareRulerFrame = 0;
    startCompareRulerAnimation(10);
  }
}


void incrementFrame(Timer t) {
  compareRulerFrame++;
  if (compareRulerFrame <= 45) {
    compareRulerAngle = compareRulerFrame;
  }
  if (compareRulerFrame >= 95) {
    comparingRulers = false;
    t.cancel();
  }
  drawSETUP();
}

startCompareRulerAnimation(int msec) {
  return new Timer.periodic(new Duration(milliseconds: msec), incrementFrame);
}

void touchDragSETUP(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;
  draggingSETUP(currPoint);
}

void mouseDragSETUP(MouseEvent event) {
  draggingSETUP(event.offset);
}


void draggingSETUP(Point currentPt) {
  if (grabbed != "") {
    if (grabbed == "vertical") {
      int newvtickh = currentPt.y - voff;
      if (newvtickh < 1) {
        newvtickh = 1;
      }
      int newvticks = (vrulerheight / newvtickh).round();
      if (newvticks != vticks && newvticks <= maxvticks && newvticks >= minvticks) {
        updateVSweepsSETUP(newvticks);
        vticks = newvticks;
        drawSETUP();
      }
    } else if (grabbed == "horizontal") {
      int newhtickw = currentPt.x - hoff;
      if (newhtickw < 1) {
        newhtickw = 1;
      }
      int newhticks = (hrulerwidth / newhtickw).round();
      //TODO: seems to allow more resolution on horizontal than is taken account of in vertical.
      //TODO:  Issue is that the units are being snapped to rounded versions of the tickw.
      if (newhticks != hticks && newhticks <= maxhticks && newhticks >= minhticks) {
        updateHSweepsSETUP(newhticks);
        hticks = newhticks;
        ticwid = hrulerwidth / hticks;
        if (unitsLocked) {
          makeVEqualToH();
          ensureAllPointsAreOnscreen();
        }
        drawSETUP();
      }
    } else if (grabbed == "s1end") {
      s1end = updateEndSETUP(s1end, currentPt);
      drawSETUP();
    } else if (grabbed == "s2end") {
      s2end = updateEndSETUP(s2end, currentPt);
      drawSETUP();
    } else if (grabbed == "middle") {
      updateWithShiftSETUP(currentPt);
      drawSETUP();
    }
  }
}

//TODO:  when we change the number of subdivisions and we can drag onto the subdivisions,
//then we need to call s1end = updateEndSETUP(s1end, s1end); and similar for s2end, where we
//are using the the subdivision version of the  getXFor reporter.
Point updateEndSETUPOLD(Point endpt, Point mspt) {
  //Point pxPt = new Point(getXForHTick(endpt.x), getYForVTick(endpt.y));
  Point pxPt = new Point(getXForHSubTick(endpt.x), getYForVSubTick(endpt.y));
  int delx = mspt.x - pxPt.x;
  int dely = mspt.y - pxPt.y;
  if (delx > .5 * ticwid / hSubTicks && endpt.x < hticks * hSubTicks) {
    return new Point(endpt.x + 1, endpt.y);
  } else if (delx < -.5 * ticwid / hSubTicks && endpt.x > 0) {
    return new Point(endpt.x - 1, endpt.y);
  }
  if (dely > .5 * ticht / vSubTicks && endpt.y < vticks * vSubTicks) {
    return new Point(endpt.x, endpt.y + 1);
  } else if (dely < -.5 * ticht / vSubTicks && endpt.y > 0) {
    return new Point(endpt.x, endpt.y - 1);
  }
  return endpt;
}

Point updateEndSETUP(Point endpt, Point mspt) {
  num newSubTickH = getSubTickCoordForPixelH(mspt.x);
  num newSubTickV = getSubTickCoordForPixelV(mspt.y);
  if (newSubTickH < 0  || newSubTickH > hticks * hSubTicks) { newSubTickH = endpt.x; }
  if (newSubTickV < 0  || newSubTickV > vticks * vSubTicks) { newSubTickV = endpt.y; }
  return new Point(newSubTickH, newSubTickV);
}


void updateWithShiftSETUP(Point now) {
  num delx = now.x - dragOrigin.x;
  num dely = now.y - dragOrigin.y;
  int shiftx = ((hSubTicks * delx) / ticwid).round();
  int shifty = ((vSubTicks * dely) / ticht).round();
  Point new1 = new Point(olds1.x + shiftx, olds1.y + shifty);
  Point new2 = new Point(olds2.x + shiftx, olds2.y + shifty);
  if (new1.x >= 0 && new1.x <= hticks * hSubTicks && new1.y >= 0 && new1.y <= vticks * vSubTicks) {
    if (new2.x >= 0 && new2.x <= hticks * hSubTicks && new2.y >= 0 && new2.y <= vticks * vSubTicks) {
      s1end = new1;
      s2end = new2;
    }
  }
}

void stopDragSETUP(MouseEvent event) {
  grabbed = "";
  //print("got here - mouse");
  drawSETUP();
}

void stopTouchSETUP(TouchEvent evt) {
  grabbed = "";
  //overrideFontsForIPAD();
  drawSETUP();
}


void drawSETUP() {
  adjustDimensions();
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (grabbed == "horizontal" || grabbed == "vertical") {
    drawGrid(ctx);
    drawRulers(ctx);
    drawSweeperSETUP(ctx, oldpx2, oldpx1);
  } else {
    //if (grabbed != "") {
    drawGrid(ctx);
    //}
    //Point strt = new Point(getXForHTick(s1end.x), getYForVTick(s1end.y));
    //Point end = new Point(getXForHTick(s2end.x), getYForVTick(s2end.y));
    Point strt = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
    Point end = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));
    drawRulers(ctx);
    drawSweeperSETUP(ctx, strt, end);
  }
  ctx.drawImageScaled(rulerCompareButton, 0, 0, 58, 58);
  if (comparingRulers) {
    drawHorizontalAxisCompare(ctx, 50);
    drawVerticalAxisCompare(ctx, 50);
  }
  drawTools();
}

void updateHSweepsSETUP(int newticks) {
  double n1x = (olds1.x / oldhtix) * newticks;
  double n2x = (olds2.x / oldhtix) * newticks;
  s1end = new Point(n1x.round(), s1end.y);
  s2end = new Point(n2x.round(), s2end.y);
}

void updateVSweepsSETUP(int newticks) {
  double n1y = (olds1.y / oldvtix) * newticks;
  double n2y = (olds2.y / oldvtix) * newticks;
  s1end = new Point(s1end.x, n1y.round());
  s2end = new Point(s2end.x, n2y.round());
}

void drawSweeperSETUP(CanvasRenderingContext2D ctxt, Point strt, Point end) {
  ctxt.strokeStyle = "#000";

  ctxt.lineWidth = 10;
  ctxt.beginPath();
  ctxt.moveTo(strt.x, strt.y);
  ctxt.lineTo(end.x, end.y);
  ctxt.closePath();
  ctxt.stroke();
  ctxt.lineWidth = 1;

  ctxt.beginPath();
  ctxt.arc(strt.x, strt.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  if (grabbed == "s1end") {
    ctxt.fillStyle = "#4C4";
    ctxt.fill();
  } else {
    ctxt.fillStyle = "#999";
    ctxt.fill();
  }

  ctxt.beginPath();
  ctxt.arc(end.x, end.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  if (grabbed == "s2end") {
    ctxt.fillStyle = "#4C4";
    ctxt.fill();
  } else {
    ctxt.fillStyle = "#999";
    ctxt.fill();
  }

  Point mid = new Point(((strt.x + end.x) / 2).round(), ((strt.y + end.y) / 2).round());
  ctxt.beginPath();
  ctxt.arc(mid.x, mid.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  if (grabbed == "middle") {
    ctxt.fillStyle = "#4C4";
    ctxt.fill();
  } else {
    ctxt.fillStyle = "#999";
    ctxt.fill();
  }
}
