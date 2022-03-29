from fastapi import FastAPI, status, HTTPException, Body, Path, Query, BackgroundTasks
from fastapi.responses import PlainTextResponse, HTMLResponse
from enum import Enum

# Some useful conversion utilities, but at this stage not used.
# https://github.com/vaab/colour
#from colour import Color

import pixels

app = FastAPI()

# Some background: in the original Flask implementation, main would kick
# off the driver in one thread and the api in another. The api would
# simply signal an update event in pixels which the driver was monitoring.
# This provided good decoupling. In fastapi however, we run the api with
# an ASGI, so there's no main as such within which to spawn separate
# threads. So, since the api is now the chief, we take advantage of its
# ability to spawn separate threads. This is the thread function, which
# calls a function pointer in pixels, maintaining our loose coupling to
# the driver. We do lose the ability of the driver thread to run its own
# show though. That functionality was only used to trigger a to-be-sure
# periodic update of the strip. If that turns out to be necessary, we can
# use `fastapi_utils.tasks.repeat_every`.
@app.on_event("startup")
def update_strip():
  if pixels.strip_update_func:
    pixels.strip_update_func()


class NumberFormat(str, Enum):
  hexadecimal = "hex"
  decimal = "dec"

# Note that "title" defaults to "Pixel Id" and only appears (inconspicuously) in
# ReDoc, not Swagger UI, so we only provide "description". Also, "gt" and "lt"
# don't work in Swagger UI and in ReDoc they produce the easy-to-miss exclusive
# interval notation, eg. "[0..10)". So we stick with "ge" and "le" instead.
pixel_id_path_param = Path(..., description="The index of the RGB LED pixel.",
                                example=5, ge=0, le=pixels.MAX_NUM_PIXELS-1)

offset_query_param = Query(0, description="""
The index of the first RGB LED pixel to apply the method to.""",
                              example=5, ge=0, le=pixels.MAX_NUM_PIXELS-1)

count_query_param =  Query(None, description="""
The number of sequential pixel colour values to apply the method to.
If not specified, the method applies to all pixels from `offset` onwards.""",
                                 example=3, ge=0, le=pixels.MAX_NUM_PIXELS)

# Note that "title" defaults to "Body" and only appears (not prominently) in ReDoc,
# so we only provide "description". Although it only appears in ReDoc too.
put_pixel_body  = Body(..., media_type="text/plain",
                            description="""
The white, red, blue, green colour value to apply to the specified pixel, in `0xWWRRGGBB` format.
JSON does not support hexadecimal number format, so for convenience we accept text/plain and
support hexadecimal with the `0x` prefix, or decimal without it.""",
                            example="0x0066BBFF")

put_pixels_body = Body(..., media_type="application/json",
                            description="""
A JSON array of white, red, blue, green colour value for each of `count` pixels, to apply
to the pixels starting from index `offset`.""",
                            example=[6732799, 0, 0])

get_pixel_resp =  { "description": """
The white, red, blue, green colour value of the specified pixel, in `0xWWRRGGBB` format.""",
                    "content": {
                      "text/plain": { "example": "0x0066BBFF" }
                    }
                  }

put_pixel_resp =  { "description": "The index and new colour value of the updated pixel.",
                    "content": {
                      "application/json": { "example": {"5": 6732799} }
                    }
                  }

get_pixels_resp = { "description": """
A JSON array of `count` pixel colour values, starting from index `offset`.""",
                    "content": {
                      "application/json": { "example": [6732799, 0, 0] }
                    }
                  }

put_pixels_resp = { "description": "A JSON array of the colour values of **all** pixels.",
                    "content": {
                      "application/json": { "example": [0, 0, 0, 0, 0, 6732799, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
                    }
                  }




@app.get("/pixels/{pixel_id}", tags=["pixels"], response_class=PlainTextResponse,
                               responses={ 200: get_pixel_resp })
async def get_pixel(pixel_id: int = pixel_id_path_param,
                    number_format: NumberFormat = NumberFormat.hexadecimal):
    if pixels.is_valid_index(pixel_id):
      if number_format == NumberFormat.hexadecimal:
        return PlainTextResponse("0x{:08X}".format(pixels.pixels[pixel_id]))
      else:
        return PlainTextResponse(str(format(pixels.pixels[pixel_id])))
    else:
      raise HTTPException(status.HTTP_404_NOT_FOUND, "Pixel ({}) does not exist".format(pixel_id))


@app.put("/pixels/{pixel_id}", tags=["pixels"],
                               responses={ 200: put_pixel_resp })
async def put_pixel(*, pixel_id: int = pixel_id_path_param,
                       body: str = put_pixel_body,
                       tasks: BackgroundTasks):
  if pixels.is_valid_index(pixel_id):
    try:
      val = int(body, 0)
      if pixels.is_valid_pixel(val):
        pixels.pixels[pixel_id] = val
        tasks.add_task(update_strip)
        return {pixel_id: pixels.pixels[pixel_id]}
      else:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Specified pixel value ({}) is not between 0x{:08x} and 0x{:08x}."
                            .format(body, pixels.COLOUR_MIN, pixels.COLOUR_MAX))
    except:
      raise HTTPException(status.HTTP_400_BAD_REQUEST,
                          "Could not parse data ({}) as pixel value.".format(body))
  else:
    raise HTTPException(status.HTTP_404_NOT_FOUND,
                        "Pixel ({}) does not exist".format(pixel_id))


@app.get("/pixels", tags=["pixels"],
                    responses= { 200: get_pixels_resp })
async def get_pixels(offset: int = offset_query_param,
                     count: int = count_query_param):
  if not count:
    count = pixels.MAX_NUM_PIXELS - offset
  elif offset + count > pixels.MAX_NUM_PIXELS:
    raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                        "Offset + count ({}+{}) exceeds {} elements."
                        .format(offset, count, pixels.MAX_NUM_PIXELS))
                          
  # For now use default array-as-JSON format. In future we could support
  # options as parameters and adorn response with metadata like data format.
  # Good discussion on considerations when jsonifying an array here:
  # https://softwareengineering.stackexchange.com/questions/286293/whats-the-best-way-to-return-an-array-as-a-response-in-a-restful-api
  return pixels.pixels[offset:offset+count]


@app.put("/pixels", tags=["pixels"],
                    responses= { 200: put_pixels_resp })
async def put_pixels(*, offset: int = offset_query_param,
                        body: list[int] = put_pixels_body,
                        tasks: BackgroundTasks):
  if offset + len(body) > pixels.MAX_NUM_PIXELS:
    raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                        "The offset plus the length of the supplied data ({}+{}) exceeds {} elements."
                        .format(offset, len(body), pixels.MAX_NUM_PIXELS))

  for i, p in enumerate(body):
    if pixels.is_valid_pixel(p):
      pixels.pixels[offset+i] = p
    else:
      raise HTTPException(status.HTTP_400_BAD_REQUEST,
                          message="Could not parse data ({}) at index ({}) as pixel value."
                                  .format(p, i))
  
  tasks.add_task(update_strip)
  return pixels.pixels


@app.put("/off", tags=["commands"],
                 responses={ 200: put_pixels_resp })
async def off(tasks: BackgroundTasks):
  pixels.all_off()
  
  tasks.add_task(update_strip)
  return pixels.pixels

@app.put("/party", tags=["commands"])
async def party(tasks: BackgroundTasks):
  tasks.add_task(pixels.run_party)
  return pixels.pixels


@app.get("/redoc-try", include_in_schema=False)
async def redoc_try_html():
  html = f"""
<!DOCTYPE html>
<html>
<body>
  <div id="redoc-container"></div>
  <script src="https://cdn.jsdelivr.net/npm/redoc@2.0.0-rc.55/bundles/redoc.standalone.min.js"> </script>
  <script src="https://cdn.jsdelivr.net/gh/wll8/redoc-try@1.4.0/dist/try.js"></script>
  <script>
    initTry(`{app.openapi_url}`)
  </script>
</body>
</html>
"""
  return HTMLResponse(html)
