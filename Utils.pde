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

// changes player movement, returns how the world should rotate.
float mouseMove(PVector movement, boolean mousePress) {
  if (mousePress) {
    float speed = map(mouseY-height/2, -height/SPEED_RADIUS/2, +height/SPEED_RADIUS/2, -SPEED, +SPEED) ;
    movement.set(0, speed).limit(SPEED);  
    return map(mouseX-width/2, -width/2, width/2, +0.1, -0.1);
  } else
    movement.mult(0.65);
  return 0;
}


void swap(PVector a, PVector b) {
  PVector buf = b.copy();
  b = a.copy();
  a = buf;
}
