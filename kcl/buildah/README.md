# Buildah Pipeline KCL Module

This module generates Tekton PipelineRun resources for building container images with Buildah.

## Available Options

You can override the following parameters using `-D` flags:

### Pipeline Parameters
| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `gitUrl` | Git repository URL (must be GitHub HTTPS) | `https://github.com/patrickloeber/python-docker-tutorial` | `-D gitUrl=https://github.com/myorg/myrepo` |
| `branchName` | Git branch or tag to checkout | `main` | `-D branchName=develop` |
| `verifySsl` | Verify SSL certificates (`true`/`false`) | `false` | `-D verifySsl=true` |
| `imageName` | Target image name and tag | `ttl.sh/python:v1` | `-D imageName=myregistry.com/app:v2` |
| `context` | Build context directory | `example1` | `-D context=src` |

### Git Pipeline Reference
| Option | Description | Default |
|--------|-------------|---------|
| `gitUrl` (resolver) | Pipeline definition repository | `https://github.com/stuttgart-things/stage-time.git` |
| `gitRevision` | Pipeline definition revision | `main` |
| `gitPath` | Path to pipeline YAML | `pipelines/build-image-buildah.yaml` |

### Storage Configuration
| Option | Description | Default |
|--------|-------------|---------|
| `storageClass` | Kubernetes storage class | `openebs-hostpath` |
| `storageSize` | PVC size (must end with Mi/Gi) | `20Mi` |
| `storageAccessModes` | PVC access mode | `ReadWriteOnce` |

### Other
| Option | Description | Default |
|--------|-------------|---------|
| `pipelinePrefix` | PipelineRun name prefix | `pr-buildah` |

## Usage

### Pull from OCI registry
```bash
kcl run oci://ghcr.io/stuttgart-things/kcl-tekton-buildah
```
