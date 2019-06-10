// setting
boolean DEBUG           = true ;      // main Debug param

boolean DEBUG_VIRTUAL   = false;      // see virual point and wall when portal works
boolean DEBUG_LINES     = false;      // see light traces
boolean DEBUG_POINTS    = false;      // points on wich walls and portals are based
boolean DEBUG_VECTOR    = false;      // see move line

boolean DEBUG_COLLISON  = false ;      // main Debug param for collesion
boolean DEBUG_COLLISON_PROJECTION  =true ;// see projections body on  collision works
boolean DEBUG_COLLISON_VIRTUAL     =true ;// see virtual walls when collision works
boolean DEBUG_COLLISON_SPECIAL     =true ;// see virtual walls when after collision work position close to the walls
boolean DEBUG_COLLISON_INTERSECTION=true ;// see intersection vector (position,movement) on virtual walls when collision works


boolean CACHING = true;               // can fuck portals up
float SPEED = 8;                      // speed of character
int RECURSIVITY = 1;                  // you can see portals in portals N times (does not work yet)
int BODY_SIZE = 1;                    // размер игрока
float COLLISION_DISTANCE = 3;         // расстояние, на котором виртуальная стена находится от обычной
String LEVEL = "level_test.json";

// === Global TODO List ===
// - Mouse world rotation
// - Wall collision
// - Portal teleport player

// - в Wall разобраться, что происходит в функциях из интернетов
// - Пофиксить колижен еще сильнее. 

//Баг: вероятно, при непрямых плоскостях колижен не работает совсем. Скорее всего, ошибка кроется в функция класса Visible

//Баг: если двигаться близко к виртуальной стене и почти параллельно ей, то возможно ускорение движения засчет телепортации

//Баг: если попытаться пройти через стены с угла > 180 градусов, то можно пройти сквозь него. 
//Предпологаемый фикс - продлить виртуальные стены по длинне в зависимости от COLLISION_DISTANCE так, чтобы закрыть эту брешь

// global variables
boolean   mousePress = false;
PVector   movement = new PVector(0,0);
PVector   position = new PVector(450,250);
Level     level;
int count = 0;
int mcount = 0;
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
  mouseMove(movement, mousePress);
 
  // move the character
  // C O L L I S I O N   P R O C E S S !!!
  
  PVector aftermov = position.copy().add(movement);//Предпологаемая позиция, куда игрок переместиться в среде без колижена
  PVector prepos = position.copy().add(movement.copy().mult(-1).normalize());//Точка, сдвинутая немного назад. Нужна чтобы избегать некоторых странных багов
  //Вместе они образую линию (aftermov, prepos), линию движения игрока
  if (DEBUG && DEBUG_COLLISON) {
    translate(-position.x+width/2, -position.y+height/2);
    push();
    line(position.x,position.y,aftermov.x,aftermov.y);
    stroke(255,0,0,255);
    line(position.x,position.y,prepos.x,prepos.y); 
    stroke(0,255,0,255);
    line(aftermov.x,aftermov.y,prepos.x,prepos.y); 
    pop();
  }
  for (Visible wall : level.walls) {
    
    if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_PROJECTION) {
      PVector proj = wall.projection(position, true);
      if (proj != null) {
        circle(proj.x, proj.y, 3);
      }
    }
    
    Wall virt_wall = new Wall(wall.first().copy(), wall.secon().copy()); //Виртуальная стена колижена
    PVector normile = virt_wall.projection(position, true); //Если игрок в принципе может коснуться некоторой стены, то мы будем рабоать с этой стеной
    if (normile != null) { //Если проекция есть, то игрок может коснуться стены
      normile = position.copy().sub(normile).normalize().mult(COLLISION_DISTANCE);//Определим, в каком направлении виртаульная стена
      //И сдвинем её туда
      virt_wall.a.add(normile);
      virt_wall.b.add(normile);
      if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_VIRTUAL) line(virt_wall.a.x, virt_wall.a.y, virt_wall.b.x, virt_wall.b.y);
      
      if (virt_wall.intersection(aftermov,prepos) != null) {//Если было перечение виртуальной стены и линии движения игрока, то начать колижен
        if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_INTERSECTION) {
          PVector pos = virt_wall.intersection(aftermov,prepos);
          push();
          stroke(255,0,0,255);
          circle(pos.x, pos.y, 2);
          pop();
          
        }
        
        boolean was = false; //переменная, описывающая, нужно ли после перемещения позиции дополнительно сдвигать на противоположный движению вектор
        if ( wall.distance(position) >  wall.distance(aftermov) || wall.intersection(aftermov,prepos) != null) was = true; //TODO: вероятно, это не все условия
        position = virt_wall.projection(aftermov, false);//Переместить позицию на проекцию на виртуальной стене   
        if (was) position.add(movement.copy().mult(-1)); //Если напрвление движение В стену, то дополнительно отодвинуть позицию 
        aftermov = position.copy().add(movement); //Пересчитать линию движения игрока
        prepos = position.copy().add(movement.copy().mult(-1).normalize()); 
      }    
      
    }
    
  }
  
  position.add(movement);
  
  for (Visible wall : level.walls) {  
    if (wall.distance(position) < COLLISION_DISTANCE) { //Если итоговая позиция попадает в зону межу стеной и виртуальной стеной
      //То найти точку проекции на виртуальную стену и переместить позицию туда
      Wall virt_wall = new Wall(wall.first().copy(), wall.secon().copy());
      PVector normile = virt_wall.projection(position, true);
      if (normile != null) {
        normile = position.copy().sub(normile).normalize().mult(COLLISION_DISTANCE);
        virt_wall.a.add(normile);
        virt_wall.b.add(normile);
        if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_SPECIAL) {
          push();
          stroke(0,0,255,255);
          line(virt_wall.a.x, virt_wall.a.y, virt_wall.b.x, virt_wall.b.y);
          pop();
        }
        position = virt_wall.projection(position, false);
      }
    }
  }
  if (!(DEBUG && DEBUG_COLLISON)) translate(-position.x+width/2, -position.y+height/2);
  for (Portal portal : level.portals) {
    portal.ReLoad();
  }
  
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
    if (DEBUG && DEBUG_POINTS) {
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
  
  if (DEBUG && DEBUG_VIRTUAL) {
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
    if (DEBUG && DEBUG_LINES) {
      stroke(255,50);
      line(position.x, position.y,  p.x, p.y);
    }
  }
  endShape(CLOSE);
  pop();
  
  // draw the vector (debug only)
  if (mousePress && DEBUG && DEBUG_VECTOR) {
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
  circle(position.x,position.y,BODY_SIZE);
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
}

// =================================================================================================================

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
  if (teleporter != null && count < RECURSIVITY && result != null) {
    return recursiveCast(ray, teleporter.teleport(wallsToCast), count+1 , result.copy().sub(position).mag() );
  } 

  return result;
}


void mousePressed() {
  mousePress = true;
}

void mouseReleased() {
  mousePress = false;
}
