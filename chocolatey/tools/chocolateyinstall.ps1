$ErrorActionPreference = 'Stop';
$arguments = @{}
$packageParameters = $env:chocolateyPackageParameters
$installArguments  = $env:chocolateyInstallArguments

$packageName     = 'Tyche'
$fileType        = 'exe'
$softwareName    = 'Tyche*'
$softwareVersion = $env:chocolateyPackageVersion
$url             = "http://server-where-tyche-is.com/tyche/$($softwareVersion)/TycheInstaller.exe"
$silentArgs      = '/VERYSILENT /COMPONENTS=""'
$toolsDir        = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$installPath     = [System.IO.Path]::Combine($env:ProgramFiles, 'Marriott Sinclair\Tyche')
$osArchitecture  = Get-OSArchitectureWidth

If (!($osArchitecture = '64')) {
  Write-Error "64 bit system check failed, $softwareName requires a 64bit Windows..."
} Else {
  Write-Warning "64 bit system check passed"
}

If ($installArguments) {
  $match_pattern = "\/(?<option>([a-zA-Z]+))=(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
  $option_name = 'option'
  $value_name = 'value'

  If ($installArguments -Match $match_pattern) {
    $results = $installArguments | Select-String $match_pattern -AllMatches
    $results.Matches | % {
      $arguments.Add(
        $_.Groups[$option_name].Value.Trim(),
        $_.Groups[$value_name].Value.Trim())
    }
  } Else {
    Throw "Install Arguments were found but were invalid (REGEX Failure)"
  }
  If ($arguments.ContainsKey("DIR")) {
    Write-Warning "DIR Argument Found"
    $installPath = $arguments["DIR"]
  }
}

If ($packageParameters) {
  $match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
  $option_name = 'option'
  $value_name = 'value'

  If ($packageParameters -Match $match_pattern) {
    $results = $packageParameters | Select-String $match_pattern -AllMatches
    $results.Matches | % {
      $arguments.Add(
        $_.Groups[$option_name].Value.Trim(),
        $_.Groups[$value_name].Value.Trim())
    }
  } Else {
    Throw "Package Parameters were found but were invalid (REGEX Failure)"
  }
  If ($arguments.ContainsKey("licenceID")) {
    Write-Warning "licencePath Parameter Found"
    $licenceID = $arguments["licenceID"]
  }
  If ($arguments.ContainsKey("licencePass")) {
    Write-Warning "licencePass Parameter Found"
    $licencePass = $arguments["licencePass"]
  }
} Else {
  Write-Warning "No Package Parameters Passed in"
}

$packageArgs = @{
  packageName    = $packageName
  fileType       = $fileType
  silentArgs     = $silentArgs
  url            = $url
  validExitCodes = @(0)
  checksum       = ''
  checksumType   = 'md5'
}

$local_key       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

$key = Get-ItemProperty -Path @($machine_key6432, $machine_key, $local_key) `
                        -ErrorAction SilentlyContinue `
                        | ? { $_.DisplayName -Like "$softwareName" }

If ($key.Count -ge 1) {
  Write-Warning "$packageName has already been installed by other means."
} Else {
  Try {
    Install-ChocolateyPackage @packageArgs

    If ($packageParameters) {
      $licenceFile = [System.IO.Path]::Combine($toolsDir, 'licence.txt')
      $encoding = [System.Text.Encoding]::UTF8
      $xmlWriter = New-Object System.XMl.XmlTextWriter($licenceFile, $encoding)

      $xmlWriter.Formatting = 'Indented'
      $xmlWriter.Indentation = 2
      $xmlWriter.IndentChar = " "

      $xmlWriter.WriteStartDocument()

      $xmlWriter.WriteStartElement('TycheLicenceDetails')
      $xmlWriter.WriteAttributeString("xmlns", "i", `
          "http://www.w3.org/2000/xmlns/", `
          "http://www.w3.org/2001/XMLSchema-instance")

      $xmlWriter.WriteStartElement('InstallationName')
      $xmlWriter.WriteAttributeString("i:nil", "true")
      $xmlWriter.WriteEndElement()
      $xmlWriter.WriteElementString('LicenceID', $licenceID)
      $xmlWriter.WriteElementString('Password', $licencePass)

      $xmlWriter.WriteEndElement()

      $xmlWriter.WriteEndDocument()
      $xmlWriter.Flush()
      $xmlWriter.Close()
    }

    $tychelicenser = [System.IO.Path]::Combine($installPath, 'TycheLicenser.exe')
    & $tycheLicenser -load $licenceFile -acceptEULA
  } Catch {
    Throw "Failed to install software $softwareName"
  }
}
