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

  print(d);

  // Getting Inputs From The Event TODO: Fix when the format of the data is finished!
  String EventVertices = d['vertices'];
  String OriginalEventPieces = d['outlineVertices'];
  List<List<num>> EventShapeColors = d['colors'];
  int EventMode = d['mode'];
  bool EventRotationsAllowed = d['rotationsAllowed'];

  print(EventShapeColors);

  /*
  ticht = d['ticht'];
  ticwid = d['ticwid'];
  vSubTicks = d['hSubTicks'];
  hSubTicks = d['vSubTicks'];
  */

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
        if (EventShapeColors[i].length == 4) {
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

    if (EventMode == 2) { // sweeping mode

      // The way sweep is structured, this does not make sense
      /*
      List<Point> b = ParseSlider(OriginalEventPieces);

      if (!b.isEmpty) {
        if ((b[0].y - a[0].y) != 0) {
          dragIsVertical = true;
          draggedUnits = a[0].y - b[0].y;
          print(a[0].y - b[0].y);
        }
        else {
          if ((b[0].x - a[0].x) != 0) {
            dragIsVertical = false;
            draggedUnits = a[0].x - b[0].x;
            print(a[0].x - b[0].x);
          }
        }

        if ((b[0].y - a[0].y == 0) && (b[0].x - a[0].x == 0)) {
          draggedUnits = 0;
          print("both zero");
        }
      }
      else {
        draggedUnits = 0;
      }
      */
    }

    if (EventMode == 4) {
      if (inputPoint1.y != inputPoint2.y) {  // ensuring that the slider for Cavalieri is in the right position
        inputPoint2 = new Point(inputPoint2.x, inputPoint1.y);
      }


      savedT2S = ParsePoints(OriginalEventPieces);

      if (!savedT2S.isEmpty) {
        cavIsDragging = true;
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
      readyToGoOn = false;
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

  if (((MODE == 1) || (MODE == 2)) || (MODE == 4)) {
    pieceVertices =
        "'(" + s1end.x.toString() + ", " + s1end.y.toString() + "), (" +
            s2end.x.toString() + ", " + s2end.y.toString() + ")'";

    if ((MODE == 2)) {
      if (dragIsVertical) {
        originalPieceVertices = "'(" + s1end.x.toString() + ", " +
            (s1end.y - draggedUnits).toString() + "), (" + s2end.x.toString() +
            ", " + (s2end.y - draggedUnits).toString() + ")'";
      }
      else {
        originalPieceVertices =
            "'(" + (s1end.x - draggedUnits).toString() + ", " +
                s1end.y.toString() + "), (" +
                (s2end.x - draggedUnits).toString() + ", " +
                s2end.y.toString() + ")'";
      }
    }

    if (MODE == 4) {
      if (cavIsDragging) {
        List<Point> L1 = t1s.reversed;
        int i = 0;
        while (i < L1.length) {
          print(L1[i]);
          originalPieceVertices =
              originalPieceVertices + ", (" + (L1[i].x).toString() + ", " +
                  L1[i].y.toString() + ")";
          i++;
        }

        i = 0;
        while (i < t2s.length) {
          originalPieceVertices =
              originalPieceVertices + ", (" + t2s[i].x.toString() + ", " +
                  t2s[i].y.toString() + ")";
          i++;
        }
      }
    }
  }

  //postSomething("hi");

  //dataToEncode = '''[ { inputVertices: $pieceVertices }, { outlineVertices : $originalPieceVertices }, { colors: $colorsList }, { mode: $MODE }, {rotationsAllowed: $rotationsAllowed } ]''';

  //dataToEncode = '''[ { inputVertices: $pieceVertices }, { outlineVertices : $originalPieceVertices }, { colors: $colorsList }, { mode: $MODE }, {rotationsAllowed: $rotationsAllowed } ]''';



  dataToEncode = {
    'vertices': pieceVertices,
    'outlineVertices' : originalPieceVertices,
    'colors': colorsList,
    'mode': MODE,
    'rotationsAllowed': rotationsAllowed,
    'ticht': ticht,
    'ticwid': ticwid,
    'vSubTicks': vSubTicks,
    'hSubTicks': hSubTicks
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