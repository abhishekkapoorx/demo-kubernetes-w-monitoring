import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.request import urlopen


USERS_URL = os.environ.get("USERS_URL", "http://users:8000/users")
ORDERS_URL = os.environ.get("ORDERS_URL", "http://orders:8000/orders")


def fetch_json(url):
    with urlopen(url, timeout=3) as response:
        return json.load(response)


class FrontendHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_json({"status": "ok"})
            return

        if self.path not in ("/", "/index.html"):
            self.send_error(404, "Not found")
            return

        try:
            users = fetch_json(USERS_URL)
            orders = fetch_json(ORDERS_URL)
            body = (
                "<!doctype html><html><head><title>Kubernetes demo</title></head>"
                "<body><h1>Kubernetes microservices demo</h1>"
                "<h2>Users</h2><pre>%s</pre><h2>Orders</h2><pre>%s</pre>"
                "</body></html>"
            ) % (json.dumps(users, indent=2), json.dumps(orders, indent=2))
            self.send_html(body)
        except Exception as error:
            self.send_json({"error": "backend unavailable", "detail": str(error)}, 502)

    def send_html(self, body):
        encoded = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def send_json(self, payload, status=200):
        encoded = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, format, *args):
        print("%s - %s" % (self.address_string(), format % args))


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    HTTPServer(("0.0.0.0", port), FrontendHandler).serve_forever()
