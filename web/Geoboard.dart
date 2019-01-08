part of sweeps;

// variables having to do with dragging vertices:
int pieceIndexSelected = null; // for determining which piece is being changed
int vertexIndexSelected = null; // for determining which vertex is being dragged
Point selectedVertex = null; // for drawing the vertex as it moves
bool draggingVertex = false; // general purpose variable for checking

// so that the shape can be returned to the original state if the final location of the vertex
Piece originalPieceBeforeModification = null;


List<Point> problemPoints = new List<Point>();

num uncertaintyAllowed = .2; //uncertainty on the clicks

// On a click, choose a vertex, inputted point is in tick coordinates
void selectVertex(Point pt) {
  int pieceIndex = 0;
  int vertexIndex = 0;

  draggingVertex = false;

  while (pieceIndex < pieces.length && (!draggingVertex) ) {
    while (vertexIndex < pieces[pieceIndex].vertices.length && (!draggingVertex)) {
      if (pieces[pieceIndex].vertices[vertexIndex].distanceTo(pt) < uncertaintyAllowed) {
        pieceIndexSelected = pieceIndex;
        vertexIndexSelected = vertexIndex;
        originalPieceBeforeModification = new Piece(pieces[pieceIndex].vertices);
        originalPieceBeforeModification.setColorString(pieces[pieceIndex].fillsty);
        draggingVertex = true;
      }
      else {
        vertexIndex++;
      }
    }

    if (!draggingVertex) {
      vertexIndex = 0;
      pieceIndex++;
    }
  }


  if (!draggingVertex) {
    pieceIndex = 0;
    int firstVertexIndex = 0;

    while (pieceIndex < pieces.length && (!draggingVertex)) {
      List<Point> vertices = pieces[pieceIndex].vertices;

      num len = pieces[pieceIndex].vertices.length;

      while (firstVertexIndex < len && (!draggingVertex)) {
        if (isOnSegment(pt, vertices[firstVertexIndex], vertices[(firstVertexIndex + 1) % len])) {
          originalPieceBeforeModification = new Piece(pieces[pieceIndex].vertices);
          originalPieceBeforeModification.setColorString(pieces[pieceIndex].fillsty);
          pieces[pieceIndex].vertices.insert(firstVertexIndex + 1, pt);
          pieceIndexSelected = pieceIndex;
          vertexIndexSelected = firstVertexIndex + 1;
          draggingVertex = true;
        }
        else {
          firstVertexIndex++;
        }
      }

      if (!draggingVertex) {
        firstVertexIndex = 0;
        pieceIndex++;
      }

    }

  }
}



// returns true if the first inputted point is on the line segment specified
// by the second and third inputted points (up to the uncertainty) and false otherwise
bool isOnSegment(Point test, Point v1, Point v2) {
  if ((v1.distanceTo(test) < uncertaintyAllowed) ||
      (v2.distanceTo(test) < uncertaintyAllowed)) {
    return false; // want to see if this should be a new point, though here this should not actually make much of a difference
  }

  if (v2.distanceTo(v1) == 0) {
    return false;
  }
  // if v1 and v2 are the same point, there was an error in the function's inputs

  if ((test.x < v1.x) == (test.x < v2.x)) {
    if ((v1.x - v2.x).abs() > uncertaintyAllowed) {
      return false;
    }
  }

  if ((test.y < v1.y) == (test.y < v2.y)) {
    if ((v1.y - v2.y).abs() > uncertaintyAllowed) {
      return false;
    }
  }

  num dist = ((v2.y - v1.y) * (test.x - v1.x) - (v2.x - v1.x) * (test.y - v1.y)).abs() / (v2.distanceTo(v1));
  return (dist < uncertaintyAllowed);

}

// general drawing method
void drawGEO() {
  CanvasRenderingContext2D ctx = canv.context2D;
  ctx.clearRect(0, 0, canv.width, canv.height);

  drawGridAndRulers(canv);
  drawTools();


  pieces.forEach((piece) => piece.draw(ctx));

  pieces.forEach((piece) => (piece.vertices.forEach((p) => drawPoint(ctx, convertFromTickCoordinates(p), "#999", radiusOfRotationPoints))));

  //problemPoints.forEach((p) => drawPoint(ctx, convertFromTickCoordinates(p), "#C4C", radiusOfRotationPoints));

  if (draggingVertex) {
    Point selectedVertex = pieces[pieceIndexSelected].vertices[vertexIndexSelected];
    drawPoint(ctx, convertFromTickCoordinates(selectedVertex), "#222", radiusOfRotationPoints);
  }
}


// tests to see if there is an overlap when the point in the piece
// at index i in the piece's vertex list is replaced by the point pt
bool doesNotHitSide(Piece p, int index, Point pt) {
  Point v1 = p.vertices[(index - 1) % p.vertices.length];
  Point v2 = p.vertices[(index + 1) % p.vertices.length];

  // the sides v1 pt and v2, pt are the new sides bordering the selected point

  problemPoints = new List<Point>();

  int len = p.vertices.length;
  int j = 0;
  while (j < p.vertices.length) {
    Point tv1 = p.vertices[j];
    Point tv2 = p.vertices[(j + 1) % len];

    //checking the side (j, j + 1) against the side at (index, index + 1)
    if (((j - index) % len != 0) && ((j - (index + 1)) % len != 0) && (((j + 1) - (index + 1)) % len != 0) && (((j + 1) - index) % len != 0)) {
      if (p.numIntersections(v2, pt, tv1, tv2) == 1) {
        // print("hit");
        //print("the piece has " + p.vertices.length.toString() + " vertices");

        problemPoints.add(tv1);
        problemPoints.add(tv2);
      }
    }

    // checking the side (j, j + 1) against the side at (index - 1, index)
    if (((j - index) % len != 0) && ((j - (index - 1)) % len != 0) && (((j + 1) - (index - 1)) % len != 0) && (((j + 1) - index) % len != 0)) {
      if (p.numIntersections(v1, pt, tv1, tv2) == 1) {
        // print("hit");
        // print("the piece has " + p.vertices.length.toString() + " vertices");

        problemPoints.add(tv1);
        problemPoints.add(tv2);
      }
    }
    j++;
  }

  if (problemPoints.length > 0) {
    return false;
  }

  return true;
}



//GEOBOARD HAS AN IMMEDIATE RESPONSE TO THE CLICK.
void startDragGEO(MouseEvent event) {
  clickLogicGEO(event.offset);
}

void startTouchGEO(TouchEvent evt) {
  Point initPoint = evt.changedTouches[0].client;
  clickLogicGEO(initPoint);
}

void clickLogicGEO(Point mousePoint) { // inputted point is where the mouse clicked in computer's coordinates, not the world's constructed ones; logic for mouse DOWN only
  if (!draggingVertex) {
    selectVertex(convertToTickCord(mousePoint));
  }
  //print(draggingVertex);

  drawGEO();
}

void touchDragGEO(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;

  generalDraggingGEO(currPoint);
}

void generalDraggingGEO(Point p) {
  if (draggingVertex) {
    Point pt = convertToTickCord(p);

    if (doesNotHitSide(pieces[pieceIndexSelected], vertexIndexSelected, pt)) {
      pieces[pieceIndexSelected].vertices[vertexIndexSelected] = pt;
    }
  }

  drawGEO();
}

void mouseDragGEO(MouseEvent event) {
  Point currPoint = event.offset;

  generalDraggingGEO(currPoint);
}

void stopDragGEO(MouseEvent event) {

  Point finalPoint = event.offset;

  drawEndGEO(finalPoint);
}

void stopTouchGEO(TouchEvent evt) {
  Point currPoint = evt.changedTouches[0].client;

  drawEndGEO(currPoint);
}

void drawEndGEO(Point p) {
  if (draggingVertex) {
    // removing an adjacent vertex if the vertex moved is on top of this
    num len = pieces[pieceIndexSelected].vertices.length;

    Point newPoint = roundPoint(pieces[pieceIndexSelected], vertexIndexSelected, p);

    if (newPoint == null) {
      pieces[pieceIndexSelected] = originalPieceBeforeModification;
    }
    else {
      pieces[pieceIndexSelected].vertices[vertexIndexSelected] = newPoint;

      if (pieces[pieceIndexSelected].vertices[(vertexIndexSelected - 1) % len]
          .distanceTo(newPoint) < uncertaintyAllowed) {
        pieces[pieceIndexSelected].vertices.removeAt(
            (vertexIndexSelected - 1) % len);
      }
      if (pieces[pieceIndexSelected].vertices[(vertexIndexSelected + 1) % len]
          .distanceTo(newPoint) < uncertaintyAllowed) {
        pieces[pieceIndexSelected].vertices.removeAt(
            (vertexIndexSelected + 1) % len);
      }
    }
  }

  pieceIndexSelected = null;
  vertexIndexSelected = null;
  draggingVertex = false;
  selectedVertex = null;
  originalPieceBeforeModification = null;

  drawGEO();
}



// gets the grid point that a rubber band would snap to
Point roundPoint(Piece p, int index, Point pt) { // piece, index of selected point, place to move selected point to
  Point inTicks = convertToTickCord(pt);

  num currentPlacedX = inTicks.x;
  num currentPlacedY = inTicks.y;

  num lowx = currentPlacedX.floor();
  num lowy = currentPlacedY.floor();

  int len = p.vertices.length;
  Point v1 = p.vertices[(index - 1) % len];
  Point v2 = p.vertices[(index + 1) % len];

  Point p1 = new Point (lowx, lowy);
  Point p2 = new Point (lowx + 1, lowy);
  Point p3 = new Point (lowx, lowy + 1);
  Point p4 = new Point (lowx + 1, lowy + 1);

  List<Point> possibilities = [p1, p2, p3, p4];

  int i = 0;
  while (i < possibilities.length) {
    if (doesNotHitSide(p, index, possibilities[i])) {
      i++;
    }
    else {
      if (p.vertices[(index + 1) % len].distanceTo(possibilities[i]) <
          uncertaintyAllowed ||
          p.vertices[(index - 1) % len].distanceTo(possibilities[i]) <
              uncertaintyAllowed) {
        i++;
      }
      else {
        possibilities.removeAt(i);
      }
    }
  }

  if (possibilities.length == 0) {
    return null;
  }
  else {
   int keepingIndex = 0;
   num distK = v1.distanceTo(possibilities[0]) + v2.distanceTo(possibilities[0]);
   int currentIndex = 0;
   while (currentIndex < possibilities.length) {
     num distC = v1.distanceTo(possibilities[currentIndex]) + v2.distanceTo(possibilities[currentIndex]);
     if (distC < distK) {
       keepingIndex = currentIndex;
       distK = distC;
     }
     currentIndex++;
   }
   return possibilities[keepingIndex];
  }
}

// converts between computer and tick coordinate systems
Point convertToTickCord(Point p) {
  num tickx = (hSubTicks * (p.x - hoff) / (ticwid));
  num ticky = (vSubTicks * (p.y - voff) / (ticht));

  return new Point(tickx, ticky);
}


Point convertFromTickCoordinates(Point p) {
  num xcor = ((p.x * ticwid / hSubTicks) + hoff).round();
  num ycor = ((p.y * ticht / vSubTicks) + voff).round();
  return new Point(xcor, ycor);
}


