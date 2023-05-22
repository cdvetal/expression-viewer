class Node {

  Tree tree;
  Node parent;
  String name;
  int depth;
  ArrayList<Node> inputs = new ArrayList<Node>();
  PImage image = null;
  String ticket = null;
  
  Node(Tree tree, String name, int depth, Node parent) {
    this.tree = tree;
    this.name = name;
    this.depth = depth;
    this.parent = parent;
    if (this.name.contains(".")) {
      assert nameIsNumber():
      "Node name contains a point but does not represent a number";
    }
  }

  void addInput(Node input) {
    // Add input node to this node
    assert !isConstant():
    "You can not add inputs to a node that stores a number";
    inputs.add(input);
    input.parent = this;
  }

  boolean isFunction() {
    // Return True if this node is a function (contains inputs), False otherwise.
    return getNumInputs() > 0;
  }

  boolean isTerminal() {
    // Return True if this node is a terminal (contains no inputs), False otherwise.
    return !isFunction();
  }

  boolean isArgument() {
    // Return True if this node is a terminal and stores an argument (not a constant), False otherwise.
    return isTerminal() && !nameIsNumber();
  }

  boolean isConstant() {
    // Return True if this node is a terminal and stores a number, False otherwise.
    return isTerminal() && nameIsNumber();
  }

  int getNumInputs() {
    // Get number of inputs.
    return inputs.size();
  }
  
  PImage getImage() {
    // Get the output image of this node.
    return image;
  }

  ArrayList<Node> getSubtreeNodes() {
    // Get list of nodes containing this node and all descendant nodes.
    ArrayList<Node> nodes = new ArrayList<Node>();
    recursivellyGetSubtreeNodes(nodes);
    return nodes;
  }

  private void recursivellyGetSubtreeNodes(ArrayList<Node> nodesList) {
    // Get list of nodes containing this node and all descendant nodes.
    // The returned list is 1D and the order of the nodes is determined by the tree cascade structure from top to bottom.
    // The only argument of this function is a list used to store all descendant nodes during the recursive call of this function.
    nodesList.add(this);
    if (isFunction()) {
      for (Node n : inputs) {
        n.recursivellyGetSubtreeNodes(nodesList);
      }
    }
  }

  String getString() {
    // Get expression string of the (sub)tree whose root is this node.
    // If this node is a terminal, the returned string is simply its name.
    String output = name;
    if (isFunction()) {
      output += "(";
      for (int i = 0; i < inputs.size(); i++) {
        output += inputs.get(i).getString();
        if (i < inputs.size() - 1) {
          output += ",";
        }
      }
      output += ")";
    }
    return output;
  }

  String getSyntax() {
    // Get string with the syntax of this node.
    // If this node is a terminal, the returned string is simply its name.
    String letters = "abcdefghijklmnopqrstuvwxyz";
    String output = name;
    if (isFunction()) {
      output += "(";
      for (int i = 0; i < inputs.size(); i++) {
        output += letters.charAt(i % letters.length());
        if (i < inputs.size() - 1) {
          output += ",";
        }
      }
      output += ")";
    }
    return output;
  }

  private boolean nameIsNumber() {
    // Return True if the name of this node is a number, False otherwise.
    try {
      Float.parseFloat(name);
      return true;
    }
    catch(NumberFormatException e) {
      return false;
    }
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

class Tree {

  String expression;
  Node root;
  int numDepthLevels;

  Tree(String expression) {
    this.expression = expression;

    // Clean expression
    this.expression = expression.replaceAll("\\s+", "");

    // Check the validity of the expression
    assert this.expression.length() > 0; // Check minimum length

    // Check valid characters
    assert this.expression.matches("^[a-zA-Z0-9(),._-]+$");

    // Check that the number of opening and closing parentheses are equal
    int openParentheses = 0;
    int closeParentheses = 0;
    for (int i = 0; i < this.expression.length(); i++) {
      if (this.expression.charAt(i) == '(') {
        openParentheses++;
      } else if (this.expression.charAt(i) == ')') {
        closeParentheses++;
      }
    }
    assert openParentheses == closeParentheses;

    // Check common errors
    assert "(),".indexOf(this.expression.charAt(0)) == -1;
    assert !this.expression.startsWith(")");
    assert !this.expression.startsWith(",");
    assert !this.expression.endsWith("(");
    assert !this.expression.endsWith(",");
    assert !this.expression.contains(")(");
    assert !this.expression.contains("()");
    assert !this.expression.contains("((");
    assert !this.expression.contains("(,");
    assert !this.expression.contains(",)");
    assert !this.expression.contains(",(");
    assert !this.expression.contains(",,");

    // Convert the expression into a list of nodes arranged in a cascade
    ArrayList<String> nodes_names = new ArrayList<String>();
    ArrayList<Integer> nodes_depths = new ArrayList<Integer>();
    int curr_node_depth = 0;
    String curr_node_name = "" + this.expression.charAt(0);
    for (int i = 1; i < this.expression.length(); i++) {
      char c = this.expression.charAt(i);
      if ("(),".indexOf(c) > -1) {
        if (curr_node_name.length() > 0) {
          nodes_names.add(curr_node_name);
          nodes_depths.add(curr_node_depth);
          curr_node_name = "";
        }
        if (c == '(') {
          curr_node_depth += 1;
        } else if (c == ')') {
          curr_node_depth -= 1;
        }
      } else {
        curr_node_name += c;
      }
    }
    if (curr_node_name.length() > 0) {
      nodes_names.add(curr_node_name);
      nodes_depths.add(curr_node_depth);
    }

    // Convert the nodes arranged in a cascade into a tree
    root = new Node(this, nodes_names.get(0), nodes_depths.get(0), null);
    Node last_node = root;
    for (int i = 1; i < nodes_names.size(); i++) {
      Node new_node = new Node(this, nodes_names.get(i), nodes_depths.get(i), null);
      if (new_node.depth == last_node.depth) {
        last_node.parent.addInput(new_node);
      } else if (new_node.depth > last_node.depth) {
        last_node.addInput(new_node);
      } else {
        Node target_parent = last_node.parent;
        while (target_parent.depth >= new_node.depth) {
          target_parent = target_parent.parent;
        }
        target_parent.addInput(new_node);
      }
      last_node = new_node;
    }

    // Sanity check
    assert this.expression.equals(root.getString());

    // Calculate number of tree depth levels
    numDepthLevels = 0;
    for (Integer d : nodes_depths) {
      numDepthLevels = max(numDepthLevels, d + 1);
    }
  }

  String getCascadeString() {
    // Get string with nodes arranged in a cascade.
    String output = "";
    ArrayList<Node> nodes = root.getSubtreeNodes();
    for (int i = 0; i < nodes.size(); i++) {
      if (nodes.get(i).depth > 0) {
        output += String.format("%0" + (nodes.get(i).depth * 2) + "d", 0).replace("0", " ");
      }
      output += nodes.get(i).name;
      if (i < nodes.size() - 1) {
        output += "\n";
      }
    }
    return output;
  }
}
