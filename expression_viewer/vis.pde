import java.util.Map;
import java.util.*;

class NodeShape {

  static final int IMAGE_INITIAL_SIZE = 100;
  static final int IMAGE_MARGIN = 5;
  static final int IMAGE_MARGIN_BOTTOM = 20;

  Node node;
  Rectangle bounds = new Rectangle(0, 0, IMAGE_INITIAL_SIZE + IMAGE_MARGIN * 2, IMAGE_INITIAL_SIZE + IMAGE_MARGIN + IMAGE_MARGIN_BOTTOM);
  boolean hovered = false;

  NodeShape(Node node) {
    this.node = node;
  }

  void setPosition(float x, float y) {
    setX(x);
    setY(y);
  }

  void setX(float x) {
    bounds.x = x;
  }

  void setY(float y) {
    bounds.y = y;
  }

  void move(float moveX, float moveY) {
    bounds.x += moveX;
    bounds.y += moveY;
  }

  void scale(float factor) {
    bounds.w *= factor;
    bounds.h *= factor;
  }

  void draw(PGraphics pg) {
    // Draw node body
    pg.noStroke();
    pg.fill(hovered ? 220 : 235);
    pg.rect(bounds.x, bounds.y, bounds.w, bounds.h);
    
    // Draw image
    float imageX = bounds.x + IMAGE_MARGIN;
    float imageY = bounds.y + IMAGE_MARGIN;
    float imageSize = bounds.w - IMAGE_MARGIN * 2;
    if (node.getOutput() != null && node.getOutput().width > 0) {
      pg.image(node.getOutput(), imageX, imageY, imageSize, imageSize);
    } else {
      pg.noFill();
      pg.stroke(150);
      pg.strokeWeight(1);
      pg.rect(imageX, imageY, imageSize, imageSize);
      pg.line(imageX, imageY, imageX + imageSize, imageY + imageSize);
      pg.line(imageX + imageSize, imageY, imageX, imageY + imageSize);
    }

    // Draw label
    float bottomMargin = bounds.h - (IMAGE_MARGIN + imageSize);
    pg.fill(50);
    pg.textSize(max(bottomMargin * 0.8, 11));
    pg.textAlign(CENTER, CENTER);
    pg.text(node.name, bounds.getCentreX(), bounds.getBottom() - bottomMargin * 0.666);
  }

  PVector getInputPoint() {
    return new PVector(bounds.getCentreX(), bounds.getBottom());
  }

  PVector getOutputPoint() {
    return new PVector(bounds.getCentreX(), bounds.y);
  }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

class TreeShape {

  static final int VER_SPACE_BETWEEN_LEVELS = NodeShape.IMAGE_INITIAL_SIZE / 3;
  static final int HOR_SPACE_BETWEEN_NODES_OF_SAME_PARENT = NodeShape.IMAGE_MARGIN * 2;
  static final int HOR_SPACE_BETWEEN_NODES_OF_DIFF_PARENT = NodeShape.IMAGE_MARGIN * 6;

  Tree tree;
  ArrayList<NodeShape> nodeShapes = new ArrayList<NodeShape>();
  HashMap<Node, NodeShape> node_obj_per_node = new HashMap<Node, NodeShape>();
  HashMap<Integer, ArrayList<NodeShape>> node_objs_per_depth = new HashMap<Integer, ArrayList<NodeShape>>();
  Rectangle bounds;

  float scale = 1;
  float scale_min = 0;
  float scale_max = 0;

  TreeShape(Tree tree) {
    setTree(tree);
  }

  TreeShape(String expression) {
    setExpression(expression);
  }

  void setExpression(String expression) {
    setTree(expression != null ? new Tree(expression) : null);
  }

  void setTree(Tree tree) {
    // Reset data
    nodeShapes.clear();
    node_obj_per_node.clear();
    node_objs_per_depth.clear();
    bounds = null;

    // Set tree
    this.tree = tree;

    // Nothing to do here if there is no tree
    if (this.tree == null) {
      return;
    }

    // Crete node objects
    ArrayList<Node> nodes = tree.root.getSubtreeNodes();
    for (Node n : nodes) {
      NodeShape ns = new NodeShape(n);
      nodeShapes.add(ns);
      node_obj_per_node.put(n, ns);
      if (!node_objs_per_depth.containsKey(n.depth)) {
        node_objs_per_depth.put(n.depth, new ArrayList<NodeShape>());
      }
      node_objs_per_depth.get(n.depth).add(ns);
    }

    // Make a first positioning of the nodes by placing them in the corresponding depth and aligning them to the left
    // For each depth level, from top to bottom
    for (Map.Entry<Integer, ArrayList<NodeShape>> e : node_objs_per_depth.entrySet()) {
      int currDepth = e.getKey();
      ArrayList<NodeShape> currDepthNodeShapes = e.getValue();
      for (int i = 0; i < currDepthNodeShapes.size(); i++) {
        NodeShape currNodeShape = currDepthNodeShapes.get(i);
        if (i == 0) {
          currNodeShape.setX(0);
          currNodeShape.setY(0 + currDepth * (currNodeShape.bounds.h + VER_SPACE_BETWEEN_LEVELS));
        } else {
          NodeShape node_obj_on_left = node_objs_per_depth.get(currDepth).get(i - 1);
          float margin_left = node_obj_on_left.node.parent == currNodeShape.node.parent ? HOR_SPACE_BETWEEN_NODES_OF_SAME_PARENT : HOR_SPACE_BETWEEN_NODES_OF_DIFF_PARENT;
          currNodeShape.setX(node_obj_on_left.bounds.x + node_obj_on_left.bounds.w + margin_left);
          currNodeShape.setY(node_obj_on_left.bounds.y);
        }
      }
    }

    // Make a second positioning of the nodes by aligning them properly with their parent nodes
    // For each depth level, from bottom to top and excluding the top (root) level
    int curr_depth = tree.numDepthLevels - 1;
    while (curr_depth > 0) {
      // While there are nodes in the current depth to position
      List<NodeShape> remaining_node_objs = new ArrayList<NodeShape>(node_objs_per_depth.get(curr_depth));
      while (remaining_node_objs.size() > 0) {
        // Get next nodes that share the same parent
        List<Node> group_nodes = remaining_node_objs.get(0).node.parent.inputs;
        List<NodeShape> group_nodes_objs = new ArrayList<NodeShape>();
        for (Node n : group_nodes) {
          group_nodes_objs.add(node_obj_per_node.get(n));
        }
        // Remove selected nodes from the list of nodes to position
        for (NodeShape ns : group_nodes_objs) {
          remaining_node_objs.remove(ns);
        }
        // Calculate horizontal centre position of the children
        float groupMinX = Float.MAX_VALUE;
        float groupMaxX = Float.MIN_VALUE;
        for (NodeShape ns : group_nodes_objs) {
          groupMinX = min(groupMinX, ns.bounds.getCentreX());
          groupMaxX = max(groupMaxX, ns.bounds.getCentreX());
        }
        float group_centre_x = (groupMinX + groupMaxX) / 2f;
        // Calculate horizontal centre position of the parent
        NodeShape parent_obj = node_obj_per_node.get(group_nodes.get(0).parent);
        float parent_centre_x = parent_obj.bounds.getCentreX();
        // Move children or parent horizontally so they become aligned by their centre
        // Select nodes to be moved
        float move_x = 0;
        List<NodeShape> node_objs_to_move;
        if (group_centre_x > parent_centre_x) {
          // Select parent node and the nodes on the right
          int index_first_parent_obj = node_objs_per_depth.get(curr_depth - 1).indexOf(parent_obj);
          node_objs_to_move = node_objs_per_depth.get(curr_depth - 1).subList(index_first_parent_obj, node_objs_per_depth.get(curr_depth - 1).size());
          // Add nodes on left if they are all terminals
          List<NodeShape> node_objs_on_left = node_objs_per_depth.get(curr_depth - 1).subList(0, index_first_parent_obj);
          boolean only_terminals_on_left = true;
          for (NodeShape ns : node_objs_on_left) {
            if (!ns.node.isTerminal()) {
              only_terminals_on_left = false;
              break;
            }
          }
          if (only_terminals_on_left) {
            node_objs_to_move.addAll(node_objs_on_left);
          } else {
            // Add nodes immediately on left that are terminals and share the same parent
            ArrayList<NodeShape> copy = new ArrayList<NodeShape>(node_objs_on_left);
            for (int i = copy.size() - 1; i >= 0; i--) {
              NodeShape ns = copy.get(i);
              if (ns.node.isTerminal() && ns.node.parent == node_objs_to_move.get(0).node.parent) {
                node_objs_to_move.add(ns);
              } else {
                break;
              }
            }
          }
          move_x = group_centre_x - parent_centre_x;
        } else {
          // Select current nodes, the nodes on the right, and all the nodes underneath
          node_objs_to_move = new ArrayList<NodeShape>();
          List<NodeShape> objs_on_right_inclusive = node_objs_per_depth.get(curr_depth).subList(node_objs_per_depth.get(curr_depth).indexOf(group_nodes_objs.get(0)), node_objs_per_depth.get(curr_depth).size());
          for (NodeShape ns : objs_on_right_inclusive) {
            for (Node n : ns.node.getSubtreeNodes()) {
              node_objs_to_move.add(node_obj_per_node.get(n));
            }
          }
          move_x = parent_centre_x - group_centre_x;
        }
        // Move selected nodes
        for (NodeShape ns : node_objs_to_move) {
          ns.move(move_x, 0);
        }
      }
      // Go to the above depth level
      curr_depth -= 1;
    }

    // Update bounds
    float left = Float.MAX_VALUE;
    float top = Float.MAX_VALUE;
    float right = Float.MIN_VALUE;
    float bottom = Float.MIN_VALUE;
    for (NodeShape ns : nodeShapes) {
      left = min(left, ns.bounds.x);
      top = min(top, ns.bounds.y);
      right = max(right, ns.bounds.getRight());
      bottom = max(bottom, ns.bounds.getBottom());
    }
    bounds = new Rectangle(left, top, right - left, bottom - top);

    resetZoom();
  }

  void draw(PGraphics pg) {
    // Draw bounds
    //pg.noFill();
    //pg.stroke(255, 255, 50);
    //pg.rect(bounds.x, bounds.y, bounds.w, bounds.h);

    // Draw connections between nodes
    pg.noFill();
    pg.stroke(0);
    pg.strokeWeight(1);
    for (NodeShape ns : nodeShapes) {
      PVector p1 = ns.getInputPoint();
      for (Node input : ns.node.inputs) {
        PVector p2 = node_obj_per_node.get(input).getOutputPoint();
        pg.bezier(p1.x, p1.y, p1.x, lerp(p1.y, p2.y, 0.75), p2.x, lerp(p1.y, p2.y, 0.25), p2.x, p2.y);
        // Draw arrow over bezier curve
        // TODO
      }
    }

    // Draw nodes
    for (NodeShape ns : nodeShapes) {
      ns.draw(pg);
    }
  }

  void onMouseMoved() {
    // Find which node is being mouse hovered
    NodeShape node_hovered_temp = null;
    for (NodeShape ns : nodeShapes) {
      if (node_hovered_temp == null && ns.bounds.contains(mouseX, mouseY)) {
        node_hovered_temp = ns;
        ns.hovered = true;
      } else {
        ns.hovered = false;
      }
    }
  }

  void setPosition(float x, float y) {
    float deltaX = x - bounds.x;
    float deltaY = y - bounds.y;
    move(deltaX, deltaY);
  }

  void move(float moveX, float moveY) {
    for (NodeShape ns : nodeShapes) {
      ns.move(moveX, moveY);
    }
    bounds.x += moveX;
    bounds.y += moveY;
  }

  void zoom(float anchorX, float anchorY, float scaleFactor) {
    // Calculate new scale value
    float new_scale = scale * scaleFactor;
    // Limit scale range
    if (scale_min != 0) {
      new_scale = max(new_scale, scale_min);
    }
    if (scale_max != 0) {
      new_scale = min(new_scale, scale_max);
    }
    // Nothing to do here if the scale value is the same
    if (new_scale == scale) {
      return;
    }
    // Nothing to do here if no tree exists (returning only here allows to change scale without a tree)
    if (tree == null) {
      return;
    }
    // Calculate new x-position based on the zoom anchor
    float anchor_x_normalised = (anchorX - bounds.x) / bounds.w;
    float new_w = bounds.w * (new_scale / scale);
    float new_x = anchorX - new_w * anchor_x_normalised;
    // Calculate new y-position based on the zoom anchor
    float anchor_y_normalised = (anchorY - bounds.y) / bounds.h;
    float new_h = bounds.h * (new_scale / scale);
    float new_y = anchorY - new_h * anchor_y_normalised;
    // Move to origin
    setPosition(0, 0);
    // Apply new scale
    setScale(new_scale);
    // Move to new position
    setPosition(new_x, new_y);
  }

  void resetZoom() {
    float margin = 0.05 * min(width, height);
    fit(new Rectangle(margin, margin, width - margin * 2, height - margin * 2));
    // Set minimum zoom of the tree to current zoom level so that it fits inside the window
    scale_min = scale;
    // Set maximum zoom of the tree so that each node is not larger than a percentage of the smaller side of the window
    scale_max = 0.333 * min(width, height) / NodeShape.IMAGE_INITIAL_SIZE;
  }

  void fit(Rectangle fitBounds) {
    // Nothing to do here if no tree exists
    if (tree == null) {
      return;
    }
    // Calculate aspect ratio of the given limits
    float limits_aspect_ratio = fitBounds.w / fitBounds.h;
    // Calculate aspect ratio of the tree
    float content_aspect_ratio = bounds.w / bounds.h;
    // Calculate factor to scale the tree up or down so that it fits inside the given limits
    float scale_factor = limits_aspect_ratio > content_aspect_ratio ? fitBounds.h / bounds.h : fitBounds.w / bounds.w;
    // Calculate new scale value
    float new_scale = scale * scale_factor;
    // Move to origin
    setPosition(0, 0);
    // Apply new scale
    setScale(new_scale);
    // Move to centre of the given limits
    setPosition(fitBounds.x + (fitBounds.w - bounds.w) / 2f, fitBounds.y + (fitBounds.h - bounds.h) / 2f);
  }

  private void setScale(float scale) {
    // Calculate multiplication factor to transform the current scale into the new one
    float scaleFactor = scale / this.scale;
    // Set new scale
    this.scale = scale;
    // Multiply all coordinates and dimensions by the factor calculated above
    for (NodeShape ns : nodeShapes) {
      ns.scale(scaleFactor);
      ns.setPosition(ns.bounds.x * scaleFactor, ns.bounds.y * scaleFactor);
    }
    bounds.w *= scaleFactor;
    bounds.h *= scaleFactor;
  }

  void useRandomImages() {
    for (Node n : tree.root.getSubtreeNodes()) {
      n.output = createRandomImage(200, 200);
    }
  }
}
