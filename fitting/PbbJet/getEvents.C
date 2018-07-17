
void getEvents(TString Dir, TString match){
  
  
  //
  
  //TObjArray*flist=Files.Tokenize(',');
  //for(int i=0;i<flist->GetSize();i++){
  //cout<<i<<" "<<((TString*)((*flist)[i]))->Data()<<endl;
  //TH1F*H=(TH1F*)F.Get("NEvents");
  //}

  float total=0.;

  TSystemDirectory dir(Dir, Dir); 
  TList *files = dir.GetListOfFiles(); 
  if (files) { 
    TSystemFile *file; 
    TString fname;
    TIter next(files); 
    while ((file=(TSystemFile*)next())) { 
      fname = file->GetName(); 
      if (!file->IsDirectory() && fname.Contains(match.Data()) && fname.EndsWith(".root")) {
	//cout << fname.Data() << endl; 
	TFile F(Dir+"/"+fname.Data(),"READ");
	TH1F*H=(TH1F*)F.Get("NEvents");
	if(!H) return;
	total+=H->GetBinContent(1);
      } 
    } 
  }
  std::cout<<"Total "<<total<<std::endl;

  //char ev[100];
  //sprintf(ev,"%f",H->Integral());
  //cout<<ev<<endl;
  //gSystem->SetEnv("MYEVENTS",ev);
}
