"""Serve build/web on localhost:8080 with a no-store cache header."""

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        rel = self.path.split("?", 1)[0].split("#", 1)[0]
        local = self.translate_path(rel)
        name = os.path.basename(rel.rstrip("/"))
        if rel != "/" and not os.path.exists(local) and "." not in name:
            self.path = "/index.html"
        return super().do_GET()


if __name__ == "__main__":
    server = ThreadingHTTPServer(("localhost", 8080), Handler)
    print(f"serving {ROOT} at http://localhost:8080", flush=True)
    server.serve_forever()
