import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


ORDERS = [
    {"id": 101, "user_id": 1, "item": "Kubernetes course", "status": "shipped"},
    {"id": 102, "user_id": 2, "item": "Container handbook", "status": "processing"},
]


class OrderHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_json({"status": "ok"})
        elif self.path == "/orders":
            self.send_json({"orders": ORDERS})
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
    HTTPServer(("0.0.0.0", port), OrderHandler).serve_forever()
