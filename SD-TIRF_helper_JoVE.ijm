//
// -------------- Choice between registration correction yes/no --------------------
//
Dialog.create("Registration correction");
items = newArray("Yes", "No");
Dialog.addRadioButtonGroup("Do you want to perform registration correction on the data?", items, 1, 2, "Yes");
Dialog.show();
choice = Dialog.getRadioButton();
if (choice=="Yes") {
//
// -------------- Registration correction part --------------------
//
Dialog.create("Registration correction");
items = newArray("Yes", "No");
Dialog.addRadioButtonGroup("Do you want to create a new registration landmark file?", items, 1, 2, "Yes");
Dialog.show();
choice = Dialog.getRadioButton();
if (choice=="Yes") {BeadCorr();}
  
function BeadCorr() { 
Dialog.create("Open beads image series");
Dialog.addMessage("Select the .nd file of the beads for registration correction");
Dialog.show();
run("Bio-Formats");
wait(250);
rename("beads-images");
run("Split Channels"); 
wait(250);
run("TurboReg "); // it is important to choose the same channel order as in the dtaset that has to be corrected
waitForUser("Registration correction", "Apply the registration correction on the beads first,\nby activating SAVE ON EXIT and ACCURATE \nclick on AUTOMATIC \nthen save the results as landmark file\nand click OK to continue");
run("Close All");
} //end of function BeadCorr

Dialog.create("Landmarks");
Dialog.addMessage("Select the landmark file for registration correction");
Dialog.show();
pathfile=File.openDialog("Choose the landmark file"); 
filestring=File.openAsString(pathfile); 
rows=split(filestring,"\n"); 
x=newArray(rows.length); 
y=newArray(rows.length); 
for(i=10; i<=12; i++){ 
	columns=split(rows[i],"\t"); 
	x[i]=parseFloat(columns[0]); 
	y[i]=parseFloat(columns[1]); 
};
for(i=15; i<=17; i++){ 
	columns=split(rows[i],"\t"); 
	x[i]=parseFloat(columns[0]); 
	y[i]=parseFloat(columns[1]); 
};
//
// -------------- SD image registration correction part --------------------
//
Dialog.create("Open SD image series");
Dialog.addMessage("Select the .nd file and open the SD image series");
Dialog.show();
run("Bio-Formats");
wait(250);
rename("SD-images");
run("32-bit");
getDimensions(w, h, channels, slices, frames);
if (channels==2) {
run("Split Channels");
SDregistration();
} else if (channels==1) {
  Dialog.create("Registration correction");
  items = newArray("Yes", "No");
  Dialog.addRadioButtonGroup("Do you want to register this SD channel?", items, 1, 2, "Yes");
  Dialog.show();
  choice = Dialog.getRadioButton();
  if (choice=="Yes") {rename("C2-SD-images");SDregistration();}
  else if (choice=="No") {rename("C1-SD-images");}
  
  
}
function SDregistration() {
selectWindow("C2-SD-images");
for(h=1; h<=slices; h++){
run("Make Substack...", "slices="+h+" frames=1-"+frames+"");
wait(250);
rename("C2-SD-images-sub");
for(k=1; k<frames; k++){
selectWindow("C2-SD-images-sub");
Stack.setPosition(1, 1, 1);
run("Make Substack...", "delete slices=1");
selectWindow("Substack (1)");
rename("Substack");
width = getWidth();
height = getHeight();
run("TurboReg ", 
	"-transform " // Registers the channel that has been selected as source channel before.
	+ "-window Substack" + " "// Source (window reference).
	+ width + " " + height + " " // output size
	+ "-rigidBody " // This corresponds to rotation and translation.
	+ x[10] + " " + y[10] + " " // Source translation landmark.
	+ x[15] + " " + y[15] + " " // Target translation landmark.
	+ x[11] + " " + y[11] + " " // Source first rotation landmark.
	+ x[16] + " " + y[16] + " " // Target first rotation landmark.
	+ x[12] + " " + y[12] + " " // Source second rotation landmark.
	+ x[17] + " " + y[17] + " " // Target second rotation landmark.
	+ "-showOutput");
close("Substack");
selectWindow("Output");
Stack.setSlice(2);
run("Delete Slice");
run("Copy");
selectWindow("C2-SD-images"); 
Stack.setPosition(1, h, k);
run("Paste");
close("Output");
wait(250);
};
selectWindow("C2-SD-images-sub");
run("TurboReg ", 
	"-transform " // Registers the channel that has been selected as source channel before.
	+ "-window C2-SD-images-sub" + " "// Source (window reference).
	+ width + " " + height + " " // output size
	+ "-rigidBody " // This corresponds to rotation and translation.
	+ x[10] + " " + y[10] + " " // Source translation landmark.
	+ x[15] + " " + y[15] + " " // Target translation landmark.
	+ x[11] + " " + y[11] + " " // Source first rotation landmark.
	+ x[16] + " " + y[16] + " " // Target first rotation landmark.
	+ x[12] + " " + y[12] + " " // Source second rotation landmark.
	+ x[17] + " " + y[17] + " " // Target second rotation landmark.
	+ "-showOutput");
close("C2-SD-images-sub");
selectWindow("Output");
Stack.setSlice(2);
run("Delete Slice");
run("Copy");
selectWindow("C2-SD-images"); 
Stack.setPosition(1, h, k+1);
run("Paste");
resetMinAndMax();
close("Output");
wait(250);
}
} //end of function SDregistration
//
// ------------- TIRF image registration part --------------------
//
Dialog.create("Open TIRF image series");
Dialog.addMessage("Select the .nd file and open the TIRF image series");
Dialog.show();
run("Bio-Formats");
wait(250);
rename("TIRF-images");
run("32-bit");
getDimensions(w, h, channels, slices, frames);
if (channels==2) {
run("Split Channels");
TIRFregistration();
} else if (channels==1) {
  Dialog.create("Registration correction");
  items = newArray("Yes", "No");
  Dialog.addRadioButtonGroup("Do you want to register this TIRF channel?", items, 1, 2, "Yes");
  Dialog.show();
  choice = Dialog.getRadioButton();
  if (choice=="Yes") {rename("C2-TIRF-images");TIRFregistration();rename("C2s-TIRF-images");}
  else if (choice=="No") {rename("C1s-TIRF-images");
  }
}
function TIRFregistration() {
selectWindow("C2-TIRF-images");
newImage("TIRF-2-blank", "32-bit black", w, h, frames);
run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");

for(k=1; k<frames; k++){
selectWindow("C2-TIRF-images");
Stack.setPosition(1, 1, 1);
run("Make Substack...", "delete slices=1");
selectWindow("Substack (1)");
rename("Substack");
width = getWidth();
height = getHeight();
run("TurboReg ", 
	"-transform " // Registers the channel that has been selected as source channel before.
	+ "-window Substack" + " "// Source (window reference).
	+ width + " " + height + " " // output size
	+ "-rigidBody " // This corresponds to rotation and translation.
	+ x[10] + " " + y[10] + " " // Source translation landmark.
	+ x[15] + " " + y[15] + " " // Target translation landmark.
	+ x[11] + " " + y[11] + " " // Source first rotation landmark.
	+ x[16] + " " + y[16] + " " // Target first rotation landmark.
	+ x[12] + " " + y[12] + " " // Source second rotation landmark.
	+ x[17] + " " + y[17] + " " // Target second rotation landmark.
	+ "-showOutput");
close("Substack");
selectWindow("Output");
Stack.setSlice(2);
run("Delete Slice");
run("Copy");
selectWindow("TIRF-2-blank"); 
Stack.setPosition(1, 1, k);
run("Paste");
close("Output");
wait(250);
};
selectWindow("C2-TIRF-images");
run("TurboReg ", 
	"-transform " // Registers the channel that has been selected as source channel before.
	+ "-window C2-TIRF-images" + " "// Source (window reference).
	+ width + " " + height + " " // output size
	+ "-rigidBody " // This corresponds to rotation and translation.
	+ x[10] + " " + y[10] + " " // Source translation landmark.
	+ x[15] + " " + y[15] + " " // Target translation landmark.
	+ x[11] + " " + y[11] + " " // Source first rotation landmark.
	+ x[16] + " " + y[16] + " " // Target first rotation landmark.
	+ x[12] + " " + y[12] + " " // Source second rotation landmark.
	+ x[17] + " " + y[17] + " " // Target second rotation landmark.
	+ "-showOutput");
close("C2-TIRF-images");
selectWindow("Output");
Stack.setSlice(2);
run("Delete Slice");
run("Copy");
selectWindow("TIRF-2-blank"); 
Stack.setPosition(1, 1, k+1);
run("Paste");
rename("C2-TIRF-images");
resetMinAndMax();
close("Output");
} //end of function TIRFregistration
//
// ------------- Multichannel hyperstack creation part --------------------
//
if (isOpen("C1-SD-images")) {
	selectWindow("C1-SD-images");
	getDimensions(w, h, channels, slices, frames);
}
else {
	selectWindow("C2-SD-images");
	getDimensions(w, h, channels, slices, frames);
}

if (isOpen("C1-TIRF-images")) {run("Merge Channels...", "c1=[C1-TIRF-images] c2=[C2-TIRF-images] create ignore");
rename("TIRF-images");
run("Add Slice", "add=slice");
for (i=1; i<slices-1; i++) { // adds empty planes on top of the TIRF plane according to SD dataset
      selectWindow("TIRF-images");
      run("Add Slice", "add=slice");
      wait(250);
   }
}
else if (isOpen("C1s-TIRF-images")) {run("Merge Channels...", "c1=[C1s-TIRF-images] c2=[C1s-TIRF-images] create ignore");
rename("C1-TIRF-images");
run("Add Slice", "add=slice");
for (i=1; i<slices-1; i++) { // adds empty planes on top of the TIRF plane according to SD dataset
      selectWindow("C1-TIRF-images");
      run("Add Slice", "add=slice");
      wait(250);
   }
   Stack.setPosition(2, 1, 1);
   run("Delete Slice", "delete=channel");
}
else if (isOpen("C2s-TIRF-images")) {run("Merge Channels...", "c1=[C2s-TIRF-images] c2=[C2s-TIRF-images] create ignore");
rename("C2-TIRF-images");
run("Add Slice", "add=slice");
for (i=1; i<slices-1; i++) { // adds empty planes on top of the TIRF plane according to SD dataset
      selectWindow("C2-TIRF-images");
      run("Add Slice", "add=slice");
      wait(250);
   }
   Stack.setPosition(1, 1, 1);
   run("Delete Slice", "delete=channel");
}
if (isOpen("TIRF-images")) {
	selectWindow("TIRF-images");
	run("Split Channels");
	}

waitForUser("Merge channels", "e.g. choose for 2 SD and 2 TIRF channels \nc1=[C1-SD-images] c2=[C2-SD-images] c5=[C1-TIRF-images] c6=[C2-TIRF-images]");
run("Merge Channels...");
rename("SD-TIRF-images");

	} //end of registration correction part

else {SD_TIRF_merge();}

function SD_TIRF_merge() {
//
// ----------- Creation of SD-TIRF dataset without registration correction ------------
//

// open SD file
Dialog.create("Open SD image series");
Dialog.addMessage("Select the .nd file and open the SD image series");
Dialog.show();
run("Bio-Formats");
rename("SD-images");
getDimensions(w, h, channels, slices, frames);
if (channels==2) {run("Split Channels");}

// open TIRF file
Dialog.create("Open TIRF image series");
Dialog.addMessage("Select the .nd file and open the TIRF image series");
Dialog.show();
run("Bio-Formats");
rename("TIRF-images");
if (isOpen("C1-SD-images")) {
	selectWindow("C1-SD-images");
	getDimensions(w, h, channels, slices, frames);
	SDslices=slices;
}
else {
	selectWindow("SD-images");
	getDimensions(w, h, channels, slices, frames);
	SDslices=slices;
}
selectWindow("TIRF-images");
getDimensions(w, h, channels, slices, frames);
if (channels==2) {
run("Add Slice", "add=slice");
for (i=1; i<SDslices-1; i++) {
      selectWindow("TIRF-images");
      run("Add Slice", "add=slice");
      wait(250);
   }
   run("Split Channels");
}
else {
	run("Merge Channels...", "c1=[TIRF-images] c2=[TIRF-images] create ignore");
	rename("TIRF-images");
	run("Add Slice", "add=slice");
	for (i=1; i<SDslices-1; i++) { // adds empty planes on top of the TIRF plane according to SD dataset
      selectWindow("TIRF-images");
      run("Add Slice", "add=slice");
      wait(250);
   }
   Stack.setPosition(2, 1, 1);
   run("Delete Slice", "delete=channel");
   rename("TIRF-images");
}
// merge channels
waitForUser("Merge channels", "e.g. choose for 2 SD and 2 TIRF channels \nc1=[C1-SD-images] c2=[C2-SD-images] c5=[C1-TIRF-images] c6=[C2-TIRF-images]");
run("Merge Channels...");
rename("SD-TIRF-images");
getDimensions(w, h, channels, slices, frames);
for (i=1; i<=channels; i++) {
        Stack.setChannel(i);
        resetMinAndMax();
}
}
