#!/usr/bin/python3

import requests
import threading
import time

HOST = 'http://localhost:9990/req-{}'

class Req (threading.Thread):
    def __init__(self, n):
        threading.Thread.__init__(self)
        self.n = n

    def run(self):
        print('request {}'.format(self.n))
        r = requests.get(HOST.format(self.n))
        print('Request {} = {}'.format(self.n, r.status_code))
        #r2 = requests.get('http://localhost:8080/req-{}'.format(self.n))
        #print('Request2 {} = {}'.format(self.n, r2.status_code))

print('Starting')

threads = []
for i in range(1, 36):
    r = Req(i)
    r.start()
    #time.sleep(2)
    threads.append(r)

for t in threads:
    t.join()
print('Done')
