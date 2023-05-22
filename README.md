# expression_viewer
 
## Expression editing

There are two methods for modifying the input expression:

1. **Code variable:** You can insert the expression string in the variable `expression` (located at the beginning of the code) before running the visualiser.
2. **Text file:** You can store the expression string in the file `expression.txt` which is continuously watched by the visualiser for modifications. By default this file is located inside the visualiser folder `expression_viewer/`, but you can easily change this my modifying the variable `expressionFile` (located at the beginning of the code). This method is useful for live expression editing or to visualise expression being generated programmatically.

Please note that the second method overrides the first. Thus, if there is an expression saved in the file, this will be the one that will be visualised (ignoring the expression specified in the code).

## Integration with Genetic Programming engine

The integration of this tool with a GP engine allows rendering the output (image) of each tree node. Specifically, the visualiser asks the GP engine to generate images for a set of expressions, including the input expression and all of its subexpressions. Once these images are generated and saved in a folder, the visualiser loads and displays them in the tree. Whenever the expression changes, the visualiser asks the GP engine for new images.

This integration is based on a communication through files on disk.
