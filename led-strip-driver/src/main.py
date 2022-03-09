#import threading

import api
import pixels
import driver

# Hook up our driver to pixels so api can remain decoupled.
pixels.strip_update_func = driver.update_strip

# Expose the fastapi app to the outside world.
app = api.app


if __name__ == '__main__':
  print("This script must be run with an ASGI/WSGI such as uvicorn.")
