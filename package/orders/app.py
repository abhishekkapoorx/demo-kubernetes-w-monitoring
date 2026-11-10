import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.propagate import extract
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest


ORDERS = [
    {"id": 101, "user_id": 1, "item": "Kubernetes course", "status": "shipped"},
    {"id": 102, "user_id": 2, "item": "Container handbook", "status": "processing"},
]

REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["service", "path", "method", "status"])
REQUEST_DURATION = Histogram("http_request_duration_seconds", "HTTP request duration", ["service", "path"])
service_name = os.environ.get("OTEL_SERVICE_NAME", "orders")
provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)


class OrderHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parent_context = extract(dict(self.headers))
        with tracer.start_as_current_span("GET " + self.path, context=parent_context) as span:
            with REQUEST_DURATION.labels(service_name, self.path).time():
                if self.path == "/metrics":
                    self.send_metrics()
                    status = 200
                elif self.path == "/health":
                    self.send_json({"status": "ok"})
                    status = 200
                elif self.path == "/orders":
                    self.send_json({"orders": ORDERS})
                    status = 200
                else:
                    self.send_error(404, "Not found")
                    status = 404
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
