/* RFID tagin lukemiseen tarvittavat muuttujat */
import processing.serial.*;  
Serial rfid1;    //eka lukija
Serial rfid2;    //toka lukija
Serial arduino;    //arduino
String inString = "Tyhjä";  // Input string from serial port
int lf = 10;      // ASCII linefeed 

/* tagit */
String[] tagit = {
"66006BEEEC0F", //sarake B
"66006C34625C", //sarake C
"66006C081A18", //sarake D
"66006C0DFCFB"  //sarake E
};

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
int rullausNopeus = 4; //kuinka monta pikselia kerrallaan siirretään
int fadeNopeus = 15; //ristivaihtojen nopeus
boolean tauko = false; //pidetäänkö kaaviota paikallaan
int timer = 0;
int timerMax = 200;
boolean valitseKeissi = true; //valitaanko keissi uudelleen
boolean coincidence = false; //tuleeko näytölle teksti "Coincidence?"
boolean alku = false; //Mennäänkö aloitusruutuun
int montako = 0; //montako RFID korttia lukijassa

int keissi = 0; //mikä tapaus piirretään

int y1 = 7; //Mikä sarake valitaan datasta
int y2 = 1;
int offset1 = 0; //kuinka paljon tyhjiä arvoja on alussa
int offset2 = 0;

void setup() {
  size(leveys, korkeus);
  kaavio = createGraphics(leveysMax,korkeus); //luodaan riittävän suuri piirustusalusta
  otsikko = createGraphics(leveys,korkeus);
  background(tausta); //taustaväri
  /* ruvetaan kuuntelemaan sarjaporttia */
  println(Serial.list()); 
  rfid1 = new Serial(this, Serial.list()[2], 9600); 
  rfid1.bufferUntil(lf); 
  rfid2 = new Serial(this, Serial.list()[3], 9600); 
  rfid2.bufferUntil(lf); 
  arduino = new Serial(this, Serial.list()[1], 9600); 
  arduino.bufferUntil(lf); 
}

void draw() {

  if(valitseKeissi) { //esine lisätty tai poistettu
  switch(keissi) { 
    /* taukoanimaatio */
    case 0: 
      marg = 0;
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
      
    /* histogrammi */
    case 4:
      marg = 20;
      piirraHistogram(y1);
      rullaus = false;
      coincidence = false;
      break;
      
    /* kaksi viivaa */
    case 5:
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
      
    /* korrelaatioteksti */
    case 8:
      piirraKorrelaatio(y1,y2);
      rullaus=false;
      coincidence = true;
      break;
      
    /* kaksi settiä yhdistävä kaavio */
    case 9:
      y2 = 5;
      piirraMatch(y1, y2);
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
      keissi = arvoKeissi(montako);    
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
          if(timer < timerMax) {
            timer++;
          } else {
            timer = 0;
            tauko = false;
            fadeOut = true;
          }
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

/* Yksi palkki */
void piirraPalkit(int sarake) {
  nollaaKaavio(); //tyhjennetään edellinen kaaviopiirros
  kaavio.rectMode(CORNERS);   //säädetään palkkien piirustusmuoto
  float min = minimi(sarake); //datan pienin arvo, skaalausta varten
  float maks = maksimi(sarake); //data suurin arvo, skaalausta varten

  kaavio.beginDraw(); //aloitetaan piirustus
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
      kaavio.fill(tayte1); //palkin sisusvärin asetus
      kaavio.stroke(viiva1); //palkin viivan värin asetus
      if(data.getFloat(i,sarake) > 0) { //piirretään vain, jos dataa on, puuttuva arvot on merkitty -1:llä
        kaavio.rect(i*vali,korkeus-alamarg,i*vali+vali*3/4,korkeus-alamarg-map(data.getFloat(i, sarake),min,maks,alamarg,korkeus-2*alamarg)); 
        //piirretään suorakulmio antamalla sen kulmien koordinaatit.
        //vali kertoo palkkien vasemman alakulman välisen etäisyyden, joten i*vali antaa kullekin palkille oikean alakulman koordinaatin.
        //Palkkien leveys on 3/4 osaa välistä
        //alamarg kertoo alle jäävän tilan, ylhäälle jätetään 2 kertaa alamarginaali
        //map skaalaa arvon näytölle, eli venyttää esim välin 20-25 arvot välille 0-800.
      }
      kaavio.textFont(f); //fontin asetus
      kaavio.textAlign(CENTER); //tekstin asemointi
      kaavio.fill(teksti); //tekstin värin asetus
      String arvo = data.getString(i,sarake); //otetaan arvo
      if(arvo.length() > 5) { //näytetään vain osa desimaaleista
        arvo = arvo.substring(0,4); 
      }
      if(data.getFloat(i,sarake) > 0) { //tulostetaan arvo vain, jos se on positiivinen eli dataa on
        kaavio.text(arvo,i*vali+vali/2*3/4,korkeus-alamarg-map(data.getFloat(i, sarake),min,maks,alamarg,korkeus-2*alamarg)-5);
      }
      kaavio.fill(teksti);
      kaavio.text(data.getString(i, 0),i*vali+vali/2*3/4, korkeus-5); //vuosiotsikot alle
      
   
  }
  kaavio.endDraw();
  //kaavion otsikon piirto, erillinen objekti
  otsikko.beginDraw();
  otsikko.fill(teksti);
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.text(data.getColumnTitle(sarake),leveys/2,50);
  otsikko.endDraw();
  
}


/* Kaksi palkkia */
void piirraPalkit(int sarake1, int sarake2) { //samanlainen kuin yhden palkin tapaus
  nollaaKaavio();
  kaavio.rectMode(CORNERS);
  float min1 = minimi(sarake1);
  float maks1 = maksimi(sarake1);
  float min2 = minimi(sarake2);
  float maks2 = maksimi(sarake2);

  kaavio.beginDraw();
  kaavio.textFont(f);
  kaavio.textAlign(CENTER);
  String arvo = "";
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
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
      arvo = data.getString(i,sarake2);
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

/* XY-kaavio */
void piirraXY(int sarake1, int sarake2) {
  nollaaKaavio();
  FloatList x = new FloatList(data.getFloatColumn(sarake1)); //tallennetaan tiedot listaksi helpompaa käsittelyä varten
  FloatList y = new FloatList(data.getFloatColumn(sarake2));
  for(int i = 0; i < x.size(); i++) { //poistetaan puuttuvat arvot listoista. Jos toisesta puuttuu arvo, poistetaan molemmat, sillä tarvitaan arvopareja.
    if(x.get(i) < 0 || y.get(i) < 0) {
      x.remove(i);
      y.remove(i);
    }
  }

  kaavio.beginDraw();
  kaavio.stroke(viiva1);
  int koko = 10; //pisteen koko
  //Piirretään pisteet
  for (int i = 0; i < x.size(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    kaavio.fill(tayte1);    
    //Piirretään piste, arvot skaalattu näytölle koordinaateiksi map-funktiolla
    kaavio.ellipse(map(x.get(i),x.min(),x.max(),0,leveys), korkeus - map(y.get(i),y.min(),y.max(),0,korkeus),koko,koko);
  }

  //Piirretään akselien otsikot
  kaavio.textFont(f3);
  kaavio.textAlign(CENTER);
  kaavio.fill(teksti);
  kaavio.text(data.getColumnTitle(sarake1),leveys/2, korkeus-10); //x-akselin otsikko  
  kaavio.pushMatrix(); //lisätään objektiin muutosmatriisi
  kaavio.rotate(3*HALF_PI);  //pyöritetään koko kuvaa 90 astetta
  kaavio.text(data.getColumnTitle(sarake2),-korkeus/2,30); //y-akseli
  kaavio.popMatrix(); //poistetaan muutosmatriisi, jolloin kuva kääntyy takaisin

  kaavio.endDraw();  

  otsikko.beginDraw();
  otsikko.textFont(f3);
  otsikko.textAlign(CENTER);
  otsikko.fill(teksti);
  otsikko.text(data.getColumnTitle(sarake1) + " vs.",leveys/2,50);
  otsikko.text(data.getColumnTitle(sarake2),leveys/2,100);
  otsikko.endDraw();
  
  
}

/* Yhden viivan piirto */
void piirraViiva(int sarake) { //samantapainen kuin palkin piirto
  nollaaKaavio();
  kaavio.beginDraw();

  //piirretään viiva
  kaavio.beginShape(); //viiva on yhtenäinen "shape", joka piirretään osissa, siksi beginShape
  kaavio.fill(tausta);
  float min = minimi(sarake);
  float maks = maksimi(sarake);

  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    kaavio.stroke(viiva1);
    if(data.getFloat(i,sarake) > 0) {    
      kaavio.vertex(i*vali,korkeus-map(data.getFloat(i,sarake),min,maks,alamarg,korkeus-2*alamarg));
      //vertex piirtää viivaa aina edellisestä koordinaatistaan seuraavaksi annettuun. Koordinaatit annetaan siis yksitellen.
    }
  }
  kaavio.endShape();

  //Lisätään arvot viivaan
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

/* Kaksi viivaa */
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

/* Tulostaa suurimman muutoksen */
void piirraMuutos(int askel, int sarake) { //askel kertoo, kuinka pitkää aikaväliä katsotaan
  nollaaKaavio();
  kaavio.beginDraw();
  kaavio.textFont(f2);
  kaavio.textAlign(CENTER);
  kaavio.fill(teksti,255);
  
  float muutos = 0; //tarkasteltavan muutoksen arvo
  int indeksi = -1; //muutoksen indeksi; milloin muutos tapahtui (alkuvuosi)
  float maks = 0; //suurimman muutoksen arvo

  for(int i = 0; i < data.getRowCount(); i++) {
    if(i + askel < data.getRowCount()) { //varmistetaan, että arvoja riittää
      if(data.getFloat(i,sarake) > 0 && data.getFloat(i+askel,sarake) > 0) { //tarkistetaan, että tietoja ei puutu
        if(abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake)) > maks) { //lasketaan muutoksen itseisarvo ja verrataan tähän astiseen maksimiin
          maks = abs(data.getFloat(i,sarake) - data.getFloat(i+askel, sarake)); //jos oli suurempi, tallennetaan uudeksi maksimiksi
          muutos = (data.getFloat(i,sarake) - data.getFloat(i+askel, sarake)); //muutoksen oikea arvo
          indeksi = i; //tallennetaan milloin muutos tapahtui
        }  
      } else {
      }
    } else {
    }
  }
  
  String otsikko = data.getColumnTitle(sarake); //otetaan sarakkeen otsikko, sisältää myös suureen
  String label = otsikko.substring(0,otsikko.indexOf("(")); //poistetaan suure otsikosta
  String suure = otsikko.substring(otsikko.indexOf("(")+1,otsikko.indexOf(")")); //tallennetaan suure omaksi muuttujakseen
  String muutos_lyh = String.format("%.2f", muutos); //vähennetään muutoksen desimaalit kahteen
  
  //tulostetaan teksit näytölle
  kaavio.text("The biggest change over " + askel + " year time range in",leveys/2,50);
  kaavio.text(label,leveys/2,100);
  kaavio.text("happened from " + data.getString(indeksi,0) + " to " + data.getString(indeksi+askel,0) + ": ",leveys/2,150);
  kaavio.text(muutos_lyh + " " + suure + ".",leveys/2,200);
  kaavio.text("The president of the United States was " + data.getString(indeksi,0),leveys/2,250);

  kaavio.endDraw();



}

/* Histogrammi */
void piirraHistogram(int sarake) {
  nollaaKaavio();
  FloatList sarakedata = new FloatList(data.getFloatColumn(sarake)); //tetaan data taas listaan helpompaa käsittelyä varten
  for(int i = 0; i < sarakedata.size(); i++) { //poistetaan puuttuvat tiedot
    if(sarakedata.get(i) < 0) {
      sarakedata.remove(i);
    }
  }
  float min = sarakedata.min();
  float maks = sarakedata.max();
  float lev = (maks-min)/10; //tehdään histogrammiin kymmenen palkkia, joten lasketaan, kuinka leveät vaihteluvälit ovat
  Frequency hist = new Frequency(sarakedata.array(),min,maks,lev); //Papaya kirjaston Frequency laskee histogrammin
  
  float[] frek = hist.getFrequency(); //otetaan histogrammin tiedot arrayhin
  float frekmaks = 0; //katsotaan, mikä on suurin frekvenssi
  for(int i = 0; i < frek.length;i++) {
    if(frek[i] > frekmaks) {
      frekmaks = frek[i];
    }
  }
    
  kaavio.beginDraw();
  kaavio.rectMode(CORNERS);
  float binLeveys = (leveys-2*marg)/hist.getNumBins(); //lasketaan, kuinka leveitä palkit ovat näytöllä
  for(int i = 0; i < frek.length; i++) { //piirretään palkit
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

/* Korrelaatio */
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
  
  //Papaya kirjaston Linear laskee lineaarisen regression ja palauttaa kulmakertoimen ja vakiotermin.
  float[] coeff = Linear.bestFit(sarakedata1.array(),sarakedata2.array()); 
  float slope = coeff[0]; 
  String muutos = "";
  //katsotaan onko kulmakerroin positiivinen vai negatiivinen, sen perusteella valitaan oikea sana
  if(slope > 0) {
    muutos = "increases";
  } else {
    muutos = "decreases";
    slope = 0 - slope;
  }
  //sama otsikonpuljaus kuin piirraMuutos funktiossa
  String label = data.getColumnTitle(sarake1);
  String otsikko1 = label.substring(0,label.indexOf("("));
  String suure1 = label.substring(label.indexOf("(")+1,label.indexOf(")"));
  label = data.getColumnTitle(sarake2);
  String otsikko2 = label.substring(0,label.indexOf("("));
  String suure2 = label.substring(label.indexOf("(")+1,label.indexOf(")"));

  //tulostetaan tekstit
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

/* Kaavion tyhjennys */  
void nollaaKaavio() {
  x_0=0;
  kaavio.beginDraw();
  kaavio.clear();
  kaavio.endDraw();
  otsikko.beginDraw();
  otsikko.clear();
  otsikko.endDraw();
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

/*
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
*/

/* arvotaan, mitä piirretään */
int arvoKeissi(int datat) {

  if(datat == 0) { //ei kortteja
    alku = true;
    return 0;
  } else if(datat == 1) { //yksi kortti
    alku = false;
    return round(random(0.5,4.4));
  } else if(datat == 2) { //kaksi korttia
    alku = false;
    return round(random(4.5,8.4));
  } else { //ei kortteja
    alku = true;
    return 0;
  }
  
}

/* matsaus, ei vielä tehty */
void piirraMatch(int sarake1, int sarake2) {
  
}

/* tätä kutsutaan aina kun sarjaportti sanoo jotain
   eli kun rfid kortti laitetaan lukijaan (jolloin rfid lukija lähettää sarjaporttiin kortin tunnuksen ja arduino ykkösen)
   tai kun rfid kortti otetaan pois (jolloin arduino lähettää sarjaporttiin nollan) */
void serialEvent(Serial p) { 
  if(p == rfid1) { //p on sarjaportin tunnus
    inString = p.readString();  //luetaan
    inString = trim(inString);  //poistetaan välilyönnit
    for(int i = 0;i < tagit.length; i++) { //käydään kortit läpi
      if(inString.equals(tagit[i])) { //jos löytyy sama tunnus
        y1 = i+1; //asetetaan valittavaksi dataksi oikea sarakkeen numero. Sarakkeen indeksi alkaa ykkösestä, i niollasta, siksi täytyy lisätä ykkönen
      } 
    }
  }

  if(p == rfid2) {
    inString = p.readString(); 
    inString = trim(inString);
    for(int i = 0;i < tagit.length; i++) {
      if(inString.equals(tagit[i])) {
        y2 = i+1;
      } 
    }
  }
  
  if(p == arduino) { 
    //arduino lähettää vietin muotoa "x;y", jossa x ja y on 1 tai nolla.
    //x on eka kortinlukija, y on toinen. 
    //1 tarkoittaa että kortti on paikalla, 0 että ei ole
    //Otetaan nämä arvot talteen.
    inString = p.readString(); 
    inString = trim(inString);
    int lasna1 = 0;
    int lasna2 = 0;

    if(inString.length() > 2) {      
      lasna1 = Integer.parseInt(inString.substring(0,1));
      lasna2 = Integer.parseInt(inString.substring(2,3));
    }
    if(lasna1 == 1 && lasna2 == 1) { //molemmat läsnä
      montako = 2;
    } else if(lasna1 == 1 || lasna2 == 1) { //toinen läsnä
      montako = 1;
    } else { //ei kortteja
      montako = 0;
    }
  }

  fadeOut = true; //jotain muuttui, joten thedään fadeout, josta puolestaan kutsutaan keissinarvontaa
} 
  
  

