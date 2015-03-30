name             'etherpad-lite'
maintainer       'OpenWatch FPC'
maintainer_email 'jj@chef.io'
license          'Apache 2.0'
description      'Installs etherpad-lite'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.1'

depends         'nodejs'
depends         'database'
depends         'postgresql'
depends         'npm'
depends         'nginx'
depends         'runit'

# Check README.md for attributes
