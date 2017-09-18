part of sweeps;

void testShapeNonConvex() {

  pieces.clear();
  Point point1 = new Point (1, 1);
  Point point2 = new Point (1, 5);
  Point point3 = new Point (5, 5);
  Point point4 = new Point (3, 3);
  Point point5 = new Point (5, 1);

  Piece toTest = new Piece ([point1, point2, point3, point4, point5]);
  pieces.clear();
  pieces.add(toTest);
}

void testOfSort() {
  List<num> sort = [1, 2, 3, 3];
  sort.sort((a, b) => a.compareTo(b));
  print(sort);

}

void testPiece1() {
  pieces.clear();
  Piece testPiece = new Piece( [new Point (2, 0), new Point (6, 4), new Point (6, 4), new Point (3, 7), new Point (5, 9), new Point (3, 11), new Point (6, 14), new Point (9, 14), new Point (6, 11), new Point (6, 11), new Point (8, 9), new Point (6, 7), new Point (6, 7), new Point (9, 4), new Point (6.0, 1.0), new Point (5, 0)]);
  pieces.add(testPiece);
}

void testPiece2() {
  pieces.clear();
  Piece testPiece = new Piece([ new Point (2, 0), new Point (2, 1), new Point (5, 4), new Point (4, 5), new Point (6, 7), new Point (3, 10), new Point (6, 13), new Point (6, 14), new Point (4, 16), new Point (4, 17), new Point (6, 19), new Point (7.0, 19.0), new Point (10, 19), new Point (8, 17), new Point (8, 16), new Point (10, 14), new Point (10, 13), new Point (7, 10), new Point (7, 10), new Point (10, 7), new Point (8, 5), new Point (9, 4), new Point (7.0, 2.0), new Point (6, 1), new Point (6, 0)]);
  pieces.add(testPiece);
}

void testPiece3() {
  pieces.clear();
  Piece testPiece = new Piece( [ new Point (6, 0), new Point (7, 1), new Point (7, 2), new Point (8, 3), new Point (7.0, 4.0), new Point (6, 5), new Point (6, 6), new Point (7.0, 7.0), new Point (9, 9), new Point (8, 10), new Point (9, 11), new Point (16, 11), new Point (15, 10), new Point (16, 9), new Point (13, 6), new Point (13, 5), new Point (15, 3), new Point (14, 2), new Point (14, 1), new Point (13, 0), new Point (7.0, 0.0)]);
  pieces.add(testPiece);
}


void testVerticalCutting() {
  /*
   * [Point(3, 1), Point(4, 2), Point(5, 3), Point(4, 4), Point(3, 5), Point(3, 6), Point(4, 7), Point(9, 7), Point(8, 6), Point(8, 5), Point(9, 4), Point(10, 3), Point(9, 2), Point(8, 1)]
   *
       */
  List<Point> pointsForTestPiece =
  /*     [new Point(3, 1), new Point(4, 2), new Point(5, 3), new Point(4, 4), new Point(3, 5), new Point(3, 6),
       new Point(4, 7), new Point(9, 7), new Point(8, 6), new Point(8, 5), new Point(9, 4), new Point(10, 3), new Point(9, 2), new Point(8, 1)];
*/
  /*
      [new Point(2, 1), new Point(3, 2), new Point(2, 3), new Point(2, 4), new Point(3, 5), new Point(2, 6),
       new Point(3, 7), new Point(3, 8), new Point(7, 8), new Point(7, 7), new Point(6, 6), new Point(7, 5),
       new Point(6, 4), new Point(6, 3), new Point(7, 2), new Point(6, 1)];
  */
  [new Point(2, 1), new Point(3, 2), new Point(2, 3), new Point(3, 4), new Point(3, 5), new Point(2, 6),
  new Point(7, 6), new Point(8, 5), new Point(8, 4), new Point(7, 3), new Point(8, 2), new Point(7, 1)];

  Piece testPiece = new Piece(pointsForTestPiece);
  List<Piece> returns = testPiece.cutVertical(3.0);
  print("*************");
  returns.forEach( (piece) => print(piece.vertices.toString() ));
  print("*************");
}