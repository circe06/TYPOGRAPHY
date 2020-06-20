/**
 * NyARToolkit for proce55ing/3.0.5
 * (c)2008-2017 nyatla
 * airmail(at)ebony.plala.or.jp
 * 
 * ARマーカとIdマーカを同時に使う例です。
 * このスケッチはARマーカのkanji,hiroと、idマーカは0,1番のマーカを使います。
 * 全ての設定ファイルとマーカファイルはスケッチディレクトリのlibraries/nyar4psg/dataにあります。
 * 
 * This sample handles 2 ARToolkit style markers and 2 NyId markers at same time.
 * The sketch uses ARToolKit standard marker files(kanji.patt,hiro.patt) and NyIdMarker(#0 and #1).
 * Any pattern and configuration files are found in libraries/nyar4psg/data inside your sketchbook folder.
 */
import processing.video.*;
import jp.nyatla.nyar4psg.*;

import geomerative.*;              // geomerative library for text manipulation and point extraction
import wblut.processing.*;         // hemesh library section for displaying shapes
import wblut.hemesh.*;             // hemesh library section with main HE_Mesh class 
import wblut.geom.*;               // hemesh library section with geometry classes


Capture cam;
MultiMarker nya;

RFont font;                        // geomerative font used for creating the 3D text
WB_Render render;                  // hemesh class for displaying shapes
HE_Mesh mesh;                      // the main HE_Mesh instance to hold the 3D mesh
String input = "9";             // the input string that is transformed into a 3D mesh 

float ypos=0;
float speed=0;
float gravity=0.2;

void setup() {
  size(640, 480, P3D);
  colorMode(RGB, 100);
  println(MultiMarker.VERSION);
  cam=new Capture(this, 640, 480);
  nya=new MultiMarker(this, width, height, "C:/Users/Pallavi Ray/Documents/Processing/libraries/nyar4psg/data/camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
  nya.addARMarker("C:/Users/Pallavi Ray/Documents/Processing/libraries/nyar4psg/data/patt.hiro", 80);//id=0
  nya.addARMarker("C:/Users/Pallavi Ray/Documents/Processing/libraries/nyar4psg/data/patt.kanji", 80);//id=1
  nya.addNyIdMarker(0, 80);//id=2
  nya.addNyIdMarker(1, 80);//id=3
  cam.start();

  // Geomerative
  RG.init(this); // initialize the Geomerative library
  RCommand.setSegmentator(RCommand.UNIFORMSTEP); // settings for the generated shape density
  RCommand.setSegmentStep(2); // settings for the generated shape density
  font = new RFont("FreeSans.ttf", 200); // create the font used by Geomerative

  // Hemesh
  render = new WB_Render(this); // setup the hemesh render class for displaying shapes

  // call the two methods (see below) that do the actual work in this sketch 
  mesh = createHemeshFromString(input); // create a 3D mesh from an input string (using Geomerative & Hemesh)
  colorFaces(mesh); // color the faces of the generated mesh using a bit of custom code
}

void draw()
{ 
  lights();
  if (cam.available() !=true) {
    return;
  }
  cam.read();
  nya.detect(cam);
  background(0);
  nya.drawBackground(cam);//frustumを考慮した背景描画
  for (int i=0; i<4; i++) {
    if ((!nya.isExist(i))) {
      continue;
    }
    nya.beginTransform(i);
    //fill(100*(((i+1)/4)%2), 100*(((i+1)/2)%2), 100*(((i+1))%2));
    //translate(0, 0, 20);
    //text("9", 0, 0, 0);


    rotateX(-PI/2);
    rotateY(PI);
   // rotateZ(-PI/2);
    translate(-20, ypos, 0);
    ypos=ypos+speed;
    speed=speed+gravity;

    if (ypos>15) {
      speed=speed*-1;
    }

    // display the mesh using colored faces and subtle edge lines
    noStroke();
    for (HE_Face face : mesh.getFacesAsArray ()) {
      // colors are stored in each Face's label (see colorFaces() method below)
      fill(face.getColor());
      // draw the face using Hemesh's render class
      render.drawFace(face, false);
    }

    nya.endTransform();
  }
}

// Turn a string into a 3D HE_Mesh
HE_Mesh createHemeshFromString(String s) {

  // Geomerative
  RMesh rmesh = font.toGroup(s).toMesh(); // create a 2D mesh from a text
  rmesh.translate(0, rmesh.getHeight()/2); // center the mesh

  // Geomerative & Hemesh
  ArrayList <WB_Triangle> triangles = new ArrayList <WB_Triangle> (); // holds the original 2D text mesh
  ArrayList <WB_Triangle> trianglesFlipped = new ArrayList <WB_Triangle> (); // holds the flipped 2D text mesh
  RPoint[] pnts;
  WB_Triangle t, tFlipped;
  WB_Point a, b, c;
  // extract the triangles from geomerative's 2D text mesh, then place them
  // as hemesh's 3D WB_Triangle's in their respective lists (normal & flipped)
  for (int i=0; i<rmesh.strips.length; i++) {
    pnts = rmesh.strips[i].getPoints();
    for (int j=2; j<pnts.length; j++) {
      a = new WB_Point(pnts[j-2].x, pnts[j-2].y, 0);
      b = new WB_Point(pnts[j-1].x, pnts[j-1].y, 0);
      c = new WB_Point(pnts[j].x, pnts[j].y, 0);
      if (j % 2 == 0) {
        t = new WB_Triangle(a, b, c);
        tFlipped = new WB_Triangle(c, b, a);
      } else {
        t = new WB_Triangle(c, b, a);
        tFlipped = new WB_Triangle(a, b, c);
      }
      // add the original and the flipped triangle (to close the 3D shape later on) to their respective lists
      triangles.add(t);
      trianglesFlipped.add(tFlipped);
    }
  }

  // Hemesh
  // Creating a quality extruded 3D HE_Mesh in 4 steps

  // 1. create the base 3D HE_Mesh from the triangles of the 2D text shape
  // (at this point you basically have a 2D text shape stored in a 3D HE_Mesh)
  HE_Mesh tmesh = new HE_Mesh(new HEC_FromTriangles().setTriangles(triangles));

  // 2. extrude the base mesh by a certain distance
  // (at this point you have an extruded shape, but it is open on the side where the original 2D base shape was!)
  tmesh.modify(new HEM_Extrude().setDistance(20));

  // 3. add the flipped faces to the extruded base mesh
  // (at this point we add the flipped faces to closes the mesh, the flipping ensures correct, outward normals) 
  tmesh.add(new HE_Mesh(new HEC_FromTriangles().setTriangles(trianglesFlipped)));

  // 4. create a quality internal structure (useful for the mesh manipulations in subsequent examples)
  tmesh.clean();

  // Done! Return the HE_Mesh...
  return tmesh;
}

// color each face in the mesh based on it's xy-position using HSB colormode
void colorFaces(HE_Mesh mesh) {
  colorMode(HSB);
  for (HE_Face face : mesh.getFacesAsArray ()) {
    WB_Coord c = face.getFaceCenter();
    face.setColor(color(183,49,75));
  }
  colorMode(RGB, 255); // (re)set colorMode to RGB
}