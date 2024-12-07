Currently supported: OpenBSD, FreeBSD
Planned: NetBSD

OpenBSD:
Copy directory 'openbsd/openpngstudio' into '/usr/ports/multimedia/', make sure
e.g. 'Makefile' is as follows '/usr/ports/multimedia/openpngstudio/Makefile'.
Now cd into it, run 'make', then 'make package' and finally 'make install'

FreeBSD:
Copy directory 'freebsd/openpngstudio' into '/usr/ports/multimedia/', make sure
e.g. 'Makefile' is as follows '/usr/ports/multimedia/openpngstudio/Makefile'.
Now cd into it, run 'make install-missing-packages', then 'make', then
'make package' and finally 'make install'

Finish:
You should now have executable '/usr/local/bin/OpenPNGStudio' present
Assets can be found in '/usr/local/share/openpngstudio/'

Notes:
I wasn't sure where to exactly put assets, so I just put them in
'/usr/local/share'

If there is a way to use latest commit instead of hash, that would be great!
Not an issue either way
