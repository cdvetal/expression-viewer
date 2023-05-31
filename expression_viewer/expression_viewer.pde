import java.nio.file.Files;

String expression = "sub(z,div(mul(y,mul(scalar(0.7433),sub(x,y))),sub(cos(y),x)))";
File fileWithExpression = null;
File fileWithGPEngineOrder = null;
File fileWithGPEngineFeedback = null;
File folderWithGPEngineImages = null;
int imageSize = 128;

Tree tree;
TreeShape treeShape;
int prevWidth;
int prevHeight;
long expressionFileLastChecked = -1;
long nodesWithoutImagesLastChecked = -1;
boolean waitingForImages = false;
RandomString randomString = new RandomString(4);

void settings() {
  size(int(displayWidth * 0.8), int(displayHeight * 0.8));
  smooth(8);
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(60);
  surface.setResizable(true);
  createExitHandler();

  if (fileWithExpression == null) {
    fileWithExpression = new File(dataPath("expression.txt"));
  }
  if (fileWithGPEngineOrder == null) {
    fileWithGPEngineOrder = new File(dataPath("gp_engine_order.txt"));
  }
  if (fileWithGPEngineFeedback == null) {
    fileWithGPEngineFeedback = new File(dataPath("gp_engine_feedback.txt"));
  }
  if (folderWithGPEngineImages == null) {
    folderWithGPEngineImages = new File(dataPath("gp_engine_images"));
  }

  assert !fileWithGPEngineOrder.exists();
  assert !fileWithGPEngineFeedback.exists();
  assert !folderWithGPEngineImages.exists();
  println("Watching expression at: " + fileWithExpression.getPath());

  tree = new Tree(expression);
  //println(tree.getCascadeString());
  treeShape = new TreeShape(tree);
  //treeShape.useRandomImages();
}

void draw() {
  if (width != prevWidth || height != prevHeight) {
    prevWidth = width;
    prevHeight = height;
    onResize();
  }
  watchInputExpressionFile();
  orderImages();

  background(255);
  treeShape.draw(getGraphics());

  if (waitingForImages) {
    displayMessageWaiting();
    searchForImages();
  }
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

void keyReleased() {
  if (key == 'e') {
    launch(fileWithExpression.getPath());
  }
}

void onResize() {
  treeShape.resetZoom();
}

void createExitHandler() {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run() {
      if (fileWithGPEngineOrder.exists()) {
        fileWithGPEngineOrder.delete();
      }
      if (fileWithGPEngineFeedback.exists()) {
        fileWithGPEngineFeedback.delete();
      }
    }
  }
  ));
}

void displayMessageWaiting() {
  float messageHeight = 15;
  color messageColour = color(100);
  pushMatrix();
  translate(30, height - 30);
  pushMatrix();
  rotate(millis() / 200f);
  noFill();
  strokeWeight(1);
  stroke(messageColour);
  arc(0, 0, messageHeight, messageHeight, 0, PI);
  popMatrix();
  fill(messageColour);
  textSize(messageHeight * 0.9);
  textAlign(LEFT, CENTER);
  text("Waiting for images", messageHeight * 1.2, -messageHeight * 0.2);
  popMatrix();
}

void watchInputExpressionFile() {
  if (System.currentTimeMillis() - expressionFileLastChecked > 1000) {
    expressionFileLastChecked = System.currentTimeMillis();
  } else {
    return;
  }

  // Create input expression file if it does not exist
  if (!fileWithExpression.exists()) {
    try {
      fileWithExpression.createNewFile();
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return;
  }

  String text = null;
  try {
    text =  new String(Files.readAllBytes(fileWithExpression.toPath()));
    text = text.replaceAll("\\s+", "");
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  if (text == null || text.isEmpty() || text.equals(expression)) {
    return;
  }
  expression = text;

  // Create tree from the loaded expression
  Tree newTree = null;
  try {
    newTree = new Tree(expression);
  }
  catch (Exception | AssertionError e) {
    println("Unable to create tree from expression: " + expression);
    if (e.getMessage() != null) {
      println("Error: " + e.getMessage());
    }
  }

  // Update visualisation
  if (newTree != null) {
    treeShape.setTree(newTree);
  }

  orderImages();
}


void orderImages() {
  if (waitingForImages || fileWithGPEngineOrder.exists()) {
    return;
  }
  
  if (System.currentTimeMillis() - nodesWithoutImagesLastChecked > 5000) {
    nodesWithoutImagesLastChecked = System.currentTimeMillis();
  } else {
    return;
  }
  
  println("Checking nodes");
  
  ArrayList<Node> nodes = tree.root.getSubtreeNodes();
  ArrayList<String> subexpressions = new ArrayList<String>();
  ArrayList<String> tickets = new ArrayList<String>();
  for (Node n : nodes) {
    if (n.getImage() == null) {
      String subexpression = n.getString();
      if (!subexpressions.contains(subexpression)) {
        subexpressions.add(subexpression);
        String ticket = randomString.nextString();
        tickets.add(ticket);
        n.ticket = ticket;
      } else {
        String ticket = tickets.get(subexpressions.indexOf(subexpression));
        n.ticket = ticket;
      }
    }
  }
  
  if (subexpressions.isEmpty()) {
    return;
  }
  
  ArrayList<String> outputLines = new ArrayList<String>();
  outputLines.add("#image_size," + imageSize);
  outputLines.add("#path_dir_images," + folderWithGPEngineImages.getPath());
  outputLines.add("#path_file_feedback," + fileWithGPEngineFeedback.getPath());
  for (int i = 0; i < subexpressions.size(); i++) {
    outputLines.add(tickets.get(i) + ",\"" + subexpressions.get(i) + "\"");
  }
  String[] outputLinesArray = (String[]) outputLines.toArray(new String[0]);
  saveStrings(fileWithGPEngineOrder.getPath(), outputLinesArray);

  waitingForImages = true;
}


void searchForImages() {
  if (!fileWithGPEngineFeedback.exists()) {
    return;
  }

  String[] feedbackLines = loadStrings(fileWithGPEngineFeedback.getPath());
  if (feedbackLines.length > 0) {
    println(feedbackLines);
  }

  if (folderWithGPEngineImages.exists() && folderWithGPEngineImages.isDirectory()) {
    ArrayList<Node> nodes = tree.root.getSubtreeNodes();
    for (File f : folderWithGPEngineImages.listFiles()) {
      if (f.getName().endsWith(".png")) {
        String filename = f.getName().split("\\.")[0];
        for (Node n : nodes) {
          if (n.ticket != null && n.ticket.equals(filename)) {
            n.image = loadImage(f.getPath());
            n.ticket = null;
            break;
          }
        }
      }
    }
  }

  // Delete feedback file
  fileWithGPEngineFeedback.delete();

  waitingForImages = false;
}
