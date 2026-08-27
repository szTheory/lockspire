#!/usr/bin/env python3
"""One-request local Hex release endpoint for exact-byte upload tests."""

from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import sys


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def handle_expect_100(self):
        self.send_response_only(100)
        self.end_headers()
        return True

    def do_POST(self):
        if self.headers.get("transfer-encoding", "").lower() == "chunked":
            chunks = []
            while True:
                size = int(self.rfile.readline().split(b";", 1)[0], 16)
                if size == 0:
                    self.rfile.readline()
                    break
                chunks.append(self.rfile.read(size))
                self.rfile.read(2)
            payload = b"".join(chunks)
        else:
            length = int(self.headers.get("content-length", "0"))
            payload = self.rfile.read(length)

        Path(sys.argv[1]).write_bytes(payload)
        body = b'{"html_url":"http://example.invalid/releases/fixture"}'
        self.send_response(201)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format, *_args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_port, flush=True)
server.handle_request()
server.server_close()
