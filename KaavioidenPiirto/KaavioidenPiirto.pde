import processing.serial.*; 
 
Serial myPort;    // The serial port
String inString = "Tyhjä";  // Input string from serial port
int lf = 10;      // ASCII linefeed 

PGraphics kaavio; //tähän piirretään
int x_0 = 0;  //nollataan palkkien sijainti
int vali = 50; //palkkien väli
float kerroin = 1;
Table data = loadTable("data3.csv","header");

int leveys = 800;
int korkeus = 600;
int leveysMax = (data.getRowCount()-1)*vali;

int marg = 20;
float zoom = leveys - 2*marg;

int lapinakyvyys = 0;
boolean fadeIn = true;
boolean fadeOut = false;

int keissi = 1;

color tausta = color(255,255,255);
color viiva = color(0,0,0);
color viiva2 = color(255,0,0);
color tayte = color(255,255,255);
color teksti = color(0,0,0);

boolean zoomIn = true;
boolean zoomOut = false;

void setup() {
  size(leveys, korkeus);
  kaavio = createGraphics(leveysMax,korkeus); //luodaan riittävän suuri piirustusalusta
  background(tausta); //taustaväri
  skaalaa();
  println(Serial.list()); 
  myPort = new Serial(this, Serial.list()[0], 9600); 
  myPort.bufferUntil(lf); 
}

void draw() {
  if(inString.equals("66006BEEEC0F")) {
    keissi = 1;
  } else if(inString.equals("66006C34625C")) {
    keissi = 2;
  } else {
    keissi = 0;
  }
  switch(keissi) {
    case 0:
      marg = 0;
      piirraViiva();
      break;
    case 1:
      marg = 20;
      piirraPalkit(1);
      piirraTeksti();  
      break;
    case 2:
      piirraViiva();
      break;
    case 3:
      piirraXY();
      break;
  }


  //Nollataan tausta  
  rectMode(CORNER);
  fill(tausta);
  stroke(tausta);
  rect(0,0,width,height);
  
  if(fadeIn) {
    tint(tausta,lapinakyvyys);
    image(kaavio,marg + x_0,0+(korkeus-zoom/leveysMax*korkeus),zoom,zoom/leveysMax*korkeus);
    if(lapinakyvyys >= 255) {
      fadeIn = false;
    } else {
      lapinakyvyys++;
    }
  } else if(fadeOut) {
    tint(tausta,lapinakyvyys);
    image(kaavio,marg + x_0,0+(korkeus-zoom/leveysMax*korkeus),zoom,zoom/leveysMax*korkeus);
    if(lapinakyvyys <= 0) {
      fadeOut = false;
      fadeIn = true;
    } else {
      lapinakyvyys--;
    }
    
  } else {  
  if (zoomIn) {
    image(kaavio,marg + x_0,0+(korkeus-zoom/leveysMax*korkeus),zoom,zoom/leveysMax*korkeus);
    if(zoom >= leveysMax) {
      zoomIn = false;
    } else {
      zoom = zoom + 3;
    }
  } else if(zoomOut) {
    image(kaavio,marg + x_0,0+(korkeus-zoom/leveysMax*korkeus),zoom,zoom/leveysMax*korkeus);
    if(zoom <= (leveys - 2*marg)) {
      zoomOut = false;
      zoomIn = true;
      fadeOut = true;
    } else {
      zoom = zoom - 3;
      x_0 = x_0 + 3;
    }
  } else {
    image(kaavio,marg + x_0,0);
    if (x_0 <= -(leveysMax-leveys+marg)) {
      zoomOut = true;
    } else {
      x_0--;    
    }
  }
  }
  

}

void piirraTauko() {
  
}

void piirraPalkit(int sarake) {
//säädetään palkkien piirustusmuoto
  kaavio.rectMode(CORNERS);

//aloitetaan piirustus
  kaavio.beginDraw();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    TableRow row = data.getRow(i); //otetaan rivi
    //Piirretään palkki
    kaavio.fill(tayte);
    kaavio.stroke(viiva);
    kaavio.rect(i*vali,korkeus,i*vali+vali*3/4,korkeus-kerroin*row.getInt("Articles"));
  }
  kaavio.endDraw();
  
}

void piirraTeksti() {
/*
  //säädetään fontti kohdalleen
  PFont f;
  f = createFont("Verdana",14,false);
  
  kaavio.beginDraw();
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    TableRow row = data.getRow(i); //otetaan rivi
    //laitetaan tekstiä palkin päälle
    kaavio.textFont(f);
    kaavio.textAlign(CENTER);
    kaavio.fill(viiva);
    kaavio.text(row.getString("sana"),i*vali+vali/2*3/4,korkeus-kerroin*row.getInt("x")-5);
  }
  kaavio.endDraw();
*/
}

void piirraXY() {
  kaavio.beginDraw();
  kaavio.stroke(0);
  kaavio.fill(0);    
  int koko = 3;

  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    TableRow row = data.getRow(i); //otetaan rivi
    //Piirretään piste
    kaavio.ellipse(row.getInt("Articles"), korkeus - row.getInt("Pigs"),koko,koko);
  }
  kaavio.endDraw();  
}

void piirraViiva() {
  kaavio.beginDraw();
  kaavio.beginShape();
      kaavio.fill(tausta);

    for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    TableRow row1 = data.getRow(i); //otetaan rivi
    //Piirretään viiva
    kaavio.stroke(viiva);
    kaavio.vertex(i*vali,korkeus-kerroin*row1.getInt("Articles"));
//    kaavio.stroke(viiva2);
//    kaavio.vertex(i*vali,korkeus-kerroin*row1.getInt("y"));
  }
  kaavio.endShape();
  kaavio.endDraw();

}
  
void nollaaKaavio() {
  kaavio.beginDraw();
  kaavio.rectMode(CORNER);
  kaavio.fill(tausta);
  kaavio.stroke(tausta);
  kaavio.rect(0,0,leveysMax,korkeus);
  kaavio.endDraw();
  
}

void piirraAkselit() {
  
}

void skaalaa() {
  int maksimi = 0;
  for (int i = 0; i < data.getRowCount(); i++) { //käydään läpi data rivi kerrallaan, kunnes rivejä ei enää ole
    TableRow row = data.getRow(i); //otetaan rivi
    if(row.getInt("Articles") > maksimi) {
      maksimi = row.getInt("Articles");
    } else if(row.getInt("Pigs") > maksimi) {
      maksimi = row.getInt("Pigs");
    } else {
    }
  }
  float k = korkeus;
  kerroin = (k-50)/maksimi;
}
 
void serialEvent(Serial p) { 
  nollaaKaavio();
  inString = p.readString(); 
  inString = trim(inString);

} 
  
  

