# Sonata: A Qompass Fork of Podman

![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/containers/podman)
[![Go Report Card](https://goreportcard.com/badge/github.com/containers/libpod)](https://goreportcard.com/report/github.com/containers/libpod)

<br/>

Sonata is a tool for managing containers and images, volumes mounted into those containers, and pods made from groups of containers.
Podman runs containers on Linux, but can also be used on Mac and Windows systems using a Sonata-managed virtual machine.
Sonata is based on Podman, an open-source tool for container lifecycle management that is also contained in this repository. The libpod library provides APIs for managing containers, pods, container images, and volumes.

## Overview and scope

At a high level, the scope of Podman and libpod is the following:

* Support for multiple container image formats, including OCI and Docker images.
* Full management of those images, including pulling from various sources (including trust and verification), creating (built via Containerfile or Dockerfile or committed from a container), and pushing to registries and other storage backends.
* Full management of container lifecycle, including creation (both from an image and from an exploded root filesystem), running, checkpointing and restoring (via CRIU), and removal.
* Full management of container networking, using Netavark.
* Support for pods, groups of containers that share resources and are managed together.
* Support for running containers and pods without root or other elevated privileges.
* Resource isolation of containers and pods.
* Support for a Docker-compatible CLI interface, which can both run containers locally and on remote systems.
* No manager daemon, for improved security and lower resource utilization at idle.
* Support for a REST API providing both a Docker-compatible interface and an improved interface exposing advanced Podman functionality.
* Support for running on Windows and Mac via virtual machines run by `podman machine`.


## Rootless
Sonata can be easily run as a normal user, without requiring a setuid binary.
When run without root, Podman containers use user namespaces to set root in the container to the user running Sonata.
Rootless Sonata runs locked-down containers with no privileges that the user running the container does not have.
Some of these restrictions can be lifted (via `--privileged`, for example), but rootless containers will never have more privileges than the user that launched them.
If you run Sonata as your user and mount in `/etc/passwd` from the host, you still won't be able to change it, since your user doesn't have permission to do so.

## Out of scope

* Specialized signing and pushing of images to various storage backends.
  See [Skopeo](https://github.com/containers/skopeo/) for those tasks.
* Support for the Kubernetes CRI interface for container management.
  The [CRI-O](https://github.com/cri-o/cri-o) daemon specializes in that.

## OCI Projects Plans

Sonata uses OCI projects and best of breed libraries for different aspects:
- Runtime: We use the [OCI runtime tools](https://github.com/opencontainers/runtime-tools) to generate OCI runtime configurations that can be used with any OCI-compliant runtime, like [crun](https://github.com/containers/crun/) and [runc](https://github.com/opencontainers/runc/).
- Images: Image management uses the [containers/image](https://github.com/containers/image) library.
- Storage: Container and image storage is managed by [containers/storage](https://github.com/containers/storage).
- Networking: Networking support through use of [Netavark](https://github.com/containers/netavark) and [Aardvark](https://github.com/containers/aardvark-dns).  Rootless networking is handled via [slirp4netns](https://github.com/rootless-containers/slirp4netns).
- Builds: Builds are supported via [Buildah](https://github.com/containers/buildah).
- Conmon: [Conmon](https://github.com/containers/conmon) is a tool for monitoring OCI runtimes, used by both Podman and CRI-O.
- Seccomp: A unified [Seccomp](https://github.com/containers/common/blob/main/pkg/seccomp/seccomp.json) policy for Podman, Buildah, and CRI-O.



