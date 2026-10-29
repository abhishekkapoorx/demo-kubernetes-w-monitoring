import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


USERS = [
    {"id": 1, "name": "Ada Lovelace", "role": "developer"},
    {"id": 2, "name": "Grace Hopper", "role": "platform engineer"},
]


class UserHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_json({"status": "ok"})
        elif self.path == "/users":
            self.send_json({"users": USERS})
        else:
            self.send_error(404, "Not found")

    def send_json(self, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print("%s - %s" % (self.address_string(), format % args))


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    HTTPServer(("0.0.0.0", port), UserHandler).serve_forever()
