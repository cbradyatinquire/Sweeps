part of sweeps;



EventListener x = messageResponse;


int toNumber(String s) {
  return [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ].indexOf(s);
}

bool toBool(String s) {
  if (s.contains("true"))
    return true;
  return false;
}

void messageResponse2(MessageEvent e){
  print(e.data);
}

// response to event
void messageResponse(MessageEvent e) {

  // var converter = new JsonDecoder();

  // var d = converter.convert(e.data);

  var d = e.data;


  // Getting Inputs From The Event TODO: Fix when the format of the data is finished!
  String eventVertices = d['vertices'];
  String originalEventVertices = d['outlineVertices'];
  List<List<num>> EventShapeColors = d['colors'];
  int EventMode = d['mode'];
  bool EventRotationsAllowed = d['rotationsAllowed'];



  // what to do with the event
  rotationsAllowed = EventRotationsAllowed;
  MODEAfterSetup = EventMode;

  List<Piece> originalEventPieces = ParsePieces(originalEventVertices);

  // processing the vertices
  if (EventMode == 3 || EventMode == 5) {
    pieces = ParsePieces(eventVertices);

    if (EventShapeColors != null) {
      int i = 0;
      while (i < pieces.length && i < EventShapeColors.length) {
        if (EventShapeColors[i].length == 4) {
          pieces[i].setColor(EventShapeColors[i]);
        }
        i++;
      }
    }

    inputPieces = copy(pieces);
  }
  else {
    List<Point> sliderPoints = ParseSlider(eventVertices);
    inputPoint1 = sliderPoints[0];
    inputPoint2 = sliderPoints[1];

    if (EventMode == 1) {
      s1end = sliderPoints[0];
      s2end = sliderPoints[1];
      doModeSpecificLogic();
    }
  }


  if (SWEEPMouseDown == null) {
    doEventSetup();
    navigationEvents = tools.onMouseDown.listen(testSwitchMode);
  }

  MODE = 1;
  TurnOffAllMain();
  TurnOnSETUP();
  splash.style.opacity = "0.0";
  splash.style.zIndex = "-1";

  adjustDimensions(); // initializes several variables

  ticht = d['ticht']; // TODO: should this be hticks?
  ticwid = d['ticwid']; // TODO: should this be vticks? if so adjustDimensions should be after
  vSubTicks = d['hSubTicks'];
  hSubTicks = d['vSubTicks'];
  vunits_abbreviated = d['vUnits'];
  hunits_abbreviated = d['hUnits'];
  unitsLocked = d['unitsLocked'];
  bool gridCut = d['cutWithGrid'];

  drawSETUP();
  drawTools();

  if (EventMode > 1) {
    MODE = EventMode;

    if (EventMode == 2) {
      originalPieces = new List<Piece>();
      pieces = new List<Piece>();
      MODE = 2;

      List<Point> inputtedPoints = ParsePoints(eventVertices);
      Point a = inputtedPoints[0];
      Point b = inputtedPoints[1];

      if (inputtedPoints.length == 2) {
        s1end = new Point(a.x, a.y);
        s2end = new Point(b.x, b.y);
        dragOrigin = new Point(getXForHSubTick((a.x + b.x) / 2.0),
            getYForVTick((a.y + b.y) / 2.0));
        doModeSpecificLogic();
      }
      else {
        if (inputtedPoints.length != 2) {
          Point c = inputtedPoints[2];
          Point d = inputtedPoints[3];

          s1end = new Point(c.x, c.y);
          s2end = new Point(d.x, d.y);
          dragOrigin = new Point(getXForHSubTick((c.x + d.x) / 2.0),
              getYForVTick((c.y + d.y) / 2.0));
          doModeSpecificLogic();

          s1end = a;
          s2end = b;

          num difx = b.x - c.x;
          num dify = b.y - c.y;

          if (difx == 0) {
            dragIsVertical = true;
            draggedUnits = dify;
          }

          if (difx != 0) {
            dragIsVertical = false;
            draggedUnits = difx;
          }

          grabbed = "middle";
          drawSWEEP();
          grabbed = "done";
        }
      }
    }

    if (EventMode == 3) {
      if (gridCut) {
        cutFlavor = "all";
        if (notACopy(inputPieces, originalEventPieces)) {
          hasCut = true;
        }
        else {
          hasCut = false;
        }
      }
      else {
        cutFlavor = "selected";
        hasCut = true;
      }
      setCutPoints();
      doModeSpecificLogic();

      pieces = copy(inputPieces);
      originalPieces = copy(originalEventPieces);
      drawCUT();
      drawTools();
    }

    if (EventMode == 4) {
      hasCut = false;
      List<Point> toMakeT1 = ParsePoints(originalEventVertices);
      List<Point> toMakeT2 = ParsePoints(eventVertices);
      s1end = toMakeT1.last;
      s2end = toMakeT2.last;
      readyToGoOn = false;
      MODE = 4;
      doModeSpecificLogic();
      cavIsDragging = false;

      t1s = toMakeT1;
      t2s = toMakeT2;
      draggedUnits = t1s.length - 1;
    }

    if (MODEAfterSetup == 5) {
      doModeSpecificLogic();
      pieces = copy(inputPieces);
      originalPieces = copy(originalEventPieces);

      drawGEO();
    }
  }
}





void postSomething(var s) {
  window.parent.postMessage(s, "*");
  //context['fiona']
}

void manageWebpageInput() {
  window.addEventListener("message", x);
}


//requires classes from dart:html
void postImageData(CanvasElement canv, List<String> annotation) {

  String idata = canv.toDataUrl();

  var dataToEncode;

  List<List<num>> colorsList = new List<List<num>>();
  String pieceVertices = "";
  String originalPieceVertices = "";

  if ((MODE == 3) || (MODE == 5)) {
    pieces.forEach((p) => pieceVertices = pieceVertices + " | " + p.toString());

    pieces.forEach((p) => colorsList.add(p.getColor()));

    originalPieces.forEach((p) => originalPieceVertices = originalPieceVertices + " | " + p.toString());
  }

  bool gridCut = false;
  if (MODE == 3 && cutFlavor == "all") {
    gridCut = true;
  }

  if ((MODE == 1)) {
    pieceVertices = convertPointListToString([s1end, s2end]);
    originalPieceVertices = "";
  }

  if ((MODE == 2)) {
    Point a, b;
    if (dragIsVertical) {
      a = new Point(s2end.x, s2end.y - draggedUnits);
      b = new Point(s1end.x, s1end.y - draggedUnits);
    }
    else {
      a = new Point(s2end.x - draggedUnits, s2end.y);
      b = new Point(s1end.x - draggedUnits, s1end.y);
    }
    pieceVertices = convertPointListToString([s1end, s2end, a, b]);
    originalPieceVertices = "";
  }

  if (MODE == 4) {
    String string1 = convertPointListToString(t1s);
    String string2 = convertPointListToString(t2s);
    originalPieceVertices = string1;
    pieceVertices = string2;
  }


  dataToEncode = {
    'vertices': pieceVertices,
    'outlineVertices' : originalPieceVertices,
    'colors': colorsList,
    'mode': MODE,
    'rotationsAllowed': rotationsAllowed,
    'ticht': ticht,
    'ticwid': ticwid,
    'vSubTicks': vSubTicks,
    'hSubTicks': hSubTicks,
    'vUnits' : vunits_abbreviated,
    'hUnits' : hunits_abbreviated,
    'unitsLocked': unitsLocked,
    'cutWithGrid': gridCut
  };




  //print( jsc.escapePrivateClassPrefix );//context.toString() );
  //c.alert("hi");


  //dataToEncode = MODE.toString() + "^" + pieceVertices + "^" + originalPieceVertices + "^" + colorsList.toString() + "^" + rotationsAllowed.toString();
  //var sid = Uri.encodeQueryComponent(className);
  //var dat = Uri.encodeQueryComponent(dataToEncode);
  //var dat = Uri.encodeQueryComponent(dataToEncode);

  print(className);
  String user = annotation[0];
  String comm = annotation[1];

  var met = {'name':'$user', 'description': '$comm' };

  var dataToSend = { 'metadata': met, 'image': idata, 'data': dataToEncode, 'type' : 'export-settings' };

  postSomething(dataToSend);



  /*
   HttpRequest.request('http://rendupo.com:8000/uploads/?session-id=$sid&metadata=$met&image=$im&data=$dat', method:'POST')
      .then((HttpRequest resp) {
    // Do something with the response.
     print(resp.responseText);
  });
   */


}




//requires classes from dart:html
void oldPostImageData(CanvasElement canv, List<String> annotation) {

  //HttpRequest request = new HttpRequest();

  //logic for receipt of response to the request.
  //request.onReadyStateChange.listen((_) {
  // if (request.readyState == HttpRequest.DONE &&
  //    (request.status == 200 || request.status == 0)) {
  //   print("data saved ok..." + request.responseText); // output the response from the server
  // }
  // });

  String idata = canv.toDataUrl();

  annotation = new List<String>();
  annotation.add("hi");

  //request.open("POST","http://54.69.108.80/sweep_image_old/", async: false);

  FormData fdata = new FormData();

  fdata.append('app_id', myUID.toString());
  fdata.append('app_annotation', annotation[0]);
  fdata.append('app_imagedata', idata);


  HttpRequest.request('http://54.69.108.80/sweep_image/', method: 'POST', sendData: fdata).then((HttpRequest r) {
    print("request sent");
  });

}