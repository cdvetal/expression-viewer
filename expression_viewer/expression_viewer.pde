import java.nio.file.Files;

String defaultExpression = "sub(z,div(mul(y,mul(scalar(0.7433),sub(x,y))),sub(cos(y),x)))";
File expressionFile = null;

Tree tree;
TreeShape treeShape;
int prevWidth;
int prevHeight;

long expressionFileLastChecked = -1;
String loadedExpression = null;

void settings() {
  size(int(displayWidth * 0.8), int(displayHeight * 0.8));
  smooth(8);
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(60);
  surface.setResizable(true);
  createExitHandler();
  
  tree = new Tree(defaultExpression);
  //println(tree.getCascadeString());
  treeShape = new TreeShape(tree);
  treeShape.useRandomImages();
  
  if (expressionFile == null) {
    expressionFile = new File(sketchPath("expression.txt"));
  }
  watchInputExpressionFile();
  
  println("Watching expression at: " + expressionFile.getPath());
}

void draw() {
  if (width != prevWidth || height != prevHeight) {
    prevWidth = width;
    prevHeight = height;
    onResize();
  }
  watchInputExpressionFile();
  background(255);
  treeShape.draw(getGraphics());
}

void mouseMoved() {
  treeShape.onMouseMoved();
}

void mouseDragged() {
  treeShape.move(mouseX - pmouseX, mouseY - pmouseY);
}

void mouseWheel(MouseEvent event) {
  if (event.getCount() != 0) {
    treeShape.zoom(mouseX, mouseY, event.getCount() < 0 ? 1.01 : 1 / 1.01);
  }
}

void keyPressed() {
  if (key == ESC) {
    key = 0;
  }
}

void onResize() {
  treeShape.resetZoom();
}

void createExitHandler() {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run() {
      // TODO
    }
  }
  ));
}

void watchInputExpressionFile() {
  // Create input expression file if it does not exist
  if (!expressionFile.exists()) {
    try {
      expressionFile.createNewFile();
    }
    catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  // Load expression file with a certain frequency
  if (System.currentTimeMillis() - expressionFileLastChecked > 1000) {
    expressionFileLastChecked = System.currentTimeMillis();
  } else {
    return;
  }
  String text = null;
  try {
    text =  new String(Files.readAllBytes(expressionFile.toPath()));
    text = text.replaceAll("\\s+", "");
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  if (text == null || text.isEmpty() || text.equals(loadedExpression)) {
    return;
  }
  loadedExpression = text;
  
  // Create tree from the loaded expression
  Tree newTree = null;
  try {
    newTree = new Tree(loadedExpression);
  }
  catch (Exception | AssertionError e) {
    println("Unable to create tree from expression: " + loadedExpression);
    if (e.getMessage() != null) {
      println("Error: " + e.getMessage());
    }
  }
  
  // Update visualisation
  if (newTree != null) {
    treeShape.setTree(newTree);
  }
}
