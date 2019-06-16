abstract class Visible {
  abstract PVector first(); //Первая точка
  abstract PVector secon(); //Вторая точка
  float coef() {
    return (secon().y - first().y) / (secon().x - first().x);
  }
  abstract void show();
  abstract Visible copyShift(PVector by);
  abstract void ReLoad();
  //Найти расстояние от point до линии (first(), secon())  
  float distance(PVector point) {
    return abs( (secon().y - first().y)*point.x - (secon().x - first().x)*point.y + secon().x*first().y - secon().y*first().x )/ (first().copy().sub(secon()).mag());
  }
  //Найти пересечние отрезков (first(), secon()) и (point1, point2)
  //Если пересечения нет -> вернуть null
  //Если перечение есть  -> вернуть точку перечения
  PVector intersection(PVector point1, PVector point2) {
    PVector a1 = new PVector(0,0), a2 = new PVector(0,0);
    if (intersect(first().copy(),secon().copy(),point1.copy(),point2.copy(),a1,a2)) {
      PVector ret = new PVector(a1.x,a1.y);
      return ret;
    }
    return null;
  }
  //Найти проекция точки point на линию (first(), secon())
  //Если border == true  -> проверить, лежит ли проекция на отрезке, если да, то вернуть точку, иначе вернуть null
  //Если border == false -> вернуть проекцию на линии
  PVector projection(PVector point, boolean border) {
    float x0 = first().x, y0 = first().y;
    float x1 = secon().x, y1 = secon().y;
    float x2 = point.x, y2 = point.y;
    float x,y;
    
    if (abs(x0 - x1) < 0.1) {
      x = x0;
      y = y2;
    }
    else if (abs(y0 - y1) < 0.1) {
      x = x2;
      y = y0;
    }
    else {
      float dx = x1 - x0;
      float dy = y1 - y0;
      x = (x2 * dx*dx  + dx*dy*(y2-y0) + x0*dy*dy)/(dx*dx + dy*dy);
      y = y2 - (dx/dy)*(x - x2);
      
    }
    if (border) if ( (x < min(x0,x1)) || (x > max(x0,x1)) || (y < min(y0,y1)) || (y > max(y0,y1))) return null;
    return new PVector(x, y);
  }
  
  //Возвращает true, если было событие колижена
  abstract boolean collision(PVector pos, PVector mov);
}

//Очень интересный скомунижжженый код с интернетов
//TODO: перевести на человеческий
//---------------------------------------------------------------------------------------------------

float EPS =1E-4;

//No My Function 0
boolean speccheck(PVector a, PVector b) {
  if (a.x < b.x-EPS || abs(a.x-b.x) < EPS && a.y < b.y - EPS) return true;
  return false;
}
//No My class 0
class myline {
  float a, b, c;
  myline() {}
  myline (PVector p, PVector q) {
    a = p.y - q.y;
    b = q.x - p.x;
    c = - a * p.x - b * p.y;
    float z = sqrt (a*a + b*b);
    if (abs(z) > EPS) {
      a /= z;
      b /= z;
      c /= z;
    }
  } 
  float mydist(PVector p) {
    return a * p.x + b * p.y + c;
  }
};
//determinant
float det(float a, float b, float c, float d) {
  return a*d - b*c;
}
//No My Function 2
boolean betw (float l, float r, float x) {
  return min(l,r) <= x + EPS && x <= max(l,r) + EPS;
}
//No My Function 3
boolean intersect_1d (float a, float b, float c, float d) {
  if (a > b)  {
    float buf = a;
    a = b;
    b = buf;
  }
  if (c > d)  {
    float buf = c;
    c = d;
    d = buf;
  };
  return max (a, c) <= min (b, d) + EPS;
}

//No My Function 4 intersect
//TODO: используя правило "замени термин его значением" убрать все дополнительнные классы, засунув всё в intersect
boolean intersect (PVector a, PVector b, PVector c, PVector d, PVector left, PVector right) {
  if (! intersect_1d (a.x, b.x, c.x, d.x) || ! intersect_1d (a.y, b.y, c.y, d.y)) {
    return false;
  }
  myline m = new myline(a, b);
  myline n = new myline(c, d);
  float zn = det (m.a, m.b, n.a, n.b);
  if (abs (zn) < EPS) {
    if (abs (m.mydist (c)) > EPS || abs (n.mydist (a)) > EPS)
      return false;
    if (speccheck(b,a)) swap(b,a);
    if (speccheck(d,c)) swap(d,c);
    
    if (speccheck(a,c)) left = c;
    else left = a;
    if (speccheck(b,d)) right = b;
    else right = d;
    return true;
  }
  else {
    left.x = right.x = - det (m.c, m.b, n.c, n.b) / zn;
    left.y = right.y = - det (m.a, m.c, n.a, n.c) / zn;
    return betw (a.x, b.x, left.x)
      && betw (a.y, b.y, left.y)
      && betw (c.x, d.x, left.x)
      && betw (c.y, d.y, left.y);
  }
}

//---------------------------------------------------------------------------------------------------

class Wall extends Visible {
  PVector a, b;
  
  Wall(PVector u, PVector v) {
    a = u;
    b = v;
  }
  
  Visible copyShift(PVector by) {
    return new Wall(a.copy().add(by), b.copy().add(by));
  }
  
  void show() {
    push();
    stroke(255);
    strokeWeight(2);
    line(a.x,a.y,b.x,b.y);
    pop();
  }
  
  PVector first() {
    return a;
  }
  
  PVector secon() {
    return b;
  }
  
  void ReLoad() {
   //Why should I do a long reflection-based check if I can call an empty function?..
  }
  
  boolean collision(PVector pos, PVector mov) {
    PVector aft = pos.copy().add(mov);
    if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_PROJECTION) {
      PVector proj = this.projection(pos, true);
      if (proj != null) {
        circle(proj.x, proj.y, 3);
      }
    }
    
    Wall virt_wall = new Wall(a.copy(), b.copy()); //Виртуальная стена колижена
    PVector normile = virt_wall.projection(pos, false); //Если игрок в принципе может коснуться некоторой стены, то мы будем рабоать с этой стеной
    if (normile != null) { //Если проекция есть, то игрок может коснуться стены
      if (virt_wall.intersection(aft,pos) != null) {//Если было перечение виртуальной стены и линии движения игрока, то начать колижен
        if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_INTERSECTION) {
          PVector posd = virt_wall.intersection(aft,pos);
          push();
          stroke(255,0,0,255);
          circle(posd.x, posd.y, 2);
          pop();
          
        }
        normile = pos.copy().sub(normile).normalize().mult(COLLISION_DISTANCE);//Определим, в каком направлении виртаульная стена
        //И сдвинем её туда
        virt_wall.a.add(normile);
        virt_wall.b.add(normile);
        
        if (DEBUG && DEBUG_COLLISON && DEBUG_COLLISON_VIRTUAL) line(virt_wall.a.x, virt_wall.a.y, virt_wall.b.x, virt_wall.b.y);
        pos.set(virt_wall.projection(pos,false));
        aft = virt_wall.projection(aft,false);
        mov.set(aft.copy().sub(pos));
        return true;
      }    
      
    }
    return false;
  }
  
}
