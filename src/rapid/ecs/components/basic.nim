## Basic, common components.
##
## Components should ultimately be nothing but pure data. Due to certain
## limitations, that isn't always possible, but usage of pointers should be kept
## to a minimum to aid easy serialization.

import aglet

type
  CompPosition* = object
    ## Position component.
    position*: Vec2f
  CompSize* = object
    ## Size component.
    size*: Vec2f
  CompColor* = object
    ## Color component.
    color*: Rgba32f
