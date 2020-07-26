## Physics components.

import glm/vec

type
  PhysicsBody* = object
    ## Physics body component. Signifies that an entity should have physics
    ## simulation.
    velocity*, acceleration*: Vec2f
  Gravity* = object
    ## Gravity component. Signifies that the entity has gravity.
    gravity*: Vec2f
