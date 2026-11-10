import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.request import Request, urlopen

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.propagate import inject
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

USERS_URL = os.environ.get("USERS_URL", "http://users:8000/users")
ORDERS_URL = os.environ.get("ORDERS_URL", "http://orders:8000/orders")
REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["service", "path", "method", "status"])
REQUEST_DURATION = Histogram("http_request_duration_seconds", "HTTP request duration", ["service", "path"])
service_name = os.environ.get("OTEL_SERVICE_NAME", "frontend")
provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)


def fetch_json(url):
    request = Request(url)
    inject(request.headers)
    with urlopen(request, timeout=3) as response:
        return json.load(response)


class FrontendHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        with tracer.start_as_current_span("GET " + self.path) as span:
            with REQUEST_DURATION.labels(service_name, self.path).time():
                if self.path == "/metrics":
                    self.send_metrics()
                    status = 200
                elif self.path == "/health":
                    self.send_json({"status": "ok"})
                    status = 200
                elif self.path not in ("/", "/index.html"):
                    self.send_error(404, "Not found")
                    status = 404
                else:
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
                        status = 200
                    except Exception as error:
                        self.send_json({"error": "backend unavailable", "detail": str(error)}, 502)
                        status = 502
                REQUESTS.labels(service_name, self.path, "GET", str(status)).inc()
                span.set_attribute("http.route", self.path)
                span.set_attribute("http.status_code", status)

    def send_metrics(self):
        body = generate_latest()
        self.send_response(200)
        self.send_header("Content-Type", CONTENT_TYPE_LATEST)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

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
