interface Visible {
  PVector first();
  PVector secon();
  void show();
  Visible copyShift(PVector by);
  void ReLoad();
  float distance(PVector point);
  PVector intersection(PVector point1, PVector point2);
  PVector projection(PVector point);
}

class Wall implements Visible {
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
  
  float distance(PVector point) {
    //TODO: Желательно в новый класс Solid или впихнуть в интерфейс Visible
    float x0 = a.x, x1 = b.x;
    float y0 = a.y, y1 = b.y;
    float x2 = point.x, y2 = point.y;
    return abs( (y1 - y0)*x2 - (x1 - x0)*y2 + x1*y0 - y1*x0 )/ (a.copy().sub(b).mag());
  }
  
  PVector intersection(PVector point1, PVector point2) {
    //TODO: Желательно в новый класс Solid или впихнуть в интерфейс Visible
    float x0 = a.x, y0 = a.y;
    float x1 = b.x, y1 = b.y;
    float x2 = point1.x, y2 = point1.y;
    float x3 = point2.x, y3 = point2.y;
    float x,y;
    float dx0 = x0 - x1, dy0 = y0 - y1;
    float dx1 = x2 - x3, dy1 = y2 - y3;
    float del = dx0*dy1 - dx1*dy0;
    if (abs(del) < 0.0001) return null;
    float xy0 = x0*y1 - y0*x1;
    float xy1 = x2*y3 - y2*x3;
    
    x = (xy0 * dx1 - xy1 * dx0) / del;
    y = (xy0 * dy1 - xy1 * dy0) / del;
    
    if ( (x < min(x0,x1)) || (x > max(x0,x1)) || (y < min(y0,y1)) || (y > max(y0,y1)) || 
         (x < min(x2,x3)) || (x > max(x2,x3)) || (y < min(y2,y3)) || (y > max(y2,y3))    ) return null;
    return new PVector(x, y);
    
  }
  
  PVector projection(PVector point) {
    //TODO: Желательно в новый класс Solid или впихнуть в интерфейс Visible
    float x0 = a.x, y0 = a.y;
    float x1 = b.x, y1 = b.y;
    float x2 = point.x, y2 = point.y;
    float x,y;
    
    if (abs(x0 - x1) < 0.01) {
      x = x0;
      y = y2;
    }
    else if (abs(y0 - y1) < 0.01) {
      x = x2;
      y = y0;
    }
    else {
      x = ( x0*pow(y1-y2,2) + x2* pow(x1-x0,2) + (x1 - x0)*(y1 - y0)*(y2 - y0) )/ ( pow(y1-y0,2) + pow(x1 - x0,2));
      y = (x1-x0)*(x2 - x)/(y1-y0)+y2;
    }
    if ( (x < min(x0,x1)) || (x > max(x0,x1)) || (y < min(y0,y1)) || (y > max(y0,y1))) return null;
    return new PVector(x, y);
  }
  
}
