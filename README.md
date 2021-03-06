# secure-wordpress

It is not Wordpress's fault that your self-hosted instance is insecure. Wordpress is not insecure, people are.

Overview of Recommendations:

1. Buy a VPS with Wordpress already baked in, like at [Digital Ocean](https://www.digitalocean.com/).
2. Lock down the VPS. Turn off root ssh. Create a wp user. Lock down apache or replace it with nginx and lock down nginx. Change the default ports. Install [fail2ban](http://www.fail2ban.org/) and [ufw](https://help.ubuntu.com/community/UFW).
3. Lock down MySQL (runs Wordpress). Keep your VPS up-to-date with unattended-upgrades package.
4. Do the Wordpress web install on the VPS and then immediately lock it down with the [recommended plugins](recommended-plugins.md).


### Details

check out [enchilada.md](enchilada.md) to get the complete guide for apache, nginx, and the linux virtual server itself.

check out [recommended-plugins.md](recommended-plugins.md) for just the plugins you should install at a minimum post-install.
