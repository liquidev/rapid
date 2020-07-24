## Physics components.

import glm/vec

type
  CompPhysicsBody* = object
    ## Physics body component. Signifies that an entity should have physics
    ## simulation.
    velocity*, acceleration*: Vec2f
  CompGravity* = object
    ## Gravity component. Signifies that the entity has gravity.
    gravity*: Vec2f
