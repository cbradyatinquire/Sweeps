library sweeps;

import 'dart:html';
import 'dart:math';
import 'dart:core';
import 'dart:async';

import 'package:uuid/uuid.dart';

part "piece.dart";
part "setup.dart";
part "sweep.dart";
part "cut.dart";
part "cavalieri.dart";
part "post.dart";

ImageElement forkedRightButton, rightButton, leftButton;
ImageElement cameraButton, rulerCompareButton, cutSelectedButton, cutSelectedClosedButton, cavalieriButton;
CanvasElement canv, tools;
DivElement splash;
DivElement sCapBook;
int voff = 60;
int hoff = 60;
int vrulerheight, hrulerwidth;

String littleCanvasFont = 'italic 20pt Calibri';
String bigCanvasFont = 'italic 26pt  Calibri';
String overrideHTMLInputFont = "24pt sans-serif";
String overrideHTMLPromptFont = "26pt sans-serif";


bool unitsLocked = false;

bool showArea = false;

//changing and displaying units
String hunits_abbreviated = "in";
//String hunits_full = "horizontal sweep units";

String vunits_abbreviated = "in";
//String vunits_full = "vertical sweep units";

String areaToDisplay = "";

var listenForVerticalUnitsSubmit, listenForHorizontalUnitsSubmit;
ButtonInputElement submitUnitsButton;


int MODE = 0;
var captions = ["Click to start!", "Set up Sweeper & Units", "Drag to Sweep", "Click to Cut; Drag to Arrange", "Tilt to Sweep Down"];
bool readyToGoOn = true;

//relevant to the SETUP mode
var SETUPMouseDown, SETUPTouchStart, SETUPMouseMove, SETUPTouchMove, SETUPMouseUp, SETUPTouchEnd;
num hticks = 20;
num vticks = 15;
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
Point s2end = new Point(5, 7);
Point olds1, olds2, oldpx1, oldpx2;
num oldvtix;
num oldhtix;

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
//for forward/back navigation.
var navigationEvents;
bool hasCut = false;
List<Piece> pieces = new List<Piece>();
Piece draggingPiece = null;
Point pieceDragOrigin;

//Screen captures
List<ImageData> screencaps = new List<ImageData>();
List<String> screens = new List<String>();
List<String> toolsText = new List<String>();
String currentToolsText = "";
int screenPointer = 0;

bool wasInCavalieri = false;
Point screenCapIconCenter = new Point(tools.width / 4, 2 * tools.height / 3);
Point cavalieriCenter = new  Point(3 * tools.width / 4, 2 * tools.height / 3);

bool comparingRulers = false;
int compareRulerAngle = 0;
int compareRulerFrame = 0;



var uuid = new Uuid();
var myUID = uuid.v4();


void testVerticalCutting() {
  /*
   * [Point(3, 1), Point(4, 2), Point(5, 3), Point(4, 4), Point(3, 5), Point(3, 6), Point(4, 7), Point(9, 7), Point(8, 6), Point(8, 5), Point(9, 4), Point(10, 3), Point(9, 2), Point(8, 1)]
   * 
       */
  List<Point> pointsForTestPiece = 
 /*     [new Point(3, 1), new Point(4, 2), new Point(5, 3), new Point(4, 4), new Point(3, 5), new Point(3, 6), 
       new Point(4, 7), new Point(9, 7), new Point(8, 6), new Point(8, 5), new Point(9, 4), new Point(10, 3), new Point(9, 2), new Point(8, 1)];
*/
  /*    
      [new Point(2, 1), new Point(3, 2), new Point(2, 3), new Point(2, 4), new Point(3, 5), new Point(2, 6), 
       new Point(3, 7), new Point(3, 8), new Point(7, 8), new Point(7, 7), new Point(6, 6), new Point(7, 5), 
       new Point(6, 4), new Point(6, 3), new Point(7, 2), new Point(6, 1)];
  */
  [new Point(2, 1), new Point(3, 2), new Point(2, 3), new Point(3, 4), new Point(3, 5), new Point(2, 6), 
   new Point(7, 6), new Point(8, 5), new Point(8, 4), new Point(7, 3), new Point(8, 2), new Point(7, 1)];
  
  Piece testPiece = new Piece(pointsForTestPiece);
  List<Piece> returns = testPiece.cutVerticalCavalieri(3.0);
  print("*************");
  returns.forEach( (piece) => print(piece.vertices.toString() ));
  print("*************");
}

void main() {
  //print(myUID.toString());
  
  //testVerticalCutting();
  
  rightButton = new ImageElement()..src = "images/rightImage.jpg";
  leftButton = new ImageElement()..src = "images/leftImage.jpg";
  forkedRightButton = new ImageElement()..src = "images/forkedRightImage.jpg";
  cameraButton = new ImageElement()..src = "images/screencap.png";
  cavalieriButton = new ImageElement()..src = "images/cavalieri2.png";
  rulerCompareButton = new ImageElement()..src = "images/rulerCompare.png";
  cutSelectedButton = new ImageElement()..src = "images/cutSelected.png";
  cutSelectedClosedButton = new ImageElement()..src = "images/cutSelectedClosed.png";
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
  // document.querySelector("#trashIcon").onMouseUp.listen( deleteScreenCap );
  // document.querySelector("#trashIcon").onTouchEnd.listen( deleteScreenCap );
  document.querySelector("#trashIcon").onClick.listen(deleteScreenCap);

  // document.querySelector("#closeIcon").onMouseUp.listen( closeScreenCapWindow );
//  document.querySelector("#closeIcon").onTouchEnd.listen( closeScreenCapWindow );
  document.querySelector("#closeIcon").onClick.listen(closeScreenCapWindow);


  //document.querySelector("#screencap").onMouseUp.listen( MOUSEforwardOrBackInScreens );
  //document.querySelector("#screencap").onTouchEnd.listen( TOUCHforwardOrBackInScreens );
  document.querySelector("#screencap").onClick.listen( MOUSEforwardOrBackInScreens );
  document.querySelector("#leftIcon").onClick.listen(MOUSEbackInScreens);
  document.querySelector("#rightIcon").onClick.listen(MOUSEforwardInScreens);

}

void testSwitchMode(MouseEvent e) {
  int rbound = tools.width - 2 * tools.height;
  int lbound = tools.height * 2;

  int screenCapIconTolerance = 40;
  int cavalieriButtonTolerance = 64;
  if (e.offset.x > rbound && MODE < 3) { //we're in the right arrow
    if (readyToGoOn) {
      MODE++;
      readyToGoOn = false;
      if (MODE == 3) {
        if (e.offset.y < (tools.height / 2)) {
          cutFlavor = "all";
          hasCut = false;
          doModeSpecificLogic();
        } else {
          cutFlavor = "selected";
          hasCut = true;
          setCutPoints();
          doModeSpecificLogic();
        }
      } else {
        doModeSpecificLogic();
      }
    }
  } else if (e.offset.x > rbound && MODE == 4 ) {
    MODE = 3; 
    animLoopTimer.cancel();
    goOnFromCavalieri(e.offset.y);
  } else if (e.offset.x < lbound) { //we're in the left arrow
    if (MODE == 4) {
      MODE = 1;
      readyToGoOn = false;
      draggedUnits = 0;
      animLoopTimer.cancel();
      doModeSpecificLogic();
    } else if (MODE > 1) {
      MODE--;
      if (wasInCavalieri) { 
        MODE = 1;
        wasInCavalieri = false;
        hasCut = false;
      }
      readyToGoOn = false;
      draggedUnits = 0;
      doModeSpecificLogic();
    } else if (MODE == 1) {
      window.location.reload();
    }
  } else if (e.offset.distanceTo(screenCapIconCenter) < screenCapIconTolerance) {
    addScreenCap();
    openScreenCapsWindow();
  } else if (MODE==1) {
    if (  (e.offset.x - cavalieriCenter.x < cavalieriButtonTolerance) && (e.offset.y > tools.height / 3)  ) {
      MODE = 4;
      doModeSpecificLogic();
    }
  } else if (MODE==2 || MODE==4) {
    if (  (e.offset.x - cavalieriCenter.x < cavalieriButtonTolerance) && (e.offset.y > tools.height / 3)  ) {
      showArea = !showArea;
      //drawSWEEP();
      drawTools();
    }
  }
}



void goOnFromCavalieri(int yclickvalue) {
  wasInCavalieri = true;

  if (mouseDownSubscription != null && !mouseDownSubscription.isPaused ) {
    mouseDownSubscription.pause();
    mouseUpSubscription.pause();
    mouseMoveSubscription.pause();
  }
  
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

     if (CUTMouseDown.isPaused) {
       CUTMouseDown.resume();
       CUTTouchStart.resume();
       CUTMouseMove.resume();
       CUTTouchMove.resume();
       CUTMouseUp.resume();
       CUTTouchEnd.resume();
     }
     
     //FOR CUTTING CAVALIERI WITH GRID POINTS MANUALLY.
     if (yclickvalue < (tools.height / 2)) {
       cutFlavor = "all";
       hasCut = false;
     } else {
       cutFlavor = "selected";
       hasCut = true;
     }
     setCutPoints();
    

     List<Point> gridPoints = new List<Point>();
     for (int i = 0; i<t1s.length; i++ ) {
         gridPoints.add(t1s[i]);
       }
       for (int j = t2s.length - 1; j>=0; j-- ) {
         gridPoints.add(t2s[j]);
       }
     //gridPoints.add(t1s[0]);
     
     pieces.clear();
     Piece whole = new Piece(gridPoints);
     pieces.add(whole);
     
     drawCUT();
     drawTools();
}

void addScreenCap() {
  //ImageData imageData = canv.context2D.getImageData(0,0,canv.width,canv.height);
  String base64Cap = canv.toDataUrl("image/png");
  
  //screencaps.add(imageData);
  screens.add(base64Cap);
  toolsText.add(currentToolsText);
  postImageData(canv, currentToolsText);
}

void closeScreenCapWindow(var event) {
  document.querySelector("#screenCapDiv").style.visibility = "hidden";
  resumeEventsForScreenCapsWindow();
}

void deleteScreenCap(var event) {
  screens.removeAt(screenPointer);
  toolsText.removeAt(screenPointer);
  if (screens.length == 0) {
    closeScreenCapWindow(event);
  } else {
    changeScreen(0);
  }
}


void MOUSEforwardOrBackInScreens(MouseEvent me) {
  Point clickPoint = me.client;
  doFwdBackLogic(clickPoint);
}

void MOUSEforwardInScreens(MouseEvent me ) {
  changeScreen(1);
}
void MOUSEbackInScreens(MouseEvent me ) {
  changeScreen(-1);
}

void TOUCHforwardOrBackInScreens(TouchEvent evt) {
  Point clickPoint = evt.changedTouches[0].client;
  doFwdBackLogic(clickPoint);
}


void doFwdBackLogic(Point clickPoint) {
  if (clickPoint.x > (2 * document.querySelector("#screencap").clientWidth / 3)) {
    changeScreen(1);
  } else if (clickPoint.x < (document.querySelector("#screencap").clientWidth / 3)) {
    changeScreen(-1);
  }
}

void changeScreen(int del) {
  screenPointer = screenPointer + del;
  if (screenPointer >= screens.length) {
    screenPointer = 0;
  } else if (screenPointer < 0) {
    screenPointer = screens.length - 1;
  }
  loadScreen(document.querySelector("#screencap"));
}

void loadScreen(CanvasElement sc) {
  ImageElement i = new ImageElement();
  i.src = screens[screenPointer];
  i.onLoad.listen((e) {
    SpanElement numLabel = document.querySelector("#screennum");
    numLabel.innerHtml = (screenPointer + 1).toString() + " of " + screens.length.toString();

    DivElement bottomLabel = document.querySelector("#toolstext");
    bottomLabel.innerHtml = toolsText[screenPointer];

    sc.context2D.clearRect(0, 0, sc.width, sc.height);

    sc.context2D.drawImageScaled(i, 0, 0, sc.width, sc.height);
  });
}



void openScreenCapsWindow() {
  DivElement scpop = document.querySelector("#screenCapDiv");
  DivElement topstuff = document.querySelector("#topbar");
  DivElement botstuff = document.querySelector("#bottombar");
  scpop.style.visibility = "visible";
  CanvasElement sc = document.querySelector("#screencap");
  sc.width = scpop.clientWidth;
  sc.height = scpop.clientHeight - topstuff.clientHeight - botstuff.clientHeight;
  loadScreen(sc);
  screenPointer = screens.length - 1;
  pauseEventsForScreenCapsWindow();
  changeScreen(0);
}


void pauseEventsForScreenCapsWindow() {
  //print("Pausing nav");
  navigationEvents.pause();
  if (MODE == 1) {
      SETUPMouseDown.pause();
      SETUPTouchStart.pause();
      SETUPMouseMove.pause();
      SETUPTouchMove.pause();
      SETUPMouseUp.pause();
      SETUPTouchEnd.pause();
    }

    if (MODE == 2) {
      SWEEPMouseDown.pause();
      SWEEPTouchStart.pause();
      SWEEPMouseMove.pause();
      SWEEPTouchMove.pause();
      SWEEPMouseUp.pause();
      SWEEPTouchEnd.pause();
    }
  
  if (MODE == 3) {
      CUTMouseDown.pause();
      CUTTouchStart.pause();
      CUTMouseMove.pause();
      CUTTouchMove.pause();
      CUTMouseUp.pause();
      CUTTouchEnd.pause();  
  }
}

void resumeEventsForScreenCapsWindow() {
  //print("resuming nav");
  navigationEvents.resume();
  if (MODE == 1) {
        SETUPMouseDown.resume();
        SETUPTouchStart.resume();
        SETUPMouseMove.resume();
        SETUPTouchMove.resume();
        SETUPMouseUp.resume();
        SETUPTouchEnd.resume();
      }

      if (MODE == 2) {
        SWEEPMouseDown.resume();
        SWEEPTouchStart.resume();
        SWEEPMouseMove.resume();
        SWEEPTouchMove.resume();
        SWEEPMouseUp.resume();
        SWEEPTouchEnd.resume();
      }
    
    if (MODE == 3) {
        CUTMouseDown.resume();
        CUTTouchStart.resume();
        CUTMouseMove.resume();
        CUTTouchMove.resume();
        CUTMouseUp.resume();
        CUTTouchEnd.resume();  
    }
}


//response to forward back buttons, once the MODE value has been switched.
void doModeSpecificLogic() {
  //print("MODE = " + MODE.toString());
  if (MODE == 1) {
    if (SETUPMouseDown.isPaused) {
      SETUPMouseDown.resume();
      SETUPTouchStart.resume();
      SETUPMouseMove.resume();
      SETUPTouchMove.resume();
      SETUPMouseUp.resume();
      SETUPTouchEnd.resume();
      showArea = false;
    }

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
  if (MODE == 4) {
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
    
    if (!CUTMouseDown.isPaused) {
      CUTMouseDown.pause();
      CUTTouchStart.pause();
      CUTMouseMove.pause();
      CUTTouchMove.pause();
      CUTMouseUp.pause();
      CUTTouchEnd.pause();
    }
    
    if (ss != null && ss.isPaused){
      ss.resume();
    }
    startCavalieriLoop();
    
    drawCavalieri();
    drawTools();
  }
}



//FOR ALL MODES
void startUp(MouseEvent event) {
  doEventSetup();
  MODE = 1;
  navigationEvents = tools.onMouseDown.listen(testSwitchMode);
  splash.style.opacity = "0.0";
  splash.style.zIndex = "-1";

  drawSETUP();
  drawTools();
  
   makeVEqualToH();
   unitsLocked = true;
   
   drawSETUP();
   drawTools();
}

void drawStatus(CanvasRenderingContext2D ctx) {
  ctx.strokeStyle = "#000";
  ctx.fillStyle = "#000";
  ctx.font = bigCanvasFont;
  ctx.textAlign = 'center';
  if (((MODE == 1 || MODE == 2) && draggedUnits != 0) || (MODE == 3 && hasCut)) {
    if (wasInCavalieri) { 
      num denom = hSubTicks * vSubTicks;
      String fracString = " ";
      if (denom != 1) {
        fracString = "/" + denom.toString() + " ";
      }
      areaToDisplay = cavalieriArea.toString() + fracString + getAreaUnitsString(); 
    }
    currentToolsText = "Area swept";
    if (showArea) {
      currentToolsText += ": " + areaToDisplay;
    }
  } else if (MODE == 4 && cavalieriHeight > 0) {
    num denom = hSubTicks * vSubTicks;
    String fracString = " ";
    if (denom != 1) {
      fracString = "/" + denom.toString() + " ";
    }
    
    currentToolsText = "Area swept";
    if (showArea) {
      currentToolsText += ": " + cavalieriArea.toString() + fracString + getAreaUnitsString();
    }
  } else {
    currentToolsText = captions[MODE];
  }

  ctx.fillText(currentToolsText, tools.width / 2, tools.height / 2); // 2 * tools.height / 3);
  ctx.drawImageScaled(cameraButton, screenCapIconCenter.x - 32, screenCapIconCenter.y - 32, 64, 64);
  
  if (MODE == 1 && s1end.y == s2end.y) { 
    ctx.drawImageScaled(cavalieriButton, cavalieriCenter.x - 49, cavalieriCenter.y - 28, 98, 56);
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
  if ( (MODE == 2 && readyToGoOn) || (MODE==4 && cavalieriHeight > 0 ) ){
    ctx.drawImageScaled(forkedRightButton, tools.width - imwid, 0, imwid, imht);
  }
  
  if (MODE < 2 && readyToGoOn) {
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




void updateSweeperHPoints(int oldval, int newval) {
  s1end = new Point((newval * s1end.x / oldval).round(), s1end.y);
  s2end = new Point((newval * s2end.x / oldval).round(), s2end.y);
}

void updateSweeperVPoints(int oldval, int newval) {
  s1end = new Point(s1end.x, (newval * s1end.y / oldval).round());
  s2end = new Point(s2end.x, (newval * s2end.y / oldval).round());
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
  String toreturn = theArea.toString();
  if (hSubTicks > 1 || vSubTicks > 1) {
    num denom = hSubTicks * vSubTicks;
    toreturn = toreturn + " / " + denom.toString() + " ";
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


num getGridCoordForPixelH(int px) {
  return (hSubTicks * (px - hoff) / (ticwid));
}

num getGridCoordForPixelV(int py) {
  return (vSubTicks * (py - voff) / (ticht));
}

int getSubTickCoordForPixelH(int px) {
  return (hSubTicks * (px - hoff) / (ticwid)).round();
}

int getSubTickCoordForPixelV(int py) {
  return (vSubTicks * (py - voff) / (ticht)).round();
}


void overrideFontsForIPAD() {
  print("got here");
  document.querySelectorAll(".popinput").style.font = "20pt sans-serif";
  document.querySelectorAll(".popbutton").style.font = "22pt sans-serif";
}



void drawVerticalText(CanvasRenderingContext2D ctxt, String toDraw, int xc, int yc) {
  ctxt.save();
  ctxt.translate(xc, yc);
  ctxt.rotate(-PI / 2);
  ctxt.fillText(toDraw, 0, 0);
  ctxt.restore();
}



//MEASUREMENT FRAME
int getXForHTick(num i) {
  return hoff + (i * ticwid).round();
}

int getXForHSubTick(num i) {
  return hoff + (i * ticwid / hSubTicks).round();
}

int getYForVTick(num j) {
  return voff + (j * ticht).round();
}

int getYForVSubTick(num j) {
  return voff + (j * ticht / vSubTicks).round();
}

void drawGrid(CanvasRenderingContext2D ctxt) {
  //ctxt.strokeStyle = "#555";
  ctxt.strokeStyle = "#222";

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
  ctxt.strokeStyle = "#000";  //#30F
  ctxt.setLineDash([]);
  ctxt.lineWidth = 0.2;  //.1
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
  } else if (MODE == 3 && cutFlavor == "selected") {
    ctxt.beginPath();
    ctxt.moveTo(hcuts.x, hcuts.y);
    ctxt.lineTo(hcuts.x, hcuts.y + vrulerheight);
    ctxt.moveTo(hcuts.x - 10, hcuts.y - 10);
    ctxt.rect(hcuts.x - 10, hcuts.y - 10, 20, 20); //(hcuts.x, hcuts.y, 10, 0, 2 * PI);
    ctxt.closePath();
    if (cutGrabbed == "horizontal") {
      ctxt.fillStyle = "#7F4";
      ctxt.strokeStyle = "#7F4";
      ctxt.fill();
    } else {
      ctxt.fillStyle = "#999";
      ctxt.strokeStyle = "#000";
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
  

  if (MODE == 0 || MODE == 1) { //SETUP MODE, draw hotspot
    
    if (unitsLocked == false) {
      ctxt.beginPath();
      ctxt.arc(vhots.x, vhots.y, 10, 0, 2 * PI);
      ctxt.closePath();
      if (grabbed == "vertical") {
        ctxt.fillStyle = "#4C4";
        ctxt.fill();
      } else {
        ctxt.fillStyle = "#999";
        ctxt.fill();
      }
      ctxt.stroke();
    }
  } else if (MODE == 3 && cutFlavor == "selected") {
    ctxt.beginPath();
    ctxt.moveTo(vcuts.x, vcuts.y);
    ctxt.lineTo(vcuts.x + hrulerwidth, vcuts.y);
    ctxt.moveTo(vcuts.x - 10, vcuts.y - 10);
    ctxt.rect(vcuts.x - 10, vcuts.y - 10, 20, 20);
    ctxt.closePath();
    if (cutGrabbed == "vertical") {
      ctxt.fillStyle = "#7F4";
      ctxt.strokeStyle = "#7F4";
      ctxt.fill();
    } else {
      ctxt.fillStyle = "#999";
      ctxt.strokeStyle = "#000";
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

void drawHorizontalAxisCompare(CanvasRenderingContext2D ctxt, int bott) {
  int tsize = 30;

  ctxt.save();
  ctxt.translate(hoff, bott);
  ctxt.rotate(compareRulerAngle * (PI / 180));
  ctxt.beginPath();
  ctxt.strokeStyle = "#000";

  ctxt.fillStyle = "#FA7";
  ctxt.rect(0, -50, hrulerwidth, 50);
  ctxt.fillRect(0, -50, hrulerwidth, 50);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();

  ctxt.beginPath();
  ticwid = hrulerwidth / hticks;


  for (num i = 0; i <= hticks; i++) {
    int x = 0 + (i * ticwid).round();
    ctxt.moveTo(x, tsize / 2);
    ctxt.lineTo(x, 0 - tsize);
  }
  ctxt.moveTo(0, 0);
  ctxt.lineTo((hticks * ticwid).round(), 0);
  ctxt.closePath();
  ctxt.stroke();
  ctxt.restore();
}

void drawVerticalAxisCompare(CanvasRenderingContext2D ctxt, int right) {
  int tsize = 30;
  ctxt.save();
  ctxt.translate(right, voff);
  ctxt.rotate(compareRulerAngle * (-PI / 180));
  ctxt.beginPath();
  ctxt.strokeStyle = "#000";
  ctxt.fillStyle = "#FA7";
  ctxt.rect(-50, 0, 50, vrulerheight * 1.5);
  ctxt.fillRect(-50, 0, 50, vrulerheight * 1.5);
  ctxt.closePath();
  ctxt.fill();
  ctxt.stroke();

  ctxt.beginPath();
  ticht = vrulerheight / vticks;

  for (num i = 0; i <= (vticks * 1.5); i++) {
    int y = 0 + (i * ticht).round();
    ctxt.moveTo(tsize / 2, y);
    ctxt.lineTo(0 - tsize, y);
  }
  ctxt.moveTo(0, 0);
  ctxt.lineTo(0, (vticks * ticht * 1.5).round());
  ctxt.closePath();
  ctxt.stroke();
  ctxt.restore();
}
