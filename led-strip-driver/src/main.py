from flask import Flask, request
from flask_restful import Resource, Api, reqparse, abort

# Some useful conversion utilities, but at this stage not used.
# https://github.com/vaab/colour
#from colour import Color


app = Flask(__name__)
api = Api(app)

MAX_NUM_PIXELS = 500

# After far too much deliberation, have opted to use 0xWWRRGGBB as internal LED
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

pixel_indices = range(MAX_NUM_PIXELS)
pixels = [] # list of 32-bit integers encoding 8 bit white, red, green, blue values: 0xWWRRGGBB

def is_valid_pixel(p):
  return isinstance(p, int) and p >= COLOUR_MIN and p <= COLOUR_MAX

for i in pixel_indices:
  pixels.append(COLOUR_BLACK) #all off (black) by default


class Pixel(Resource):
  def get(self, pixel_id):
    if pixel_id in pixel_indices:
      return pixels[pixel_id]
    else:
      abort(404, message="Pixel ({}) does not exist".format(pixel_id))
  
  def put(self, pixel_id):
    if pixel_id in pixel_indices:
      try:
        val = int(request.data, 0)
        if is_valid_pixel(val):
          pixels[pixel_id] =  val
          return {pixel_id: pixels[pixel_id]}
        else:
          abort(422, message="Specified pixel value ({}) is not between 0x{08x} and 0x{08x}."
                              .format(request.data, COLOUR_MIN, COLOUR_MAX))
      except:
        abort(400, message="Could not parse data ({}) as pixel value.".format(request.data))
    else:
      abort(404, message="Pixel ({}) does not exist".format(pixel_id))


class Pixels(Resource):
  def parse_and_validate_args(self):
    parser = reqparse.RequestParser()
    parser.add_argument('offset', type=int, location='args')
    parser.add_argument('count', type=int, location='args')
    args = parser.parse_args()

    offset = 0
    count = MAX_NUM_PIXELS

    if args['offset'] is not None:
      offset = args['offset']
      if offset < 0:
        abort(422, message="Offset ({}) must be positive.".format(offset))
      elif offset > MAX_NUM_PIXELS:
        abort(422, message="Offset ({}) exceeds {} elements.".format(offset, MAX_NUM_PIXELS))
    
    if args['count'] is not None:
      count = args['count']
      if count < 0:
        abort(422, message="Count ({}) must be positive.".format(count))
      elif offset + count > MAX_NUM_PIXELS:
        abort(422, message="Offset + count ({}+{}) exceeds {} elements.".format(offset, count, MAX_NUM_PIXELS))

    return offset, count

  # optional parameters allows call from put() without parsing args twice
  def get(self, offset=None, count=MAX_NUM_PIXELS):
    if not offset:
      offset, count = self.parse_and_validate_args()

    # For now use default array-as-JSON format. In future we could support
    # options as parameters and adorn response with metadata like data format.
    # Good discussion on considerations when jsonifying an array here:
    # https://softwareengineering.stackexchange.com/questions/286293/whats-the-best-way-to-return-an-array-as-a-response-in-a-restful-api
    # By the way, it's not at all obvious why Resource.get can return a List.
    # It looks like Flask cannot, but Flask-RESTful wraps View in Resource and
    # introduces "representations". The conversion from List appears to happen here:
    # https://github.com/flask-restful/flask-restful/blob/master/flask_restful/representations/json.py#L21
    return pixels[offset:offset+count], 200

  def put(self):
    offset, wha = self.parse_and_validate_args()
    data = request.json # must send as "application/json"
    if not isinstance(data, list):
      abort(400, message="Could not parse data as JSON array.")
    elif len(data) > MAX_NUM_PIXELS-offset:
      abort(422, message="JSON array size ({}) exceeds {} elements.".format(len(data), MAX_NUM_PIXELS-offset))
    else:
      for i, p in enumerate(data):
        if is_valid_pixel(p):
          pixels[offset+i] = p
        else:
          abort(400, message="Could not parse data ({}) at index ({}) as pixel value.".format(p, i))
      return self.get(offset)


api.add_resource(Pixels, '/pixels')
api.add_resource(Pixel, '/pixels/<int:pixel_id>')

#@app.route('/')
#def hello_world():
#    return 'Hello, World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
