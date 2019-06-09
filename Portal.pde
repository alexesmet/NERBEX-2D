
//TODO: вынести все функции в отдельный файл

//Повернуть точку what относительно where на угол angle
//А по или против часовой - да кто его знает. //TODO: выяснить, куда вращает
PVector RotateAround(PVector what, PVector where, float angle) {
  float sinangle = sin(angle), cosangle = cos(angle);           
  float normalX = what.x - where.x;
  float normalY = what.y - where.y;
  what.x = where.x + normalX * cosangle - normalY * sinangle;
  what.y = where.y + normalY * cosangle + normalX * sinangle;
  return what;
}

//Изменить расстояние от where до what в coef раз. Меняется точка what
PVector MultAround(PVector what, PVector where, float coef) {
  what.x = where.x + (what.x - where.x) * coef;
  what.y = where.y + (what.y - where.y) * coef;
  return what;
}
 
//Считает угол относительно OX. Думает, что вектор base исходит от точки (0,0)
//TODO: сделать нормально, без минусов
//В Н И М А Т Е Л Ь Н О !!! Центр координат - слева СВЕРХУ! вектор (0,1) выглядит направленным вниз, но его угол PI!
float Angle(PVector base) {
  float angle = acos(base.x/base.mag());
  if (base.y < 0) angle = 2*PI - angle;
  return angle;
}

//Вернуть угол между base и what
//Угол возвращается в черт знает каких пределах, но всё работает
//TODO: определить пределы
float PVectorAngle(PVector base, PVector what) {
  return Angle(what) - Angle(base);
}

class Portal implements Visible{
  PVector coords;
  PVector direction; //mag = radius
  PVector a, b; // for drawing 
  color col = color(100,150,200);
  int UID;
  float DeltaAngle = 0; //Хранит в себе разность углов между связанным порталом
  float MultDist = 1; //Хранит в себе отношение длинн порталов 
  boolean didDrawPinkWalls = true; // for debug, draw teleported walls only once.
  
  Portal linked = null;
  PVector tran = null;
  
  Visible[] chache = null; 
  
  Portal(PVector a, PVector b) {
    this.a = a;
    this.b = b;
    this.UID = int(random(6000));
    
    direction = a.copy().sub(b).div(2).rotate(HALF_PI).normalize();
    coords = a.copy().add(b).div(2);
  }
  
  void link(Portal p) {
    linked = p;
    tran = p.coords.copy().sub(this.coords); // LEADS OUT
    //p.linked = this;
    //p.tran = this.tran.copy().mult(-1);
    DeltaAngle = PVectorAngle(direction, linked.direction);//Расчитать разность углов
    MultDist = abs(a.copy().sub(b).mag()/linked.a.copy().sub(linked.b).mag());//TODO: написать это НОРМАЛЬНО 
  }
  
  Visible[] teleport(Visible[] portWalls) { //for walls
    if (chache == null) {
      float angle = DeltaAngle + PI;
      ArrayList<Visible> cacheProto = new ArrayList<Visible>();
      Visible shifted = null;
      for (Visible vis : portWalls) {
        if (this.linked.equals(vis)) continue; // we should not see back of this portal anymore
        if (this.equals(vis)) continue;        // BREAKS RECURSIVITY
        //Повороты и умножения всякие
        shifted = vis.copyShift(tran.copy().mult(-1)); 
        RotateAround(shifted.first(), coords,  -angle);
        RotateAround(shifted.secon(), coords,  -angle);
        MultAround(shifted.first(),   coords,  MultDist);
        MultAround(shifted.secon(),   coords,  MultDist);
        
        //TODO: переносить только половину стен
        if (true) {
          cacheProto.add(shifted);
        }
      }
      chache =  cacheProto.toArray(new Visible[0]);
    } 
    //TODO: проверить баг, что в chache лежат дубликаты.
    if (DEBUG && !didDrawPinkWalls) { // draw pink wall
      didDrawPinkWalls = true;
      push();
      stroke(255,100,255,150);
      for (Visible vis : chache) 
        line(vis.first().x, vis.first().y, vis.secon().x, vis.secon().y);
      pop();
    }
    
    return chache;
  }
  
  void clearCache() {
    chache = null;
  }
  
  Visible copyShift(PVector by) {
    Portal res = new Portal(a,b);
    res.link(this.linked);
    res.UID = this.UID;
    return res;
  }
  
  boolean isGood(PVector pos) {
    PVector left  = a.copy().sub(pos).normalize();
    PVector right = b.copy().sub(pos).normalize();
    float FOV = PVector.angleBetween(right.copy().add(left), direction);
    return FOV < HALF_PI;
  }
  
  
  
  ArrayList<PVector> translate(PVector[] points, PVector pos) {  // for points
    float angle = DeltaAngle;//Угол между порталами //TODO: пройтись по коду и выяснить, можно ли заменить angle на DeltaAngle без критических последствий 
    angle += PI; //Волшебный доворот на PI, без этой волшебной констнты нихуя не работает
    ArrayList<PVector> list = new ArrayList<PVector>();
    PVector left  = a.copy().sub(pos).normalize();
    PVector right = b.copy().sub(pos).normalize();
    float FOV = PVector.angleBetween(right.copy().add(left), direction);
    boolean good = FOV < HALF_PI;
    
    RotateAround(left , new PVector(0,0), angle); //TODO: узнать как работает rotate и юзнуть его, а не вот это вот
    RotateAround(right, new PVector(0,0), angle);
    PVector lstart  = linked.b.copy();
    PVector rstart  = linked.a.copy();  
    if (DEBUG) {//Дебаг отрисовки линий, показывающий область видимости после перехода из портала
      push();
      strokeWeight(1);
      stroke(col);
      if (good) {
        line(lstart.x, lstart.y, lstart.x+left.x *200, lstart.y+left.y *200);//Тут были a.x +tran.x //Заменено на lstart  = linked.b.copy() выше
        line(rstart.x, rstart.y, rstart.x+right.x*200, rstart.y+right.y*200);
        fill(0,255,0);
      }
      else fill(255,0,0);
      arc(coords.x+direction.x*15, coords.y+direction.y*15, 15, 15, direction.heading()-0.5-PI, direction.heading()+0.5-PI);
      pop();
    }
    
    if (!good) return list;
    
    //angle = PVectorAngle(direction, linked.direction);
    
    //angle = - angle;
    PVector transChar = pos.copy().add(tran); // virtaul camera base
    PVector s2 = RotateAround(transChar.copy(),linked.coords,angle);; // virtaul camera rotate
    PVector transMultChar = MultAround(s2.copy(),linked.coords,linked.MultDist);//TODO: убрать лишнюю переменную
    if (DEBUG) { //показать точку новой виртуальной камеры
      push();
      fill(255, 150);
      stroke(240, 150);
      strokeWeight(2);
      //circle(transChar.x,transChar.y,1);
      //circle(s2.x,s2.y,3);
      circle(transMultChar.x,transMultChar.y,4);
      pop();
    }
    transChar = transMultChar;
    for (PVector point : points) {  
      PVector vectorTo = point.copy().sub(transChar);
      if (PVector.angleBetween(left,  vectorTo.copy().rotate(HALF_PI)) +0.001 > HALF_PI &&
          PVector.angleBetween(right, vectorTo.copy().rotate(HALF_PI)) -0.001 < HALF_PI) {
          PVector newpoint;
          newpoint = point.copy().add(tran.copy().mult(-1));  
          RotateAround(newpoint,coords,-angle);
          MultAround(newpoint,coords,MultDist);
          list.add(newpoint);
          //Отрисовка виртуальный камеры
          if (DEBUG) { 
            push();
            strokeWeight(1);
            fill(0);
            stroke(col,120);
            line(transChar.x, transChar.y, transChar.x + vectorTo.x, transChar.y + vectorTo.y);
            stroke(250,100,0);
            circle(point.x, point.y, 5);
            pop();
          }
      }
    }
    
    return list;
  }
  
  boolean equals(Object obj) {
    if (this == obj) return true;
    if (obj instanceof Portal) {
      Portal o = (Portal) obj;
      return this.UID == o.UID;
    }
    return false;
    
  }

  void show() {
    push();
    strokeWeight(2);
    stroke(col);
    fill(col);
    line(a.x, a.y, b.x, b.y);
    arc(coords.x+direction.x*11, coords.y+direction.y*11, 10, 10, direction.heading()-0.5-PI, direction.heading()+0.5-PI);
    circle(coords.x, coords.y, 5);
    pop();
  }
  
  ArrayList<PVector> getPoints() {
    ArrayList<PVector> list = new ArrayList<PVector>();
    return list;
  }
 
  PVector first() {
    return a;
  }
  
  PVector secon() {
    return b;
  }
  
  void ReLoad() {
    direction = a.copy().sub(b).div(2).rotate(HALF_PI).normalize();
    coords = a.copy().add(b).div(2);
    //link(linked);
    didDrawPinkWalls = false;
  }
  
}
