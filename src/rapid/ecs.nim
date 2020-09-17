## Master ECS module, imports all the basics needed to get up and running with
## an ECS world.

import ecs/[
  system_macro,
  ecs_macro,
]

export system_macro
export ecs_macro

# i don't want to throw out good code, so let's just emit a warning
# to any daredevils that try to use this
{.warning: "rapid/ecs is heavily unfinished, use rapid/ec for the time being".}
