# AMInstaller
AMInstaller is a bash script which installs and configures AirMessage.

# Usage

> GUI Version Coming Soon

## CLI Version
Open cli.sh in your favourite code editor and modify these variables.

```
AM_PASS
SUDOPASS
```

Optionally you can modify these variables as well.

```
AM_SF
AM_PORT
AM_AUTO_UPDATE
AM_SERVER_ADDR (Either IP or Domain)
AM_VERSION (If a newer version is available. Support to find latest version will come soon)
```

## Usage
Open Terminal
```
$ cd /path/to/cli.sh
$ chmod a+x cli.sh # (Only do this once)
$ ./cli.sh
```
After the installation, I suggest letting the script open AirMessage for you. 
This way it will ensure you get prompted to enable the required accessibility features in System Preferences.
