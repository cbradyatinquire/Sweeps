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
        
    int hits = 0;
    for (List<Point>side in sides) {
      hits += numIntersections(startPoint, new Point(x, y), side[0], side[1]);
    }

    return ( hits % 2 != 0 );
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
  List<Piece> cutVerticalCavalieri( num xcor ) {
    
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
  }

  // reeturns a list of pieces where the common sides of the original list are glued together (no restrictions)
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
      } //only one vertex touched (outer bounary)
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
