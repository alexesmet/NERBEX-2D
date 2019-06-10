class Level {
  PVector[] points;
  Visible[] walls;
  Portal[]  portals;
  
  Level(String path) {
    // coordinates are INT
    // struct world from JSON file
    JSONObject level = loadJSONObject(path);
    JSONArray jPoints  = level.getJSONArray("points");
    JSONArray jWalls   = level.getJSONArray("walls");
    JSONArray jPortals = level.getJSONArray("portals");
    JSONArray jLinks = level.getJSONArray("links");
    
    points = new PVector[jPoints.size()];
    for(int i=0; i<jPoints.size(); i++ ) {
      int[] coor = jPoints.getJSONObject(i).getJSONArray("xy").getIntArray();
      points[i] = new PVector(coor[0], coor[1]);
    }
    
    walls = new Visible[jWalls.size() + jPortals.size()];
    for(int i=0; i<jWalls.size(); i++ ) {
      int[] bases = jWalls.getJSONObject(i).getJSONArray("wl").getIntArray();
      walls[i] = new Wall(points[bases[0]],points[bases[1]]);
    }
    
    portals = new Portal[jPortals.size()];
    for(int i=0; i<jPortals.size(); i++ ) {
      int[] bases = jPortals.getJSONObject(i).getJSONArray("pt").getIntArray();
      Portal toAdd = new Portal(points[bases[0]],points[bases[1]]);
      toAdd.UID = i;
      portals[i] = toAdd;       walls[i+jWalls.size()] = toAdd;
    }
    
    for(int i=0; i<jLinks.size(); i++ ) {
      int[] ids = jLinks.getJSONObject(i).getJSONArray("ln").getIntArray();
      portals[ids[0]].link(portals[ids[1]]);
    }
    
    for (Portal portal : portals) {
      portal.ReLoad();
    }
  }
  
  //Повернуть весь мир на угол angle
  //Положительный angle значит поворот по часовой стрелке
  void rotates(PVector position, float angle) {
    float normalX, normalY;
    float sinangle = sin(angle), cosangle = cos(angle);
    for (PVector point : this.points) {
      normalX = point.x - position.x;
      normalY = point.y - position.y;
      point.x = position.x + normalX * cosangle - normalY * sinangle;
      point.y = position.y + normalY * cosangle + normalX * sinangle;
    }
     
    for (Portal portal : this.portals) {
      portal.ReLoad();
    }
  }
  
  //Увеличить все расстояния на coef от точки отсчета position
  void scales(PVector position, float coef) {
    for (PVector point : this.points) {
      MultAround(point,   position,  coef);
    }
    
    for (Portal portal : this.portals) {
      portal.ReLoad();
    }
  }
   
}
