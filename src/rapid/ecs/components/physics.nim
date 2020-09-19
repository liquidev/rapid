## Physics components.

import glm/vec

type
  PhysicsBody* = object
    ## 2D physics body component. Signifies that an entity should have physics
    ## simulation.
    velocity*, acceleration*: Vec2f
  Gravity* = object
    ## 2D gravity component. Signifies that the entity has gravity.
    force*: Vec2f
