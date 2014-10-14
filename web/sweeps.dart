library sweeps;

import 'dart:html';
import 'dart:math';
import 'dart:core';

part "piece.dart";

ImageElement rightButton, leftButton;
CanvasElement canv, tools;
DivElement splash;
DivElement sCapBook;
int voff = 60;
int hoff = 60;
int vrulerheight, hrulerwidth;

String littleCanvasFont = 'italic 20pt Calibri';
String bigCanvasFont = 'italic 31pt  Calibri';
String overrideHTMLInputFont = "26pt sans-serif";
String overrideHTMLPromptFont = "28pt sans-serif";


//changing and displaying units
String hunits_abbreviated = "hsu";
//String hunits_full = "horizontal sweep units";

String vunits_abbreviated = "vsu";
//String vunits_full = "vertical sweep units";

String areaToDisplay = "";

var listenForVerticalUnitsSubmit, listenForHorizontalUnitsSubmit;
ButtonInputElement submitUnitsButton;


int MODE = 0;
var captions = ["Click to start!", "Set up Sweeper & Measures", "Drag to Sweep", "Click to Cut; Drag to Arrange", "Arrange the Pieces"];
bool readyToGoOn = true;

//relevant to the SETUP mode
var SETUPMouseDown, SETUPTouchStart, SETUPMouseMove, SETUPTouchMove, SETUPMouseUp, SETUPTouchEnd;
int hticks = 12;
int vticks = 9;
int hSubTicks = 1;
int vSubTicks = 1;
int hSubTicksBefore = 1;
int vSubTicksBefore = 1;
int maxhticks = 24;
int maxvticks = 15;
int minhticks = 2; //9;
int minvticks = 2; //6;

double ticwid;
double ticht;
Point s1end = new Point(2, 3);
Point s2end = new Point(4, 6);
Point olds1, olds2, oldpx1, oldpx2;
int oldvtix, oldhtix;

Point vhots = new Point(hoff - 10, voff);
Point hhots = new Point(hoff, voff - 10);
String grabbed = "";
num dragThreshold = 600;
Point dragOrigin;


//relevant to the SWEEP mode
var SWEEPMouseDown, SWEEPTouchStart, SWEEPMouseMove, SWEEPTouchMove, SWEEPMouseUp, SWEEPTouchEnd;
bool dragIsVertical = true;
int draggedUnits = 0;

//relevant to the CUT mode
var CUTMouseDown, CUTTouchStart, CUTMouseMove, CUTTouchMove, CUTMouseUp, CUTTouchEnd;
bool hasCut = false;
List<Piece> pieces = new List<Piece>();
Piece draggingPiece = null;
Point pieceDragOrigin;

//Screen captures
List<ImageData> screencaps = new List<ImageData>();
List<String> screens = new List<String>();
int screenPointer = 0;


void main() {
  rightButton = new ImageElement()..src = "images/rightImage.jpg";
  leftButton = new ImageElement()..src = "images/leftImage.jpg";
  canv = querySelector("#scanvas");
  tools = querySelector("#tcanvas");
  splash = querySelector("#splashdiv");
  submitUnitsButton = document.querySelector("#submitUnit");
  splash.onClick.listen(startUp);
  
}

void doEventSetup() {
  //SETUP MODE EVENTS
  SETUPMouseDown = canv.onMouseDown.listen(startDragSETUP);
  SETUPTouchStart = canv.onTouchStart.listen(startTouchSETUP);
  SETUPMouseMove = canv.onMouseMove.listen(mouseDragSETUP);
  SETUPTouchMove = canv.onTouchMove.listen(touchDragSETUP);
  SETUPMouseUp = canv.onMouseUp.listen(stopDragSETUP);
  SETUPTouchEnd = canv.onTouchEnd.listen(stopTouchSETUP);

  //SWEEP MODE EVENTS
  SWEEPMouseDown = canv.onMouseDown.listen(startDragSWEEP);
  SWEEPTouchStart = canv.onTouchStart.listen(startTouchSWEEP);
  SWEEPMouseMove = canv.onMouseMove.listen(mouseDragSWEEP);
  SWEEPTouchMove = canv.onTouchMove.listen(touchDragSWEEP);
  SWEEPMouseUp = canv.onMouseUp.listen(stopDragSWEEP);
  SWEEPTouchEnd = canv.onTouchEnd.listen(stopTouchSWEEP);

  //CUT MODE EVENTS
  CUTMouseDown = canv.onMouseDown.listen(startDragCUT);
  CUTTouchStart = canv.onTouchStart.listen(startTouchCUT);
  CUTMouseMove = canv.onMouseMove.listen(mouseDragCUT);
  CUTTouchMove = canv.onTouchMove.listen(touchDragCUT);
  CUTMouseUp = canv.onMouseUp.listen(stopDragCUT);
  CUTTouchEnd = canv.onTouchEnd.listen(stopTouchCUT);

  //unit change dialog events
  submitUnitsButton = document.querySelector("#submitUnit");
  listenForHorizontalUnitsSubmit = submitUnitsButton.onClick.listen(getHorizUnits);
  listenForVerticalUnitsSubmit = submitUnitsButton.onClick.listen(getVerticalUnits);
  listenForHorizontalUnitsSubmit.pause();
  listenForVerticalUnitsSubmit.pause();

  //Pause the SWEEP mode events because we start in SETUP mode
  SWEEPMouseDown.pause();
  SWEEPTouchStart.pause();
  SWEEPMouseMove.pause();
  SWEEPTouchMove.pause();
  SWEEPMouseUp.pause();
  SWEEPTouchEnd.pause();

  //Pause the CUT mode events because we start in SETUP mode
  CUTMouseDown.pause();
  CUTTouchStart.pause();
  CUTMouseMove.pause();
  CUTTouchMove.pause();
  CUTMouseUp.pause();
  CUTTouchEnd.pause();
 
  
  
  //set up mouse actions on the screen capture dialog.
  document.querySelector("#trashIcon").onMouseUp.listen( deleteScreenCap );
  document.querySelector("#trashIcon").onTouchEnd.listen( deleteScreenCap );
  
  
  document.querySelector("#closeIcon").onMouseUp.listen( closeScreenCapWindow );
  document.querySelector("#closeIcon").onTouchEnd.listen( closeScreenCapWindow );
  
  document.querySelector("#screencap").onMouseUp.listen( MOUSEforwardOrBackInScreens );
  document.querySelector("#screencap").onTouchEnd.listen( TOUCHforwardOrBackInScreens );
  
}

void testSwitchMode(MouseEvent e) {
  int rbound = tools.width - 2 * tools.height;
  int lbound = tools.height * 2;
  Point screenCapIconCenter = new Point( tools.width / 3, tools.height / 2);
  int screenCapIconTolerance = 50;
  if (e.offset.x > rbound && MODE < 3) { //we're in the right arrow
    MODE++;
    readyToGoOn = false;
    doModeSpecificLogic();
  } else if (e.offset.x < lbound) { //we're in the left arrow
    if (MODE > 1) {
      MODE--;
      readyToGoOn = false;
      draggedUnits = 0;
      doModeSpecificLogic();
    } else if (MODE == 1) {
      window.location.reload();
    }
  } else if (e.offset.distanceTo(screenCapIconCenter) < screenCapIconTolerance ) {
    addScreenCap();
    openScreenCapsWindow();
  }
}

void addScreenCap() {
  //ImageData imageData = canv.context2D.getImageData(0,0,canv.width,canv.height);
  String base64Cap = canv.toDataUrl("image/png");
  //screencaps.add(imageData);
  screens.add(base64Cap);
}

void closeScreenCapWindow( var event ) {
  document.querySelector("#screenCapDiv").style.visibility = "hidden";
}
 
void deleteScreenCap( var event ) {
  screens.removeAt(screenPointer);
  if (screens.length == 0) {
    closeScreenCapWindow( event );
  } else {
    changeScreen(0);
  }
}

void MOUSEforwardOrBackInScreens ( MouseEvent me ) {
  Point clickPoint = me.client;
  doFwdBackLogic( clickPoint );
}

void  TOUCHforwardOrBackInScreens ( TouchEvent evt ) {
  Point clickPoint = evt.changedTouches[0].client;
  doFwdBackLogic( clickPoint );
}


void doFwdBackLogic( Point clickPoint ) {
  print(clickPoint.x);
  if ( clickPoint.x > (2 * document.querySelector("#screencap").clientWidth / 3) ) {
    changeScreen(1);
    print("next");
  } else if ( clickPoint.x < ( document.querySelector("#screencap").clientWidth / 3) ) {
    changeScreen( -1 );
    print("prev");
  }
  
}

void changeScreen( int del ) {
  screenPointer = screenPointer + del;
  if (screenPointer >= screens.length) {
    screenPointer = 0;
  } else if (screenPointer < 0 ) {
    screenPointer = screens.length - 1;
  }
  loadScreen(document.querySelector("#screencap"));
}

void loadScreen(CanvasElement sc ) {
  ImageElement i = new ImageElement();
  i.src = screens[ screenPointer ];
  SpanElement numLabel = document.querySelector("#screennum"); 
  numLabel.innerHtml = (screenPointer + 1).toString() + " of " + screens.length.toString();
  sc.context2D.clearRect(0, 0, sc.width, sc.height);
  sc.context2D.drawImageScaled(i, 0, 0, sc.width, sc.height);
}

void openScreenCapsWindow() {
  DivElement scpop = document.querySelector("#screenCapDiv");
  DivElement topstuff = document.querySelector("#topbar");
  scpop.style.visibility = "visible";
  CanvasElement sc = document.querySelector("#screencap");
  sc.width = scpop.clientWidth;
  sc.height = scpop.clientHeight - topstuff.clientHeight;
  loadScreen(sc);
}



//response to forward back buttons, once the MODE value has been switched.
void doModeSpecificLogic() {
  //print("MODE = " + MODE.toString());
  if (MODE == 1) {
    SETUPMouseDown.resume();
    SETUPTouchStart.resume();
    SETUPMouseMove.resume();
    SETUPTouchMove.resume();
    SETUPMouseUp.resume();
    SETUPTouchEnd.resume();

    if (!SWEEPMouseDown.isPaused) {
      SWEEPMouseDown.pause();
      SWEEPTouchStart.pause();
      SWEEPMouseMove.pause();
      SWEEPTouchMove.pause();
      SWEEPMouseUp.pause();
      SWEEPTouchEnd.pause();
    }

    if (!CUTMouseDown.isPaused) {
      CUTMouseDown.pause();
      CUTTouchStart.pause();
      CUTMouseMove.pause();
      CUTTouchMove.pause();
      CUTMouseUp.pause();
      CUTTouchEnd.pause();
    }

    rememberPresentSETUPSWEEP();
    readyToGoOn = true; //testing this
    drawSETUP();
    drawTools();
  }
  if (MODE == 2) {
    if (!SETUPMouseDown.isPaused) {
      SETUPMouseDown.pause();
      SETUPTouchStart.pause();
      SETUPMouseMove.pause();
      SETUPTouchMove.pause();
      SETUPMouseUp.pause();
      SETUPTouchEnd.pause();
    }

    SWEEPMouseDown.resume();
    SWEEPTouchStart.resume();
    SWEEPMouseMove.resume();
    SWEEPTouchMove.resume();
    SWEEPMouseUp.resume();
    SWEEPTouchEnd.resume();

    if (!CUTMouseDown.isPaused) {
      CUTMouseDown.pause();
      CUTTouchStart.pause();
      CUTMouseMove.pause();
      CUTTouchMove.pause();
      CUTMouseUp.pause();
      CUTTouchEnd.pause();
    }

    grabbed = "";
    draggedUnits = 0;
    hasCut = false;
    rememberPresentSETUPSWEEP();
    drawSWEEP();
    drawTools();
  }
  if (MODE == 3) {
    if (!SETUPMouseDown.isPaused) {
      SETUPMouseDown.pause();
      SETUPTouchStart.pause();
      SETUPMouseMove.pause();
      SETUPTouchMove.pause();
      SETUPMouseUp.pause();
      SETUPTouchEnd.pause();
    }

    if (!SWEEPMouseDown.isPaused) {
      SWEEPMouseDown.pause();
      SWEEPTouchStart.pause();
      SWEEPMouseMove.pause();
      SWEEPTouchMove.pause();
      SWEEPMouseUp.pause();
      SWEEPTouchEnd.pause();
    }

    CUTMouseDown.resume();
    CUTTouchStart.resume();
    CUTMouseMove.resume();
    CUTTouchMove.resume();
    CUTMouseUp.resume();
    CUTTouchEnd.resume();
    hasCut = false;
    List<Point> gridPoints = new List<Point>();
    gridPoints.add(s1end);
    gridPoints.add(s2end);

    if (dragIsVertical) {
      gridPoints.add(new Point(s2end.x, s2end.y - draggedUnits));
      gridPoints.add(new Point(s1end.x, s1end.y - draggedUnits));
    } else {
      gridPoints.add(new Point(s2end.x - draggedUnits, s2end.y));
      gridPoints.add(new Point(s1end.x - draggedUnits, s1end.y));

    }
    pieces.clear();
    Piece whole = new Piece(gridPoints);
    pieces.add(whole);

    drawCUT();
    drawTools();
  }
}



//FOR ALL MODES
void startUp(MouseEvent event) {
  doEventSetup();
  MODE = 1;
  tools.onMouseDown.listen(testSwitchMode);
  splash.style.opacity = "0.0";
  splash.style.zIndex = "-1";
  drawSETUP();
  drawTools();
}

void drawStatus(CanvasRenderingContext2D ctx) {
  ctx.strokeStyle = "#000";
  ctx.fillStyle = "#000";
  ctx.font = bigCanvasFont;
  ctx.textAlign = 'center';
  if (((MODE == 1 || MODE == 2) && draggedUnits != 0) || (MODE == 3 && hasCut)) {
    ctx.fillText("Area swept: " + areaToDisplay, tools.width / 2, 2 * tools.height / 3);
  } else {
    ctx.fillText(captions[MODE], tools.width / 2, 2 * tools.height / 3);
  }

  /*if (MODE == 2 && grabbed == "done") {
    ctx.textAlign = 'right';
    ctx.fillStyle = "#0B0";
    ctx.fillText("Go On", tools.width - tools.height, 2 * tools.height / 3);
    ctx.strokeText("Go On", tools.width - tools.height, 2 * tools.height / 3);
    ctx.textAlign = 'left';
    ctx.fillStyle = "#B00";
    ctx.fillText("Go Back", tools.height, 2 * tools.height / 3);
    ctx.strokeText("Go Back", tools.height, 2 * tools.height / 3);
  }
  * */
}


void drawTools() {
  CanvasRenderingContext2D ctx = tools.context2D;
  ctx.clearRect(0, 0, tools.width, tools.height);
  int imht = tools.height;
  int imwid = 2 * imht; //right now they're 2:1
  if (MODE > 0) {
    ctx.drawImageScaled(leftButton, 0, 0, imwid, imht);
  }
  if (MODE < 3 && readyToGoOn) {
    ctx.drawImageScaled(rightButton, tools.width - imwid, 0, imwid, imht);
  }
  drawStatus(ctx);
}

void adjustDimensions() {
  vrulerheight = canv.height - voff;
  hrulerwidth = canv.width - hoff;
  ticwid = hrulerwidth / hticks;
  ticht = vrulerheight / vticks;
}

int sqPixelDistance(Point p1, Point p2) {
  // print("("+p1.x.toString()+","+p1.y.toString()+") and ("+p2.x.toString()+","+p2.y.toString()+")");
  return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
}


//dialog contents & logic for the measurement changing dialog.
//TODO:  add the idea of equalizing the units.
void displayUnitDialogH() {
  //TextInputElement tie = document.querySelector("#unitname");
  //tie.value = hunits_full;
  TextInputElement tie2 = document.querySelector("#unitshort");
  tie2.value = hunits_abbreviated;
  RangeInputElement rie = document.querySelector("#subdiv");
  rie.value = hSubTicks.toString();
  SpanElement se = document.querySelector("#sliderval");
  se.innerHtml = hSubTicks.toString();

  document.querySelector("#popupDiv").style.visibility = "visible";

  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  listenForHorizontalUnitsSubmit.resume();
}

void getHorizUnits(MouseEvent me) {
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
    int oldHSubTicks = hSubTicks;
    hSubTicks = proposedSubDivs;
    updateSweeperHPoints(oldHSubTicks, hSubTicks);
    document.querySelector("#popupDiv").style.visibility = "hidden";
    drawSETUP();
  }
  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
}

void updateSweeperHPoints(int oldval, int newval ) {
  s1end = new Point((newval * s1end.x / oldval).round(), s1end.y);
  s2end = new Point((newval * s2end.x / oldval).round(), s2end.y);
}

void updateSweeperVPoints(int oldval, int newval ) {
  s1end = new Point(s1end.x, (newval * s1end.y / oldval).round() );
  s2end = new Point(s2end.x, (newval * s2end.y / oldval).round() );
}

void getVerticalUnits(MouseEvent me) {
  //TextInputElement tie = document.querySelector("#unitname");
  TextInputElement tie2 = document.querySelector("#unitshort");
  //String proposedUnits = tie.value;
  String proposedAbbrev = tie2.value;
  RangeInputElement rie = document.querySelector("#subdiv");
  int proposedSubDivs = rie.valueAsNumber.round();
  //if (proposedUnits.length > 0 && proposedAbbrev.length > 0) {
  if (proposedAbbrev.length > 0) {
    //vunits_full = proposedUnits;
    vunits_abbreviated = proposedAbbrev;
       
    int oldVSubTicks = vSubTicks;
    vSubTicks = proposedSubDivs;
    updateSweeperVPoints(oldVSubTicks, vSubTicks);
    
    document.querySelector("#popupDiv").style.visibility = "hidden";
    drawSETUP();
  }
  if (!listenForVerticalUnitsSubmit.isPaused) {
    listenForVerticalUnitsSubmit.pause();
  }
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
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
  document.querySelector("#popupDiv").style.visibility = "visible";
  if (!listenForHorizontalUnitsSubmit.isPaused) {
    listenForHorizontalUnitsSubmit.pause();
  }
  listenForVerticalUnitsSubmit.resume();
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

void startDragSWEEP(MouseEvent event) {
  initInteractionSWEEP(event.offset);
}

void startTouchSWEEP(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  initInteractionSWEEP(initPoint);
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
  for (int xc = 0; xc < hticks * hSubTicks ; xc++) {
    List<Piece> newPcs = new List<Piece>();
    pieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xc)));
    pieces = newPcs;
  }

  // print(pieces.length.toString() + " PIECES. with vertices...");
  // pieces.forEach( (piece) => print( piece.vertices.length.toString() + piece.verticesAsString() ) );

  for (int yc = 0; yc < vticks * vSubTicks ; yc++) {
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

void initInteractionSWEEP(Point initPoint) {
  if (inMiddle(initPoint)) {
    grabbed = "body";
    draggedUnits = 0;
    setupDragOriginMemorySETUPSWEEP(initPoint);
    drawSWEEP();
  }
}

void drawSWEEP() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (grabbed != "") {
    drawGrid(ctx);
    drawRulers(ctx);
    drawSweeperSweptSWEEP(ctx);
    drawSweeperCurrentSWEEP(ctx);
    areaToDisplay = getAreaString() + " " + getAreaUnitsString();
    if (draggedUnits == 0) {
      readyToGoOn = false;
    } else {
      readyToGoOn = true;
    }
  } else {
    drawGrid(ctx);
    drawRulers(ctx);
    drawSweeperCurrentSWEEP(ctx);
  }
  drawTools();
}

num getSweeperLength() {
  if (dragIsVertical) {
    return (s1end.x - s2end.x).abs();
  } else {
    return (s1end.y - s2end.y).abs();
  }
}

//TODO: check it worked
String getAreaString() {
  num sweeperLen = getSweeperLength();
  num theArea = (sweeperLen * draggedUnits).abs();
  String toreturn = theArea.toString() ;
  if (hSubTicks > 1 || vSubTicks > 1) {
    num denom = hSubTicks * vSubTicks;
    toreturn = "<sup>" + toreturn + "</sup> &frasl; <sub>" + denom.toString() + "</sub>";
  }
  return toreturn;
}

String getAreaUnitsString() {
  if (hunits_abbreviated == vunits_abbreviated) {
    String squareCode = "\u00B2"; //8729
    return (hunits_abbreviated + squareCode);
  } else {
    String dotCode = "\u2219"; //8729
    return (hunits_abbreviated + dotCode + vunits_abbreviated);
  }
}


void setupDragOriginMemorySETUPSWEEP(Point initPoint) {
  dragOrigin = initPoint;
  rememberPresentSETUPSWEEP();
}

//TODO:  check it worked
void rememberPresentSETUPSWEEP() {
  olds1 = new Point(s1end.x, s1end.y);
  olds2 = new Point(s2end.x, s2end.y);
//  oldpx1 = new Point(getXForHTick(s1end.x), getYForVTick(s1end.y));
//  oldpx2 = new Point(getXForHTick(s2end.x), getYForVTick(s2end.y));  
  oldpx1 = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
  oldpx2 = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));
  oldvtix = vticks;
  oldhtix = hticks;
}

void initInteractionSETUP(Point initPoint) {
  readyToGoOn = true;
  if (sqPixelDistance(initPoint, vhots) < dragThreshold) {
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
  }
}

bool inMiddle(Point mse) {
  //Point one = new Point(getXForHTick(s1end.x), getYForVTick(s1end.y));
  //Point two = new Point(getXForHTick(s2end.x), getYForVTick(s2end.y));
  Point one = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
  Point two = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));
  Point mid = new Point(((one.x + two.x) / 2).round(), ((one.y + two.y) / 2).round());
  if (sqPixelDistance(mse, mid) < 2 * dragThreshold) {
    return true;
  }
  return false;
}


void touchDragSETUP(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;
  draggingSETUP(currPoint);
}

void mouseDragSETUP(MouseEvent event) {
  draggingSETUP(event.offset);
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
    pieceDragOrigin = new Point(pieceDragOrigin.x + (delx * ticwid / hSubTicks), pieceDragOrigin.y + (dely * ticht / vSubTicks) );
    //print("before shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
    draggingPiece.shiftBy(delx, dely);
    //print("after shift by " + delx.toString() + ","  + dely.toString() + "--" + draggingPiece.vertices[0].x.toString()+","+draggingPiece.vertices[0].y.toString());
  }

  drawCUT();
  CanvasRenderingContext2D ctx = canv.context2D;
  draggingPiece.drawAsDragging(ctx);
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
  if (delx.abs() > dely.abs()) {
    dragIsVertical = false;
  } else {
    dragIsVertical = true;
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
    if (new2.x >= 0 && new2.x <= hticks * hSubTicks && new2.y >= 0 && new2.y <= vticks* vSubTicks) {
      s1end = new1;
      s2end = new2;
      draggedUnits = wantToDragSubUnits;
    }
  }
  drawSWEEP();
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
      if (newhticks != hticks && newhticks <= maxhticks && newhticks >= minhticks) {
        updateHSweepsSETUP(newhticks);
        hticks = newhticks;
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
 return new Point(getSubTickCoordForPixelH(mspt.x), getSubTickCoordForPixelV(mspt.y));
}

int getSubTickCoordForPixelH( int px ) {
  return (hSubTicks *  (px - hoff) / (ticwid )).round();
}

int getSubTickCoordForPixelV( int py ) {
  return (vSubTicks *  (py - voff) / (ticht )).round();
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


void overrideFontsForIPAD() {
  print("got here");
  document.querySelectorAll(".popinput").style.font = "20pt sans-serif";
  document.querySelectorAll(".popbutton").style.font = "22pt sans-serif";
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

void stopDragCUT(MouseEvent event) {
  draggingPiece = null;
  drawCUT();
}

void stopTouchCUT(TouchEvent evt) {
  draggingPiece = null;
  drawCUT();
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
  ctxt.fillStyle = "rgba(255, 0, 0, 0.15)";
  if (draggedUnits != 0) {
    if (dragIsVertical) {
      ctxt.fillRect(0, strt.y, hoff, strt2.y - strt.y);
      ctxt.fillRect(strt.x, 0, end.x - strt.x, voff);
    } else {
      ctxt.fillRect(strt.x, 0, strt2.x - strt.x, voff);
      ctxt.fillRect(0, strt.y, hoff, end.y - strt.y);
    }
  }

  if (draggedUnits != 0) {
    //ADD Drag Units to rulers.
    ctxt.strokeStyle = "#000";
    ctxt.fillStyle = "#000";
    ctxt.font = littleCanvasFont;
    ctxt.textAlign = 'center';
    //horizontal

    //TODO:  check it worked.
    String ifFractions = " ";
    if (dragIsVertical) {
      String numToDraw = getSweeperLength().abs().toString();
      if (hSubTicks > 1) {
        numToDraw = "<sup>" + numToDraw + "</sup>";
        ifFractions = " &frasl; <sub>" + hSubTicks.toString() + "</sub>";
      }
      String toDraw = numToDraw + ifFractions + hunits_abbreviated;
      ctxt.fillText(toDraw, ((strt.x + end.x) / 2).round(), 28);
    } else {
      String numToDraw = draggedUnits.abs().toString();
      if (hSubTicks > 1) {
        numToDraw = "<sup>" + numToDraw + "</sup>";
        ifFractions = " &frasl; <sub>" + hSubTicks.toString() + "</sub>";
      }
      String toDraw = numToDraw + ifFractions + hunits_abbreviated;
      ctxt.fillText(toDraw, ((strt.x + strt2.x) / 2).round(), 28);
    }


    ifFractions = " ";
    //vertical
    //TODO: check it worked
    if (dragIsVertical) {
      String numToDraw = draggedUnits.abs().toString();
      if ( vSubTicks > 1) {
        numToDraw = "<sup>" + numToDraw + "</sup>";
        ifFractions = " &frasl; <sub>" + vSubTicks.toString() + "</sub>";
      }
      String toDraw = numToDraw + ifFractions + vunits_abbreviated;
      int ycor = ((strt.y + strt2.y) / 2).round();
      drawVerticalText(ctxt, toDraw, 28, ycor);
    } else {
      String numToDraw = getSweeperLength().abs().toString();
      if (vSubTicks > 1) {
        numToDraw = "<sup>" + numToDraw + "</sup>";
        ifFractions = " &frasl; <sub>" + vSubTicks.toString() + "</sub>";
      }
      String toDraw = numToDraw +  ifFractions + vunits_abbreviated;
      int ycor = ((strt.y + end.y) / 2).round();
      drawVerticalText(ctxt, toDraw, 28, ycor);
    }

  }
}

void drawVerticalText(CanvasRenderingContext2D ctxt, String toDraw, int xc, int yc) {
  ctxt.save();
  ctxt.translate(xc, yc);
  ctxt.rotate(-PI / 2);
  ctxt.fillText(toDraw, 0, 0);
  ctxt.restore();
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

  ctxt.lineWidth = 1;
  ctxt.beginPath();
  ctxt.arc(strt.x, strt.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  ctxt.fillStyle = "#222";
  ctxt.fill();

  ctxt.beginPath();
  ctxt.arc(end.x, end.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  ctxt.fillStyle = "#222";
  ctxt.fill();

  Point mid = new Point(((strt.x + end.x) / 2).round(), ((strt.y + end.y) / 2).round());
  ctxt.beginPath();
  ctxt.arc(mid.x, mid.y, 10, 0, 2 * PI);
  ctxt.closePath();
  ctxt.stroke();
  if (grabbed == "body") {
    ctxt.fillStyle = "#4C4";
    ctxt.fill();
  } else {
    ctxt.fillStyle = "#999";
    ctxt.fill();
  }
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


//************************************************************************************
//SWEEP MODE VERSIONS OF METHODS





//MEASUREMENT FRAME
int getXForHTick(num i) {
  return hoff + (i * ticwid).round();
}

int getXForHSubTick( num i ) {
  return hoff + (i * ticwid / hSubTicks).round();
}

int getYForVTick(num j) {
  return voff + (j * ticht).round();
}

int getYForVSubTick(num j) {
  return voff + (j * ticht / vSubTicks).round();
} 

void drawGrid(CanvasRenderingContext2D ctxt) {
  ctxt.strokeStyle = "#555";

  ctxt.beginPath();
  ctxt.setLineDash([2]);
  ticwid = hrulerwidth / hticks;
  hhots = new Point((hoff + ticwid).round(), voff - 20);
  for (num i = 0; i <= hticks; i++) {
    int x = getXForHTick(i);
    ctxt.moveTo(x, 0);
    ctxt.lineTo(x, canv.height);
  }
  ticht = vrulerheight / vticks;
  vhots = new Point(hoff - 20, (voff + ticht).round());
  for (num j = 0; j <= vticks; j++) {
    int y = getYForVTick(j);
    ctxt.moveTo(0, y);
    ctxt.lineTo(canv.width, y);
  }
  ctxt.closePath();
  ctxt.stroke();
  
  ctxt.beginPath();
  ctxt.strokeStyle = "#30F";
  ctxt.setLineDash([]);
  ctxt.lineWidth = 0.1;
  for (num i = 0; i <= hticks; i++) {
    for (num j = 1; j < hSubTicks; j++) {
      int x1 = getXForHTick(i + j / hSubTicks);
      ctxt.moveTo(x1, 0);
      ctxt.lineTo(x1, canv.height);
    }
  }
  for (num j = 0; j <= vticks; j++) {
    for (num k = 1; k < vSubTicks; k++) {
      int y1 = getYForVTick(j + k / vSubTicks);
      ctxt.moveTo(0, y1);
      ctxt.lineTo(canv.width, y1);
    }
  }
  ctxt.closePath();
  ctxt.stroke();
  ctxt.lineWidth = 1;
  

}

void drawRulers(CanvasRenderingContext2D ctxt) {
  //print("h subdivisions = " + hSubTicks.toString() + ", and v subdivisions = " + vSubTicks.toString());
  ctxt.beginPath();
  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#FA7";
  ctxt.rect(0, voff, 50, vrulerheight);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();
  drawVerticalAxis(ctxt, 50);

  ctxt.beginPath();
  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#FA7";
  ctxt.rect(hoff, 0, hrulerwidth, 50);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();
  drawHorizontalAxis(ctxt, 50);
}


void drawHorizontalAxis(CanvasRenderingContext2D ctxt, int bott) {
  int tsize = 30;
  ctxt.beginPath();
  ctxt.strokeStyle = "#000";

  ticwid = hrulerwidth / hticks;

  hhots = new Point((hoff + ticwid).round(), voff - 25);
  for (num i = 0; i <= hticks; i++) {
    int x = hoff + (i * ticwid).round();
    ctxt.moveTo(x, bott);
    ctxt.lineTo(x, bott - tsize);
    for (num j = 1; j < hSubTicks; j++) {
      int x1 = getXForHTick(i + j / hSubTicks);
      ctxt.moveTo(x1, bott);
      ctxt.lineTo(x1, bott - tsize / 2);
    }
  }
  ctxt.closePath();
  ctxt.stroke();

  if (MODE == 0 || MODE == 1) { //SETUP; show hotspot
    ctxt.beginPath();
    ctxt.arc(hhots.x, hhots.y, 10, 0, 2 * PI);
    ctxt.closePath();
    if (grabbed == "horizontal") {
      ctxt.fillStyle = "#4C4";
      ctxt.fill();
    } else {
      ctxt.fillStyle = "#999";
      ctxt.fill();
    }
    ctxt.stroke();
  }

  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#000";
  ctxt.font = 'italic 16pt sans-serif';
  ctxt.textAlign = 'right';
  ctxt.fillText(hunits_abbreviated, hrulerwidth + hoff / 2, 25);
}

void drawVerticalAxis(CanvasRenderingContext2D ctxt, int right) {
  int tsize = 30;
  ctxt.beginPath();
  ctxt.strokeStyle = "#000";

  ticht = vrulerheight / vticks;
  vhots = new Point(hoff - 25, (voff + ticht).round());
  for (num i = 0; i <= vticks; i++) {
    int y = voff + (i * ticht).round();
    ctxt.moveTo(right, y);
    ctxt.lineTo(right - tsize, y);
    for (num k = 1; k < vSubTicks; k++) {
      int y1 = getYForVTick(i + k / vSubTicks);
      ctxt.moveTo(right, y1);
      ctxt.lineTo(right - tsize / 2, y1);
    }
  }
  ctxt.closePath();
  ctxt.stroke();
  ctxt.beginPath();
  ctxt.arc(vhots.x, vhots.y, 10, 0, 2 * PI);
  ctxt.closePath();

  if (MODE == 0 || MODE == 1) { //SETUP MODE, draw hotspot
    if (grabbed == "vertical") {
      ctxt.fillStyle = "#4C4";
      ctxt.fill();
    } else {
      ctxt.fillStyle = "#999";
      ctxt.fill();
    }
    ctxt.stroke();
  }


  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#000";
  ctxt.font = 'italic 16pt sans-serif';
  ctxt.textAlign = 'left';
  ctxt.save();
  ctxt.translate(25, vrulerheight + voff - 10);
  ctxt.rotate(-PI / 2);
  ctxt.fillText(vunits_abbreviated, 0, 0);
  ctxt.restore();
}
