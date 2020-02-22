library sweeps;

import 'dart:html';
import 'dart:math';
import 'dart:core';
import 'dart:async';

import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'dart:js';


part "piece.dart";
part "setup.dart";
part "sweep.dart";
part "cut.dart";
part "cavalieri.dart";
part "post.dart";
part "tests.dart";
part "parsingInput.dart";
part "Geoboard.dart";
part "ModeManagingMethods.dart";



ImageElement forkedRightButton, rightButton, leftButton, rotateButtonUpState, rotateButtonDownState, reflectButtonUpState, reflectButtonDownState;
ImageElement cameraButton, rulerCompareButton, cutSelectedButton, cutSelectedClosedButton, cavalieriButton;
CanvasElement canv, tools;
DivElement splash;
DivElement sCapBook;
int voff = 60; // controls placement of dark orange vertical margin
int hoff = 60; // controls placement of dark orrange horizontal margin
int vrulerheight, hrulerwidth;

String littleCanvasFont = 'italic 20pt Calibri';
String bigCanvasFont = 'italic 26pt  Calibri';
String overrideHTMLInputFont = "24pt sans-serif";
String overrideHTMLPromptFont = "26pt sans-serif";
String className;


bool unitsLocked = false;
bool willPost = true;

bool showArea = false; // (in the text below the sweeping environment)

//changing and displaying units
String hunits_abbreviated = "in";
//String hunits_full = "horizontal sweep units";

String vunits_abbreviated = "in";
//String vunits_full = "vertical sweep units";

String areaToDisplay = "";

var listenForVerticalUnitsSubmit, listenForHorizontalUnitsSubmit;
ButtonInputElement submitUnitsButton;

ButtonInputElement submitScreenCapButton, cancelScreenCapButton;
var listenForSubmitScreenCap, listenForCancelScreenCap;
TextInputElement usernameBox, commentTextBox;


int MODE = 0;
var captions = ["Click to start!", "Set up Sweeper & Units", "Drag to Sweep", "Click to Cut; Drag to Arrange", "Tilt to Sweep Down", "Construct Shapes to Dissect", "Click to Rotate; Drag to Arrange"];
bool readyToGoOn = true;
// MODES:
// 0: initial state
// 1: Setup
// 2: Sweeping
// 3: Cutting
// 4: Cavalieri
// 5: Geoboard

int MODEAfterSetup;

JsObject input = context['arguments'];
bool rotationsAllowed = input['rotationsAllowed'];
bool reflectionsAllowed = input['reflectionsAllowed'];

String inputVertices = input['vertices'];

Point inputPoint1, inputPoint2;
List<Piece> inputPieces;
List<List<num>> colorsOfPieces;


//relevant to the SETUP mode
var SETUPMouseDown, SETUPTouchStart, SETUPMouseMove, SETUPTouchMove, SETUPMouseUp, SETUPTouchEnd;
num hticks = 20;      //****CHANGE HERE FOR GRID CHANGES....
num vticks = 15;    //****CHANGE HERE FOR GRID CHANGES....
int hSubTicks = 2;    //****CHANGE HERE FOR GRID CHANGES....
int vSubTicks = 2;    //****CHANGE HERE FOR GRID CHANGES....
int maxhticks = 24;
int maxvticks = 15;
int minhticks = 2; //9;
int minvticks = 2; //6;

//tick width and height (for displaying the grid)
double ticwid;
double ticht;

// setup of the endpoints for the initial state of the squeegee
Point s1end = new Point(2, 3);
Point s2end = new Point(5, 7);

//variables for remembering the state of the system used in the method rememberPresentSETUPSWEEP()
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
bool dragIsVertical = true; //false => that the drag is horizontal (logic for this in sweep.dart)
int draggedUnits = 0; // also used in sweep.dart

//relevant to the CUT mode
var CUTMouseDown, CUTTouchStart, CUTMouseMove, CUTMouseGetRotationPoint, CUTTouchGetRotationPoint, CUTTouchMove, CUTMouseUp, CUTTouchEnd;
List<Piece> originalPieces;
//for forward/back navigation.
var navigationEvents;
bool hasCut = false;
List<Piece> pieces = new List<Piece>();
Piece draggingPiece = null;
Point pieceDragOrigin;

bool doingRotation = false;
int indexSelectedForRotation = -1;

bool doingReflection = false;

// relevant only to the Cavalieri mode
StreamSubscription<DeviceMotionEvent> TabletTiltSensorCav; // for tablets
var mouseDownCav, mouseMoveCav, mouseUpCav; // for computers


// relevant only to the geoboard
var GEOMouseDown, GEOTouchStart, GEOMouseMove, GEOTouchMove, GEOMouseUp, GEOTouchEnd;

//Screen captures
List<ImageData> screencaps = new List<ImageData>();
List<String> screens = new List<String>();
List<String> toolsText = new List<String>();
String currentToolsText = "";
int screenPointer = 0;

bool wasInCavalieri = false;
Point screenCapIconCenter = new Point(max(tools.width / 4, tools.height * 2), 2 * tools.height / 3); // 2 * tools.height is the offset of the arrow buttons
Point cavalieriCenter = new Point(3 * tools.width / 4, 2 * tools.height / 3);

bool comparingRulers = false;
int compareRulerAngle = 0;
int compareRulerFrame = 0;



var uuid = new Uuid();
var myUID = uuid.v4();

void modePrint() {
  print(MODE.toString());
}


void main() {
  rightButton = new ImageElement()..src = "images/rightImage.jpg";
  leftButton = new ImageElement()..src = "images/leftImage.jpg";
  forkedRightButton = new ImageElement()..src = "images/forkedRightImage.jpg";
  cameraButton = new ImageElement()..src = "images/screencap.png";
  cavalieriButton = new ImageElement()..src = "images/cavalieri2.png";
  rulerCompareButton = new ImageElement()..src = "images/rulerCompare.png";
  cutSelectedButton = new ImageElement()..src = "images/cutSelected.png";
  cutSelectedClosedButton = new ImageElement()..src = "images/cutSelectedClosed.png";
  rotateButtonDownState = new ImageElement()..src = "images/rotateDown.png";
  rotateButtonUpState = new ImageElement()..src = "images/rotateUp.png";

  //****CHANGE THESE TO QUINLEY'S IMAGES.
  reflectButtonDownState = new ImageElement()..src = "images/reflectDown.png";
  reflectButtonUpState = new ImageElement()..src = "images/reflectUp.png";

  canv = querySelector("#scanvas");
  tools = querySelector("#tcanvas");
  splash = querySelector("#splashdiv");
  submitUnitsButton = document.querySelector("#submitUnit");
  submitScreenCapButton = document.querySelector("#submitPost");
  cancelScreenCapButton = document.querySelector("#cancelPost");

  manageInputs();
  manageWebpageInput(); // can react to outside requests to change the state
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
  CUTMouseGetRotationPoint = canv.onMouseMove.listen(mouseGetRotationPoint);
  CUTTouchGetRotationPoint = canv.onTouchMove.listen(touchGetRotationPoint);
  CUTMouseUp = canv.onMouseUp.listen(stopDragCUT);
  CUTTouchEnd = canv.onTouchEnd.listen(stopTouchCUT);

  //Cav MODE EVENTS
  TabletTiltSensorCav = window.onDeviceMotion.listen((DeviceMotionEvent e) {
    ax = e.accelerationIncludingGravity.x;
    ay = e.accelerationIncludingGravity.y;
    az = e.accelerationIncludingGravity.z;
    numDeviceMotionEvents++;
  });

  TabletTiltSensorCav.pause();
  numDeviceMotionEvents = 0;

  mouseDownCav = canv.onMouseDown.listen(CavMouseDown);
  mouseUpCav = canv.onMouseUp.listen(CavMouseUp);
  mouseMoveCav = canv.onMouseMove.listen(CavMouseMove);

  mouseDownCav.pause();
  mouseUpCav.pause();
  mouseMoveCav.pause();


  //unit change dialog events
  submitUnitsButton = document.querySelector("#submitUnit");
  listenForHorizontalUnitsSubmit = submitUnitsButton.onClick.listen(getHorizUnits);
  listenForVerticalUnitsSubmit = submitUnitsButton.onClick.listen(getVerticalUnits);
  listenForHorizontalUnitsSubmit.pause();
  listenForVerticalUnitsSubmit.pause();

  //Pause the SWEEP mode events because we start in SETUP mode
  TurnOffSWEEP();

  //Pause the CUT mode events because we start in SETUP mode
  TurnOffCUT();

  //relevant only to Geoboard
  GEOMouseDown = canv.onMouseDown.listen(startDragGEO);
  GEOTouchStart = canv.onTouchStart.listen(startTouchGEO);
  GEOMouseMove = canv.onMouseMove.listen(mouseDragGEO);
  GEOTouchMove = canv.onTouchMove.listen(touchDragGEO);
  GEOMouseUp = canv.onMouseUp.listen(stopDragGEO);
  GEOTouchEnd = canv.onTouchEnd.listen(stopTouchGEO);

  TurnOffGEO();


  //Post events
  listenForSubmitScreenCap = submitScreenCapButton.onClick.listen(goOnWithScreenCap);
  listenForCancelScreenCap = cancelScreenCapButton.onClick.listen(cancelScreenCap);
  listenForCancelScreenCap.pause();
  listenForSubmitScreenCap.pause();

  //set up mouse actions on the screen capture dialog.
  document.querySelector("#trashIcon").onClick.listen(deleteScreenCap);

  document.querySelector("#closeIcon").onClick.listen(closeScreenCapWindow);

  document.querySelector("#screencap").onClick.listen( MOUSEforwardOrBackInScreens );
  document.querySelector("#leftIcon").onClick.listen(MOUSEbackInScreens);
  document.querySelector("#rightIcon").onClick.listen(MOUSEforwardInScreens);

}

void testSwitchMode(MouseEvent e) {
  int rbound = tools.width - 2 * tools.height;
  int r2bound = tools.width - 4 * tools.height;
  int lbound = tools.height * 2;

  int screenCapIconTolerance = (tools.height / 2.0).round();
  int cavalieriButtonTolerance = 64;

  if (e.offset.x > rbound && MODE == 3 && rotationsAllowed && hasCut) { // want to do a rotation
    if (doingRotation) {
      doingRotation = false;
      indexSelectedForRotation = -1;
      doingReflection = false;
      flipGrabbed = "none";
      activeDragging = "none";
    }
    else {
      doingRotation = true;
      doingReflection = false;
      flipGrabbed = "none";
      activeDragging = "none";
    }
    drawCUT();
    drawTools();
  }

  if (e.offset.x > r2bound && e.offset.x < rbound && MODE == 3 && reflectionsAllowed && hasCut) { // want to do a rotation
    if (doingReflection) {
      doingReflection = false;
      flipGrabbed = "none";
      activeDragging = "none";
      doingRotation = false;
      indexSelectedForRotation = -1;
    }
    else {
      doingReflection = true;
      flipGrabbed = "none";
      activeDragging = "none";
      doingRotation = false;
      indexSelectedForRotation = -1;
    }
    drawCUT();
    drawTools();
  }


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
  } else if (e.offset.x > rbound && MODE == 5) {
    MODE = 3;
    //  if (e.offset.y < (tools.height / 2)) {
    //    cutFlavor = "all";
    //    hasCut = false;
    //    doModeSpecificLogic();
    //  } else {
    cutFlavor = "selected";
    hasCut = true;
    setCutPoints();
    doModeSpecificLogic();
    //  }

    originalPieces = copy(pieces);
    doModeSpecificLogic();
  } else if ((e.offset.x > rbound && MODE == 4) && t1s.length > 1) {
    MODE = 3; 
    animLoopTimer.cancel();
    goOnFromCavalieri(e.offset.y);
  } else if (e.offset.x < lbound) { //we're in the left arrow
    if (MODE == 1) { // setup -> unchanged
      // do nothing
    }
    else if (MODE == 2) { // sweeping -> setup / sweeping -> unchanged
      if (MODEAfterSetup != 2 && draggedUnits == 0) {
        MODE = 1;

        if (dragIsVertical) {
          s1end = new Point(s1end.x, s1end.y - draggedUnits);
          s2end = new Point(s2end.x, s2end.y - draggedUnits);
        }
        else {
          s1end = new Point(s1end.x - draggedUnits, s1end.y);
          s2end = new Point(s2end.x - draggedUnits, s2end.y);
        }

        doModeSpecificLogic();
      }
      else {
        if (dragIsVertical) {
          s1end = new Point(s1end.x, s1end.y - draggedUnits);
          s2end = new Point(s2end.x, s2end.y - draggedUnits);
        }
        else {
          s1end = new Point(s1end.x - draggedUnits, s1end.y);
          s2end = new Point(s2end.x - draggedUnits, s2end.y);
        }
        doModeSpecificLogic();
      }
    }
    else if (MODE == 3) { // cut -> cut / cut -> cav / cut -> geo / cut -> setup (after cav from setup)/ cut -> sweep
      if (MODEAfterSetup == 3 || notACopy(pieces, originalPieces)) {
        pieces = copy(originalPieces);
        if (cutFlavor == "all") {
          hasCut = false;
        }
        drawCUT();
      }
      else if (MODEAfterSetup == 5) {
        pieces = copy(originalPieces);
        MODE = 5;
        doModeSpecificLogic();
      }
      else if (wasInCavalieri) {
       MODE = 4;
       hasCut = false;

       startCavalieriLoopNotFromScrach();
      }
      else {
        MODE = 2;

        Point a = originalPieces[0].vertices[0];
        Point b = originalPieces[0].vertices[1];
        Point c = originalPieces[0].vertices[2];
        Point d = originalPieces[0].vertices[3];

        s1end = new Point(c.x, c.y);
        s2end = new Point(d.x, d.y);

        doModeSpecificLogic();

        s1end = a;
        s2end = b;

        num difx = b.x - c.x;
        num dify = b.y - c.y;

        if (difx == 0) {
          dragIsVertical = true;
          draggedUnits = dify;
        }
        else {
          dragIsVertical = false;
          draggedUnits = difx;
        }
        grabbed = "done";
        drawSWEEP();
      }
    }
    else if (MODE == 4) { // cav -> cav / cav -> setup
      if (t1s.length > 1) {
        t1s.removeLast();
        t2s.removeLast();
        s1end = t1s.last;
        s2end = t2s.last;
        drawCavalieri();
      }
      else {
        if (MODEAfterSetup != 4) {
          TurnOffCav();
          MODE = 1;
          draggedUnits = 0;
          pieces = new List<Piece>();
          originalPieces = new List<Piece>();
          doModeSpecificLogic();
        }
      }
    }
    else if (MODE == 5) { // geo -> geo
      pieces = copy(originalPieces);
      drawGEO();
    }
  }
  else if (e.offset.distanceTo(screenCapIconCenter) < screenCapIconTolerance) {
    getUserInput();
  } else if (MODE==1 && s1end.y == s2end.y) {  //THIS is where i block accidental cavalieri
    if (  ((e.offset.x - cavalieriCenter.x).abs() < 2 * cavalieriButtonTolerance) && (e.offset.y > tools.height / 3)  ) {
      MODE = 4;
      doModeSpecificLogic();
    }
  } else if (MODE==2 || MODE==4 || (MODE == 3 && hasCut)) {
    //not sure that 2 or 4 is the right set.  adding MODE == 3 && hasCut
    if (  ((e.offset.x - tools.width / 2).abs()  < 2  * cavalieriButtonTolerance) && (e.offset.y > tools.height / 3)  ) {
      showArea = !showArea;
      //drawSWEEP();
      drawTools();
    }
  }
  if ( MODE==5 ) { // && reflectionsAllowed == true) {
    if (  ((e.offset.x - tools.width / 2).abs()  < 2  * cavalieriButtonTolerance) && (e.offset.y > tools.height / 3)  ) {
      print("would export vertex list");
      print ( exportVertexList() );
    }
  }
}


void getUserInput() {
  pauseEventsForScreenCapsWindow();

  document.querySelector("#popupDivToPost").style.visibility = "visible";

  commentTextBox = document.querySelector("#descriptionToPost");
  usernameBox = document.querySelector("#usernameToPost");

  listenForCancelScreenCap.resume();
  listenForSubmitScreenCap.resume();
}

void goOnWithScreenCap(MouseEvent e) {
  document.querySelector("#popupDivToPost").style.visibility = "hidden";
  listenForCancelScreenCap.pause();
  listenForSubmitScreenCap.pause();

  String comments = commentTextBox.value;
  String username = usernameBox.value;

  List<String> toSend = new List<String>();
  toSend.add(username);
  toSend.add(comments);

  commentTextBox.value = "";

  addScreenCap(toSend);
  openScreenCapsWindow();
}

void cancelScreenCap(MouseEvent e) {
  document.querySelector("#popupDivToPost").style.visibility = "hidden";
  listenForCancelScreenCap.pause();
  listenForSubmitScreenCap.pause();

  resumeEventsForScreenCapsWindow();
}

void goOnFromCavalieri(int yclickvalue) {
  wasInCavalieri = true;

  //animLoopTimer.cancel();

  if (mouseDownCav != null && !mouseDownCav.isPaused ) {
    TurnOffCav();
  }
  
  if (!SETUPMouseDown.isPaused) {
    TurnOffSETUP();
  }

  if (!SWEEPMouseDown.isPaused) {
    TurnOffSWEEP();
  }

  if (CUTMouseDown.isPaused) {
    TurnOnCUT();
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
  originalPieces = copy(pieces);

  drawCUT();
  drawTools();
}

void addScreenCap(List<String> annotations) {
  //ImageData imageData = canv.context2D.getImageData(0,0,canv.width,canv.height);
  String base64Cap = canv.toDataUrl("image/png");
  
  //screencaps.add(imageData);
  screens.add(base64Cap); // Two lists, one of screenshots & one of captions
  toolsText.add(annotations[0] + ": " + annotations[1]);
  if (willPost) {
    postImageData(canv, annotations); // posting newest addition to webpage
  }
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
  changeScreen(0);


}


void pauseEventsForScreenCapsWindow() {
  //print("Pausing nav");
  navigationEvents.pause();
  if (MODE == 1) {
    TurnOffSETUP();
  }

  if (MODE == 2) {
    TurnOffSWEEP();
  }
  
  if (MODE == 3) {
    TurnOffCUT();
  }

  if (MODE == 4) {
    PauseCavForScreenCap();
  }

  if (MODE == 5) {
    TurnOffGEO();
  }
}

void resumeEventsForScreenCapsWindow() {
  //print("resuming nav");
  navigationEvents.resume();
  if (MODE == 1) {
     TurnOnSETUP();
  }

  if (MODE == 2) {
    TurnOnSWEEP();
  }

  if (MODE == 3) {
    TurnOnCUT();
  }

  if (MODE == 4) {
    ResumeCavForScreenCap();
  }

  if (MODE == 5) {
    TurnOnGEO();
  }
}


//response to forward back buttons, once the MODE value has been switched.
void doModeSpecificLogic() {
  //print("MODE = " + MODE.toString());
  if (MODE == 1) { // SETUP
    if (SETUPMouseDown.isPaused) {
      TurnOnSETUP();
      showArea = false;
    }

    if (!SWEEPMouseDown.isPaused) {
      TurnOffSWEEP();
    }

    if (!CUTMouseDown.isPaused) {
      TurnOffCUT();
    }

    if (!GEOMouseDown.isPaused) {
      TurnOffGEO();
    }

    rememberPresentSETUPSWEEP();

    //variables that need to be reset if you're coming back to this
    draggedUnits = 0;
    wasInCavalieri = false;


    readyToGoOn = true;
    drawSETUP();
    drawTools();
  }
  if (MODE == 2) { // SWEEPING
    if (!SETUPMouseDown.isPaused) {
      TurnOffSETUP();
    }

    TurnOnSWEEP();

    if (!CUTMouseDown.isPaused) {
      TurnOffCUT();
    }

    if (!GEOMouseDown.isPaused) {
      TurnOffGEO();
    }

    grabbed = "";
    draggedUnits = 0;
    hasCut = false;
    doingRotation = false;
    rotationInProgress = false;
    indexSelectedForRotation = -1;
    rememberPresentSETUPSWEEP();
    drawSWEEP();
    drawTools();
  }
  if (MODE == 3) { // CUTTING
    if (!SETUPMouseDown.isPaused) {
      TurnOffSETUP();
    }

    if (!SWEEPMouseDown.isPaused) {
      TurnOffSWEEP();
    }

    if (!GEOMouseDown.isPaused) {
      TurnOffGEO();
    }

    TurnOffCav();

    TurnOnCUT();

    if (MODEAfterSetup != 5) {
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
      originalPieces = copy(pieces);
    }

    drawCUT();
    drawTools();
  }
  if (MODE == 4) {
    if (!SETUPMouseDown.isPaused) {
      TurnOffSETUP();
    }

    TurnOffSWEEP();
    
    if (!CUTMouseDown.isPaused) {
      TurnOffCUT();
    }

    if (!GEOMouseDown.isPaused) {
      TurnOffGEO();
    }

    TurnOnCav();

    numDeviceMotionEvents = 0;
    pieces = new List<Piece>();
    originalPieces = new List<Piece>();
    startCavalieriLoop();
    drawCavalieri();
    drawTools();
  }

  if (MODE == 5) {
    if (!SETUPMouseDown.isPaused) {
      TurnOffSETUP();
    }

    if (!SWEEPMouseDown.isPaused) {
      TurnOffSWEEP();
    }

    if (!CUTMouseDown.isPaused) {
      TurnOffCUT();
    }

    TurnOnGEO();

    drawGEO();
  }
}



//FOR ALL MODES
void startUp(MouseEvent event) {
  doEventSetup();
  MODE = 1;
  navigationEvents = tools.onMouseDown.listen(testSwitchMode);
  splash.style.opacity = "0.0";
  splash.style.zIndex = "-1";

  adjustDimensions(); // initializes several variables
  makeVEqualToH();
  unitsLocked = true;

  drawSETUP();
  drawTools();

  if (MODEAfterSetup > 1) {
    MODE = MODEAfterSetup;

    if (MODEAfterSetup == 2 || MODEAfterSetup == 4) {
      s1end = new Point(inputPoint1.x, inputPoint1.y);
      s2end = new Point(inputPoint2.x, inputPoint2.y);
      doModeSpecificLogic();
    }

    if (MODEAfterSetup == 3) {
      cutFlavor = "selected";
      hasCut = true;
      setCutPoints();
      doModeSpecificLogic();

      pieces = copy(inputPieces);
      originalPieces = copy(inputPieces);
      drawCUT();
      drawTools();
    }

    if (MODEAfterSetup == 5) {
      pieces = copy(inputPieces);
      originalPieces = copy(inputPieces);

      doModeSpecificLogic();
      drawGEO();
    }

  }
}

void drawStatus(CanvasRenderingContext2D ctx, imwid, imht) {
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
    if (doingReflection) {
      if (activeDragging == "none" && flipGrabbed == "none") { currentToolsText = "Choose & Position a Mirror";}
      else if (flipGrabbed == "none") {currentToolsText = "Click a Shape to Flip"; }
      else { currentToolsText = "Drag Mirror to Position";}
    }
    if (doingRotation) {
      if (indexSelectedForRotation == -1) {
        currentToolsText = "Click a Shape to Rotate";
      } else {currentToolsText = "Click Center of Rotation";}
    }
    if ( reflectionsAllowed && !doingRotation && !doingReflection) { currentToolsText = "Dissect and Rearrange"; }
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
  }
  else {
    currentToolsText = captions[MODE];
  }

  ctx.fillText(currentToolsText, min(tools.width / 2, tools.width - 2 * imwid), imwid / 4); // 2 * tools.height / 3);
  ctx.drawImageScaled(cameraButton, screenCapIconCenter.x - ( imht / 4 ), screenCapIconCenter.y - ( imht / 4 ), ( imht / 2 ), (imht / 2 ));

  if (MODE == 1 && s1end.y == s2end.y) { 
    ctx.drawImageScaled(cavalieriButton, cavalieriCenter.x - 49, cavalieriCenter.y - 28, 98, 56); // TODO: Make this rational
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
  */
}


void drawTools() {
  CanvasRenderingContext2D ctx = tools.context2D;
  ctx.clearRect(0, 0, tools.width, tools.height);
  int imht = tools.height;
  int imwid = 2 * imht; //right now they're 2:1

  if (tools.width < 4.5 * tools.height) {
    imwid = ((2.0 / 4.5) * tools.width).round();
    imht = (imwid / 2).round();
  }

  screenCapIconCenter = new Point(max(tools.width / 4, (imwid * 1.125).round()), 2 * imht / 3); // 2 * tools.height is the offset of the arrow buttons
  cavalieriCenter = new Point(3 * tools.width / 4, imwid / 3);
  drawStatus(ctx, imwid, imht);


  if (MODE > 0) {
    ctx.drawImageScaled(leftButton, 0, 0, imwid, imht);
  }
  if ( (MODE == 2 && readyToGoOn) || (MODE==4 && t1s.length > 1 ) ){
    ctx.drawImageScaled(forkedRightButton, tools.width - imwid, 0, imwid, imht);
  }

  if ( MODE == 5 ){
    //ctx.drawImageScaled(forkedRightButton, tools.width - imwid, 0, imwid, imht);
    ctx.drawImageScaled(rightButton, tools.width - imwid, 0, imwid, imht);
  }
  
  if (MODE < 2 && readyToGoOn) {
    ctx.drawImageScaled(rightButton, tools.width - imwid, 0, imwid, imht);
  }

  if (MODE == 3 && rotationsAllowed && hasCut) {
    if (doingRotation){
      ctx.drawImageScaled(rotateButtonDownState, tools.width - imwid, 0, imwid, imht);
    }
    else {
      ctx.drawImageScaled(rotateButtonUpState, tools.width - imwid, 0, imwid, imht);
    }

  }

  if (MODE == 3 && reflectionsAllowed && hasCut) {
    if (doingReflection){
      ctx.drawImageScaled(reflectButtonDownState, tools.width - 2 * imwid, 0, imwid, imht);
    }
    else {
      ctx.drawImageScaled(reflectButtonUpState, tools.width - 2 * imwid, 0, imwid, imht);
    }

  }



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
    //draggedUnits = 0; removed so that it wouldn't
    if (draggedUnits == 0) {
      setupDragOriginMemorySETUPSWEEP(initPoint);
    }
    drawSWEEP();
  }
}

void drawSWEEP() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);
  if (grabbed != "") {
    drawGridAndRulers(canv);
    drawSweeperSweptSWEEP(ctx);
    drawSweeperCurrentSWEEP(ctx);
    areaToDisplay = getAreaString() + " " + getAreaUnitsString();
    if (draggedUnits == 0) {
      readyToGoOn = false;
    } else {
      readyToGoOn = true;
    }
  } else {
    drawGridAndRulers(canv);
    drawSweeperCurrentSWEEP(ctx);
  }
  drawTools();
}


// For Area computation
num getSweeperLength() {
  if (dragIsVertical) {
    return (s1end.x - s2end.x).abs();
  } else {
    return (s1end.y - s2end.y).abs();
  }
}

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

void rememberPresentSETUPSWEEP() {
  olds1 = new Point(s1end.x, s1end.y);
  olds2 = new Point(s2end.x, s2end.y);
  oldpx1 = new Point(getXForHSubTick(s1end.x), getYForVSubTick(s1end.y));
  oldpx2 = new Point(getXForHSubTick(s2end.x), getYForVSubTick(s2end.y));
  oldvtix = vticks;
  oldhtix = hticks;
}



bool inMiddle(Point mse) {
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
  //print("got here");
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

void drawGridAndRulers(CanvasElement canv) {
  if ((hrulerwidth != (canv.width - hoff)) || (vrulerheight != (canv.height - voff))) {
    fixSize(canv);
  }

  CanvasRenderingContext2D ctxt = canv.context2D;
  drawGrid(ctxt);
  drawRulers(ctxt);
}

void fixSize(CanvasElement canv) { // ToDo: Finish This
  num newhrulerwidth = canv.width - hoff;
  num newvrulerheight = canv.height - voff;

  if (newhrulerwidth >= hrulerwidth) {
    hrulerwidth = newhrulerwidth;
  }

  if (newvrulerheight >= vrulerheight) {
    vrulerheight = newvrulerheight;
  }

  if ((newhrulerwidth < hrulerwidth) || (newvrulerheight < vrulerheight)) {
    Point p = maxXYCors(); // this is in tics

    if (newhrulerwidth < hrulerwidth) {

    }

    num newMaxX = newhrulerwidth / ticwid; // These are all in pixels
    num newMaxY = newvrulerheight / ticht;
  }

}

Point maxXYCors() {
  return new Point (0, 0); // TODO: FIX THIS
}


//Drawing Grids/Rulers, Axes
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
    if ( doingReflection ) {
      ctxt.moveTo(hcuts.x, hcuts.y + 10 );
      ctxt.arc(hcuts.x, hcuts.y, 10, -1 * PI / 2 , 3 * PI / 2);
      //ctxt.moveTo(hcuts.x - 10, hcuts.y - 10);
      //ctxt.rect(hcuts.x - 10, hcuts.y - 10, 20, 20);
    } else {
      ctxt.moveTo(hcuts.x - 10, hcuts.y - 10);
      ctxt.rect(hcuts.x - 10, hcuts.y - 10, 20, 20); //(hcuts.x, hcuts.y, 10, 0, 2 * PI);
    }
    ctxt.closePath();
    if (cutGrabbed == "horizontal" || flipGrabbed == "horizontal" || activeDragging == "horizontal") {
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
  } else if (MODE == 3 && cutFlavor == "selected") {  //*****HERE TO CHANGE THE SHAPE OF THE GRABBER
    ctxt.beginPath();
    ctxt.moveTo(vcuts.x, vcuts.y);
    ctxt.lineTo(vcuts.x + hrulerwidth, vcuts.y);
    if ( doingReflection ) {
      ctxt.arc(vcuts.x, vcuts.y, 10, 0, 2 * PI);
    } else {
      ctxt.moveTo(vcuts.x - 10, vcuts.y - 10);
      ctxt.rect(vcuts.x - 10, vcuts.y - 10, 20, 20);
    }
    ctxt.closePath();
    if (cutGrabbed == "vertical" || flipGrabbed == "vertical" || activeDragging == "vertical") {
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


List<Piece> copy(List<Piece> input) {
  List<Piece> toReturn = new List<Piece>();

  int i = 0;
  while (i < input.length) {
    toReturn.add(input[i].copy());
    i++;
  }

  return toReturn;
}