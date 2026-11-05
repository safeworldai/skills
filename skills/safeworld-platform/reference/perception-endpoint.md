# Perception endpoint (video suites)

A video suite's items are recorded clips, not simulations. `safeworld suite start --endpoint`
sends each clip, one frame at a time, to an HTTP endpoint that you run, and the platform scores
the boxes that come back. The platform never calls your infrastructure, and the CLI never
receives the ground truth. To compare your boxes with the ground truth, open the clip in the web
app's suite-run report (Watch clip).

The CLI needs `ffmpeg` 5.1 or later on PATH to decode the clips.

## The contract (`safeworld.perception_endpoint/v1`)

Serve three routes under one base URL (the `--endpoint` value):

| Route | Request | Response |
|---|---|---|
| `GET /health` | — | Any `2xx` when your model is loaded and can take frames. |
| `POST /reset` | JSON `{"clip_id", "camera", "width", "height", "fps"}` | Any `2xx`. Clear tracker state here: a new clip starts. |
| `POST /act` | Body: one PNG frame (`Content-Type: image/png`). Headers: `X-Safeworld-Frame` (0-based index), `X-Safeworld-Time-S` (seconds from the clip start), `X-Safeworld-Camera`. | JSON `{"detections": [{"bbox_xyxy": [x0, y0, x1, y1], "score": 0.0-1.0, "label": "person"}]}` |

Rules for `/act`:

- Box coordinates are pixels of the frame you received, with
  `0 <= x0 < x1 <= width` and `0 <= y0 < y1 <= height`.
- `score` is from 0 to 1.
- One frame holds at most 1,000 detections.
- A detection with an empty `label` is dropped.
- Frames of one clip arrive one at a time and in order. Answer each before
  the next one is sent.

An answer that breaks a rule fails the item with `endpoint_bad_response`.

## How the platform scores

Each video item has a rule, `safeworld.video_detection_rule/v1`:

- A detection counts when its `label` is the rule's label (for example
  `person`) and its `score` reaches the rule's `min_score`.
- A frame that shows the person is a **hit** when a counted detection overlaps
  the person's box with IoU at or above the rule's `iou_min`. A person cut by
  the edge of a 360° frame has two boxes; either one counts.
- A counted detection that overlaps no person is a **false alarm**.
- **Recall** is hits divided by the frames that show the person.
- The item is `approved` when recall reaches the rule's `min_recall`, else
  `rejected`.

The result shows the recall, the frames with a person, and the false alarms
per frame. `suite status` shows the recall in the RUN column (see
`suite status`). The
verdict and these numbers are also in the suite-run report in the web app,
where Watch clip plays each clip with your boxes and the ground truth.

## Exit codes

| Item result | Exit code |
|---|---|
| `approved` | 0 |
| `rejected` (recall under `min_recall`) | 6 |
| `failed` (your endpoint or the decode failed) | 3 |
| Not started: `/health` never answered within `--endpoint-ready-timeout` | 3 |

When your endpoint fails, the item fails with one of these codes:

| Code | Meaning |
|---|---|
| `endpoint_unreachable` | No answer: a connection failure or a request timeout (`--endpoint-timeout`, default 30 s). |
| `endpoint_error` | A non-`2xx` answer. |
| `endpoint_bad_response` | A `2xx` answer that breaks the contract. |
| `decode_failed` | `ffmpeg` could not decode the clip, or it gave a different frame count. |

## A minimal endpoint

This example serves a person detector with the Python standard library and
`ultralytics`. Replace `detect()` with your own model.

```python
import io, json
from http.server import BaseHTTPRequestHandler, HTTPServer

import numpy as np
from PIL import Image
from ultralytics import YOLO

model = YOLO("yolo11s.pt")

def detect(rgb):
    result = model.predict(rgb[..., ::-1], classes=[0], conf=0.05, verbose=False)[0]
    return [
        {"bbox_xyxy": box.xyxy[0].tolist(), "score": float(box.conf), "label": "person"}
        for box in result.boxes
    ]

class Handler(BaseHTTPRequestHandler):
    def _answer(self, status, payload=None):
        body = json.dumps(payload or {}).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self._answer(200 if self.path == "/health" else 404)

    def do_POST(self):
        data = self.rfile.read(int(self.headers["Content-Length"]))
        if self.path == "/reset":
            return self._answer(200)
        if self.path == "/act":
            rgb = np.asarray(Image.open(io.BytesIO(data)).convert("RGB"))
            return self._answer(200, {"detections": detect(rgb)})
        self._answer(404)

HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
```

Ultralytics already keeps boxes inside the image. If your model can return a
box past the edge, clip it to the frame before you answer.
