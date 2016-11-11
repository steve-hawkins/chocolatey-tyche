This repository contains source code and templates for building a
[Chocolatey](http://chocolatey.org) package for Tyche.
The package can be installed by running
`choco install Tyche`.

The Tyche Chocolatey package simply kicks off the `TycheInstaller.exe` installer.
To upgrade Tyche once installed with Chocolatey simply run
`choco upgrade Tyche`.

There are some optional install arguments and package package parameters.
Examples are given in the packages.config, which can also be used as follows
`choco install packages.config`

## Building

To build an Tyche chocolatey package, you'll need access to a Windows machine
with the following tools:

### Requirements

+ [Chocolatey](http://chocolatey.org/)
  + You will need to close and reopen your command prompt or PowerShell window
    after installing.

### Instructions

1. Clone this repository
2. Publish an Tyche release that includes an `TycheInstaller.exe` file
3. Update the MD5 checksum in the tools\chocolateyinstall.ps1
4. Update the version number in the tyche.nuspec file
5. Run `choco pack`

### Publishing

Follow [these](https://github.com/chocolatey/chocolatey/wiki/CommandsPush)
instructions to setup your API key so you can publish. You can find
your API key in your chocolatey [account page](https://chocolatey.org/account).

Once you've built the `.nupkg` file you can push it up the chocolatey by
running:

```
choco push .\Tyche.0.XXX.0.nupkg
```
