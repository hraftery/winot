import threading

import api
import driver

#sleepEvent = threading.Event()
# sleepEvent.wait(10) # wait for up to 10 seconds
# sleepEvent.set() # wake thread


if __name__ == '__main__':
  update_strip_thread = threading.Thread(target = driver.update_strip)
  update_strip_thread.start()

  api.app.run(host='0.0.0.0', port=80)
