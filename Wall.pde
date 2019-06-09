interface Visible {
  PVector first();
  PVector secon();
  void show();
  Visible copyShift(PVector by);
  void ReLoad();
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
}
  
