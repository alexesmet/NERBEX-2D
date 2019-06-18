abstract class Visible {
  abstract PVector first(); //Первая точка
  abstract PVector secon(); //Вторая точка
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
    
    PVector a = first().copy();
    PVector b = secon().copy();
    PVector c = point1.copy();
    PVector d = point2.copy();
    
    float EPS =1E-4;
    float amin = min(a.x,b.x);
    float amax = max(a.x,b.x);
    float bmin = min(c.x,d.x);
    float bmax = max(c.x,d.x);
    if (max(amin,bmin) > min(amax,bmax) + EPS) return null;
    amin = min(a.y,b.y);
    amax = max(a.y,b.y);
    bmin = min(c.y,d.y);
    bmax = max(c.y,d.y);
    if (max(amin,bmin) > min(amax,bmax) + EPS) return null;
    
    float ma = a.y - b.y;
    float mb = b.x - a.x;
    float mc = -ma * a.x - mb * a.y;
    float z = sqrt(ma*ma + mb*mb);
    if (z > EPS) {
      ma /= z;
      mb /= z;
      mc /= z;
    }  
    float na = c.y - d.y;
    float nb = d.x - c.x;
    float nc = -na * c.x - nb * c.y;
    z = sqrt(na*na + nb*nb);
    if (z > EPS) {
      na /= z;
      nb /= z;
      nc /= z;
    } 
    
    float zn = ma*nb - mb*na;
    PVector ans1 = new PVector(0,0);
    PVector ans2 = new PVector(0,0);
    if (abs (zn) < EPS) {
      if (abs (ma * c.x + mb * c.y + mc) > EPS || abs (na * a.x + nb * a.y + nc) > EPS) return null;
      
      if (b.x < a.x-EPS || abs(b.x-a.x) < EPS && b.y < a.y - EPS) swap(b,a);
      if (d.x < c.x-EPS || abs(d.x-c.x) < EPS && d.y < c.y - EPS) swap(d,c);
      if (a.x < c.x-EPS || abs(a.x-c.x) < EPS && a.y < c.y - EPS) ans1 = c;
      else ans1 = a;
      if (b.x < d.x-EPS || abs(b.x-d.x) < EPS && b.y < d.y - EPS) ans2 = b;
      else ans2 = d;
      return ans1;
    }
    else {
      ans1.x = ans2.x = - (mc*nb - mb*nc) / zn;
      ans1.y = ans2.y = - (ma*nc - mc*na) / zn;
      if ( (min(a.x,b.x) <= ans1.x + EPS && ans1.x <= max(a.x,b.x) + EPS) 
         &&(min(a.y,b.y) <= ans1.y + EPS && ans1.y <= max(a.y,b.y) + EPS) 
         &&(min(c.x,d.x) <= ans1.x + EPS && ans1.x <= max(c.x,d.x) + EPS) 
         &&(min(c.y,d.y) <= ans1.y + EPS && ans1.y <= max(c.y,d.y) + EPS)) return ans1;
      else return null;
        
    }    
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
