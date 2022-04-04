import os
from time import sleep

# user may specify and call a LED strip update function using this global
# allows decoupling of the implementation from the caller.
strip_update_func = None

def all_off():
  global pixels
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]

def is_valid_index(i):
  return isinstance(i, int) and i >= 0 and i < MAX_NUM_PIXELS

def is_valid_pixel(p):
  return isinstance(p, int) and p >= COLOUR_MIN and p <= COLOUR_MAX



MAX_NUM_PIXELS = int(os.getenv('MAX_NUM_PIXELS', '500'))

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
COLOUR_PURPLE     = 0x00FF00FF
COLOUR_YELLOW     = 0x00FFFF00
COLOUR_CYAN       = 0x0000FFFF
COLOUR_MIN        = 0x00000000
COLOUR_MAX        = 0xFFFFFFFF


# The one and only store of current pixel data for the LED strip.
# Is a list of 32-bit ints encoding 8 bit white, red, green, blue values: 0xWWRRGGBB
pixels = []
all_off() #all off (black) by default


# Just a sneaky little demo
def run_party():
  global pixels
  global strip_update_func

  if not strip_update_func:
    print("Tried to party, but no strip_update_func.")
    return
  
  party_loop(1.0)
  print("faster")
  party_loop(0.5)
  print("faster")
  party_loop(0.2)
  party_loop(0.2)
  print("faster")
  party_loop(0.1)
  party_loop(0.1)
  party_loop(0.1)
  party_loop(0.1)
  party_loop(0.05)
  party_loop(0.05)
  party_loop(0.05)
  party_loop(0.05)
  party_loop(0.05)
  party_loop(0.05)
  print("black")
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]
  strip_update_func()
  sleep(1)
  print("all on")
  pixels = MAX_NUM_PIXELS * [COLOUR_RED]
  strip_update_func()
  sleep(0.1)
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]
  strip_update_func()
  sleep(0.5)
  pixels = MAX_NUM_PIXELS * [COLOUR_BLUE]
  strip_update_func()
  sleep(0.1)
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]
  strip_update_func()
  sleep(0.5)
  pixels = MAX_NUM_PIXELS * [COLOUR_GREEN]
  strip_update_func()
  sleep(0.1)
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]
  strip_update_func()
  sleep(0.5)
  for i in range(10):
    pixels = MAX_NUM_PIXELS * [COLOUR_RED]
    strip_update_func()
    sleep(0.5 - i/25)
    pixels = MAX_NUM_PIXELS * [COLOUR_BLUE]
    strip_update_func()
    sleep(0.5 - i/25)
    pixels = MAX_NUM_PIXELS * [COLOUR_GREEN]
    strip_update_func()
    sleep(0.5 - i/25)
  pixels = MAX_NUM_PIXELS * [COLOUR_BLACK]
  strip_update_func()
  sleep(2.5)
  print("fade")
  pixels = MAX_NUM_PIXELS * [COLOUR_WHITE]
  strip_update_func()
  sleep(2)
  pixels = MAX_NUM_PIXELS * [0xEEEEEE]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0xDDDDDD]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0xCCCCCC]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0xBBBBBB]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0xAAAAAA]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0x999999]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0x888888]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0x777777]
  strip_update_func()
  sleep(0.2)
  pixels = MAX_NUM_PIXELS * [0x666666]
  strip_update_func()
  sleep(0.25)
  pixels = MAX_NUM_PIXELS * [0x555555]
  strip_update_func()
  sleep(0.25)
  pixels = MAX_NUM_PIXELS * [0x444444]
  strip_update_func()
  sleep(0.25)
  pixels = MAX_NUM_PIXELS * [0x333333]
  strip_update_func()
  sleep(0.25)
  pixels = MAX_NUM_PIXELS * [0x222222]
  strip_update_func()
  sleep(0.25)
  pixels = MAX_NUM_PIXELS * [0x111111]
  strip_update_func()
  sleep(0.5)
  pixels = MAX_NUM_PIXELS * [0x000000]
  strip_update_func()

def party_loop(delay):
  global pixels
  global strip_update_func

  pixels[30:30+8] = 8 * [COLOUR_BLACK]
  pixels[45:45+7] = 7 * [COLOUR_BLACK]
  pixels[ 0: 0+8] = 8 * [COLOUR_RED]
  pixels[75:75+7] = 7 * [COLOUR_RED]
  strip_update_func()
  sleep(delay)
  pixels[ 0: 0+8] = 8 * [COLOUR_BLACK]
  pixels[75:75+7] = 7 * [COLOUR_BLACK]
  pixels[ 8: 8+7] = 7 * [COLOUR_BLUE]
  pixels[67:67+8] = 8 * [COLOUR_BLUE]
  strip_update_func()
  sleep(delay)
  pixels[ 8: 8+7] = 7 * [COLOUR_BLACK]
  pixels[67:67+8] = 8 * [COLOUR_BLACK]
  pixels[15:15+8] = 8 * [COLOUR_GREEN]
  pixels[60:60+7] = 7 * [COLOUR_GREEN]
  strip_update_func()
  sleep(delay)
  pixels[15:15+8] = 8 * [COLOUR_BLACK]
  pixels[60:60+7] = 7 * [COLOUR_BLACK]
  pixels[23:23+7] = 7 * [COLOUR_PURPLE]
  pixels[52:52+8] = 8 * [COLOUR_PURPLE]
  strip_update_func()
  sleep(delay)
  pixels[23:23+7] = 7 * [COLOUR_BLACK]
  pixels[52:52+8] = 8 * [COLOUR_BLACK]
  pixels[30:30+8] = 8 * [COLOUR_YELLOW]
  pixels[45:45+7] = 7 * [COLOUR_YELLOW]
  strip_update_func()
  sleep(delay)