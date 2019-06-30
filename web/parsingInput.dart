part of sweeps;


bool notACopy(List<Piece> a, List<Piece> b) {
  List<Piece> pieces1 = copy(a);
  List<Piece> pieces2 = copy(b);

  num errorTol = .05;

  if (pieces1.length != pieces2.length) {
    return true;
  }

  int j = 0;
  while (j < pieces2.length) {
    if (pieces1[j].vertices.length != pieces2[j].vertices.length) {
      return true;
    }

    int i = 0;
    while (i < pieces1[j].vertices.length) {
      if (pieces1[j].vertices[i].distanceTo(pieces2[j].vertices[i]) > errorTol) {
        return true;
      }
      i = i + 1;
    }
    j = j + 1;
  }
  return false;
}

void manageInputs() {
  MODEAfterSetup = input['mode'];
  willPost = input['post'];

  if (MODEAfterSetup == 2 || MODEAfterSetup == 4) {
    List<Point> a = ParseSlider(inputVertices);
    inputPoint1 = a[0];
    inputPoint2 = a[1];

    readyToGoOn = false;

    if (MODE == 4){ // ensuring that the slider for Cavalieri is in the right position
      if (inputPoint1.y != inputPoint2.y) {
        inputPoint2 = new Point(inputPoint2.x, inputPoint1.y);
      }
    }
  }
  else if (MODEAfterSetup == 3 || MODEAfterSetup == 5) {
    inputPieces = ParsePieces(inputVertices);
    colorsOfPieces = input['colors'];

    int i = 0;
    while (i < colorsOfPieces.length && i < inputPieces.length) {
      inputPieces[i].setColor(colorsOfPieces[i]);
      i++;
    }

  }

  String x = input['className'];

  if (x == "" || x == "#" || x == null) {
    className = "SweepGallery";
  }
  else {
    if (x[0] == "#") {
      className = x.substring(1);
    }
    else {
      className = x;
    }
  }

}


List<Point> ParseSlider(String s) {
  if (s == null) {
    return [s1end, s2end];
  }

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
        else {
          if (currentPlace == ",") {
            currentXcor = currentXcor * pow(0.1, decimalPlaces);
            onYcor = true;
            countingDec = false;
            decimalPlaces = 0;
          }

          else {
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


List<Point> ParsePoints(String s) {
  if (s == null) {
    return [];
  }

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
        else {
          if (currentPlace == ",") {
            currentXcor = currentXcor * pow(0.1, decimalPlaces);
            onYcor = true;
            countingDec = false;
            decimalPlaces = 0;
          }

          else {
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
      }
    }
    j++;
  }

  return toReturn;
}

String convertPointListToString(List<Point> x){
  String toReturn = "";
  int i = 0;

  while (i < x.length) {
    toReturn = toReturn + "(" + x[i].x.toString() + ", " + x[i].y.toString() + "), ";
    i = i + 1;
  }

  return toReturn;
}



List<Piece> ParsePieces(String s) {
  if (s == null) {
    return new List<Piece>();
  }

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
  while (j < s.length && s[j] != "^") {
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

  return toReturn;
}


List<List<num>> ParseColors(String s) {
  if (s == null) {
    return new List<List<num>>();
  }

  List<num> currentList = new List<num>();
  List<List<num>> toReturn = new List<List<num>>();

  num currentNum = 0;
  bool countingDec = false;
  num decimalPlaces = 0;

  List<String> digits = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ];

  num j = 0;
  while (j < s.length) {
    String currentPlace = s[j];

    if (currentPlace == "]") {
      if (currentList.length > 0) {
        toReturn.add(currentList);
        currentList = new List<num>();
      }
    }

    if (currentPlace != " ") {
      if (currentPlace == ",") {
        currentNum = currentNum * pow(0.1, decimalPlaces);
        currentList.add(currentNum);
        currentNum = 0;
        countingDec = false;
        decimalPlaces = 0;
      }

      num digit = digits.indexOf(currentPlace);
      if (digit != -1) {
        currentNum = currentNum * 10 + digit;

        if (countingDec) {
          decimalPlaces++;
        }
      }

      if (currentPlace == ".") {
        countingDec = true;
      }
      j++;
    }
  }

  if (currentList.length > 0) {
    toReturn.add(currentList);
  }

  return toReturn;
}


