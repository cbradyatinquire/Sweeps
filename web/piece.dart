part of sweeps;



class Piece {

  List<Point> vertices;
  List<List<Point>> sides;

  List<Point> orderedPointsWithCutVertices;

  String strokesty = "#000";
  String fillsty = "rgba(0, 0, 255, 0.3)";
  num xmin, xmax, ymin, ymax;

  Piece(List<Point> vs) {
    vertices = new List<Point>();
    for (Point p in vs) {
      if ( !vertices.contains(p) ) {
        vertices.add(p);
      }
    }
    establishBoundingBox();
    setupSides();
  }

  void establishBoundingBox() {
    xmin = null; // these are for when the method is called when
    ymin = null; // the piece is dragged, so that the previous
    xmax = null; // location of the piece is not taken into
    ymax = null; // account when calculating the bounding box

    for (Point p in vertices) {
      if (xmin == null || p.x < xmin) { xmin = p.x; }
      if (ymin == null || p.y < ymin) { ymin = p.y; }
      if (xmax == null || p.x > xmax) { xmax = p.x; }
      if (ymax == null || p.y > ymax) { ymax = p.y; }
    }
  }

  void setupSides() {
    sides = new List<List<Point>>();
    Point vlast = vertices.last;
    for (int index = 0; index < vertices.length; index++) {
      Point vnext = vertices[index];
      sides.add( [new Point(vlast.x, vlast.y), new Point(vnext.x, vnext.y)] );
      vlast = vnext;
    }
  }

  // useful method for debugging
  String verticesAsString() {
    String rtn = "Piece with vertices: ";
    vertices.forEach((vertex) => rtn += "\nVertex: (" + vertex.x.toString() + "," + vertex.y.toString() + ")");
    return rtn;
  }

  //Cutting Methods
  //gets the Y-value of the point on the line between a and b with Y-coordinate xval
  num interpolatedY(Point a, Point b, num xval) {
    if (b.x == a.x) {
      return a.y;
    } else {
      double percentage = (xval - a.x) / (b.x - a.x);
      num dely = (b.y - a.y);
      return a.y + dely * percentage;
    }
  }

//gets the X-value of the point on the line between a and b with Y-coordinate yval
  num interpolatedX(Point a, Point b, num yval) {
    if (b.y == a.y) {
      return a.x;
    } else {
      double percentage = (yval - a.y) / (b.y - a.y);
      num delx = (b.x - a.x);
      return a.x + delx * percentage;
    }
  }


  bool containsGridPoint(num x, num y) {
    if (x <= xmin || y <= ymin || x >= xmax || y >= ymax) {
      return false;
    }
    else {
      return hitParityOdd(x, y);
      // The hit parity is the number of times that a line through between the point in question and
      // a point not in the peice intersects a side of the piece. Every intersection denotes a move from
      // outside the piece to inside. Therefore, if this is odd, the point must be inside.
    }
  }

  bool hitParityOdd( num x, num y ) { // for explanation of what is being calculated and why, see comment in method "containsGridPoint"
    Point startPoint = new Point(xmin - 1.02, (ymax - ymin) / 2); // This is just chosen as point outside the piece

    num hits = getHitNumber(startPoint, new Point(x, y));

    return ( hits % 2 != 0 );
  }

  int getHitNumber( Point startPoint, Point endPoint ) {

    int hits = 0;
    for (List<Point>side in sides) {
      hits += numIntersections(startPoint, endPoint, side[0], side[1]);
    }

    return hits;
  }

  int numIntersections( Point s1p1, Point s1p2, Point s2p1, Point s2p2 ) {
    num a1, a2, b1, b2, c1, c2, d1, d2;
    num epsilon = .0000001;

    //get coefficients of line for side 1 in standard Ax + By + C = 0 form
    a1 = s1p2.y - s1p1.y;
    b1 = s1p1.x - s1p2.x;
    c1 = (s1p2.x * s1p1.y) - (s1p1.x * s1p2.y);

    //determine whether endpoints of side 2 are on same side or diff side of line.
    d1 = (a1 * s2p1.x) + (b1 * s2p1.y) + c1;
    d2 = (a1 * s2p2.x) + (b1 * s2p2.y) + c1;

    if ( d1 * d2 > 0 ) { return 0; }  //this means that side 2 is entirely above or below side 1 extended

    //now similarly for side 2 as the extended one...
    a2 = s2p2.y - s2p1.y;
    b2 = s2p1.x - s2p2.x;
    c2 = (s2p2.x * s2p1.y) - (s2p1.x * s2p2.y);

    //determine whether endpoints of side 1 are on same side or diff side of line.
    d1 = (a2 * s1p1.x) + (b2 * s1p1.y) + c2;
    d2 = (a2 * s1p2.x) + (b2 * s1p2.y) + c2;

    if (d1 * d2 > 0) { return 0; }

    if ( ( (a1 * b2) - (a2 * b1) ).abs() < epsilon   ) { return 0; } // that is, if the lines are practically parallel, and hence on top of each other
    else { return 1;}
  }


  // allows concavity on the vertical sides, but requires convexity on the horizontal sides.
  /*List<Piece> cutVerticalCavalieri( num xcor ) {
    
    List<Piece> myPieces = [this];
    if ( xcor < xmin || xcor > xmax ) { return myPieces; }

    // break up the piece along all horizontal lines
    for (int yc = 0; yc < vticks * vSubTicks; yc++) {
      List<Piece> newPcs = new List<Piece>();
      myPieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
      myPieces = newPcs;
    }

    // cut the new pieces along the vertical line to be cut along
    List<Piece> newPcs = new List<Piece>();
    myPieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xcor)));
    myPieces = newPcs;

    // eliminate "pieces" that have no area from the list
    List<Piece>realPieces = new List<Piece>();
    realPieces.addAll(myPieces.where( (piece) => (piece.vertices.length > 2) ) );

    // gather pieces into two lists, one on the left and one on the right
    realPieces.sort( (a, b) => (a.ymin).compareTo(b.ymin) );
    
    List<Piece>leftPieces = new List<Piece>();
    leftPieces.addAll( realPieces.where( (piece) => (piece.xmax <= xcor) ) );
    List<Piece>rightPieces = new List<Piece>();
    rightPieces.addAll(  realPieces.where( (piece) => (piece.xmin >= xcor) ) );

    // reconstruct the pieces that should be displayed
    List<Piece> endPieces = new List<Piece>();
    endPieces.addAll( coalesce(leftPieces) );
    endPieces.addAll( coalesce(rightPieces) );
    
    return endPieces;
  }*/

  List<Piece> cutVerticalCavalieri( num xcor ) {
    return cutGeneral(new Point(xcor, 0), new Point(xcor, 1));
  }


  // returns a list of pieces where the common sides of the original list are glued together (no restrictions)
  List<Piece> coalesce( List<Piece> inputPieces ) {
    if ( inputPieces.isEmpty ) { return inputPieces; }
    List<Piece> inputCopy = new List<Piece>();
    inputCopy.addAll( inputPieces );
    List<Piece> coalesced = new List<Piece>();
    while ( !inputCopy.isEmpty ) {
      Piece aggregator = inputCopy.first;
      List<int>usedIndices = [0];
      for (int index = 1; index < inputCopy.length; index++ ) {
        Piece candidate = inputCopy[index];
        if ( aggregator.sharesSideWith( candidate ) ) {
          aggregator = aggregate( aggregator, candidate );
          usedIndices.add(index);
        }
      }
      List<Piece>cache = new List<Piece>();
      for (int i = 0; i<inputCopy.length; i++ ) {
        if ( !usedIndices.contains(i) ) {
          cache.add(inputCopy[i]);
        }
      }
      coalesced.add( aggregator );
      inputCopy.clear();
      inputCopy.addAll(cache);
    }
    return coalesced;
  }

  // returns true if this piece shares a side with the other piece (no limitations)
  bool sharesSideWith( Piece another ) {
    for (List<Point> side in sides) {
      List<List<Point>> asides = another.sides;
      for (List<Point> aside in asides ) {
        if ( side.contains(aside.first) && side.contains(aside.last) ) // (sides only have two elements)
          return true;
      }
    }
    return false;
  }

  // creates a piece that is the union of two pieces with two common vertices (the construction of the method assumes this initial condition)
  Piece aggregate( Piece one, Piece another) {
    // finding the side in common
    int oneindex, anotherindex;
    bool reversed = null;
    for (int osnum = 0; osnum<one.sides.length; osnum++) {
      List<Point>oneside = one.sides[osnum];
      for (int asnum = 0; asnum<another.sides.length; asnum++ ) {
        List<Point>anotherside = another.sides[asnum];
        if (anotherside.contains( oneside.first )  && anotherside.contains( oneside.last ) ) {
          oneindex = osnum;
          anotherindex = asnum;
          if ( anotherside.first == oneside.first) {
            reversed = false;
          } else {
            reversed = true;
          }
          break;
        }
      }
      if (reversed != null) { break; }
    }

    // going around the first piece, then the second piece, then back around the first piece
    int step = -1;
    if (reversed) { step = 1;}
    List<Point> agvertices = new List<Point>();
    int oi = 0;
    while (oi < oneindex) {
      List<Point> oside = one.sides[oi];
      agvertices.add(oside.first);
      oi++;
    }
    int ai = anotherindex + step;
    while ( ai % another.sides.length != anotherindex) {
      List<Point> aside = another.sides[ai % another.sides.length];
      if (reversed) { agvertices.add(aside.first); }
      else { agvertices.add(aside.last); }
      ai = ai + step;
    }
    oi = oneindex + 1;
    while (oi < one.sides.length) {
      List<Point> oside = one.sides[oi];
      agvertices.add(oside.first);
      oi++;
    }
    Piece aggregate = new Piece(agvertices);
    return aggregate;
  }

  // requires convexity of the piece
  List<Piece> cutVertical(num xcor) {
    return cutGeneral(new Point (xcor, 0), new Point (xcor, 1));
    if ( xcor < xmin || xcor > xmax ) { return [ this ]; } // if cut is obviously outside, return original list

    List<Point> hitPoints = new List<Point>();
    List<int> hits = new List<int>();
    List<bool> pointIsNewToPiece = new List<bool>();
    Point init = vertices.last;
    for (int i = 0; i < vertices.length; i++) {
      Point fin = vertices[i];
      num di = xcor - init.x;
      num df = xcor - fin.x;
      if (di * df < 0) {
        hits.add(i);
        hitPoints.add(new Point(xcor, interpolatedY(init, fin, xcor)));
        pointIsNewToPiece.add(true);
      } else if (df == 0) {
        hits.add(i);
        hitPoints.add(new Point(xcor, interpolatedY(init, fin, xcor)));
        pointIsNewToPiece.add(false);
      }
      init = fin;
    }
    if (hits.length > 0) {
      if (hits.length == 1) {
        return [this];
      } //only one vertex touched (outer boundary)
      if (!pointIsNewToPiece.first && !pointIsNewToPiece.last && (hits.first - hits.last).abs() == 1) {
        return [this];
      }
      if (hits.length != 2) {
        print("UNEXPECTED LENGTH: " + hits.length.toString());
        print("with xcor = " + xcor.toString());
        print("  Piece = " + this.verticesAsString());
        return [this];
      }
      List<Piece> toreturn = new List<Piece>();

      List<Point> lp1 = new List<Point>();
      int i1 = hits.first;
      int i2 = hits.last;
      if (pointIsNewToPiece.first) {
        lp1.add(hitPoints.first);
      }
      for (int i = i1; i < i2; i++) {
        lp1.add(vertices[i]);
      }
      lp1.add(hitPoints.last);

      List<Point> lp2 = new List<Point>();
      if (pointIsNewToPiece.last) {
        lp2.add(hitPoints.last);
      }
      for (int i = i2; i < vertices.length; i++) {
        lp2.add(vertices[i]);
      }
      for (int j = 0; j < i1; j++) {
        lp2.add(vertices[j]);
      }
      lp2.add(hitPoints.first);



      toreturn.add(new Piece(lp1));
      toreturn.add(new Piece(lp2));

      return toreturn;

    } else {
      return [this];
    }
  }

  // requires convexity of the piece
  List<Piece> cutHorizontal(num ycor) {

    if ( ycor < ymin || ycor > ymax ) { return [ this ]; }

    List<Point> hitPoints = new List<Point>();
    List<int> hits = new List<int>();
    List<bool> pointIsNewToPiece = new List<bool>();
    Point init = vertices.last;
    for (int i = 0; i < vertices.length; i++) {
      Point fin = vertices[i];
      num di = ycor - init.y;
      num df = ycor - fin.y;
      if (di * df < 0) {
        hits.add(i);
        hitPoints.add(new Point(interpolatedX(init, fin, ycor), ycor));
        pointIsNewToPiece.add(true);
      } else if (df == 0) {
        hits.add(i);
        hitPoints.add(new Point(interpolatedX(init, fin, ycor), ycor));
        pointIsNewToPiece.add(false);
      }
      init = fin;
    }
    if (hits.length > 0) {
      if (hits.length == 1) {
        return [this];
      } //only one vertex touched (outer bounary)
      if (!pointIsNewToPiece.first && !pointIsNewToPiece.last && (hits.first - hits.last).abs() == 1) {
        return [this];
      }
      if (hits.length != 2) {
        print("UNEXPECTED LENGTH: " + hits.length.toString());
        print("with ycor = " + ycor.toString());
        print("  Piece = " + this.verticesAsString());
        return [this];
      }
      List<Piece> toreturn = new List<Piece>();

      List<Point> lp1 = new List<Point>();
      int i1 = hits.first;
      int i2 = hits.last;
      if (pointIsNewToPiece.first) {
        lp1.add(hitPoints.first);
      }
      for (int i = i1; i < i2; i++) {
        lp1.add(vertices[i]);
      }
      lp1.add(hitPoints.last);

      List<Point> lp2 = new List<Point>();
      if (pointIsNewToPiece.last) {
        lp2.add(hitPoints.last);
      }
      for (int i = i2; i < vertices.length; i++) {
        lp2.add(vertices[i]);
      }
      for (int j = 0; j < i1; j++) {
        lp2.add(vertices[j]);
      }
      lp2.add(hitPoints.first);



      toreturn.add(new Piece(lp1));
      toreturn.add(new Piece(lp2));

      return toreturn;

    } else {
      return [this];
    }

  }

 // cut along the line formed by one and two; need the points not to be the same, but piece need not be convex
  List<Piece> cutGeneral(Point one, Point two) {
    List<Object> important = getIntersectionsWithLine(one, two);
    List<Point> verticesWithCuts = important[0]; // list of vertices of the new pieces, including the ones formed by the new cut
    List<num> cutIndices = important[1]; // indices of the vertices formed by the new cut

    List<Piece> cutPieces = new List<Piece>(); // list which will contain the newly formed pieces

    //variables for the while loop below
    int index; // index of point in consideration

    List<bool> indexUnused = new List<bool>();
    verticesWithCuts.forEach( (v) => indexUnused.add(true) );

    List<int> currentPiece;
    bool justJumped;

    print("vertices:");
    num j = 0;
    while (j < verticesWithCuts.length){
      print(j.toString() + ": (" + verticesWithCuts[j].x.toString() + ", " + verticesWithCuts[j].y.toString() + ")" );
      j++;
    }
    print("that's all");

    print("cuts:");
    cutIndices.forEach((x) => (print(x.toString() + ": (" + verticesWithCuts[x].x.toString() + ", " + verticesWithCuts[x].y.toString() + ")" )));
    print("that's all");


    while (indexUnused.contains(true)) {
      // initializing / re-initializing variables for next loop
      index = indexUnused.indexOf(true);
      currentPiece = new List<int>();
      justJumped = false;

      while (!currentPiece.contains(index)) {
        indexUnused[index] = false;

        if (cutIndices.contains(index)) {
          currentPiece.add(index);

          if (justJumped) {
            print(index.toString() + " and stepping");
            justJumped = false;
            index++;
          }
          else {
            print(index.toString() + " and jumping");
            justJumped = true;
            index = getNextIndex(index, cutIndices); // jumping to the next indexed cut point going along the cut line
          }
        }
        else {
          print(index.toString() + " and stepping");
          currentPiece.add(index);
          index++;
        }

        if (index == verticesWithCuts.length)
          index = 0;
      }


      if (currentPiece.length > 2) {
        List<Point> vertexList = new List<Point>();
        currentPiece.forEach((i) => vertexList.add(verticesWithCuts[i]));
        cutPieces.add(new Piece(vertexList));
      }
    }
    print("done with piece");

    return cutPieces;
  }

  // This method returns a two-element list containing:
  // 0) a list of vertices obtained when the piece is cut on a line through the two points,
  // and
  // 1) a list of indices of the points which are vertices
  // (if the line passes through a vertex, its index will be in this second list)
  // IMPORTANT: The method does assume that the shape has no self-intersections
  List<Object> getIntersectionsWithLine(Point one, Point two) {
    if (vertices.length == 0)
      return [new List<Point>(), new List<num>()]; // edge case that I don't want to throw an error

    // getting a vertex list which has no repeated vertices or 180 degree angles
    // this is mostly important for getting rid of sides that intersect with the
    // cut line and have multiple vertices (which happens often in Cavalieri mode)
    List<Point> verticesWithoutRepeats = new List<Point>();

    num index = 0;
    while (index < vertices.length) {
      num next = (index + 1) % vertices.length;
      int previous = (index - 1 + vertices.length) % vertices.length;

      bool repeated = (vertices[previous].distanceTo(vertices[index]) <
          .000001); // for catching rounding errors


      if (repeated)
        index++;
      else {
        bool inLine = colinear(vertices[previous], vertices[index], vertices[next]);

        if (inLine)
          index++;
        else {
          verticesWithoutRepeats.add(vertices[index]);
          index++;
        }
      }
    }

    //now, adding the cut points to the new list
    num checkingIndex = 0;
    List<int> cutIndices = new List<int>();

    List<Point> verticesTotal = new List<Point>();

    Point possiblePoint = null;

    List<num> abc = getLineEq(one, two); // [a, b, c] where aX + bY + c = 0 is the equation of the line


    while (checkingIndex < verticesWithoutRepeats.length) {
      verticesTotal.add(verticesWithoutRepeats[checkingIndex]); // adding the point at the index, and checking the next side for intersections

      possiblePoint = isIntersection(checkingIndex, verticesWithoutRepeats, abc); // will consider side starting at the point indexed by checkingIndex
      if (possiblePoint != null) {
        if (possiblePoint.distanceTo(verticesWithoutRepeats[checkingIndex]) > .0001) // rounding errors
          verticesTotal.add(possiblePoint);
        cutIndices.add(verticesTotal.length - 1); // index of the last element added
      }
      checkingIndex++;
    }

    // now need to get the sorted list of possible cut points

    List<Object> toReturn = new List<Object>();

    Point outsidePoint; // just a point on the line outside the shape

    num a, b, c;
    a = abc[0];
    b = abc[1];
    c = abc[2];

    if (b != 0)
      outsidePoint = new Point(-1, (a - c) / b);
    else
      outsidePoint = new Point((0 - c) / a, -1);

    cutIndices.sort((a, b) =>
        (((outsidePoint.distanceTo(verticesTotal[a]) * 1000).round()).compareTo(
            (outsidePoint.distanceTo(verticesTotal[b]) * 1000).round())));
    // as these are lattice points, no loss of information should come from this rounding



    // now need to either remove or duplicate points that are just tips brushing
    // against the line, depending on weather or not the cut line is exiting or
    // entering the shape

    num secondaryIndex = 0;
    List<num> cutIndicesFinal = new List<num>();
    List<Point> verticesToReturn = new List<Point>();


    // figure out which cut points to remove or delete (among those on the tips of the piece)
    List<bool> duplicate = new List<bool>();
    List<bool> duplicateOrRemove = new List<bool>();
    List<bool> notACut = new List<bool>();
    cutIndices.forEach((x) => duplicate.add(false));
    cutIndices.forEach((x) => duplicateOrRemove.add(false));
    cutIndices.forEach((x) => notACut.add(false));

    num n = 0;
    num pointsSkipped = 0;

    while (n < cutIndices.length) {
      Point next = verticesTotal[(cutIndices[n] + 1) % verticesTotal.length];
      Point previous = verticesTotal[(cutIndices[n] - 1 +
          verticesTotal.length) % verticesTotal.length];

      if (onSameSide(previous, next, abc)) {
        duplicateOrRemove[n] = true;
        if ((n - pointsSkipped) % 2 == 1) {
          duplicate[n] = true;
          pointsSkipped++;
        }
        //print( "on tip: " + verticesTotal[cutIndices[n]].x.toString() + ", " + verticesTotal[cutIndices[n]].y.toString() + ", will duplicate " + duplicate[n].toString() + " at index: " + cutIndices[n].toString());
      }
      else { // checking now for sides on the cut line
        if (n < (cutIndices.length - 1)) { // the last cannot be on the side
          num d = cutIndices[n] - cutIndices[n + 1];
          if (d.abs() == 1) { // if they form a side
            bool wantToSkipBoth = true;
            if (d == -1) {
              Point twoAhead = verticesTotal[(cutIndices[n] + 2) %
                  verticesTotal.length];
              wantToSkipBoth = onSameSide(previous, twoAhead, abc);
            }
            else {
              Point twoBehind = verticesTotal[(cutIndices[n] - 2 +
                  verticesTotal.length) % verticesTotal.length];
              wantToSkipBoth = onSameSide(twoBehind, next, abc);
            }

            if (wantToSkipBoth) {
              if ((n - pointsSkipped) % 2 == 0) {
                duplicateOrRemove[n] = true;
                duplicateOrRemove[n + 1] = true;
                pointsSkipped++;
                pointsSkipped++;
              }
              n++;
            }
            else {
              if ((n - pointsSkipped) % 2 == 0) {
                duplicateOrRemove[n] = true;
                pointsSkipped++;
                n++;
              }
              else {
                duplicateOrRemove[n + 1] = true;
                pointsSkipped++;
                n++;
              }
            }
          }
        }
      }
      n++;
    }


    // go through these to get the final list of vertices and final collection of cut indices
    while (secondaryIndex < verticesTotal.length) {
      verticesToReturn.add(verticesTotal[secondaryIndex]);

      num x = cutIndices.indexOf(secondaryIndex);

      if (x != -1) {
        if (duplicateOrRemove[x]) {
          if (duplicate[x]) {
            cutIndicesFinal.add(verticesToReturn.length - 1);
            verticesToReturn.add(verticesTotal[secondaryIndex]);
            cutIndicesFinal.add(verticesToReturn.length - 1);
          }
        }
        else {
          cutIndicesFinal.add(verticesToReturn.length - 1);
        }
      }
      secondaryIndex++;
    }

    // sort the cut indices which need to be returned
    cutIndicesFinal.sort((a, b) => (((outsidePoint.distanceTo(verticesToReturn[a]) * 1000).round()).compareTo((outsidePoint.distanceTo(verticesToReturn[b]) * 1000).round())));

    // This is now all sorted, except for the cases where there are repeated indices
    // In these cases, need to ensure that you are going to jump to the closer index

    num j = 1; // first vertex will not be duplicated, so do not need to check
    while (j < cutIndicesFinal.length - 1) {
      if (verticesToReturn[cutIndicesFinal[j]].distanceTo(verticesToReturn[cutIndicesFinal[j]]) < .00001) {

        // now need to order them
        num g = max( cutIndicesFinal[j], cutIndicesFinal[j + 1]);
        num h = min( cutIndicesFinal[j], cutIndicesFinal[j + 1]);

        num previous = cutIndicesFinal[j - 1];
        num next = cutIndicesFinal[(j + 2) % cutIndicesFinal.length];


        num s = (g + 1) % verticesToReturn.length;
        while (!cutIndicesFinal.contains(s))
          s = (s + 1) % verticesToReturn.length;

        num t = (h - 1 + verticesToReturn.length) % verticesToReturn.length;
        while (!cutIndicesFinal.contains(t))
          t = (t - 1 + verticesToReturn.length) % verticesToReturn.length;

//        print("for j = " + j.toString());
//        print("s is: " + s.toString() + " and t is :" + t.toString());
//        print("g is: " + g.toString() + " and h is: " + h.toString());
//        print("previous is: " + previous.toString() + " and next is: " + next.toString());

        if (s == next || t == previous) {
          cutIndicesFinal[j + 1] = g;
          cutIndicesFinal[j] = h;
        }
        else {
          if (s == previous || t == next) {
            cutIndicesFinal[j + 1] = h;
            cutIndicesFinal[j] = g;
          }
          else {
            // only assumption now is that the next is also a tip and is unorderd
            // (as previous would have been ordered
            next = cutIndicesFinal[(j + 3) % cutIndicesFinal.length];
            if (s == next) {
            cutIndicesFinal[j + 1] = g;
            cutIndicesFinal[j] = h;
            }
            else {
              if (t == next) {
                cutIndicesFinal[j + 1] = h;
                cutIndicesFinal[j] = g;
              }
              else {
                print(
                    "logical falacy in this reasoning for j = " + j.toString());
              }
            }
          }
        }

        j++;
      }
      j++;
    }

    toReturn.add(verticesToReturn);
    toReturn.add(cutIndicesFinal);
    return toReturn;
  }

  num distanceTo(num a, num b, num length) {
    num d1 = (a - b).abs();
    num d2 = (a + (length - b)).abs();
    return min(d1, d2);
  }


  bool colinear (Point one, Point two, Point three) {
    List<num> abc = getLineEq(one, two);

    num a = abc[0];
    num b = abc[1];
    num c = abc[2];

    return ((a * three.x + b * three.y + c).abs() < .000001); // for rounding errors
  }

  // takes a list and a cut index, then returns the next cut index
  int getNextIndex(int element, List<num> cutIndices) {
    int x = cutIndices.indexOf(element);

    int previous = (x + cutIndices.length - 1) % cutIndices.length;
    int next = (x + 1) % cutIndices.length;

    if (x % 2 == 0)
      return cutIndices[next];
    else
      return cutIndices[previous];
  }






  // returns the intersection point on the segment
  // [ vertices[checkingIndex], vertices[(checkingIndex + 1) % vertices.length])
  // (where the second endpoint is not included)
  // unless that intersection point does not contribute to the cut
  Point isIntersection(int checkingIndex, List<Point> verticesWithoutRepeats, List<num> abc) {
    num a, b, c;
    num epsilon = 0.000001; // to deal with rounding errors

    a = abc[0];
    b = abc[1];
    c = abc[2];

    Point end1 = verticesWithoutRepeats[checkingIndex];
    Point end2 = verticesWithoutRepeats[((checkingIndex + 1) % verticesWithoutRepeats.length)];

    //determine whether endpoints of the side are on same side or diff side of line.
    num d1 = (a * end1.x) + (b * end1.y) + c;
    num d2 = (a * end2.x) + (b * end2.y) + c;

    if (d1 * d2 > 0)
      return null; // in this case, the points are on the same side of the line

    if (d1.abs() < epsilon)
      return end1;
    // in this case, the first point is on the line up to rounding errors
    // thus, it needs to be included in the list

    if (d2.abs() < epsilon)
      return null;
    // as the next vertex to be checked will be the vertex at checkingIndex + 1,
    // if only one point is on the line, we don't want to add it twice, so we will
    // not act in this case


    num a2, b2, c2;

    a2 = end2.y - end1.y;
    b2 = end1.x - end2.x;
    c2 = (end2.x * end1.y) - (end1.x * end2.y);

    num returnX = (c2 * b - c * b2) / (a * b2 - a2 * b);
    num returnY = (c * a2 - c2 * a) / (a * b2 - a2 * b);

    return new Point(returnX, returnY);
  }


  // returns true if points are on the same side of
  // the line given by the equationAx + By + C, where abc = [A, B, C]
  bool onSameSide(Point one, Point two, List<num> abc) {
    num a = abc[0];
    num b = abc[1];
    num c = abc[2];

    num d1 = a * one.x + b * one.y + c;
    num d2 = a * two.x + b * two.y + c;

    return ((d1 * d2) > 0);
  }


  List<num> getLineEq(Point line1, Point line2) {
    // getting the line in the form aX + bY + c = 0
    num a, b, c;
    a = line2.y - line1.y;
    b = line1.x - line2.x;
    c = (line2.x * line1.y) - (line1.x * line2.y);

    List<num> toReturn = new List<num>();
    toReturn.add(a);
    toReturn.add(b);
    toReturn.add(c);
    return toReturn;
  }

  bool isInteriorCord(Point one, Point two){
    if (getHitNumber(one, two) != 0)
      return false;

    return containsGridPoint((one.x + two.x) * 1/2, (one.y + two.y) * 1/2);
  }




  // Rotation Methods
  Point vectr(Point one, Point two ) {
    return new Point( one.x-two.x, one.y-two.y );
  }

  void rotateCounterclockwiseBy(double angle, Point center) {
    List<Point> relativePlaces = new List<Point>();
    vertices.forEach( (vertex) => relativePlaces.add(vectr(vertex, center)) );

    List<Point> rotatedPlaces = new List<Point>();
    relativePlaces.forEach( (vector) => rotatedPlaces.add(rotateVectorBy(angle, vector)));

    vertices.clear();
    rotatedPlaces.forEach( (x) => vertices.add(x + center) );
    establishBoundingBox();
    setupSides();

  }

  Point rotateVectorBy(double angle, Point v ) {
    num x = v.x;
    num y = v.y;
    num newx = x * cos(angle) - y * sin(angle);
    num newy = x * sin(angle) + y * cos(angle);

    return new Point(newx, newy);
  }

  // to avoid cumulative rounding errors
  Point rotateVectorBy180Degrees(Point v) {
    return new Point((-1.0) * v.x, (-1.0) * v.y);
  }

  // constructed to avoid any rounding errors associated with sin(pi), ext.
  Piece rotate180Degrees( Point center ) {
    List<Point> relativePlaces = new List<Point>();
    vertices.forEach( (vertex) => relativePlaces.add(vectr(vertex, center)) );

    List<Point> rotatedPlaces = new List<Point>();
    relativePlaces.forEach( (vector) => rotatedPlaces.add(rotateVectorBy180Degrees(vector)));

    List<Point> newVertices = new List<Point>();
    rotatedPlaces.forEach( (x) => newVertices.add(x + center) );

    return new Piece(newVertices);
  }

  bool possibleCenter(Point center, num worldY, num worldX) {
    num xleft = center.x - xmin; // distance currently from center to left side, ext.
    num xright = xmax - center.x;
    num yup = ymax - center.y;
    num ydown = center.y - ymin;

    bool right = center.x + xleft <= worldX; // will rotated piece fit on the world on the left, ext.
    bool left = center.x - xright >= 0;
    bool up = center.y + ydown <= worldY;
    bool down = center.y - yup >= 0;

    return (right && left && up && down);
  }

  //Drawing and Dragging Methods

  //snaps to grid by moving only by integer amounts (TODO: does not snap vertices to grid, is this desirable?)
  void shiftBy(int delx, int dely) {
    for (int i = 0; i<vertices.length; i++) {
      vertices[i]=new Point(vertices[i].x + delx, vertices[i].y + dely);
    }
    establishBoundingBox();
    setupSides();
  }

  void drawAsDragging(CanvasRenderingContext2D ctxt) {
    ctxt.strokeStyle = strokesty;
    ctxt.fillStyle = "#F55";
    mainDraw(ctxt);
  }
  void draw(CanvasRenderingContext2D ctxt) {
    ctxt.strokeStyle = strokesty;
    ctxt.fillStyle = fillsty;
    mainDraw(ctxt);
  }
  
  void mainDraw(CanvasRenderingContext2D ctxt) {
    ctxt.beginPath();
    Point strtpt = vertices.last;
    ctxt.moveTo(getXForHSubTick(strtpt.x), getYForVSubTick(strtpt.y));
    vertices.forEach((vertex) => ctxt.lineTo(getXForHSubTick(vertex.x), getYForVSubTick(vertex.y)));
    ctxt.closePath();
    ctxt.fill();
    ctxt.stroke();
  }
}