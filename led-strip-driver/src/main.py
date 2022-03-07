import threading

import api
import driver


if __name__ == '__main__':
  update_strip_thread = threading.Thread(target = driver.update_strip)
  update_strip_thread.start()

  api.app.run(host='0.0.0.0', port=80)
