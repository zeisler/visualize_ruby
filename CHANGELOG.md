All notable changes to this project will be documented in this file.

## 0.16.0 - 2019-07-10
### Changed
* Require at least Ruby version 2.3
* Set no upper bound on parser gem version.

## 0.15.1 - 2018-10-05
### Fix
* Require Forwardable.
* Use default temp directory.

## 0.15.0 - 2018-09-02
### Enhancement
* return keyword emits a terminal node in the context of a single methods. Side effects are unknown for methods returning back from a call into another method.
  
## 0.14.0 - 2018-09-02
### Enhancement
* Add parser options `unique_nodes` and `only_graphs`

## 0.13.0 - 2018-08-02
### Enhancement
- Major improvements to tracing. Defaults to in-line method calls on self for better visuals.
- Block arguments are referenced on the edge instead of given separate node.

## 0.12.0 - 2018-07-27
### Fix
* Better handle more than one OR statement.
* Fixed bug where node id's were returning nil causing malformed graphs.

## 0.11.0 - 2018-07-26
### Enhancement
* Improved highlights execution path on flow chart. It using ruby code file or string to build the graph then a file or string of calling code.
* Better display blocks without arguments.
* Added DSL for graphing and tracing code.

## 0.10.0 - 2018-07-20
### Enhancement
* Highlights execution path on flow chart. It using ruby code file or string to build the graph then a file or string of calling code.

## 0.9.0 - 2018-07-17
### Enhancement
* Properly render Messy code, gilded Rose as example https://github.com/amckinnell/Gilded-Rose-Ruby/blob/master/lib/gilded_rose.rb
* Conditions with no else statement have an edge to an END node.
* All nodes have unique IDs based on source location. 
Nodes can be merged based on there label with VisualizeRuby::Graphviz(graphs, label, unique_nodes: false)

## 0.8.0 - 2018-07-17
### Enhancement
* Better handle conditions outside of if statements.

## 0.7.0 - 2018-07-17
### Fix
* Ruby types like Hash and Array causing error. Now render as code.

## 0.6.0 - 2018-06-27
### Enhancement
* Visualize Enumerable looping
* Display nodes for block arguments

## 0.5.0 - 2018-06-22
### Enhancement
* Change some visual display for flow charts.

## 0.4.0 - 2018-06-22

### Enhancement
* Add special parsing for case statements.

## 0.3.1 - 2018-06-22

### Fix
* Better handle variables assignment before control flow. 

## 0.3.0 - 2018-06-22

### Enhancement
* Node text now parses ast back to Ruby code. Improve accurately displaying all type of ruby code.
