## Physics systems and components.

import components/basic
import components/physics
import system_macro

export Position, PhysicsBody, Gravity

system tickPhysics:
  ## Ticks the physics: updates the player's position, velocity, and
  ## acceleration.

  requires:
    position: Position
    physics: PhysicsBody

  proc update*(step: float32) =
    physics.velocity += physics.acceleration
    physics.acceleration = vec2f(0)
    position.position = physics.velocity

system applyGravity:
  ## Applies gravity to entities.

  requires:
    physics: PhysicsBody
    gravity: Gravity

  proc update*(step: float32) =
    physics.acceleration += gravity.gravity
