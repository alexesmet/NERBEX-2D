class Ray {
  PVector pos;
  PVector dir; // local
  
  Ray(PVector pos, PVector dir) {
    this.pos = pos;
    this.dir = dir;
  }
  
  void show() {
    push();
    stroke(255,100);
    strokeWeight(1);
    line(pos.x,pos.y, pos.x+dir.x*10, pos.y+dir.y*10);
    pop();
  }
 
 
  
  //Найти точку пересечения луча со стеной,
  //Если есть, то вернуть точку пересечения
  //Иначе вернуть null
  PVector cast(Visible wall) {
    
    float x1 = wall.first().x;
    float y1 = wall.first().y;
    float x2 = wall.secon().x;
    float y2 = wall.secon().y;
    
    float x3 = this.pos.x;
    float y3 = this.pos.y;
    float x4 = this.pos.x + this.dir.x;
    float y4 = this.pos.y + this.dir.y;
    
    float den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (den == 0) {
      return null;
    }
 
    float t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den;
    float u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / den;
    if (t > 0 && t < 1 && u > 0) {
      return new PVector(x1 + t * (x2 - x1), y1 + t * (y2 - y1));
    } else {
      return null;
    }
  }
}
