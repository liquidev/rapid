## Physics systems and components.

import glm/vec

import components/basic
import components/physics
import system_macro

export Position, PhysicsBody, Gravity

system tickPhysics:
  ## Ticks the physics: updates the player's position, velocity, and
  ## acceleration.

  requires:
    var position: Position
    var physics: PhysicsBody

  proc update() =
    physics.velocity += physics.acceleration
    physics.acceleration.reset()
    position.position = physics.velocity

system applyGravity:
  ## Applies gravity to entities.

  requires:
    var physics: PhysicsBody
    let gravity: Gravity

  proc update() =
    physics.acceleration += gravity.force
