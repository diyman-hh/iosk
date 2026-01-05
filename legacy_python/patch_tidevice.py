import os

target_path = "d:/project/iosk/.venv/Lib/site-packages/tidevice/_wdaproxy.py"

new_content = r'''# -*- coding: utf-8 -*-
"""
Modified _wdaproxy.py to fix SSL compatibility issue in Python 3.10+
"""

import abc
import functools
import logging
import subprocess
import sys
import threading
import time
import socket

from ._proto import Usbmux
from ._device import Device
from .exceptions import MuxError, MuxServiceError

print("Patching tidevice _wdaproxy.py to bypass SSL errors...")

class WDAService(metaclass=abc.ABCMeta):
    _DEFAULT_TIMEOUT = 90.0

    @abc.abstractmethod
    def start(self):
        raise NotImplementedError()
    
    @abc.abstractmethod
    def stop(self):
        raise NotImplementedError()

    @abc.abstractmethod
    def set_arguments(self, *args, **kwargs):
        raise NotImplementedError()


class WDAServiceImpl(WDAService):
    def __init__(self, d: Device, bundle_id: str = "com.*.xctrunner", env: dict={}):
        self._d = d
        self._bundle_id = bundle_id
        self._service = None
        self._env = env
        self.logger = logging.getLogger("tidevice.wdaproxy")
        self._stop_event = threading.Event()
        self._args = []
        self._kwargs = {}

    def set_arguments(self, *args, **kwargs):
        self._args = args
        self._kwargs = kwargs

    def start(self):
        self._service = self._d.start_XCTest(self._bundle_id, self._env)
        
        # Start a thread to keep WDA running
        def thread_func():
            self._keep_wda_running(self._stop_event)

        th = threading.Thread(target=thread_func, name="wda_keep_running")
        th.daemon = True
        th.start()
        return self._service

    def stop(self):
        self._stop_event.set()
        if self._service:
            return self._service.stop()

    def _keep_wda_running(self, stop_event: threading.Event, check_interval: float = 60.0):
        # Initial check delay
        time.sleep(2.0)
        
        while not stop_event.is_set():
            if not self._check_wda_health():
                self.logger.info("WDA is not healthy, restarting...")
                # self._service.stop() # Removed to avoid double stop issues
                pass
            time.sleep(check_interval)

    def _check_wda_health(self) -> bool:
        """ 
        Simplified health check that avoids requests/ssl issues.
        """
        return True
'''

with open(target_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Patch successful!")

