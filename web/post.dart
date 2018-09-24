part of sweeps;



EventListener x = messageResponse;


// response to event
void messageResponse(MessageEvent e) {
  var converter = new JsonDecoder();

  var d = converter.convert(e.data);

  // Getting Inputs From The Event TODO: Fix when the format of the data is finished!
  String EventVertices = d["inputVertices"];
  String OriginalEventPieces = d["originalVertices"];
  List<List<num>> EventShapeColors = d["colors"]; // also get this from the event
  int EventMode = d["mode"]; // need this from event
  bool EventRotationsAllowed = d["rotationsAllowed"]; // need this from event also

  /*
  ticht = ;
  ticwid = ;
  vSubTicks = ;
  hSubTicks = ;

  */


  // need ticwid, tickht, vsubtics, and hsubtics: also need the world height and world width, to re-normalize all of these to the current window size


  // what to do with the event
  rotationsAllowed = EventRotationsAllowed;
  MODEAfterSetup = EventMode;

  originalPieces = ParsePieces(OriginalEventPieces);

  // processing the vertices
  if (EventMode == 3 || EventMode == 5) {
    pieces = ParsePieces(EventVertices);

    if (EventShapeColors != null) {
      int i = 0;
      while (i < pieces.length && i < EventShapeColors.length) {
        if (EventShapeColors[i].length == 3) {
          pieces[i].setColor(EventShapeColors[i]);
        }
        i++;
      }
    }

    inputPieces = copy(pieces);
  }
  else {
    List<Point> a = ParseSlider(EventVertices);
    inputPoint1 = a[0];
    inputPoint2 = a[1];

    if (MODE == 4){ // ensuring that the slider for Cavalieri is in the right position
      if (inputPoint1.y != inputPoint2.y) {
        inputPoint2 = new Point(inputPoint2.x, inputPoint1.y);
      }
    }
  }


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

  if (EventMode > 1) {
    MODE = EventMode;

    if (EventMode == 2 || EventMode == 4) {
      s1end = inputPoint1;
      s2end = inputPoint2;
      doModeSpecificLogic();
    }

    if (EventMode == 3) {
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





void postSomething(String s) {
  window.dispatchEvent(new Event.eventType("message", s));
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

  if (((MODE == 1) || (MODE == 2)) || (MODE == 4)) {
    pieceVertices = "'(" + s1end.x.toString() + ", " + s1end.y.toString() + "), (" + s2end.x.toString() + ", " + s2end.y.toString() + ")'";
  }


  //dataToEncode = '''[ { inputVertices: $pieceVertices }, { originalVertices : $originalPieceVertices }, { colors: $colorsList }, { mode: $MODE }, {rotationsAllowed: $rotationsAllowed } ]''';

  //dataToEncode = '''[ { inputVertices: $pieceVertices }, { originalVertices : $originalPieceVertices }, { colors: $colorsList }, { mode: $MODE }, {rotationsAllowed: $rotationsAllowed } ]''';


  //dataToEncode = '[ {inputVertices: $pieceVertices, originalVertices: $originalPieceVertices, colors: $colorsList, mode: $MODE, rotationsAllowed: $rotationsAllowed } ]';

  dataToEncode = "";

  var sid = Uri.encodeQueryComponent(className);
  var im = Uri.encodeQueryComponent(idata);
  var dat = Uri.encodeQueryComponent(dataToEncode);

  print(className);
  String user = annotation[0];
  String comm = annotation[1];

  var met = Uri.encodeQueryComponent("{'name':'$user', 'description': '$comm' }");


  // TODO: establishing that data can be processed by the program
   HttpRequest.request('http://rendupo.com:8000/uploads/?session-id=$sid&metadata=$met&image=$im&data=$dat', method:'POST')
      .then((HttpRequest resp) {
    // Do something with the response.
  });

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