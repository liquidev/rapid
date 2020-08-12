## Basic, common components.
##
## Components should ultimately be nothing but pure data. Due to certain
## limitations, that isn't always possible, but usage of pointers should be kept
## to a minimum to aid easy serialization.

import aglet

type
  Position2D* = object
    ## 2D position component.
    position*: Vec2f
  Size* = object
    ## Size component.
    size*: Vec2f
