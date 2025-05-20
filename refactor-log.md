## 📒 Refactor Log

| Item | Type | Description |
| :-- | :-- | :-- |
| Auth handling for API endpoints | (b) Desirable | MVP skips API authentication. Future versions should add:<br>Token-based access (e.g., Cognito, JWT).<br>IP whitelisting or API Gateway-level access controls.<br>Rate limiting per client. |
| App granularity | (b) Desirable | MVP uses single FastAPI app. In future, endpoints can be split into separate services to allow:<br>Independent scaling and deployments.<br>Better fault isolation.<br>Team/module separation. |
| GitHub → EKS auth	| (b) Desirable	| Securely integrate GHA with EKS using IAM OIDC or IRSA role for Helm/kubectl access. |
| API versioning prefix	| (c) Cosmetic | Optionally wrap endpoints under /api/v1/ for future-proofing and external consistency. |
| Evaluate removing Kinesis	| (b) Desirable | If only one processing step is used (S3 triggers Lambda), Kinesis can be skipped for MVP. Document decoupling benefits if scaling later. |
| Optional validation or fraud detection before upload | (c) Cosmetic | Could intercept metadata before upload or inspect file headers |
| App/Helm: Separate endpoints into images/deployments | (a) Critical / (b) Desirable | `/upload-media` is CPU-heavy, `/results` is fast and light. They likely need different scaling long-term. |
| Container Registry Push | (a) Critical | Build & push missing in GHA. Use docker buildx + docker push or GHCR |
| Docker Image Tagging | (a) Critical | No versioning / SHA tags yet. Use github.sha or semver tied to release tags |
| App Healthchecks | (b) Desirable | Liveness/readiness probes. Important for ALB health + scaling (see below) |
| S3 media bucket | (b) Desirable | Optionally add versioning and logging. Best practice for prod-like durability/traceability |


---

### Liveness Probes
Add to `deployment.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 20
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

Add to FastAPI:
```python
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/health")
def health_check():
    return JSONResponse(content={"status": "ok"})
```