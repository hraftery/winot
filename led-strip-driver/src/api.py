from flask import Flask, request
from flask_restful import Resource, Api, reqparse, abort

# Some useful conversion utilities, but at this stage not used.
# https://github.com/vaab/colour
#from colour import Color

import pixels


app = Flask(__name__)
api = Api(app)

class Pixel(Resource):
  def get(self, pixel_id):
    if pixels.is_valid_index(pixel_id):
      return pixels.pixels[pixel_id]
    else:
      abort(404, message="Pixel ({}) does not exist".format(pixel_id))
  
  def put(self, pixel_id):
    if pixels.is_valid_index(pixel_id):
      try:
        val = int(request.data, 0)
        if pixels.is_valid_pixel(val):
          pixels.pixels[pixel_id] = val
          return {pixel_id: pixels[pixel_id]}
        else:
          abort(422, message="Specified pixel value ({}) is not between 0x{08x} and 0x{08x}."
                              .format(request.data, pixels.COLOUR_MIN, pixels.COLOUR_MAX))
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
    count = pixels.MAX_NUM_PIXELS

    if args['offset'] is not None:
      offset = args['offset']
      if offset < 0:
        abort(422, message="Offset ({}) must be positive.".format(offset))
      elif offset > pixels.MAX_NUM_PIXELS:
        abort(422, message="Offset ({}) exceeds {} elements."
                            .format(offset, pixels.MAX_NUM_PIXELS))
    
    if args['count'] is not None:
      count = args['count']
      if count < 0:
        abort(422, message="Count ({}) must be positive.".format(count))
      elif offset + count > pixels.MAX_NUM_PIXELS:
        abort(422, message="Offset + count ({}+{}) exceeds {} elements."
                            .format(offset, count, pixels.MAX_NUM_PIXELS))

    return offset, count

  # optional parameters allows call from put() without parsing args twice
  def get(self, offset=None, count=pixels.MAX_NUM_PIXELS):
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
    return pixels.pixels[offset:offset+count], 200

  def put(self):
    offset, _ = self.parse_and_validate_args()
    data = request.json # must send as "application/json"
    if not isinstance(data, list):
      abort(400, message="Could not parse data as JSON array.")
    elif len(data) > pixels.MAX_NUM_PIXELS-offset:
      abort(422, message="JSON array size ({}) exceeds {} elements."
                          .format(len(data), pixels.MAX_NUM_PIXELS-offset))
    else:
      for i, p in enumerate(data):
        if pixels.is_valid_pixel(p):
          pixels.pixels[offset+i] = p
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
