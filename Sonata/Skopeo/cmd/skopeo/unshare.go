//go:build !linux
// +build !linux

package main

func reexecIfNecessaryForImages(_ ...string) error {
	return nil
}
