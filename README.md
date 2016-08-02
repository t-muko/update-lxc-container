# update-lxc-container
A script to perform release upgrade on Ubuntu LXC container

The script mounts the LXC container root filesystem and required proc, sysfs and devpts from the host
system to the container so that LXC container can be upgraded offline using host system's networking
functions. As the LXC container is not running during the upgrade, all services should upgrade
without issues.

Known issues:
- If container was using bridge networking, the /etc/resolve.conf may be pointing to an invalid DNS server,
  which causes do-release-upgrade to claim that no upgrades were available. Manually edit resolf.conf to fix.
