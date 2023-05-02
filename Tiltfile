# Load Extensions
load('ext://earthly', 'earthly_build')

# Build
earthly_build(
    context='.',
    target='+build-site',
    ref='site',
    image_arg='IMAGE_REFS',
)

# Deploy
