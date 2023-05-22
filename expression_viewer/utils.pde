PImage createRandomImage(int w, int h) {
  int pd = pixelDensity;
  pixelDensity = 1;

  float noiseIncrement = w / 10000f;
  noiseDetail(8, 0.1);
  PGraphics image = createGraphics(w, h);
  image.beginDraw();
  image.loadPixels();
  float xoffR = random(999);
  float xoffG = random(999);
  float xoffB = random(999);
  for (int x = 0; x < image.width; x++) {
    xoffR += noiseIncrement;
    xoffG += noiseIncrement;
    xoffB += noiseIncrement;
    float yoff = 0;
    for (int y = 0; y < image.height; y++) {
      yoff += noiseIncrement;
      float r = min(noise(xoffR, yoff) * 255 * 2, 255);
      float g = min(noise(xoffG, yoff) * 255 * 2, 255);
      float b = min(noise(xoffB, yoff) * 255 * 2, 255);
      image.pixels[x + y * image.width] = color(r, g, b);
    }
  }
  image.updatePixels();
  image.endDraw();
  pixelDensity = pd;
  return image;
}


class Rectangle {

  float x = 0;
  float y = 0;
  float w = 0;
  float h = 0;

  Rectangle() {
  }

  Rectangle(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  float getRight() {
    return x + w;
  }

  float getBottom() {
    return y + h;
  }

  float getCentreX() {
    return x + w / 2;
  }

  float getCentreY() {
    return y + h / 2;
  }

  boolean contains(float x, float y) {
    return x >= this.x && x < this.x + w && y >= this.y && y < this.y + h;
  }

  boolean intersects(Rectangle other) {
    return x < other.getRight() && getRight() > other.x && y > other.getBottom() && getBottom() < other.y;
  }
}

import java.util.*;
import java.io.*;

public abstract class FileWatcher extends TimerTask {
  private long timeStamp;
  private File file;

  public FileWatcher(File file) {
    this.file = file;
    this.timeStamp = file.lastModified();
  }

  public final void run() {
    long timeStamp = file.lastModified();
    if (this.timeStamp != timeStamp) {
      this.timeStamp = timeStamp;
      onChange(file);
    }
  }

  protected abstract void onChange(File file);
}
