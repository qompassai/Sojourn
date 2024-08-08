#!/usr/bin/env bats   -*- bats -*-
#
# Tests for the namespace options
#

load helpers

# bats test_tags=distro-integration
@test "podman test all namespaces" {
    # format is nsname | option name
    tests="
cgroup | cgroupns
ipc    | ipc
net    | network
pid    | pid
uts    | uts
"

    for nstype in private host; do
        while read name option; do
            local cname="c_${name}_$(random_string)"
            # ipc is special, private does not allow joining from another container.
            # Instead we must use "shareable".
            local type=$nstype
            if [ "$name" = "ipc" ] && [ "$type" = "private" ]; then
                type="shareable"
            fi

            run_podman run --name $cname --$option $type -d $IMAGE sh -c \
                "readlink /proc/self/ns/$name; sleep inf"

            run_podman run --rm --$option container:$cname $IMAGE readlink /proc/self/ns/$name
            con2_ns="$output"

            run readlink /proc/self/ns/$name
            host_ns="$output"

            run_podman logs $cname
            con1_ns="$output"

            assert "$con1_ns" == "$con2_ns" "($name) namespace matches (type: $type)"
            local matcher="=="
            if [[ "$type" != "host" ]]; then
                matcher="!="
            fi
            assert "$con1_ns" $matcher "$host_ns" "expected host namespace to ($matcher) (type: $type)"

            run_podman rm -f -t0 $cname
        done < <(parse_table "$tests")
    done
}

# vim: filetype=sh
