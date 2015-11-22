// Instantiate objects
Player player = new Player();
ArrayList<Asteroid> asteroids = new ArrayList<Asteroid>();
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
InputHandler input = new InputHandler();

class InputHandler {
  // List of currently held keys
  // Uses Character instead of char because generics cannot use primitives
  ArrayList<Character> heldKeys = new ArrayList<Character>();

  void keyPressed(char pressedKey) {
    // See if key already in heldKeys
    for (int i = 0; i < heldKeys.size(); i++) {
      if (heldKeys.get(i) == pressedKey) {
        return;
      }
    }
    // Add key to heldKeys
    heldKeys.add(pressedKey);
  }

  void keyReleased(char releasedKey) {
    // See if key in heldKeys
    for (int i = 0; i < heldKeys.size(); i++) {
      if (heldKeys.get(i) == releasedKey) {
        heldKeys.remove(i);
      }
    }
  }

  boolean isHeld(char heldKey) {
    for (int i = 0; i < heldKeys.size(); i++) {
      if (heldKeys.get(i) == heldKey) {
        return true;
      }
    }
    return false;
  }
}

class Point {
  float x;
  float y;
  float radius;

  // Circular collisions
  Point(float radius) {
    this.radius = radius;
  }

  boolean checkCollision(Point point) {
    float minDistance = sq(this.radius - point.radius);
    float maxDistance = sq(this.radius + point.radius);
    float distance = sq(this.x - point.x) + sq(this.y - point.y);
    return (distance >= minDistance && distance <= maxDistance);
  }
}

abstract class Drawable {
  protected float direction = 0;
  protected float x;
  protected float y;
  public ArrayList<Point> collisionShape;

  void calculateCollisions() {
    // Calculate current collisions
    for (int i = 0; i < collisionShape.size(); i++) {
      collisionShape.get(i).x = this.x;
      collisionShape.get(i).y = this.y;
    }
  }

  boolean checkCollision(Drawable other) {
    // For every circle in this object's collision shape
    for (int i = 0; i < this.collisionShape.size(); i++) {
      Point curPoint = this.collisionShape.get(i);
      // Check each circle in the other object's collision shape for collision with this circle
      for (int j = 0; j < other.collisionShape.size(); j++) {
        // If any collide, return that a collision occured
        if (curPoint.checkCollision(other.collisionShape.get(j))) {
          return true;
        }
      }
    }
    return false;
  }

  void drawStart() {
    pushMatrix();
    // Move to correct location
    translate(x, y);
    // Set rotation matrix for current object
    rotate(direction);
  }

  abstract void drawSelf();

  void drawEnd() {
    popMatrix();
  }

  void draw() {
    drawStart();
    drawSelf();
    drawEnd();
  }
}

abstract class Moveable extends Drawable {
  float speed;

  void move() {
    // Loop screen
    if (this.x > width) {
      this.x = 0;
    }
    if (this.y > height) {
      this.y = 0;
    }
    if (this.x < 0) {
      this.x = width;
    }
    if (this.y < 0) {
      this.y = height;
    }

    this.x += cos(direction)*speed;
    this.y += sin(direction)*speed;
  }
}

class Player extends Moveable {
  int lives = 3;
  float maxSpeed = 15;
  float size = 10;
  int bulletFrames = 10;
  int bulletCooldown = 0;
  int invincibleFrames = 60;
  int invincible = 0;

  Player () {
    // Generate collision shape
    collisionShape = new ArrayList<Point>();
    collisionShape.add(new Point(size));
    invincible = invincibleFrames;
  }

  void update() {
    // Collision checking
    if (invincible == 0) {
      for (int i = 0; i < asteroids.size(); i++) {
        Asteroid asteroid = asteroids.get(i);
        // If colliding, die
        if (this.checkCollision(asteroid)) {
          lives -= 1;
          this.x = width / 2;
          this.y = height / 2;
          this.direction = 0;
          this.speed = 0;
          this.bulletCooldown = 0;
          this.invincible = invincibleFrames;
          if (lives < 0) {
            exit();
          }
        }
      }
    }
    else {
      // Countdown
      invincible -= 1;
    }
    // Bullet colldown
    if (bulletCooldown > 0) {
      bulletCooldown -= 1;
    }
    // Handle input
    if (input.isHeld('a')) {
      player.incrementDirection(.04);
    }
    if (input.isHeld('d')) {
      player.incrementDirection(-.04);
    }
    if (input.isHeld('w')) {
      player.incrementSpeed(.04);
    }
    if (input.isHeld('s')) {
      player.incrementSpeed(-.08);
    }
    if (input.isHeld(' ')) {
      // Fire bullet
      if (bulletCooldown == 0) {
        Bullet bullet = new Bullet(this.x, this.y, this.direction);
        bullet.speed += this.speed;
        bullets.add(bullet);
        bulletCooldown = bulletFrames;
      }
    }

    // Move player
    move();
  }

  void drawSelf() {
    // Coordinates of points to draw
    triangle(-size, -size, -size, size, size, 0);
  }

  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void move(float x, float y) {
    this.x += x;
    this.y += y;
  }

  void setDirection(float rad) {
    this.direction = rad;
  }

  void incrementDirection(float rad) {
    this.direction += rad;
  }

  void setSpeed(float speed) {
    this.speed = speed;
  }

  void incrementSpeed(float accel) {
    this.speed += accel;
    if (this.speed > maxSpeed) {
      this.speed = maxSpeed;
    }
    if (this.speed < 0) {
      this.speed = 0;
    }
  }

  void accelerate(float accel) {
    if (this.speed < .1) {
      this.speed = .1;
    }
    else {
      this.speed *= accel;
    }
  }

  void slow(float decel) {
    this.speed *= 1-decel;
  }
}

class Bullet extends Moveable {
  int framesAlive = 60;
  float size = 5;

  Bullet(float x, float y, float dir) {
    this.x = x;
    this.y = y;
    this.direction = dir;
    this.speed = 20;

    // Generate collision shape
    collisionShape = new ArrayList<Point>();
    collisionShape.add(new Point(size));
  }

  void update() {
    this.framesAlive -= 1;
    if (this.framesAlive == 0) {
      // Kill it and let it get garbage collected
      bullets.remove(this);
      return;
    }
    move();
  }

  void drawSelf() {
    ellipse(0, 0, size, size);
  }
}

class Asteroid extends Moveable {
  int size;
  int baseSize = 15;

  Asteroid(float x, float y, int size, float dir, float speed) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.direction = dir;
    this.speed = speed;

    // Generate collision shape
    collisionShape = new ArrayList<Point>();
    collisionShape.add(new Point(baseSize*size));
  }

  void update() {
    // Collision checking
    for (int i = 0; i < bullets.size(); i++) {
      Bullet bullet = bullets.get(i);
      // If colliding, die
      if (this.checkCollision(bullet)) {
        this.explode();
        bullets.remove(bullet);
      }
    }
    move();
  }

  void drawSelf() {
    ellipse(0, 0, baseSize*size, baseSize*size);
  }

  void explode() {
    // Break up
    if (size > 1) {
      asteroids.add(new Asteroid(this.x, this.y, this.size - 1, this.direction + PI/6, this.speed));
      asteroids.add(new Asteroid(this.x, this.y, this.size - 1, this.direction - PI/6, this.speed));
    }
    asteroids.remove(this);
  }
}

void setup() {
  size(1024, 768);

  player.setPosition(width/2, height/2);
  player.direction = HALF_PI;
  for (int i = 0; i < random(10, 15); i++) {
    asteroids.add(new Asteroid(random(width), random(height), int(random(1, 5)), random(2*PI), random(1, 3)));
  }
}

void draw() {
  update();
  clear();
  // Flip y coordinate scale (so 0 is at the bottom)
  scale(1, -1);
  translate(0, -height);
  player.draw();
  for (int i = 0; i < bullets.size(); i++) {
    bullets.get(i).draw();
  }
  for (int i = 0; i < asteroids.size(); i++) {
    asteroids.get(i).draw();
  }
}

void update() {
  // Check if the player has won
  if (asteroids.size() < 1) {
    exit();
  }
  // Calculate all collision boxes
  player.calculateCollisions();
  for (int i = 0; i < bullets.size(); i++) {
    bullets.get(i).calculateCollisions();
  }
  for (int i = 0; i < asteroids.size(); i++) {
    asteroids.get(i).calculateCollisions();
  }
  // Update logic
  player.update();
  for (int i = 0; i < bullets.size(); i++) {
    bullets.get(i).update();
  }
  for (int i = 0; i < asteroids.size(); i++) {
    asteroids.get(i).update();
  }
}

void keyPressed() {
  input.keyPressed(key);
}

void keyReleased() {
  input.keyReleased(key);
}
