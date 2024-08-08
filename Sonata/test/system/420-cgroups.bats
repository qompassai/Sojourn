#!/usr/bin/env bats   -*- bats -*-
#
# cgroups-related tests
#

load helpers

@test "podman run, preserves initial --cgroup-manager" {
    skip_if_remote "podman-remote does not support --cgroup-manager"

    skip_if_rootless_cgroupsv1

    # Find out our default cgroup manager, and from that, get the non-default
    run_podman info --format '{{.Host.CgroupManager}}'
    case "$output" in
        systemd)  other="cgroupfs" ;;
        cgroupfs) other="systemd"  ;;
        *)        die "Unknown CgroupManager '$output'" ;;
    esac

    run_podman --cgroup-manager=$other run --name myc $IMAGE true
    assert "$output" = "" "run true, with cgroup-manager=$other, is silent"

    run_podman container inspect --format '{{.HostConfig.CgroupManager}}' myc
    is "$output" "$other" "podman preserved .HostConfig.CgroupManager"

    if is_rootless && test $other = cgroupfs ; then
        run_podman container inspect --format '{{.HostConfig.CgroupParent}}' myc
        is "$output" "" "podman didn't set .HostConfig.CgroupParent for cgroupfs and rootless"
    fi

    # Restart the container, without --cgroup-manager option (ie use default)
    # Prior to #7970, this would fail with an OCI runtime error
    run_podman start -a myc
    assert "$output" = "" "restarted container emits no output"

    run_podman rm myc
}

# bats test_tags=distro-integration
@test "podman run --cgroups=disabled keeps the current cgroup" {
    skip_if_remote "podman-remote does not support --cgroups=disabled"
    skip_if_rootless_cgroupsv1
    runtime=$(podman_runtime)
    if [[ $runtime != "crun" ]]; then
        skip "runtime is $runtime; --cgroups=disabled requires crun"
    fi

    current_cgroup=$(cat /proc/self/cgroup)

    # --cgroupns=host is required to have full visibility of the cgroup path inside the container
    run_podman run --cgroups=disabled --cgroupns=host --rm $IMAGE cat /proc/self/cgroup
    is "$output" $current_cgroup "--cgroups=disabled must not change the current cgroup"
}

# vim: filetype=sh
