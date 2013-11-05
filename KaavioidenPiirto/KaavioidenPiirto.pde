import processing.serial.*; 
 
Serial myPort;    // The serial port
String inString = "Tyhjä";  // Input string from serial port
int lf = 10;      // ASCII linefeed 

PGraphics kaavio; //tähän piirretään
int x_0 = 0;  //nollataan palkkien sijainti
int vali = 50; //palkkien väli
Table data = loadTable("data4.csv","header");

int leveys = 800;
int korkeus = 600;
int leveysMax = (data.getRowCount()-1)*vali;

int marg = 20;
float zoom = leveys - 2*marg;
int askel = 1;

int lapinakyvyys = 0;
boolean fadeIn = true;
boolean fadeOut = false;
boolean rullaus = false;
boolean tauko = false;

int keissi = 1;

color tausta = color(25,25,25);
color viiva = color(241,90,34);
color viiva2 = color(203,219,42);
color tayte = color(224,70,23);
color teksti = color(250,250,250);

//boolean zoomIn = true;
//boolean zoomOut = false;

boolean valitse_keissi = true;

void setup() {
  size(leveys, korkeus);
  kaavio = createGraphics(leveysMax,korkeus); //luodaan riittävän suuri piirustusalusta
  background(tausta); //taustaväri
  println(Serial.list()); 
  myPort = new Serial(this, Serial.list()[0], 9600); 
  myPort.bufferUntil(lf); 
  frameRate(60);
}

void draw() {
/*
  if(inString.equals("66006BEEEC0F")) {
    keissi = 1;
  } else if(inString.equals("66006C34625C")) {
    keissi = 2;
  } else {
    keissi = 0;
  }
*/

if(valitse_keissi) {
  switch(keissi) {
    case 0:
      int y = 2;
      int offset = 0;
      while(data.getFloat(offset,y) < 0) {
        offset++;
     }
      marg = vali - (vali*(offset));
      piirraViiva(y);
      rullaus = true;
      break;
    case 1:
      y = 3;
      offset = 0;
      while(data.getFloat(offset,y) < 0) {
        offset++;
     }
      marg = vali - (vali*(offset));
      piirraPalkit(y);
      rullaus = true;
      break;
    case 2:
      int y1 = 4;
      int y2 = 5;
      int offset1 = 0;
      while(data.getFloat(offset1,y1) < 0) {
        offset1++;
      }
      int offset2 = 0;
      while(data.getFloat(offset2,y1) < 0) {
        offset2++;
      }
      
      marg = vali - (vali*(max(offset1,offset2)));

      piirraViiva(y1,y2);
      rullaus = true;
      break;
    case 3:
      marg = 0;
      piirraXY(1,2);
      rullaus = false;
      break;
    case 4:
      marg = 0;
      piirraMuutos(askel,6);
      rullaus = false;
    }
    valitse_keissi = false;

  }

  //Nollataan tausta  
  rectMode(CORNER);
  fill(tausta);
  stroke(tausta);
  rect(0,0,width,height);
  
  if(fadeIn) {
    tint(255,lapinakyvyys);
    image(kaavio,x_0+marg,0);
    if(lapinakyvyys >= 255) {
      fadeIn = false;
    } else {
      lapinakyvyys = lapinakyvyys+5;
    }
  } else if(fadeOut) {
    tint(255,lapinakyvyys);
    image(kaavio,x_0+marg,0);
    if(lapinakyvyys <= 0) {
      fadeOut = false;
      fadeIn = true;
      valitse_keissi = true;
      if(keissi > 4) {
        keissi = 0;
      } else {
        keissi++;
      }
      
      x_0=0;
 /*               if(askel > 10) {
            askel = 1;
          } else {
            askel++;
          }
*/
      } else {
        lapinakyvyys = lapinakyvyys-5;
      }
    
  } else {  
    image(kaavio,x_0+marg,0);
    if(rullaus) {
      if (x_0 <= -(leveysMax-leveys+marg)) {
        fadeOut = true;
      } else {
        x_0 = x_0 - 3;    
      }
    } else {
        PFont f;
        f = createFont("Verdana",56,false);
        textFont(f);
        textAlign(CENTER);
        fill(viiva);
        text("Coincidence?", leveys/2, korkeus/2);
        if(tauko) {
          delay(5000);
          tauko = false;
          fadeOut = true;
        } else {
          tauko = true;
        }
    }
  }
}
  



void piirraTauko() {
  
}

void piirraPalkit(int sarake) {
  nollaaKaavio();
  float kerroin = skaalaa(sarake);
//säädetään palkkien piirustusmuoto
  kaavio.rectMode(CORNERS);
  //säädetään fontti kohdalleen
  PFont f;
  f = createFont("Verdana",14,false);
 float min = minimi(sarake);
 float maks = maksimi(sarake);
//aloitetaan piirustus
  kaavio.beginDraw();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      //Piirretään palkki
      kaavio.fill(tayte);
      kaavio.stroke(viiva);
      kaavio.rect(i*vali,korkeus,i*vali+vali*3/4,korkeus-map(data.getFloat(i, sarake),min,maks,20,korkeus-20));
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(teksti);
      String arvo = data.getString(i,sarake);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake),min,maks,20,korkeus-20)-5);
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
      
   
  }
  kaavio.endDraw();
  
}

void piirraXY(int x, int y) {
  nollaaKaavio();
  float xmin = minimi(x);
  float xmax = maksimi(x);
  float ymin = minimi(y);
  float ymax = maksimi(y);  
  kaavio.beginDraw();
  kaavio.stroke(0);
  kaavio.fill(0);    
  int koko = 3;

  PFont f;
  f = loadFont("CenturyGothic-48.vlw");


  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    //Piirretään piste
    kaavio.ellipse(map(data.getFloat(i,x),xmin,xmax,0,leveys), korkeus - map(data.getFloat(i,y),ymin,ymax,0,korkeus),koko,koko);
    kaavio.textFont(f);
    kaavio.textSize(16);
    kaavio.textAlign(CENTER);
    kaavio.fill(teksti);
    kaavio.text(data.getColumnTitle(x),leveys/2, korkeus-5);
    kaavio.pushMatrix();
    kaavio.rotate(3*HALF_PI);
    kaavio.text(data.getColumnTitle(y),-korkeus/2,20);   
    kaavio.popMatrix();
  }
  kaavio.endDraw();  
}

void piirraViiva(int sarake) {
  nollaaKaavio();
  float kerroin = skaalaa(sarake);
  kaavio.beginDraw();
  kaavio.beginShape();
  kaavio.fill(tausta);
    float min = minimi(sarake);
    float maks = maksimi(sarake);

    for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole

    TableRow row1 = data.getRow(i); //otetaan rivi
    //Piirretään viiva
    kaavio.stroke(viiva);
    kaavio.vertex(i*vali,korkeus-map(row1.getFloat(sarake),min,maks,20,korkeus-20));
  }
  kaavio.endShape();


  //säädetään fontti kohdalleen
  PFont f;
  f = createFont("Verdana",14,false);

  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(teksti);
      String arvo = data.getString(i,sarake);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }

      kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake), min,maks,20,korkeus-20)-5);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
  }


  kaavio.endDraw();

}

void piirraViiva(int sarake1, int sarake2) {
  nollaaKaavio();
  kaavio.beginDraw();
  kaavio.fill(tausta,0);
  float min1 = minimi(sarake1);
  float maks1 = maksimi(sarake1);
  float min2 = minimi(sarake2);
  float maks2 = maksimi(sarake2);

  kaavio.beginShape();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    //Piirretään viiva
    kaavio.stroke(viiva);
    kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake1),min1,maks1,20,korkeus-20));
  }
  kaavio.endShape();

  kaavio.beginShape();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    //Piirretään viiva
    kaavio.stroke(viiva2);
    kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake2),min2,maks2,20,korkeus-20));
  }
  kaavio.endShape();

  //säädetään fontti kohdalleen
  PFont f;
  f = createFont("Verdana",14,false);

  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(viiva,255);
      String arvo = data.getString(i,sarake1);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake1), min1,maks1,20,korkeus-20)-5);

      kaavio.fill(viiva2,255);
      arvo = data.getString(i,sarake2);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake2), min2,maks2,20,korkeus-20)-5);
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
  }


  kaavio.endDraw();

}
void piirraMuutos(int askel, int sarake) {
  nollaaKaavio();
  kaavio.beginDraw();
  //säädetään fontti kohdalleen
  PFont f;
  f = createFont("Verdana",26,false);
  
  kaavio.textFont(f);
  kaavio.textAlign(CENTER);
  kaavio.fill(teksti,255);
  
  float muutos = 0;

  int indeksi = -1;
  float maks = 0;
  for(int i = 0; i < data.getRowCount(); i++) {
    if(i + askel < data.getRowCount()) {
      if(data.getFloat(i,sarake) > 0 && data.getFloat(i+askel,sarake) > 0) {
      if(abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake)) > maks) {
        maks = abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake));
        muutos = (data.getFloat(i,sarake) - data.getFloat(i+askel, sarake));
        indeksi = i;
      }  
    } else {
      }
    } else {
    }
  }
  String otsikko = data.getColumnTitle(sarake);
  String label = otsikko.substring(0,otsikko.indexOf("("));
  String suure = otsikko.substring(otsikko.indexOf("(")+1,otsikko.indexOf(")"));
  String muutos_lyh = String.format("%.2f", muutos);
  
  kaavio.text("The biggest change over " + askel + " year time range in",leveys/2,50);
  kaavio.text(label,leveys/2,100);
  kaavio.text("happened from " + data.getString(indeksi,0) + " to " + data.getString(indeksi+askel,0) + ": ",leveys/2,150);
  kaavio.text(muutos_lyh + " " + suure,leveys/2,200);
  kaavio.text("The president of the United States was " + data.getString(indeksi,0),leveys/2,korkeus/2+150);

  kaavio.endDraw();

}



  
void nollaaKaavio() {
  x_0=0;
  kaavio.beginDraw();
  kaavio.rectMode(CORNER);
  kaavio.fill(tausta);
  kaavio.stroke(tausta);
  kaavio.rect(0,0,leveysMax,korkeus);
  kaavio.endDraw();
  
}

void piirraAkselit() {
  
}

float skaalaa(int sarake) {
  int maksimi = 0;
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    if(data.getInt(i, sarake) > maksimi) {
      maksimi = data.getInt(i, sarake);
    } else {
    }
  }
  float k = korkeus;
  return (k-50)/maksimi;
}
 
float minimi(int sarake) {
 float minimi = 10000;
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    if(data.getFloat(i, sarake) > 0 && data.getFloat(i, sarake) < minimi) {
      minimi = data.getFloat(i, sarake);
    } else {
    }
  }
  return minimi;
}

float maksimi(int sarake) {
 float maksimi = 0;
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    if(data.getFloat(i, sarake) > maksimi) {
      maksimi = data.getFloat(i, sarake);
    } else {
    }
  }
  return maksimi;
}

int suurinMuutos(int askel, int sarake) { //palauttaa suurimman muutoksen indeksin
  int indeksi = -1;
  float maks = 0;
  for(int i = 0; i < data.getRowCount(); i++) {
    if(i + askel < data.getRowCount()) {
      if(abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake)) > maks) {
        maks = abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake));
        indeksi = i;
      } else {
      }
    } else {
    }
  }
  return indeksi;
} 
 
void serialEvent(Serial p) { 
  nollaaKaavio();
  inString = p.readString(); 
  inString = trim(inString);

} 
  
  

