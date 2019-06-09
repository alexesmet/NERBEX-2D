// setting
boolean DEBUG = false;               // main Debug param
boolean CACHING = false;            // fucks portals up, do not use
float SPEED = 8;                    // speed of character
int RECURSIVITY = 1;                // you can see portals in portals N times (does not work yet)
String LEVEL = "level_test.json";

// global variables
boolean   mousePress = false;
PVector   movement = new PVector(0,0);
PVector   position = new PVector(450,250);
Level     level;

void setup() {
  size(1000, 700);
  frameRate(30);
  ellipseMode(RADIUS); 
  stroke(50,50,50);
  
  level = new Level(LEVEL);
}

void draw() {
  background(0);  // erase screen
  
  
  
  // handle input
  if (mousePress) 
    movement.set((mouseX-width/2), (mouseY-height/2)).normalize().mult(SPEED);  
  else
    movement.mult(0.65);
 
  // move the character
  position.add(movement);
  translate(-position.x+width/2, -position.y+height/2);
  
  PVector buf = level.portals[0].coords;
  RotateAround(level.portals[0].a,buf,PI/180);
  RotateAround(level.portals[0].b,buf,PI/180);
  level.portals[0].ReLoad();
  level.portals[1].ReLoad();
  println(level.portals[1].DeltaAngle);
  println(level.portals[1].direction, level.portals[1].linked.direction);
  
  println(Angle(level.portals[1].direction));
  println(Angle(level.portals[0].direction));
  
  
  
  // find visable points (visible points are green, invisible are reed. Optimizes ray-marching
  ArrayList<PVector> visableCorners = new ArrayList<PVector>();
  for (PVector point : level.points) {
    boolean visible = true;
    
    Ray ray = new Ray(position, point.copy().sub(position));
    PVector casted = null;
    for (Visible wall : level.walls) {
      if (wall.first().equals(point) || wall.secon().equals(point) ) continue;//Если точка - кусок стены - перейти к следующей стене
      casted = ray.cast(wall);
      if (casted != null && casted.sub(position).mag() < ray.dir.mag() ) {
        visible = false;
        break;
      }
      
    }
    if (visible) visableCorners.add(point);
    if (DEBUG) {
      push();
      strokeWeight(2);
      if (!visible) {
        stroke(255,10,0);
        fill(0);
      } else {
        fill(100,250,100);
        stroke(100,250,100);
      }
      circle(point.x, point.y, 3);
      pop();
    }
  }
  
  // teleport points, ask the portals, where visible transaleted points should be
  // transalted points are marked yellow
  ArrayList<PVector> translatedPoints = new ArrayList<PVector>();
  
  for (Portal portal : level.portals) { //Теперь все порталы работаю через массив порталов
    translatedPoints.addAll(portal.translate(level.points, position));
  }
  
  if (DEBUG) {
    push();
    strokeWeight(4);
    fill(0);
    stroke(250,250,0);
    for (PVector point :translatedPoints) 
      circle(point.x, point.y, 2);
    pop();
  }
  visableCorners.addAll(translatedPoints);
  // yellow points can sometimes come from portals we are not looking at, THIS IS STRANGE, bat not fatal
  // this is because virtual camera staerts seeng things behind the output portal
  

  // double cast - cast TWO rays on each point, one a bit to left, one a bit to right. see function below
  ArrayList<PVector> cast = doubleCast(visableCorners);
  
  // sort visible points around clockwise, to make a shape from them
  PVector buffer;
  for (int i=cast.size(); i>=0;i--) {
    for (int j=1; j<i; j++) {
      if(cast.get(j).copy().sub(position).heading() < cast.get(j-1).copy().sub(position).heading()) {
        buffer    =   cast.get(j);
        cast.set(j,   cast.get(j-1));
        cast.set(j-1, buffer);
      }
    }
  }
  
  
  // draw the light, simly connect all the points in order
  push();
  fill(230);
  if (DEBUG) fill (255,100);
  stroke(152);
  strokeWeight(0);
  beginShape();
  for (int i=0;i<cast.size();i++) {
    PVector p = cast.get(i);
    vertex(p.x, p.y);
    if (DEBUG) line(position.x, position.y,  p.x, p.y);
  }
  endShape(CLOSE);
  pop();
  
  // draw the vector (debug only)
  if (mousePress && DEBUG) {
    push();
    stroke(255,255,0);
    fill(255,255,0);
    line(position.x,position.y, position.x+movement.x*4, position.y+movement.y*4);
    arc(position.x+movement.x*4,position.y+movement.y*4, 7, 7, movement.heading()-0.5-PI, movement.heading()+0.5-PI);
    pop();
    
  }
  
  // draw the body
  push();
  fill(255);
  stroke(240);
  strokeWeight(5);
  circle(position.x,position.y,10);
  pop();
 
  if (DEBUG) {
    for (Visible vis : level.walls) {
      vis.show();
    }
  }
  
  // try to remember, wich walls are translated. Does not work properlu
  if (!CACHING) {
     for (Portal p : level.portals) {
       p.clearCache();
     }
  }
  
  
  
  
  //WorldRotation(0);
}

// casts two similar rays in all shown corners. returns all points that reached the wall
ArrayList<PVector> doubleCast(ArrayList<PVector> corners ) {
  Ray lefter = new Ray(position, null);
  Ray righter = new Ray(position, null);
  ArrayList<PVector> cast = new ArrayList<PVector>();
  PVector tempCasted = null;
  for (PVector point : corners) {
    lefter.dir = point.copy().sub(position).rotate(0.0001);
    righter.dir = point.copy().sub(position).rotate(-0.0001);
    
    tempCasted = recursiveCast(lefter , level.walls , 0, 0);
    if (tempCasted != null)  cast.add(tempCasted);
    tempCasted = recursiveCast(righter, level.walls , 0, 0);
    if (tempCasted != null)  cast.add(tempCasted);
    
  }
  return cast;
}

PVector recursiveCast(Ray ray, Visible[]  wallsToCast, int count, float minMag) {
  PVector lastCasted = null;
  PVector result = null;
  Portal teleporter = null;
  for (Visible wallCast : wallsToCast) {  
    
    // regular ray-cast
    lastCasted = ray.cast(wallCast);
    if (lastCasted != null && (result == null || (lastCasted.copy().sub(position).mag() < result.copy().sub(position).mag())  && (lastCasted.copy().sub(position).mag() >= minMag)  )) {
      if (wallCast instanceof Portal ) {
        if ( ((Portal)wallCast).isGood(position) ) {
          teleporter = ((Portal)wallCast);
        } else
          continue; // if reaced back of the portal, this is not a point, go find another
      } else teleporter = null;
      result = lastCasted.copy();
    } 
  }
  // if the wall this ray was hitting was actually a portal  
  if (teleporter != null && count < RECURSIVITY) {
    return recursiveCast(ray, teleporter.teleport(wallsToCast, position), count+1 , result.copy().sub(position).mag() );
  } 

  return result;
}


void mousePressed() {
  mousePress = true;
}

void mouseReleased() {
  mousePress = false;
}

//Повернуть весь мир на угол angle
//TODO: опять же, выяснить в какую сторону...
void WorldRotation(Level lev, float angle) {
  
   float normalX, normalY;
   float sinangle = sin(angle), cosangle = cos(angle);
   for (PVector point : lev.points) {
     normalX = point.x - position.x;
     normalY = point.y - position.y;
     point.x = position.x + normalX * cosangle - normalY * sinangle;
     point.y = position.y + normalY * cosangle + normalX * sinangle;
   }
   
   for (Portal portal : lev.portals) {
     portal.ReLoad();
   }
   
}
