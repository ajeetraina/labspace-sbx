---
name: docker-review
description: Review a Dockerfile for best practices. Use when the user asks to review, audit, or improve a Dockerfile.
---

When reviewing a Dockerfile, check:

1. **Base image** — pinned tag or digest, minimal and appropriate for the workload
2. **Layer order** — dependencies before application source to maximise cache reuse
3. **Image size** — multi-stage builds, `.dockerignore`, package-manager cache flags (`--no-cache`, `--no-install-recommends`)
4. **Security** — non-root `USER`, no secrets in `ARG`/`ENV`, no `--privileged`
5. **Reproducibility** — pinned package versions, explicit `COPY` targets
