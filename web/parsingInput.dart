part of sweeps;


void manageInputs() {
  MODEAfterSetup = input['inputMode'];

  if (MODEAfterSetup == 2 || MODEAfterSetup == 4) {
    List<Point> a = ParseSlider(inputVertices);
    inputPoint1 = a[0];
    inputPoint2 = a[1];

    if (MODE == 4){ // ensuring that the slider for Cavalieri is in the right position
      if (inputPoint1.y != inputPoint2.y) {
        inputPoint2 = new Point(inputPoint2.x, inputPoint1.y);
      }
    }
  }
  else if (MODEAfterSetup == 3) {
    inputPieces = ParsePieces(inputVertices);
    colorsOfPieces = input['colors'];

    int i = 0;
    while (i < colorsOfPieces.length && i < inputPieces.length) {
      inputPieces[i].setColor(colorsOfPieces[i]);
      i++;
    }

  }
}


List<Point> ParseSlider(String s) {
  bool inPoint = false;
  List<Point> toReturn = new List<Point>();

  bool onYcor = false;
  num currentXcor = 0;
  num currentYcor = 0;
  int decimalPlaces = 0;
  bool countingDec = false;

  List<String> digits = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ];

  num j = 0;
  while (j < s.length) {
    if (toReturn.length >= 2)
      break;

    String currentPlace = s[j];


   if (currentPlace != " ") {
     if (!inPoint) {
       if (currentPlace == "(") {
          inPoint = true;
          onYcor = false;
          countingDec = false;
          decimalPlaces = 0;
          currentXcor = 0;
          currentYcor = 0;
        }
      }
      else { // if you are in a point
        if (currentPlace == ")") {
          inPoint = false;
          currentYcor = currentYcor * pow(0.1, decimalPlaces);
          toReturn.add(new Point(currentXcor, currentYcor));
        }

        if (currentPlace == ",") {
          currentXcor = currentXcor * pow(0.1, decimalPlaces);
          onYcor = true;
          countingDec = false;
          decimalPlaces = 0;
        }

        num digit = digits.indexOf(currentPlace);
        if (digit != -1) {
          if (onYcor)
            currentYcor = currentYcor * 10 + digit;
          else
            currentXcor = currentXcor * 10 + digit;
          if (countingDec)
            decimalPlaces++;
        }

        if (currentPlace == ".") {
          countingDec = true;
        }
      }
    }
    j++;
  }

  while (toReturn.length < 2)
    toReturn.add(new Point(0, 0));

  while (toReturn.length > 2)
    toReturn.removeLast();

  return toReturn;
}



List<Piece> ParsePieces(String s) {
  bool inPoint = false;
  List<Point> currentPiece = new List<Point>();
  List<Piece> toReturn = new List<Piece>();

  bool onYcor = false;
  num currentXcor = 0;
  num currentYcor = 0;
  num decimalPlaces = 0;
  bool countingDec = false;

  List<String> digits = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ];

  num j = 0;
  while (j < s.length) {
    String currentPlace = s[j];


    if (currentPlace == "|") {
      if (currentPiece.length > 2) {
        toReturn.add(new Piece(currentPiece));
        currentPiece.clear();
      }
    }
    else {
      if (currentPlace != " ") {
        if (!inPoint) {
          if (currentPlace == "(") {
            inPoint = true;
            onYcor = false;
            currentXcor = 0;
            currentYcor = 0;
            decimalPlaces = 0;
            countingDec = false;
          }
        }
        else { // if you are in a point
          if (currentPlace == ")") {
            inPoint = false;
            currentYcor = currentYcor * pow(0.1, decimalPlaces);
            currentPiece.add(new Point(currentXcor, currentYcor));
          }

          if (currentPlace == ",") {
            currentXcor = currentXcor * pow(0.1, decimalPlaces);
            countingDec = false;
            decimalPlaces = 0;
            onYcor = true;
          }

          num digit = digits.indexOf(currentPlace);
          if (digit != -1) {
            if (onYcor)
              currentYcor = currentYcor * 10 + digit;
            else
              currentXcor = currentXcor * 10 + digit;
          }
          if (countingDec)
            decimalPlaces++;
        }

        if (currentPlace == ".") {
          countingDec = true;
        }
      }
    }
    j++;
  }


  if (currentPiece.length > 2) {
    toReturn.add(new Piece(currentPiece));
    currentPiece.clear();
  }

  print(toReturn);
  return toReturn;
}



