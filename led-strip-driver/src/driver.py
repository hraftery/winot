from rpi_ws281x import PixelStrip, Color

import pixels

STRIP_PIN = 21 # 21 is PCM_DOUT. See https://github.com/jgarff/rpi_ws281x#gpio-usage
strip = PixelStrip(pixels.MAX_NUM_PIXELS, STRIP_PIN)
strip.begin()

def update_strip():
  while True:
    #print("Updating strip.")
    for i, p in enumerate(pixels.pixels):
      strip.setPixelColor(i, p)
    strip.show()

    pixels.update_event.wait(30.0)
    pixels.update_event.clear()
