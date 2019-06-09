enum PortalState{
    NONE,
    PORTALIN,
    PORTALOUT,
};

class Portal implements Visible{
  PVector coords;
  PVector direction; //mag = radius
  PVector a, b; // for drawing 
  color col = color(100,150,200);
  int UID;
  float DeltaAngle = 0; //Хранит в себе разность углов между связанным порталом
  float MultDist = 1; //Хранит в себе отношение длинн порталов 
  PortalState state = PortalState.NONE; //TODO: нужно ли это еще? Вероятно, так как сейчас есть функция нормального измерения угла между векторами, то это можно убрать
  
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
  
    //Повернуть точку what относительно where на угол angle
  //А по или против часовой - да кто его знает. TODO: выяснить, куда вращает
  private PVector RotateAround(PVector what, PVector where, float angle) {
    float sinangle = sin(angle), cosangle = cos(angle);           
    float normalX = what.x - where.x;
    float normalY = what.y - where.y;
    what.x = where.x + normalX * cosangle - normalY * sinangle;
    what.y = where.y + normalY * cosangle + normalX * sinangle;
    return what;
  }
  
  //Изменить расстояние от where до what в coef раз. Меняется точка what
  private PVector MultAround(PVector what, PVector where, float coef) {
    what.x = where.x + (what.x - where.x) * coef;
    what.y = where.y + (what.y - where.y) * coef;
    return what;
  }
  
  //Вернуть угол между base и what. base считается вектором, лежащий на оси OX
  //Угол возвращается в пределах от -PI до PI
  private float PVectorAngle(PVector base, PVector what) {
    return -atan2(base.y - what.y, base.x - what.x) * 2 + PI;
    //A = (A < 0) ? A + 360 : A;   //to [0...180] and [-1...-180]
  }
  
  void link(Portal p) {
    if (state == PortalState.NONE && p.state == PortalState.NONE) {//Установить стейты при начальной инициализации
      state = PortalState.PORTALIN;
      p.state = PortalState.PORTALOUT;
    }   
    linked = p;
    tran = p.coords.copy().sub(this.coords); // LEADS OUT
    p.linked = this;
    p.tran = this.tran.copy().mult(-1);
    DeltaAngle = PVectorAngle(direction, linked.direction);//Расчитать разность углов
    if (state == PortalState.PORTALOUT) { //wat? Я не знаю почему оно работает с этим куском, но трогать не буду. //TODO: проверить, нужен ли этот кусок
      DeltaAngle*=-1;
    }
    MultDist = abs(a.copy().sub(b).mag()/linked.a.copy().sub(linked.b).mag());//TODO: написать это НОРМАЛЬНО 
  }
  
  Visible[] teleport(Visible[] portWalls, PVector pos) { //for walls
    if (chache == null) {
      PVector left  = a.copy().sub(pos).normalize();
      PVector right = b.copy().sub(pos).normalize();
      ArrayList<Visible> cacheProto = new ArrayList<Visible>();
      Visible shifted = null;
      for (Visible vis : portWalls) {
        if (this.linked.equals(vis)) continue; // we should not see back of this portal anymore
        if (this.equals(vis)) continue;    
        //Повороты и умножения всякие
        shifted = vis.copyShift(tran.copy().mult(-1)); 
        RotateAround(shifted.first(), coords, -DeltaAngle);
        RotateAround(shifted.secon(), coords, -DeltaAngle);
        MultAround(shifted.first(),   coords,  MultDist);
        MultAround(shifted.secon(),   coords,  MultDist);
        if (DEBUG) { //TODO: нужен ли этот демаг здесь?
          push();
          strokeWeight(1);
          fill(0);
          stroke(100,250,0);
          circle(tran.copy().mult(-1).x, tran.copy().mult(-1).y, 7);
          pop();
        }
        
        PVector toA = shifted.first().copy().sub(pos);
        PVector toB = shifted.secon().copy().sub(pos);
        //TODO: переносить только половину стен
        if (PVector.angleBetween(left,  toA.copy().rotate(HALF_PI)) -0.001 > HALF_PI &&
            PVector.angleBetween(right, toA.copy().rotate(HALF_PI)) +0.001 < HALF_PI ||
            PVector.angleBetween(left,  toB.copy().rotate(HALF_PI)) -0.001 > HALF_PI &&
            PVector.angleBetween(right, toB.copy().rotate(HALF_PI)) +0.001 < HALF_PI || true) {
          cacheProto.add(shifted);
        }
      }
      chache =  cacheProto.toArray(new Visible[0]);
    } 
    //TODO: проверить баг, что в chache лежат дубликаты.
    //Возникновение: если я смотрю в портал A, то комп начинает дико лагать, а розовые линии накладываются друг на друга. Не понимаю, что происходит
    if (DEBUG) { // draw pink wall
      push();
      stroke(255,100,255,50);
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
    
    
    PVector transChar = pos.copy().add(tran); // virtaul camera base
    RotateAround(transChar,linked.coords,angle);; // virtaul camera rotate
    PVector transMultChar = MultAround(transChar.copy(),linked.coords,linked.MultDist);//TODO: убрать лишнюю переменную
    if (DEBUG) { //показать точку новой виртуальной камеры
      push();
      fill(255);
      stroke(240);
      strokeWeight(5);
      circle(transChar.x,transChar.y,1);
      circle(transMultChar.x,transMultChar.y,3);
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
            stroke(col,100);
            line(transChar.x, transChar.y, transChar.x + vectorTo.x, transChar.y + vectorTo.y);
            stroke(250,100,0);
            circle(point.x, point.y, 5);
            pop();
          }
       // }
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
    link(linked);
  }
  
}
