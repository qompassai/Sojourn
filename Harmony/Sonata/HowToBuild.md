Building from Source
Build and Run Dependencies

Required

On Fedora:

```
# Install runtime dependencies
```bash
sudo dnf -y install catatonit conmon containers-common-extra
```
On all RHEL and CentOS Stream, first install dnf-builddep:
```bash
sudo dnf -y install 'dnf-command(builddep)'
```
Install runtime dependencies:
```bash
sudo dnf -y install \
  conmon \
  containers-common \
  crun \
  iptables \
  netavark \
  nftables \
  slirp4netns
```
Debian, Ubuntu, and related distributions:
```bash
sudo apt-get install \
  btrfs-progs \
  crun \
  git \
  golang-go \
  go-md2man \
  iptables \
  libassuan-dev \
  libbtrfs-dev \
  libc6-dev \
  libdevmapper-dev \
  libglib2.0-dev \
  libgpgme-dev \
  libgpg-error-dev \
  libprotobuf-dev \
  libprotobuf-c-dev \
  libseccomp-dev \
  libselinux1-dev \
  libsystemd-dev \
  netavark \
  pkg-config \
  uidmap
```
The netavark package may not be available on older Debian / Ubuntu versions. Install the containernetworking-plugins package instead.

On openSUSE Leap 15.x and Tumbleweed:
```bash
sudo zypper -n in libseccomp-devel libgpgme-devel
```

For Arch

enable user namespaces:
```bash
sudo sysctl kernel.unprivileged_userns_clone=1
```
To enable the user namespaces permanently:
```bash
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/userns.conf
```
Building missing dependencies

If any dependencies cannot be installed or are not sufficiently current, they have to be built from source. This will mainly affect Debian, Ubuntu, and related distributions, or RHEL where no subscription is active (e.g. Cloud VMs).
golang

Be careful to double-check that the version of golang is new enough (i.e. go version), as of January 2022 version is 1.16.x or higher is required. The current minimum required version can always be found in the go.mod file. If needed, golang kits are available at https://golang.org/dl/. Alternatively, go can be built from source as follows (it's helpful to leave the system-go installed, to avoid having to bootstrap go:
```bash
export GOPATH=~/go
git clone https://go.googlesource.com/go $GOPATH
cd $GOPATH
cd src
./all.bash
export PATH=$GOPATH/bin:$PATH
```
conmon

The latest version of conmon is expected to be installed on the system. Conmon is used to monitor OCI Runtimes. To build from source, use the following:
```bash
git clone https://github.com/containers/conmon
cd conmon
export GOCACHE="$(mktemp -d)"
make
sudo make sonata
```
crun / runc

The latest version of at least one container runtime is expected to be installed on the system. crun or runc are some of the possibilities, and one is picked up as the default runtime by Sonata (crun has priority over runc). Supported versions of crun or runc are available for example on Ubuntu 22.04. runc version 1.0.0-rc4 is the minimal requirement, which is available since Ubuntu 18.04.

To double-check, runc --version should produce at least spec: 1.0.1, otherwise build your own:
```bash
git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc
cd $GOPATH/src/github.com/opencontainers/runc
make BUILDTAGS="selinux seccomp"
sudo cp runc /usr/bin/runc
```
Add configuration
```bash
sudo mkdir -p /etc/containers
sudo curl -L -o /etc/containers/registries.conf https://src.fedoraproject.org/rpms/containers-common/raw/main/f/registries.conf
sudo curl -L -o /etc/containers/policy.json https://src.fedoraproject.org/rpms/containers-common/raw/main/f/default-policy.json
```
Optional packages

Fedora, CentOS, RHEL, and related distributions:

(no optional packages)

Debian, Ubuntu, and related distributions:
```bash
apt-get install -y \
  libapparmor-dev
```

Configuration files
registries.conf
Man Page: registries.conf.5

/etc/containers/registries.conf

registries.conf is the configuration file which specifies which container registries should be consulted when completing image names which do not include a registry or domain portion.
Example from the Fedora containers-common package

$ cat /etc/containers/registries.conf
# For more information on this configuration file, see containers-registries.conf(5).
#
# NOTE: RISK OF USING UNQUALIFIED IMAGE NAMES
# We recommend always using fully qualified image names including the registry
# server (full dns name), namespace, image name, and tag
# (e.g., registry.redhat.io/ubi8/ubi:latest). Pulling by digest (i.e.,
# quay.io/repository/name@digest) further eliminates the ambiguity of tags.
# When using short names, there is always an inherent risk that the image being
# pulled could be spoofed. For example, a user wants to pull an image named
# `foobar` from a registry and expects it to come from myregistry.com. If
# myregistry.com is not first in the search list, an attacker could place a
# different `foobar` image at a registry earlier in the search list. The user
# would accidentally pull and run the attacker's image and code rather than the
# intended content. We recommend only adding registries which are completely
# trusted (i.e., registries which don't allow unknown or anonymous users to
# create accounts with arbitrary names). This will prevent an image from being
# spoofed, squatted or otherwise made insecure.  If it is necessary to use one
# of these registries, it should be added at the end of the list.
#
# # An array of host[:port] registries to try when pulling an unqualified image, in order.
unqualified-search-registries = ["registry.fedoraproject.org", "registry.access.redhat.com", "docker.io"]
#
# [[registry]]
# # The "prefix" field is used to choose the relevant [[registry]] TOML table;
# # (only) the TOML table with the longest match for the input image name
# # (taking into account namespace/repo/tag/digest separators) is used.
# #
# # If the prefix field is missing, it defaults to be the same as the "location" field.
# prefix = "example.com/foo"
#
# # If true, unencrypted HTTP as well as TLS connections with untrusted
# # certificates are allowed.
# insecure = false
#
# # If true, pulling images with matching names is forbidden.
# blocked = false
#
# # The physical location of the "prefix"-rooted namespace.
# #
# # By default, this equal to "prefix" (in which case "prefix" can be omitted
# # and the [[registry]] TOML table can only specify "location").
# #
# # Example: Given
# #   prefix = "example.com/foo"
# #   location = "internal-registry-for-example.net/bar"
# # requests for the image example.com/foo/myimage:latest will actually work with the
# # internal-registry-for-example.net/bar/myimage:latest image.
# location = "internal-registry-for-example.com/bar"
#
# # (Possibly-partial) mirrors for the "prefix"-rooted namespace.
# #
# # The mirrors are attempted in the specified order; the first one that can be
# # contacted and contains the image will be used (and if none of the mirrors contains the image,
# # the primary location specified by the "registry.location" field, or using the unmodified
# # user-specified reference, is tried last).
# #
# # Each TOML table in the "mirror" array can contain the following fields, with the same semantics
# # as if specified in the [[registry]] TOML table directly:
# # - location
# # - insecure
# [[registry.mirror]]
# location = "example-mirror-0.local/mirror-for-foo"
# [[registry.mirror]]
# location = "example-mirror-1.local/mirrors/foo"
# insecure = true
# # Given the above, a pull of example.com/foo/image:latest will try:
# # 1. example-mirror-0.local/mirror-for-foo/image:latest
# # 2. example-mirror-1.local/mirrors/foo/image:latest
# # 3. internal-registry-for-example.net/bar/image:latest
# # in order, and use the first one that exists.
#
# short-name-mode="enforcing"

[[registry]]
location="localhost:5000"
insecure=true
