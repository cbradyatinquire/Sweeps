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

  String verticesAsString() {
    String rtn = "";
    vertices.forEach((vertex) => rtn += "\nVertex: (" + vertex.x.toString() + "," + vertex.y.toString() + ")");
    return rtn;
  }

  num interpolatedY(Point a, Point b, num xval) {
    if (b.x == a.x) {
      return a.y;
    } else {
      double percentage = (xval - a.x) / (b.x - a.x);
      num dely = (b.y - a.y);
      return a.y + dely * percentage;
    }
  }


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
    }
  }
  
  
  bool hitParityOdd( num x, num y ) {
    Point startPoint = new Point(xmin - 1.02, (ymax - ymin) / 2);
    //Point startPoint = new Point(0, 5);
        
    int hits = 0;
    for (List<Point>side in sides) {
      hits += numIntersections(startPoint, new Point(x, y), side[0], side[1]);
    }
    //if (hits > 0) { 
      //print("for (x, y) = (" + x.toString() + ", " + y.toString() + "), we have " + hits.toString() + " hits");
    //}
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
    else { 
      if ( ( (a1 * b2) - (a2 * b1) ).abs() < epsilon   ) { return 0; }
      else { return 1;} 
    }
  }
  
  
  bool correctedHitTest(Point gridPoint) {
    return containsGridPoint( gridPoint.x, gridPoint.y );
  }
  
//  bool hitTest( Point click ) {
//    String side = "?";
//    Point init = vertices.last;
//    Point v0 = new Point( getXForHSubTick(init.x), getYForVSubTick(init.y) );
//    for (int i = 0; i < vertices.length; i++) {
//      Point fin = vertices[i];
//      Point v1 = new Point( getXForHSubTick(fin.x), getYForVSubTick(fin.y) );
//      Point asegment = vectr(v1, v0);
//      Point apoint = vectr(click, v0);
//      String sideNow = sideOfSegment(asegment, apoint);
//      if ( sideNow == "NONE" ) { return false; }
//      else if (side == "?") {side = sideNow; }
//      else if (side != sideNow) { return false; }
//      init = fin;
//      v0=v1;
//    }
//    return true;
//  }
  
  Point vectr(Point one, Point two ) {
    return new Point( one.x-two.x, one.y-two.y );
  }
  
  num magXProduct(Point a, Point b) {
    return ( a.x*b.y - a.y*b.x );
  }
  
  String sideOfSegment( Point segment, Point pt) {
    num xp = magXProduct(segment, pt);
    if (xp < 0) { return "Left"; }
    else if (xp > 0) { return "Right"; }
    else { return "NONE"; }
  }
  
  
  
  Point intersect( num xcor, Point e1, Point e2 ) {
    num epsilon = .0001;
    num dist = (e1.x - e2.x).abs();
    if (dist < epsilon) { //print("dist < epsilon"); 
      return null; }
    num d1 = (e1.x - xcor).abs();
    num d2 = (e2.x - xcor).abs();
    if ( dist == d1 + d2) {
      if (d1 == 0) { //print("hit endpoint 1" + e1.toString()); 
        return e1; }
      if (d2 == 0) { //print("hit endpoint 2" + e2.toString()); 
        return e2; }
      num perc1 = 1 - (d1 / dist);
      num perc2 = 1 - (d2 / dist);
      return new Point( perc1 * e1.x + perc2 * e2.x,  perc1 * e1.y + perc2 * e2.y );
    } else {
      return null;
    }
  }
  
  List<int> createOrderedPointsWithCutVertices(num xcor ) {
    orderedPointsWithCutVertices = new List<Point>();
    List<int> cutVertexIndices = new List<int>();
    
    for (List<Point> side in sides ) {
      Point vfirst = side[0];
      Point vsecond = side[1];
      Point intersection = intersect(xcor, vfirst, vsecond);
      if (intersection == null && !(vfirst.x == xcor) ) {
        orderedPointsWithCutVertices.add(vfirst);
      } else {
        if ( intersection == vfirst || vfirst.x == xcor ) {
          cutVertexIndices.add( orderedPointsWithCutVertices.length );
          orderedPointsWithCutVertices.add(vfirst);
        } else {
          orderedPointsWithCutVertices.add(vfirst);
          if (! ( intersection == vsecond ) ) {
            cutVertexIndices.add( orderedPointsWithCutVertices.length );
            orderedPointsWithCutVertices.add(intersection);
          }
        }
      }
    }
    return cutVertexIndices;
  }
  
  int findGoodCutIndex( List<int> cutList, List<int> totalList ) {
    if (cutList.length == 0) { return null; }
    int indexShift = cutList.first;
    int lastIndex = totalList.indexOf( indexShift );
    //int lastIndex = indexShift;
    print("in findgoodcutindex.  cutlist = " + cutList.toString() + " and totalList = " + totalList.toString() );
    print("indexShift =  " + indexShift.toString() );
    for (int i = 1; i<totalList.length; i++) {
      int index = ( indexShift + i ) % totalList.length;
      if ( !cutList.contains( totalList[ index ] ) ) {
        print("found that index = " + index.toString() + " we were not in the cutlist, so returning " + lastIndex.toString() );
        return lastIndex;
      }
      lastIndex = index;
    }
    print("FINDGOODCUTINDEX -->  lists were the same -- returning null");
    return null;
  }
  
  
  List<Piece>cutVerticalCavalieri( num xcor ) {

    List<Piece> myPieces = [this];
    
    for (int yc = 0; yc < vticks * vSubTicks; yc++) {
      List<Piece> newPcs = new List<Piece>();
      myPieces.forEach((piece) => newPcs.addAll(piece.cutHorizontal(yc)));
      myPieces = newPcs;
    }
    
   // for (int xc = 0; xc < hticks * hSubTicks; xc++) {
      List<Piece> newPcs = new List<Piece>();
      myPieces.forEach((piece) => newPcs.addAll(piece.cutVertical(xcor)));
      myPieces = newPcs;
   // }
    
    List<Piece>realPieces = new List<Piece>();
    realPieces.addAll(myPieces.where( (piece) => (piece.vertices.length > 2) ) );
    
    realPieces.sort( (a, b) => (a.minimumY()).compareTo(b.minimumY()) );
    
    List<Piece>leftPieces = new List<Piece>();
    leftPieces.addAll( realPieces.where( (piece) => (piece.maximumX() <= xcor) ) );
    List<Piece>rightPieces = new List<Piece>();
    rightPieces.addAll(  realPieces.where( (piece) => (piece.minimumX() >= xcor) ) );
    
    List<Piece> endPieces = new List<Piece>();
    endPieces.addAll( coalesce(leftPieces) );
    endPieces.addAll( coalesce(rightPieces) );
    
    return endPieces;
  }
  
  List<Piece>coalesce( List<Piece> inputPieces ) {
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
  
  bool sharesSideWith( Piece another ) {
    for (List<Point> side in sides) {
      List<List<Point>> asides = another.sides;
      for (List<Point> aside in asides ) {
        if ( side.contains(aside.first) && side.contains(aside.last) )
          return true;
      }
    }
    return false;
  }
  
  Piece aggregate( Piece one, Piece another) {
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
  
  num minimumY() {
    num miny = vticks*vSubTicks;
    for ( Point v in vertices ) {
      if ( v.y < miny ) { miny = v.y; }
    }
    return miny;
  }
  
  num minimumX() {
    num minx = hticks*hSubTicks;
    for ( Point v in vertices ) {
      if ( v.x < minx ) { minx = v.x; }
    }
    return minx;
  }
  
  num maximumX() {
    num maxx = 0;
    for (Point v in vertices) {
      if (v.x > maxx) { maxx = v.x; }
    }
    return maxx;
  }
  
  List<Piece>cutVerticalCavalieriDiscardedNew( num xcor ) {
    print("BEGIN -- cut with xcor = " + xcor.toString() );
    print("Piece's vertices = " + vertices.toString() );
    List<Piece> newPieces = new List<Piece>();
    List<int> cutVertexIndexList = createOrderedPointsWithCutVertices(xcor);
    List<int> includeVertexIndexList = range( 0, orderedPointsWithCutVertices.length, 1 );
    
    int firstCutIndex = findGoodCutIndex( cutVertexIndexList, includeVertexIndexList ); 
    if (firstCutIndex == null) { newPieces.add(this); return newPieces; }
    print("first cut index (counting among included indices) will be " + firstCutIndex.toString() );
    
    while (firstCutIndex != null) {
      print("NEW OUTER LOOP");
      print("Original piece's total set of vertices: " + orderedPointsWithCutVertices.toString() );
      print("cut indices are " + cutVertexIndexList.toString() );
      print("included indices are " + includeVertexIndexList.toString() );
      
      List<Point> accumulatingShapePoints = new List<Point>();
      Point compareCutPoint = orderedPointsWithCutVertices[includeVertexIndexList[firstCutIndex]];
      accumulatingShapePoints.add( compareCutPoint );
      print("compare cut Point is " + compareCutPoint.toString() );
      
      int i = 1;
      bool keepGoing = true;
      List<int> nonCutVertexIndicesAccountedFor = new List<int>();
      print ("inner loop");
      while ( i < includeVertexIndexList.length  && keepGoing) {
        Point movingCompareCutPoint = new Point( compareCutPoint.x, compareCutPoint.y );
        print("i = " + i.toString() );
        int vIndexPoint = ( i + firstCutIndex ) % includeVertexIndexList.length;
        print("vIndexPoint = " + vIndexPoint.toString() );
        int index = includeVertexIndexList[ vIndexPoint ];
        print("index = " + index.toString() );
        Point focusPoint = orderedPointsWithCutVertices[index];
        print("focusPoint = " + focusPoint.toString() );
        accumulatingShapePoints.add( focusPoint );
        if ( cutVertexIndexList.contains( index )) {
          print("the cutVertexIndexList contained " + index.toString() );
          //get compare cutpoint
          int adjustedI = includeVertexIndexList.length;
          for (int j = 0; j <= includeVertexIndexList.length; j++) {
            int testIndex = ( j + firstCutIndex ) % includeVertexIndexList.length;
            Point test = orderedPointsWithCutVertices[testIndex];
            if (cutVertexIndexList.contains( testIndex ) &&  strictBetween( focusPoint.y, test.y, movingCompareCutPoint.y )) {
              print("Looks like the cut vertex index " + testIndex.toString() + " (i.e., " + test.toString() + ") is better than " + compareCutPoint.toString() );
              movingCompareCutPoint = test;
              adjustedI = j;
              print("Shifting the compare point to " + test.toString() + " which would adjust i to " + j.toString() );
              if (adjustedI < i) { print("OOPS should not have a case where adjusted i goes down! Here i = " + i.toString() + " and adjusted i = " + adjustedI.toString() ); }
              if (adjustedI == 1) { keepGoing = false; }
            }
          }
          
          //get checkInsidePoint
          Point checkInsidePoint = new Point( xcor, (movingCompareCutPoint.y + focusPoint.y)/2); 
          print("in-out bounds check for checkInsidePoint " + checkInsidePoint.toString() + " which is midpoint of " + movingCompareCutPoint.toString() + " and " + focusPoint.toString() );
          if ( this.containsGridPoint(checkInsidePoint.x, checkInsidePoint.y) ) {
            //if inside original shape, move i to skip the intervening vertices.
            print("WAS inside.  so...");
            if (adjustedI < i ) { print( "ERROR SIGN - i should not be adjusted down "); }
            if (adjustedI == i) { print("WARNING -- i adjusted to itself. adding one"); adjustedI = i + 1; }
            else {
              print("skipping our index i 'ahead' to " + adjustedI.toString() ); 
              i = adjustedI; 
              //and add the new compare cut point
              accumulatingShapePoints.add( movingCompareCutPoint );
            }
          } else {
            print("WAS NOT inside.  just proceeding...");
            i = i + 1;
          }
        } else {
          nonCutVertexIndicesAccountedFor.add(index);
          i = i + 1;
        }
        
      }//inner while -- looping through the vertices still to be accounted for.
      
      //add the piece we just traced to our set to return
      newPieces.add( new Piece(accumulatingShapePoints ));
      print("Added new piece with points " + accumulatingShapePoints.toString() );
      
      //and clean up our accounting lists.
      accumulatingShapePoints.clear();
      includeVertexIndexList.removeWhere( (ind) => nonCutVertexIndicesAccountedFor.contains(ind) );
      nonCutVertexIndicesAccountedFor.clear();
      
      print("=========================== Going back around=================");
      //finally, find a good place to start the next round
      firstCutIndex = findGoodCutIndex( cutVertexIndexList, includeVertexIndexList );
      print("first cut index (counting among included indices) will be " + firstCutIndex.toString() );
    }//outer while - while there are any non-cut indices to account for
    
    print("returning " + newPieces.length.toString() + " new pieces");
    return newPieces;
  }
  
  bool strictBetween( num one, num test, num another ) {
    if (test == one || test == another ) { return false; }
    return ( (one-test).abs() + (test-another).abs() == (one-another).abs() );
  }
  
  
  List<int> range(int start, int end, int step) {
    List<int> myRange = new List<int>();
    for (int i = start; i<end; i=i+step) {
      myRange.add(i);
    }
    return myRange;
  }
  
  
  List<Piece>cutVerticalCavalieriOLDNew(num xcor) {
    
    List<Piece> toReturn = new List<Piece>();
    List<int> cutVertexList = createOrderedPointsWithCutVertices(xcor);
    
//    print("cut indices");
//    print( cutVertexList.toString() );
//    print("augmentex vertex list");
//    print( orderedPointsWithCutVertices.toString() );
    
    if (cutVertexList.isEmpty) { 
      toReturn.add(this);
      return toReturn;
    }
    int startAt = cutVertexList.first;
    List<Point> pointsForRemainderPiece = new List<Point>();
    List<Point> indeterminatePoints = new List<Point>();
    
    pointsForRemainderPiece.add(orderedPointsWithCutVertices[startAt]);
    indeterminatePoints.add(orderedPointsWithCutVertices[startAt]);
    
    for (int i = 1; i<= orderedPointsWithCutVertices.length; i++) {  
      int index = startAt + i;
      Point v = orderedPointsWithCutVertices[ index % orderedPointsWithCutVertices.length ];
      indeterminatePoints.add(v);
      print("TOP of loop. testing if v= " + v.toString() + " is a cut point" );
      if (cutVertexList.contains(index)) {
        Point compareStart = pointsForRemainderPiece.last;
        num starty = compareStart.y;
        
        Point compareEnd = v;
        num endy = compareEnd.y;
        
        for (int j in cutVertexList) {
          Point test = orderedPointsWithCutVertices[j];
          if (strictBetween( starty, test.y, endy )) {
            compareStart = test;
            starty = test.y;
          }
        }
        
        Point checkPoint = new Point( xcor, (compareStart.y + compareEnd.y)/2); 
        print("in-out bounds check: midpoint between " + compareStart.toString() + " and " + compareEnd.toString() );

        if ( this.containsGridPoint(checkPoint.x, checkPoint.y) ) {
          print("...and found that it was inside.  so we'd close off the shape");
          print("making a piece with the points " + indeterminatePoints.toString() );
          toReturn.add( new Piece(orderPoints(indeterminatePoints)) );
        } else {
          print("...and found that it was outside. so, add the last cluster to the remainder piece pile");
          pointsForRemainderPiece.addAll(indeterminatePoints);
          print(" now the accumulating points are " + pointsForRemainderPiece.toString() );
        }
        //either way, the indeterminate points list needs to get reinitialized with the last cutpoint.
        indeterminatePoints = new List<Point>();
        print("-- re-initializing the set of indeterminate points with v = " + v.toString() );
        indeterminatePoints.add(v);
      } else {
        print(v.toString() + " is not in cut vertex list.");
      }
    }
    pointsForRemainderPiece.addAll(indeterminatePoints);
    print( "Final piece from REMAINDER piece points: " + pointsForRemainderPiece.toString() );
    toReturn.add( new Piece(orderPoints(pointsForRemainderPiece)) );
    return toReturn;
  }
  
  
//  List<Piece>cutVerticalCavalieri(num xcor ) {
//    
//    print (this.vertices);
//    List<Piece> toReturn = new List<Piece>();
//    
//    bool inside = false;  //state marker for whether our falling vertical line is inside the figure.
//    Point newBoundaryPt1;  //marker for the first crossing point for inside.
//    int embracedIndexStart = 0; //index of first vertex that is to be excised by the cut.
//    Point priorVertex = vertices.last;
//    Point nextVertex = vertices.first;
//    int nextVertexIndex = 0;
//    
//    Point firstNew =  intersect( xcor, nextVertex, priorVertex );
//    if ( firstNew != null) {   //hits first segment of figure
//      inside = (   correctedHitTest( new Point(firstNew.x + .1 , firstNew.y + .5) )  && correctedHitTest( new Point(firstNew.x - .1 , firstNew.y + .5) )) ;
//      print("hit first segment.  inside check = " + inside.toString() );
//      embracedIndexStart = nextVertexIndex;
//    } 
//    nextVertexIndex++;
//    
//    while (  (firstNew == null || !inside ) && nextVertexIndex < vertices.length  ){
//      Point priorVertex = vertices[nextVertexIndex - 1];
//      Point nextVertex = vertices[nextVertexIndex];
//      firstNew =  intersect( xcor, nextVertex, priorVertex );
//      if ( firstNew != null) {   
//        
//        inside = (   correctedHitTest( new Point(firstNew.x + .1 , firstNew.y + .5) )  && correctedHitTest( new Point(firstNew.x - .1 , firstNew.y + .5) )) ;
//        print("hit segment defined by " + priorVertex.toString() + " and " + nextVertex.toString() + ". inside check = " + inside.toString() );
//        embracedIndexStart = nextVertexIndex;
//      }
//      nextVertexIndex++;
//    }
//    
//    if ( firstNew != null && inside && nextVertexIndex < vertices.length - 1) {  //we know that we're at nextVertexIndex < length b/c we're inside.
//      newBoundaryPt1 = firstNew;
//    
//      Point newBoundaryPt2 = null;
//      while (  (newBoundaryPt2 == null || newBoundaryPt2 == newBoundaryPt1) && nextVertexIndex < vertices.length ){  //now we are just looking for first intersect.  inside no longer to be checked
//        Point priorVertex = vertices[nextVertexIndex - 1];
//        Point nextVertex = vertices[nextVertexIndex];
//        newBoundaryPt2 =  intersect( xcor, nextVertex, priorVertex );
//        nextVertexIndex++;
//      }
//      
//      if (newBoundaryPt2 == null || newBoundaryPt2 == newBoundaryPt1) {
//        print("Should not happen -- second new is null at xcor " + xcor.toString() );
//        toReturn.add( this ); //assume no hit.  so just return ourself.
//        return toReturn;
//      }
//      else  {
//        print("hit at x=" + xcor.toString() + " -- cutting.  boundary points are: " + newBoundaryPt1.toString() + ", and " + newBoundaryPt2.toString() );
//        List<Point> pts = new List<Point>();
//        Point rnd1 = new Point( newBoundaryPt1.x.roundToDouble(), newBoundaryPt1.y.roundToDouble() );
//        if (vertices[embracedIndexStart] == rnd1) { 
//          print("skipping endpoint " + vertices[embracedIndexStart].toString() + " == " + rnd1.toString() );
//        } else {
//          pts.add(rnd1);
//        }
//        //TODO: HERE IS THE PROBLEM --! I think
//        for (int i = embracedIndexStart; i< nextVertexIndex-1; i++) {
//          pts.add(vertices[i]);
//        }
//        Point rnd2 = new Point( newBoundaryPt2.x.roundToDouble() , newBoundaryPt2.y.roundToDouble() );
//        if ( vertices[nextVertexIndex-1] == rnd2 ) { 
//          print( "skipping endpoint " + vertices[nextVertexIndex-1].toString() + " == " + rnd2.toString() );
//          pts.add(vertices[nextVertexIndex-1]);
//        } else {
//          //SHOULD I CHECK AGAINST THE PRIOR VERTEX FOR EQUALITY?  I THINK NOT NECESSARY.
//          pts.add(rnd2);
//          //pts.add(vertices[nextVertexIndex-1]);
//        }
//        
//        
//        List<Point>orderdPts = orderPoints(pts);
//        toReturn.addAll((new Piece(orderdPts)).cutVerticalCavalieri( xcor ));
//        
//        pts = new List<Point>();
//        
//       
//        for (int j = 0; j<embracedIndexStart; j++) {
//          pts.add(vertices[j]);
//        }
//        int checkIndex = (embracedIndexStart - 1) % vertices.length;
//        if ( vertices[checkIndex] == rnd1 ) {
//          print("skipping endpoint on new remainder piece " + vertices[checkIndex].toString() + " == " + rnd1.toString()  );
//        } else  {
//         pts.add(rnd1);
//        }
//        checkIndex = nextVertexIndex % vertices.length;
//        if (vertices[checkIndex] == rnd2 ) {
//          print("skipping endpoint on new remainder piece " + vertices[checkIndex].toString() + " == " + rnd2.toString()  );
//        } else {
//          pts.add(rnd2);
//        }
//        
//        if (rnd2 != vertices[nextVertexIndex-1]) {
//           pts.add(vertices[nextVertexIndex-1]);
//         }
//        
//        for (int k = nextVertexIndex; k<vertices.length; k++) {
//          pts.add(vertices[k]);
//        }
//        orderdPts = orderPoints(pts);
//        toReturn.addAll((new Piece(orderdPts)).cutVerticalCavalieri( xcor ));
//      }
//      return toReturn;
//  }//if we have hit
//    else { //missed.  so just return ourself.
//      print("missed, returning self: ");
//      toReturn.add(this);
//      return toReturn;
//    }
//  }
  
  //order points so that the left-most point with the lowest y-coord is first in the list.
 
  List<Point>orderPoints( List<Point>inPts ) {
    //find first appearance of the lowest y-coord.
    if (inPts.length == 0) { return inPts; }
    
    List<Point> ordered = new List<Point>();
    num lowx = inPts.first.x;
    num lowcor = inPts.first.y;
    int index = 0;
    
    for (int j = 0; j< inPts.length; j++ ) {
      Point p = inPts[j];
      if (p.y < lowcor) {lowcor = p.y; lowx = p.x; index = j;}
      else if ( p.y == lowcor && p.x < lowx) {
        lowx = p.x;
        index = j;
      }
    }
    
    for (int i = 0; i<inPts.length; i++) {
      ordered.add( inPts[ (index + i) % inPts.length ] );
    }
    
//    print("pre-ordering");
//    print(inPts.toString());
//    print("post-ordering");
//    print(ordered.toString());
    
    return ordered;
  }
  
  
  List<Piece> cutVertical(num xcor) {
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

  List<Piece> cutHorizontal(num ycor) {
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

  void shiftBy(int delx, int dely) {
    for (int i = 0; i<vertices.length; i++) {
      vertices[i]=new Point(vertices[i].x + delx, vertices[i].y + dely);
    }
    establishBoundingBox();
    setupSides();
    //vertices.map((vertex) => new Point(vertex.x + delx, vertex.y + dely));
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
