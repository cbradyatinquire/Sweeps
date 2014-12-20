part of sweeps;


void postImageData(CanvasElement canv, String identifier, String annotation) {
 
  HttpRequest request = new HttpRequest(); // create a new XHR

  // add an event handler that is called when the request finishes
  request.onReadyStateChange.listen((_) {
    if (request.readyState == HttpRequest.DONE &&
       (request.status == 200 || request.status == 0)) {
      print("data saved ok..." + request.responseText); // output the response from the server
    }
  });
  
  String idata = canv.toDataUrl();
  
  request.open("POST","http://54.69.108.80/sweep_image_old/", async: false);
  
  FormData fdata = new FormData(); // from dart:html

  fdata.append('app_id', identifier);
  fdata.append('app_annotation', annotation);
  fdata.append('app_imagedata', idata);

   
  HttpRequest.request('http://54.69.108.80/sweep_image/', method: 'POST', sendData: fdata).then((HttpRequest r) {
    print("request sent");
  });
}