// Code generated by go generate; DO NOT EDIT.
package manifests

import (
	"io"
	"net/url"

	"github.com/containers/podman/v5/pkg/bindings/internal/util"
)

// Changed returns true if named field has been set
func (o *ModifyOptions) Changed(fieldName string) bool {
	return util.Changed(o, fieldName)
}

// ToParams formats struct fields to be passed to API service
func (o *ModifyOptions) ToParams() (url.Values, error) {
	return util.ToParams(o)
}

// WithOperation set field Operation to given value
func (o *ModifyOptions) WithOperation(value string) *ModifyOptions {
	o.Operation = &value
	return o
}

// GetOperation returns value of field Operation
func (o *ModifyOptions) GetOperation() string {
	if o.Operation == nil {
		var z string
		return z
	}
	return *o.Operation
}

// WithAll set all when true, operate on all images in a manifest list that may be included in Images
func (o *ModifyOptions) WithAll(value bool) *ModifyOptions {
	o.All = &value
	return o
}

// GetAll returns value of all when true, operate on all images in a manifest list that may be included in Images
func (o *ModifyOptions) GetAll() bool {
	if o.All == nil {
		var z bool
		return z
	}
	return *o.All
}

// WithAnnotations set annotations to add to the entries for Images in the manifest list
func (o *ModifyOptions) WithAnnotations(value map[string]string) *ModifyOptions {
	o.Annotations = value
	return o
}

// GetAnnotations returns value of annotations to add to the entries for Images in the manifest list
func (o *ModifyOptions) GetAnnotations() map[string]string {
	if o.Annotations == nil {
		var z map[string]string
		return z
	}
	return o.Annotations
}

// WithArch set arch overrides the architecture for the image
func (o *ModifyOptions) WithArch(value string) *ModifyOptions {
	o.Arch = &value
	return o
}

// GetArch returns value of arch overrides the architecture for the image
func (o *ModifyOptions) GetArch() string {
	if o.Arch == nil {
		var z string
		return z
	}
	return *o.Arch
}

// WithFeatures set feature list for the image
func (o *ModifyOptions) WithFeatures(value []string) *ModifyOptions {
	o.Features = value
	return o
}

// GetFeatures returns value of feature list for the image
func (o *ModifyOptions) GetFeatures() []string {
	if o.Features == nil {
		var z []string
		return z
	}
	return o.Features
}

// WithOS set oS overrides the operating system for the image
func (o *ModifyOptions) WithOS(value string) *ModifyOptions {
	o.OS = &value
	return o
}

// GetOS returns value of oS overrides the operating system for the image
func (o *ModifyOptions) GetOS() string {
	if o.OS == nil {
		var z string
		return z
	}
	return *o.OS
}

// WithOSFeatures set oSFeatures overrides the OS features for the image
func (o *ModifyOptions) WithOSFeatures(value []string) *ModifyOptions {
	o.OSFeatures = value
	return o
}

// GetOSFeatures returns value of oSFeatures overrides the OS features for the image
func (o *ModifyOptions) GetOSFeatures() []string {
	if o.OSFeatures == nil {
		var z []string
		return z
	}
	return o.OSFeatures
}

// WithOSVersion set oSVersion overrides the operating system version for the image
func (o *ModifyOptions) WithOSVersion(value string) *ModifyOptions {
	o.OSVersion = &value
	return o
}

// GetOSVersion returns value of oSVersion overrides the operating system version for the image
func (o *ModifyOptions) GetOSVersion() string {
	if o.OSVersion == nil {
		var z string
		return z
	}
	return *o.OSVersion
}

// WithVariant set variant overrides the architecture variant for the image
func (o *ModifyOptions) WithVariant(value string) *ModifyOptions {
	o.Variant = &value
	return o
}

// GetVariant returns value of variant overrides the architecture variant for the image
func (o *ModifyOptions) GetVariant() string {
	if o.Variant == nil {
		var z string
		return z
	}
	return *o.Variant
}

// WithImages set images is an optional list of images to add/remove to/from manifest list depending on operation
func (o *ModifyOptions) WithImages(value []string) *ModifyOptions {
	o.Images = value
	return o
}

// GetImages returns value of images is an optional list of images to add/remove to/from manifest list depending on operation
func (o *ModifyOptions) GetImages() []string {
	if o.Images == nil {
		var z []string
		return z
	}
	return o.Images
}

// WithAuthfile set field Authfile to given value
func (o *ModifyOptions) WithAuthfile(value string) *ModifyOptions {
	o.Authfile = &value
	return o
}

// GetAuthfile returns value of field Authfile
func (o *ModifyOptions) GetAuthfile() string {
	if o.Authfile == nil {
		var z string
		return z
	}
	return *o.Authfile
}

// WithPassword set field Password to given value
func (o *ModifyOptions) WithPassword(value string) *ModifyOptions {
	o.Password = &value
	return o
}

// GetPassword returns value of field Password
func (o *ModifyOptions) GetPassword() string {
	if o.Password == nil {
		var z string
		return z
	}
	return *o.Password
}

// WithUsername set field Username to given value
func (o *ModifyOptions) WithUsername(value string) *ModifyOptions {
	o.Username = &value
	return o
}

// GetUsername returns value of field Username
func (o *ModifyOptions) GetUsername() string {
	if o.Username == nil {
		var z string
		return z
	}
	return *o.Username
}

// WithSkipTLSVerify set field SkipTLSVerify to given value
func (o *ModifyOptions) WithSkipTLSVerify(value bool) *ModifyOptions {
	o.SkipTLSVerify = &value
	return o
}

// GetSkipTLSVerify returns value of field SkipTLSVerify
func (o *ModifyOptions) GetSkipTLSVerify() bool {
	if o.SkipTLSVerify == nil {
		var z bool
		return z
	}
	return *o.SkipTLSVerify
}

// WithArtifactType set the ArtifactType in an artifact manifest being created
func (o *ModifyOptions) WithArtifactType(value *string) *ModifyOptions {
	o.ArtifactType = &value
	return o
}

// GetArtifactType returns value of the ArtifactType in an artifact manifest being created
func (o *ModifyOptions) GetArtifactType() *string {
	if o.ArtifactType == nil {
		var z *string
		return z
	}
	return *o.ArtifactType
}

// WithArtifactConfigType set the config.MediaType in an artifact manifest being created
func (o *ModifyOptions) WithArtifactConfigType(value string) *ModifyOptions {
	o.ArtifactConfigType = &value
	return o
}

// GetArtifactConfigType returns value of the config.MediaType in an artifact manifest being created
func (o *ModifyOptions) GetArtifactConfigType() string {
	if o.ArtifactConfigType == nil {
		var z string
		return z
	}
	return *o.ArtifactConfigType
}

// WithArtifactConfig set the config.Data in an artifact manifest being created
func (o *ModifyOptions) WithArtifactConfig(value string) *ModifyOptions {
	o.ArtifactConfig = &value
	return o
}

// GetArtifactConfig returns value of the config.Data in an artifact manifest being created
func (o *ModifyOptions) GetArtifactConfig() string {
	if o.ArtifactConfig == nil {
		var z string
		return z
	}
	return *o.ArtifactConfig
}

// WithArtifactLayerType set the MediaType for each layer in an artifact manifest being created
func (o *ModifyOptions) WithArtifactLayerType(value string) *ModifyOptions {
	o.ArtifactLayerType = &value
	return o
}

// GetArtifactLayerType returns value of the MediaType for each layer in an artifact manifest being created
func (o *ModifyOptions) GetArtifactLayerType() string {
	if o.ArtifactLayerType == nil {
		var z string
		return z
	}
	return *o.ArtifactLayerType
}

// WithArtifactExcludeTitles set whether or not to include title annotations for each layer in an artifact manifest being created
func (o *ModifyOptions) WithArtifactExcludeTitles(value bool) *ModifyOptions {
	o.ArtifactExcludeTitles = &value
	return o
}

// GetArtifactExcludeTitles returns value of whether or not to include title annotations for each layer in an artifact manifest being created
func (o *ModifyOptions) GetArtifactExcludeTitles() bool {
	if o.ArtifactExcludeTitles == nil {
		var z bool
		return z
	}
	return *o.ArtifactExcludeTitles
}

// WithArtifactSubject set subject to set in an artifact manifest being created
func (o *ModifyOptions) WithArtifactSubject(value string) *ModifyOptions {
	o.ArtifactSubject = &value
	return o
}

// GetArtifactSubject returns value of subject to set in an artifact manifest being created
func (o *ModifyOptions) GetArtifactSubject() string {
	if o.ArtifactSubject == nil {
		var z string
		return z
	}
	return *o.ArtifactSubject
}

// WithArtifactAnnotations set annotations to add to an artifact manifest being created
func (o *ModifyOptions) WithArtifactAnnotations(value map[string]string) *ModifyOptions {
	o.ArtifactAnnotations = value
	return o
}

// GetArtifactAnnotations returns value of annotations to add to an artifact manifest being created
func (o *ModifyOptions) GetArtifactAnnotations() map[string]string {
	if o.ArtifactAnnotations == nil {
		var z map[string]string
		return z
	}
	return o.ArtifactAnnotations
}

// WithArtifactFiles set an optional list of files to add to a new artifact manifest in the manifest list
func (o *ModifyOptions) WithArtifactFiles(value []string) *ModifyOptions {
	o.ArtifactFiles = &value
	return o
}

// GetArtifactFiles returns value of an optional list of files to add to a new artifact manifest in the manifest list
func (o *ModifyOptions) GetArtifactFiles() []string {
	if o.ArtifactFiles == nil {
		var z []string
		return z
	}
	return *o.ArtifactFiles
}

// WithBody set field Body to given value
func (o *ModifyOptions) WithBody(value io.Reader) *ModifyOptions {
	o.Body = &value
	return o
}

// GetBody returns value of field Body
func (o *ModifyOptions) GetBody() io.Reader {
	if o.Body == nil {
		var z io.Reader
		return z
	}
	return *o.Body
}