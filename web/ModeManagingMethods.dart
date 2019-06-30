part of "sweeps.dart";

void TurnOffSETUP() {
  SETUPMouseDown.pause();
  SETUPTouchStart.pause();
  SETUPMouseMove.pause();
  SETUPTouchMove.pause();
  SETUPMouseUp.pause();
  SETUPTouchEnd.pause();
}

void TurnOnSETUP() {
  while (SETUPMouseDown.isPaused) {
    SETUPMouseDown.resume();
    SETUPTouchStart.resume();
    SETUPMouseMove.resume();
    SETUPTouchMove.resume();
    SETUPMouseUp.resume();
    SETUPTouchEnd.resume();
  }
}


void TurnOffSWEEP() {
  SWEEPMouseDown.pause();
  SWEEPTouchStart.pause();
  SWEEPMouseMove.pause();
  SWEEPTouchMove.pause();
  SWEEPMouseUp.pause();
  SWEEPTouchEnd.pause();
}

void TurnOnSWEEP() {
  while (SWEEPMouseDown.isPaused) {
    SWEEPMouseDown.resume();
    SWEEPTouchStart.resume();
    SWEEPMouseMove.resume();
    SWEEPTouchMove.resume();
    SWEEPMouseUp.resume();
    SWEEPTouchEnd.resume();
  }
}

void TurnOffCUT(){
  CUTMouseDown.pause();
  CUTTouchStart.pause();
  CUTMouseMove.pause();
  CUTTouchMove.pause();
  CUTMouseGetRotationPoint.pause();
  CUTTouchGetRotationPoint.pause();
  CUTMouseUp.pause();
  CUTTouchEnd.pause();
}

void TurnOnCUT() {
  while (CUTMouseDown.isPaused) {
    CUTMouseDown.resume();
    CUTTouchStart.resume();
    CUTMouseMove.resume();
    CUTTouchMove.resume();
    CUTMouseUp.resume();
    CUTTouchEnd.resume();

    if (rotationsAllowed) {
      CUTMouseGetRotationPoint.resume();
      CUTTouchGetRotationPoint.resume();
    }
  }
}

void TurnOffGEO() {
  GEOMouseDown.pause();
  GEOTouchStart.pause();
  GEOMouseMove.pause();
  GEOTouchMove.pause();
  GEOMouseUp.pause();
  GEOTouchEnd.pause();
}

void TurnOnGEO(){
  while(GEOMouseDown.isPaused) {
    GEOMouseDown.resume();
    GEOTouchStart.resume();
    GEOMouseMove.resume();
    GEOTouchMove.resume();
    GEOMouseUp.resume();
    GEOTouchEnd.resume();
  }
}

void TurnOffAllMain() {
  TurnOffCUT();
  TurnOffCav();
  TurnOffSWEEP();
  TurnOffGEO();
  TurnOffSETUP();
}

void TurnOffCav() {
  TabletTiltSensorCav.pause();
  numDeviceMotionEvents = 0;

  mouseMoveCav.pause();
  mouseUpCav.pause();
  mouseDownCav.pause();

  if (animLoopTimer != null) {
    animLoopTimer.cancel();
    animLoopTimer = null;
  }
}

void TurnOnCav() {
  while(mouseUpCav.isPaused) {
    TabletTiltSensorCav.resume();
    mouseMoveCav.resume();
    mouseUpCav.resume();
    mouseDownCav.resume();
  }

}

void PauseCavForScreenCap() {
  TabletTiltSensorCav.pause();
  mouseMoveCav.pause();
  mouseUpCav.pause();
  mouseDownCav.pause();
  animLoopTimer = null;
}

void ResumeCavForScreenCap() {
  TabletTiltSensorCav.resume();
  mouseMoveCav.resume();
  mouseUpCav.resume();
  mouseDownCav.resume();
  animLoopTimer = new Timer(new Duration(milliseconds: 50), maybeFall);
}


