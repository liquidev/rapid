/// This file just includes FreeType. This can't be done with nimterop directly,
/// since it doesn't support #include'ing by identifier (only string)

#include <ft2build.h>
#include FT_FREETYPE_H
