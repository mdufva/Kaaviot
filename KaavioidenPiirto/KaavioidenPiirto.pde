/* RFID tagin lukemiseen tarvittavat muuttujat */
import processing.serial.*;  
Serial myPort;    // The serial port
String inString = "Tyhjä";  // Input string from serial port
int lf = 10;      // ASCII linefeed 

/* statistiikkakirjasto */
import papaya.*;

/* piirtämiseen travittavat muuttujat */
PGraphics kaavio; //tähän piirretään kaavio
PGraphics otsikko; //tiedot datasta
int x_0 = 0;  //kaavioiden origo
Table data = loadTable("data4.csv","header"); //kaikki tarvittava data

/* Ulkoasu */
int leveys = 1200;
int korkeus = 800;
int vali = 50; //palkkien väli
int marg = 20; //vasen marginaali
int alamarg = 20; //alamarginaali
int leveysMax = (data.getRowCount()-1)*vali;

/* fontti */
PFont f = loadFont("Monospaced-16.vlw");
PFont f2 = loadFont("Monospaced-36.vlw");
PFont f3 = loadFont("Monospaced-26.vlw");


/* Värit */
color tausta = color(25,25,25);
color viiva1 = color(241,90,34);
color viiva2 = color(203,219,42);
color tayte1 = color(224,70,23);
color tayte2 = color(183,199,32);
color teksti = color(250,250,250);

/* vaihdoksiin tarvittavat muuttujat */
int askel = 1; //muutoksessa laskettava vuosiväli
int lapinakyvyys = 0; //ristivaihtoihin tarvittava muuttuja
boolean fadeIn = true;  //feidataanko sisään
boolean fadeOut = false; //feidataanko pois
boolean rullaus = false; //liikutetaanko kaaviota
int rullausNopeus = 2; //kuinka monta pikselia kerrallaan siirretään
int fadeNopeus = 10; //ristivaihtojen nopeus
boolean tauko = false; //pidetäänkö kaaviota paikallaan
boolean valitseKeissi = true; //valitaanko keissi uudelleen
boolean coincidence = false;
boolean alku = false;

int keissi = 9; //mikä tapaus piirretään

int y1 = 7;
int y2 = 1;
int offset1 = 0;
int offset2 = 0;

void setup() {
  size(leveys, korkeus);
  kaavio = createGraphics(leveysMax,korkeus); //luodaan riittävän suuri piirustusalusta
  otsikko = createGraphics(leveys,korkeus);
  background(tausta); //taustaväri
  /* ruvetaan kuuntelemaan sarjaporttia */
  println(Serial.list()); 
  myPort = new Serial(this, Serial.list()[0], 9600); 
  myPort.bufferUntil(lf); 
}

void draw() {

if(valitseKeissi) { //esine lisätty tai poistettu
  switch(keissi) { 
    /* taukoanimaatio */
    case 0: 
      piirraTauko();
      rullaus = false;
      coincidence = false;
      alku = true;

      
      break;
    /* yksi viiva */
    case 1: 
      offset1 = 0;
      while(data.getFloat(offset1,y1) < 0) {
        offset1++;
      }
      marg = vali - (vali*(offset1));
      piirraViiva(y1);
      rullaus = true;
      break;
    /* yhdet palkit */
    case 2:
      offset1 = 0;
      while(data.getFloat(offset1,y1) < 0) {
        offset1++;
     }
      marg = vali - (vali*(offset1));
      piirraPalkit(y1);
      rullaus = true;
      break;

    /* teksti: suurin muutos aikavälillä */
    case 3:
      marg = 0;
      askel=round(random(0.5,10.4));
      piirraMuutos(askel,y1);
      rullaus = false;
      coincidence = true;

      break;
      
    /* historgrammi */
    case 4:
      marg = 20;
      piirraHistogram(y1);
      rullaus = false;
      coincidence = false;
      break;
      
    /* kaksi viivaa */
    case 5:
      y2 = 5;
      offset1 = 0;
      while(data.getFloat(offset1,y1) < 0) {
        offset1++;
      }
      offset2 = 0;
      while(data.getFloat(offset2,y1) < 0) {
        offset2++;
      }
      
      marg = vali - (vali*(max(offset1,offset2)));

      piirraViiva(y1,y2);
      rullaus = true;
      break;
      
    /* kaksi palkkia */
    case 6:
      y2 = 5;
      offset1 = 0;
      while(data.getFloat(offset1,y1) < 0) {
        offset1++;
      }
      offset2 = 0;
      while(data.getFloat(offset2,y1) < 0) {
        offset2++;
      }
      
      marg = vali - (vali*(max(offset1,offset2)));

      piirraPalkit(y1,y2);
      rullaus = true;
      break;    
      
    /* XY-kaavio */
    case 7:
      marg = 0;
      piirraXY(y1,y2);
      rullaus = false;
      coincidence = true;

      break;
      
      
    /* kaksi settiä yhdistävä kaavio */
    case 8:
      y2 = 5;
      piirraMatch(y1, y2);
      break;
      
    /* korrelaatioteksti */
    case 9:
      piirraKorrelaatio(y1,y2);
      rullaus=false;
      coincidence = true;
      break;
    
    }
    valitseKeissi = false;

  }

  //Nollataan tausta  
  rectMode(CORNER);
  fill(tausta);
  stroke(tausta);
  rect(0,0,width,height);
  
  if(fadeIn) {
    tint(255,lapinakyvyys);
    image(kaavio,x_0+marg,0);
    image(otsikko,0,0);
    if(lapinakyvyys >= 255) {
      fadeIn = false;
    } else {
      lapinakyvyys = lapinakyvyys+fadeNopeus;
    }
  } else if(fadeOut) {
    tint(255,lapinakyvyys);
    image(kaavio,x_0+marg,0);
    image(otsikko,0,0);
    if(lapinakyvyys <= 0) {
      fadeOut = false;
      fadeIn = true;
      valitseKeissi = true;  
      keissi = arvoKeissi(1);    
      x_0=0;
      } else {
        lapinakyvyys = lapinakyvyys-fadeNopeus;
      }  
  } else if(alku) {
    image(kaavio,x_0+marg,0);
  } else {  
    image(kaavio,x_0+marg,0);
    image(otsikko,0,0);
    if(rullaus) {
      if (x_0 <= -(leveysMax-leveys+marg)) {
        fadeOut = true;
      } else {
        x_0 = x_0 - rullausNopeus;    
      }
    } else {
        textFont(f2);
        textAlign(CENTER);
        fill(viiva1);
        if(coincidence) {
          text("Coincidence?", leveys/2, korkeus/2);
        }
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
  nollaaKaavio();
  kaavio.beginDraw();
  kaavio.textFont(f2);
  kaavio.textAlign(CENTER);
  kaavio.fill(teksti);
  kaavio.text("Place an object to a bowl", leveys/2, korkeus/2);
  kaavio.endDraw();
  
}

void piirraPalkit(int sarake) {
  nollaaKaavio();
//  float kerroin = skaalaa(sarake);
//säädetään palkkien piirustusmuoto
  kaavio.rectMode(CORNERS);
  //säädetään fontti kohdalleen
 float min = minimi(sarake);
 float maks = maksimi(sarake);
//aloitetaan piirustus
  kaavio.beginDraw();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      //Piirretään palkki
      kaavio.fill(tayte1);
      kaavio.stroke(viiva1);
      if(data.getFloat(i,sarake) > 0) {
        kaavio.rect(i*vali,korkeus-alamarg,i*vali+vali*3/4,korkeus-alamarg-map(data.getFloat(i, sarake),min,maks,alamarg,korkeus-2*alamarg));
      }
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(teksti);
      String arvo = data.getString(i,sarake);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake) > 0) {
        kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-alamarg-map(data.getFloat(i, sarake),min,maks,alamarg,korkeus-2*alamarg)-5);
      }
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
      
   
  }
  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.fill(teksti);
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.text(data.getColumnTitle(sarake),leveys/2,50);
  otsikko.endDraw();
  
}

void piirraPalkit(int sarake1, int sarake2) {
  nollaaKaavio();
  //säädetään palkkien piirustusmuoto
  kaavio.rectMode(CORNERS);
  //säädetään fontti kohdalleen
  float min1 = minimi(sarake1);
  float maks1 = maksimi(sarake1);
  float min2 = minimi(sarake2);
  float maks2 = maksimi(sarake2);

  //aloitetaan piirustus
  kaavio.beginDraw();
  kaavio.textFont(f);
  kaavio.textAlign(CENTER);
  String arvo = "";
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      //Piirretään palkki

      kaavio.fill(tayte1);
      kaavio.stroke(viiva1);
      if(data.getFloat(i,sarake1) > 0) {
        kaavio.rect(i*vali,korkeus-alamarg,i*vali+vali*3/8,korkeus-alamarg-map(data.getFloat(i, sarake1),min1,maks1,20,korkeus-2*alamarg));
      }      
      arvo = data.getString(i,sarake1);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake1) > 0) {  
        kaavio.text(arvo,i*vali+vali/2*3/8,korkeus-alamarg-map(data.getFloat(i, sarake1),min1,maks1,alamarg,korkeus-2*alamarg)-5);
      }
      kaavio.fill(tayte2);
      kaavio.stroke(viiva2);
      if(data.getFloat(i,sarake2) > 0) {
        kaavio.rect(i*vali+vali*3/8,korkeus-alamarg,i*vali+vali*3/4,korkeus-alamarg-map(data.getFloat(i, sarake2),min2,maks2,20,korkeus-2*alamarg));
      }
      arvo = data.getString(i,sarake1);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake2) > 0) {
      kaavio.text(arvo,i*vali+vali*3/6,korkeus-alamarg-map(data.getFloat(i, sarake2),min2,maks2,alamarg,korkeus-2*alamarg)-5);
      }
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
      
   
  }
  kaavio.endDraw();

  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(tayte1);
  otsikko.text(data.getColumnTitle(sarake1) + " and",leveys/2,50);
  otsikko.fill(tayte2);
  otsikko.text(data.getColumnTitle(sarake2),leveys/2,100);
  otsikko.endDraw();

  
}


void piirraXY(int x, int y) {
  nollaaKaavio();
  float xmin = minimi(x);
  float xmax = maksimi(x);
  float ymin = minimi(y);
  float ymax = maksimi(y);  
  kaavio.beginDraw();
  kaavio.stroke(viiva1);
  int koko = 10;



  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    //Piirretään piste
    kaavio.fill(tayte1);    
    kaavio.ellipse(map(data.getFloat(i,x),xmin,xmax,0,leveys), korkeus - map(data.getFloat(i,y),ymin,ymax,0,korkeus),koko,koko);
    kaavio.textFont(f3);
    kaavio.textAlign(CENTER);
    kaavio.fill(teksti);
    kaavio.text(data.getColumnTitle(x),leveys/2, korkeus-10);
    kaavio.pushMatrix();
    kaavio.rotate(3*HALF_PI);
    kaavio.text(data.getColumnTitle(y),-korkeus/2,30);   
    kaavio.popMatrix();
  }
  kaavio.endDraw();  
  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(teksti);
  otsikko.text(data.getColumnTitle(x) + " vs.",leveys/2,50);
  otsikko.text(data.getColumnTitle(y),leveys/2,100);
  otsikko.endDraw();
  
  
}

void piirraViiva(int sarake) {
  nollaaKaavio();
//  float kerroin = skaalaa(sarake);
  kaavio.beginDraw();
  kaavio.beginShape();
  kaavio.fill(tausta);
    float min = minimi(sarake);
    float maks = maksimi(sarake);

    for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole

    //Piirretään viiva
    kaavio.stroke(viiva1);
    if(data.getFloat(i,sarake) > 0) {    
      kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake),min,maks,alamarg,korkeus-2*alamarg));
    }
  }
  kaavio.endShape();


  //säädetään fontti kohdalleen

  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(teksti);
      String arvo = data.getString(i,sarake);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake) > 0) {
        kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake), min,maks,alamarg,korkeus-alamarg)-5);
      }
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
  }


  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(teksti);
  otsikko.text(data.getColumnTitle(sarake),leveys/2,50);
  otsikko.endDraw();

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
    kaavio.stroke(viiva1);
    if(data.getFloat(i,sarake1) > 0) {
      kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake1),min1,maks1,alamarg,korkeus-alamarg));
    }
  }
  kaavio.endShape();

  kaavio.beginShape();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    //Piirretään viiva
    kaavio.stroke(viiva2);
    if(data.getFloat(i,sarake2) > 0) {
      kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake2),min2,maks2,alamarg,korkeus-alamarg));
    }
  }
  kaavio.endShape();


  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(viiva1,255);
      String arvo = data.getString(i,sarake1);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake1) > 0) {
        kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake1), min1,maks1,alamarg,korkeus-alamarg)-5);
      }
      kaavio.fill(viiva2,255);
      arvo = data.getString(i,sarake2);
      if(arvo.length() > 5) {
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake2) > 0) {
        kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-map(data.getFloat(i, sarake2), min2,maks2,alamarg,korkeus-alamarg)-5);
      }
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5);
  }


  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(tayte1);
  otsikko.text(data.getColumnTitle(sarake1) + " and",leveys/2,50);
  otsikko.fill(tayte2);
  otsikko.text(data.getColumnTitle(sarake2),leveys/2,100);
  otsikko.endDraw();

}
void piirraMuutos(int askel, int sarake) {
  nollaaKaavio();
  kaavio.beginDraw();
  //säädetään fontti kohdalleen
  
  kaavio.textFont(f2);
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
  kaavio.text(muutos_lyh + " " + suure + ".",leveys/2,200);
  kaavio.text("The president of the United States was " + data.getString(indeksi,0),leveys/2,250);

  kaavio.endDraw();

}

void piirraHistogram(int sarake) {
  nollaaKaavio();
  FloatList sarakedata = new FloatList(data.getFloatColumn(sarake));
  for(int i = 0; i < sarakedata.size(); i++) {
    if(sarakedata.get(i) < 0) {
      sarakedata.remove(i);
    }
  }
  float min = sarakedata.min();
  float maks = sarakedata.max();
  float lev = (maks-min)/10;
  Frequency hist = new Frequency(sarakedata.array(),min,maks,lev);
  
  float[] frek = hist.getFrequency();
  float frekmaks = 0;
  for(int i = 0; i < frek.length;i++) {
    if(frek[i] > frekmaks) {
      frekmaks = frek[i];
    }
  }
    
  kaavio.beginDraw();
  kaavio.rectMode(CORNERS);
  float binLeveys = (leveys-2*marg)/hist.getNumBins();
  for(int i = 0; i < frek.length; i++) {
      kaavio.fill(tayte1);
      kaavio.stroke(viiva1);
      kaavio.rect(i*binLeveys,korkeus-alamarg,i*binLeveys+binLeveys*3/4,korkeus-alamarg-map(frek[i],0,frekmaks,alamarg,korkeus-2*alamarg-100));
      kaavio.textFont(f);
      kaavio.textAlign(CENTER);
      kaavio.fill(teksti);      
      kaavio.text(round(frek[i]),i*binLeveys+binLeveys/2*3/4,korkeus-alamarg-map(frek[i],0,frekmaks,alamarg,korkeus-2*alamarg-100)-5);
      kaavio.text(String.format("%.1f",min+i*lev) + "-" + String.format("%.1f",min+(i+1)*lev),i*binLeveys+binLeveys/2*3/4, korkeus-5);
  }
  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(teksti);
  otsikko.text("Histogram of " + data.getColumnTitle(sarake),leveys/2,50);
  otsikko.endDraw();

}

void piirraKorrelaatio(int sarake1, int sarake2) {
  nollaaKaavio();
  FloatList sarakedata1 = new FloatList(data.getFloatColumn(sarake1));
  FloatList sarakedata2 = new FloatList(data.getFloatColumn(sarake2));
  

  for(int i = 0; i < sarakedata1.size(); i++) {
    if(sarakedata1.get(i) < 0 || sarakedata2.get(i) < 0) {
      sarakedata1.remove(i);
      sarakedata2.remove(i);
    }
  }
  
  float[] coeff = Linear.bestFit(sarakedata1.array(),sarakedata2.array());
  float slope = coeff[0]; 
  String muutos = "";
  if(slope > 0) {
    muutos = "increases";
  } else {
    muutos = "decreases";
    slope = 0 - slope;
  }
  String label = data.getColumnTitle(sarake1);
  String otsikko1 = label.substring(0,label.indexOf("("));
  String suure1 = label.substring(label.indexOf("(")+1,label.indexOf(")"));
  label = data.getColumnTitle(sarake2);
  String otsikko2 = label.substring(0,label.indexOf("("));
  String suure2 = label.substring(label.indexOf("(")+1,label.indexOf(")"));

  kaavio.beginDraw();
  kaavio.textFont(f2);
  kaavio.textAlign(CENTER);
  kaavio.fill(teksti);
  kaavio.text("When " + otsikko1,leveys/2,50);  
  kaavio.text("increases by 1 " + suure1 + ",",leveys/2,100);
  kaavio.text("the amount of " + otsikko2,leveys/2,150);
  kaavio.text(muutos + " by " + String.format("%.2f",slope) + " " + suure2 + ".",leveys/2,200);
  kaavio.endDraw();  
  otsikko.beginDraw();
  otsikko.endDraw();
}

  
void nollaaKaavio() {
  x_0=0;
  kaavio.beginDraw();
  kaavio.clear();
  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.clear();
  otsikko.endDraw();
}
  
/*
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
*/ 
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
 
int arvoKeissi(int datat) {
    alku = false;

  if(datat == 1) {
    return round(random(0.5,7.4));
  } else {
    return 0;
  }
  
}

void piirraMatch(int sarake1, int sarake2) {
  
}

void serialEvent(Serial p) { 
  inString = p.readString(); 
  inString = trim(inString);
  
  if(inString.equals("66006BEEEC0F")) {
    y1 = 3;
  } else if(inString.equals("66006C34625C")) {
    y1 = 4;
  } else {
    y1 = 2;
  }
  keissi = arvoKeissi(1);
  fadeOut = true;


} 
  
  

