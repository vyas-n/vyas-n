# Load Extensions
load('ext://earthly', 'earthly_build')
load('ext://helm_resource', 'helm_resource')

# Build
earthly_build(
    context='.',
    target='+build-site',
    ref='site',
    image_arg='IMAGE_REFS',
)

# Deploy

helm_resource(
    'vyas-n',
    '.',
    namespace='vyas-n',
    image_keys=[
        ('image.registry', 'image.repository', 'image.tag'),
    ],
    image_deps=[
        'site',
    ],
    flags=[
        '--create-namespace',
    ],
)