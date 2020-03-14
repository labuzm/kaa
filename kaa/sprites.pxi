cimport cython

from libcpp cimport bool
from libcpp.vector cimport vector

from .kaacore.sprites cimport CSprite, c_split_spritesheet
from .kaacore.hashing cimport c_calculate_hash

DEF SPRITE_FREELIST_SIZE = 250


@cython.freelist(SPRITE_FREELIST_SIZE)
cdef class Sprite:
    cdef CSprite c_sprite

    cdef void _set_c_sprite(self, const CSprite& c_sprite):
        self.c_sprite = c_sprite

    def __init__(self, str path):
        self._set_c_sprite(CSprite.load(path.encode(), 0))

    def __richcmp__(self, Sprite other, op):
        if op == 2:
            return self.c_sprite == other.c_sprite
        elif op == 3:
            return not self.c_sprite == other.c_sprite
        else:
            return NotImplemented

    def __hash__(self):
        return c_calculate_hash[CSprite](self.c_sprite)

    def crop(self, Vector origin, Vector dimensions):
        assert self.c_sprite.has_texture()
        return get_sprite_wrapper(self.c_sprite.crop(
            origin.c_vector, dimensions.c_vector
        ))

    @property
    def origin(self):
        return Vector.from_c_vector(self.c_sprite.origin)

    @property
    def dimensions(self):
        return Vector.from_c_vector(self.c_sprite.dimensions)

    @property
    def size(self):
        return Vector.from_c_vector(self.c_sprite.get_size())


cdef Sprite get_sprite_wrapper(CSprite c_sprite):
    cdef Sprite sprite = Sprite.__new__(Sprite)
    sprite._set_c_sprite(c_sprite)
    return sprite


def split_spritesheet(
    Sprite spritesheet, Vector frame_dimensions,
    size_t frames_offset=0, size_t frames_count=0,
    Vector frame_padding=Vector(0, 0),
):
    cdef vector[CSprite] c_sprites = c_split_spritesheet(
        spritesheet.c_sprite, frame_dimensions.c_vector,
        frames_offset, frames_count, frame_padding.c_vector
    )
    cdef CSprite c_sprite

    return [get_sprite_wrapper(c_sprite) for c_sprite in c_sprites]
