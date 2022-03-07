import threading


MAX_NUM_PIXELS = 500

# After far too much deliberation, I have opted to use 0xWWRRGGBB as internal LED
# colour format. The Color library supports all sorts of other formats, but none
# are conducive to easy REST API read/write, and require massaging to suit LED strips
# anyway. So have opted for a standard that suits JSON and LEDs, as defined here:
# https://github.com/adafruit/Adafruit_NeoPixel/blob/master/Adafruit_NeoPixel.h#L352
COLOUR_BLACK      = 0x00000000
COLOUR_WHITE      = 0x00FFFFFF
COLOUR_WHITE_RGBW = 0xFF000000
COLOUR_RED        = 0x00FF0000
COLOUR_GREEN      = 0x0000FF00
COLOUR_BLUE       = 0x000000FF
COLOUR_MIN        = 0x00000000
COLOUR_MAX        = 0xFFFFFFFF

# The one and only store of current pixel data for the LED strip.
# Is a list of 32-bit ints encoding 8 bit white, red, green, blue values: 0xWWRRGGBB
pixels = MAX_NUM_PIXELS * [COLOUR_BLACK] #all off (black) by default

def is_valid_index(i):
  return isinstance(i, int) and i >= 0 and i < MAX_NUM_PIXELS

def is_valid_pixel(p):
  return isinstance(p, int) and p >= COLOUR_MIN and p <= COLOUR_MAX


# Call set() on this to trigger an update based on the content of pixels.
# Note threading is pre-emptive (asyncio is cooperative) so set() can cause
# a context switch at any point, potentially interrupting the calling thread.
# That's no big deal performance-wise, since it'll shortly switch back too.
update_event = threading.Event()

# If we need to protect pixels from concurrent access, this will do. At this
# stage we don't, because read/writes are probably always atomic, and even if
# they aren't, the driver reading a corrupted pixel value while the api is
# writing it is quite inconsequential - perhaps a brief incorrect pixel colour.
#lock = threading.Lock()
