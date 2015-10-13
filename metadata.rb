name             'etherpad-lite'
maintainer       'OpenWatch FPC'
maintainer_email 'jj@chef.io'
license          'Apache 2.0'
description      'Installs etherpad-lite'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.3.0'

depends         'nodejs', '= 2.4.2'
depends         'database', '= 4.0.9'
depends         'postgresql', '= 3.4.16'
depends         'npm', '= 0.1.2'
depends         'nginx', '= 2.7.6'
depends         'runit', '= 1.7.2'

# Check README.md for attributes
