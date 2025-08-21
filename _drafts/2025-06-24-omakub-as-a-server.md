# Omakub as a Server

Steps of what I did to setup the Minisforum:

* Install Ubuntu 24.04 LTS
* Configured Omakub following the [Omakub documentation](https://omakub.org/) to have a working machine.
  * The machine is quite good. I could just get started and installed kkiosk and run bin/check successfully. I still don't know if Postgres
* Installed `vim`

## Changes applied to use it as a server

* Updated the system:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install unattended-upgrades
```

* Enabled automatic security updates:

```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

* SKIPPED: configure static ip address

* Installed and enabled ssh:

```bash
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

* Disabled login via password:

```erb
sudo vim /etc/ssh/sshd_config

PasswordAuthentication no
```

```bash
sudo systemctl restart ssh
```

I did not change port number or disabled root login.

* Installed fail2ban:

```bash
sudo apt install fail2ban
```
