part of sweeps;


//requires classes from dart:html
void postImageData(CanvasElement canv, String annotation) {
 
  //HttpRequest request = new HttpRequest(); 

  //logic for receipt of response to the request.
  //request.onReadyStateChange.listen((_) {
   // if (request.readyState == HttpRequest.DONE &&
   //    (request.status == 200 || request.status == 0)) {
   //   print("data saved ok..." + request.responseText); // output the response from the server
   // }
 // });
  
  String idata = canv.toDataUrl();
  
  //request.open("POST","http://54.69.108.80/sweep_image_old/", async: false);
  
  FormData fdata = new FormData(); 

  fdata.append('app_id', myUID.toString());
  fdata.append('app_annotation', annotation);
  fdata.append('app_imagedata', idata);

   
  HttpRequest.request('http://54.69.108.80/sweep_image/', method: 'POST', sendData: fdata).then((HttpRequest r) {
    print("request sent");
  });
}