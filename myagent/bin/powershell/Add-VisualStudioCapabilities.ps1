[CmdletBinding()]
param()

function Add-TestCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $ShellPath,

        [Parameter(Mandatory = $true)]
        [ref]$Value)

    $directory = [System.IO.Path]::Combine($ShellPath, 'Common7\IDE\CommonExtensions\Microsoft\TestWindow')
    if (!(Test-Container -LiteralPath $directory)) {
        return
    }

    [string]$file = [System.IO.Path]::Combine($directory, 'vstest.console.exe')
    if (!(Test-Leaf -LiteralPath $file)) {
        return
    }

    Write-Capability -Name $Name -Value $directory
    $Value.Value = $directory
}

function Get-VSCapabilities {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(15, 16, 17)]
        [int]$MajorVersion,

        [Parameter(Mandatory = $true)]
        [string]$keyName
    )
    $vs = Get-VisualStudio -MajorVersion $MajorVersion
    if ($vs -and $vs.installationPath) {
        # Add VisualStudio_$($MajorVersion).0.
        # End with "\" for consistency with old ShellFolder values.
        $shellFolder = $vs.installationPath.TrimEnd('\'[0]) + "\"
        Write-Capability -Name "VisualStudio_$($MajorVersion).0" -Value $shellFolder
        $latestVS = $shellFolder
        # Add VisualStudio_IDE_$($MajorVersion).0.
        # End with "\" for consistency with old InstallDir values.
        $installDir = ([System.IO.Path]::Combine($shellFolder, 'Common7', 'IDE')) + '\'
        if ((Test-Container -LiteralPath $installDir)) {
            Write-Capability -Name "VisualStudio_IDE_$($MajorVersion).0" -Value $installDir
            $latestIde = $installDir
        }
    
        # Add VSTest_$($MajorVersion).0.
        $testWindowDir = [System.IO.Path]::Combine($installDir, 'CommonExtensions\Microsoft\TestWindow')
        $vstestConsole = [System.IO.Path]::Combine($testWindowDir, 'vstest.console.exe')
        if ((Test-Leaf -LiteralPath $vstestConsole)) {
            Write-Capability -Name "VSTest_$($MajorVersion).0" -Value $testWindowDir
            $latestTest = $testWindowDir
        }
    }
    else {
        if ((Add-CapabilityFromRegistry -Name "VisualStudio_$($MajorVersion).0" -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName -ValueName 'ShellFolder' -Value ([ref]$latestVS))) {
            $null = Add-CapabilityFromRegistry -Name "VisualStudio_IDE_$($MajorVersion).0" -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName -ValueName 'InstallDir' -Value ([ref]$latestIde)
            Add-TestCapability -Name "VSTest_$($MajorVersion).0" -ShellPath $latestVS -Value ([ref]$latestTest)
        }
    }

    if ($latestVS) {
        Write-Capability -Name 'VisualStudio' -Value $latestVS
    }

    if ($latestIde) {
        Write-Capability -Name 'VisualStudio_IDE' -Value $latestIde
    }

    if ($latestTest) {
        Write-Capability -Name 'VSTest' -Value $latestTest
    }
}

# Define the key names.
$keyName10 = 'Software\Microsoft\VisualStudio\10.0'
$keyName11 = 'Software\Microsoft\VisualStudio\11.0'
$keyName12 = 'Software\Microsoft\VisualStudio\12.0'
$keyName14 = 'Software\Microsoft\VisualStudio\14.0'
$keyName15 = 'Software\Microsoft\VisualStudio\15.0'
$keyName16 = 'Software\Microsoft\VisualStudio\16.0'
$keyName17 = 'Software\Microsoft\VisualStudio\17.0'

# Add the capabilities.
$latestVS = $null
$latestIde = $null
$latestTest = $null
$null = Add-CapabilityFromRegistry -Name 'VisualStudio_10.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName10 -ValueName 'ShellFolder' -Value ([ref]$latestVS)
$null = Add-CapabilityFromRegistry -Name 'VisualStudio_IDE_10.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName10 -ValueName 'InstallDir' -Value ([ref]$latestIde)
$null = Add-CapabilityFromRegistry -Name 'VisualStudio_11.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName11 -ValueName 'ShellFolder' -Value ([ref]$latestVS)
$null = Add-CapabilityFromRegistry -Name 'VisualStudio_IDE_11.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName11 -ValueName 'InstallDir' -Value ([ref]$latestIde)
if ((Add-CapabilityFromRegistry -Name 'VisualStudio_12.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName12 -ValueName 'ShellFolder' -Value ([ref]$latestVS))) {
    $null = Add-CapabilityFromRegistry -Name 'VisualStudio_IDE_12.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName12 -ValueName 'InstallDir' -Value ([ref]$latestIde)
    Add-TestCapability -Name 'VSTest_12.0' -ShellPath $latestVS -Value ([ref]$latestTest)
}

if ((Add-CapabilityFromRegistry -Name 'VisualStudio_14.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName14 -ValueName 'ShellFolder' -Value ([ref]$latestVS))) {
    $null = Add-CapabilityFromRegistry -Name 'VisualStudio_IDE_14.0' -Hive 'LocalMachine' -View 'Registry32' -KeyName $keyName14 -ValueName 'InstallDir' -Value ([ref]$latestIde)
    Add-TestCapability -Name 'VSTest_14.0' -ShellPath $latestVS -Value ([ref]$latestTest)
}

Get-VSCapabilities -MajorVersion 15 -keyName $keyName15

Get-VSCapabilities -MajorVersion 16 -keyName $keyName16

Get-VSCapabilities -MajorVersion 17 -keyName $keyName17

# SIG # Begin signature block
# MIIoQwYJKoZIhvcNAQcCoIIoNDCCKDACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwgL9Nmnw0Xxol
# FSNRX7258ys82s8L5VByx9V5xTx77qCCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
# Bv9XKydyAAAAAAQEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTE0WhcNMjUwOTExMjAxMTE0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0KDfaY50MDqsEGdlIzDHBd6CqIMRQWW9Af1LHDDTuFjfDsvna0nEuDSYJmNyz
# NB10jpbg0lhvkT1AzfX2TLITSXwS8D+mBzGCWMM/wTpciWBV/pbjSazbzoKvRrNo
# DV/u9omOM2Eawyo5JJJdNkM2d8qzkQ0bRuRd4HarmGunSouyb9NY7egWN5E5lUc3
# a2AROzAdHdYpObpCOdeAY2P5XqtJkk79aROpzw16wCjdSn8qMzCBzR7rvH2WVkvF
# HLIxZQET1yhPb6lRmpgBQNnzidHV2Ocxjc8wNiIDzgbDkmlx54QPfw7RwQi8p1fy
# 4byhBrTjv568x8NGv3gwb0RbAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU8huhNbETDU+ZWllL4DNMPCijEU4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMjkyMzAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjmD9IpQVvfB1QehvpC
# Ge7QeTQkKQ7j3bmDMjwSqFL4ri6ae9IFTdpywn5smmtSIyKYDn3/nHtaEn0X1NBj
# L5oP0BjAy1sqxD+uy35B+V8wv5GrxhMDJP8l2QjLtH/UglSTIhLqyt8bUAqVfyfp
# h4COMRvwwjTvChtCnUXXACuCXYHWalOoc0OU2oGN+mPJIJJxaNQc1sjBsMbGIWv3
# cmgSHkCEmrMv7yaidpePt6V+yPMik+eXw3IfZ5eNOiNgL1rZzgSJfTnvUqiaEQ0X
# dG1HbkDv9fv6CTq6m4Ty3IzLiwGSXYxRIXTxT4TYs5VxHy2uFjFXWVSL0J2ARTYL
# E4Oyl1wXDF1PX4bxg1yDMfKPHcE1Ijic5lx1KdK1SkaEJdto4hd++05J9Bf9TAmi
# u6EK6C9Oe5vRadroJCK26uCUI4zIjL/qG7mswW+qT0CW0gnR9JHkXCWNbo8ccMk1
# sJatmRoSAifbgzaYbUz8+lv+IXy5GFuAmLnNbGjacB3IMGpa+lbFgih57/fIhamq
# 5VhxgaEmn/UjWyr+cPiAFWuTVIpfsOjbEAww75wURNM1Imp9NJKye1O24EspEHmb
# DmqCUcq7NqkOKIG4PVm3hDDED/WQpzJDkvu4FrIbvyTGVU01vKsg4UfcdiZ0fQ+/
# V0hf8yrtq9CkB8iIuk5bBxuPMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGiMwghofAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICJH50t7q1rCZZmkez5PrAEa
# u3lBpYIBwcT1nBzDZmziMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAZoMjy3EmIsZlChNYMFzoCQ96Sv+6qcdcWJgQb8V7tpEffJ6Y1pZ8wNVR
# rzwwHRh1fmBcyCCwleuX8XGa7BfMirB+RtfUwwhqUz3cwsY6mn3Tl3E6ypgdVm/d
# XnmMAHQvlIyxJGD7dw7foZ6Qkw274vTvtLgUrVD/DD636f6POAkQPfqF2+NX58tV
# gAdxIXfeG7DARw3srNXFZjgBEeg3TxSaN+us6QVtjsWpxS2ThiBnfaoM5Z6piR76
# utTx3cEVj573YCwlaTsfUloXtiYqSTVOiumjAAd6kdZSx8sQStXX37cLSSmv/srN
# gBWWBTdkhMQ9rEDKHakpTp6e1efi0qGCF60wghepBgorBgEEAYI3AwMBMYIXmTCC
# F5UGCSqGSIb3DQEHAqCCF4YwgheCAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFaBgsq
# hkiG9w0BCRABBKCCAUkEggFFMIIBQQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCD/bRt8Ohw6wNsBwb/iPR9i2pc2Ac47fTvg9XoQILCijgIGZ2K0wuCt
# GBMyMDI1MDExMzEyMTgxNS41MDVaMASAAgH0oIHZpIHWMIHTMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
# Tjo2RjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaCCEfswggcoMIIFEKADAgECAhMzAAAB/Bigr8xpWoc6AAEAAAH8MA0G
# CSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTI0
# MDcyNTE4MzExNFoXDTI1MTAyMjE4MzExNFowgdMxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9w
# ZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjZGMUEt
# MDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAp1DAKLxpbQcPVYPHlJHy
# W7W5lBZjJWWDjMfl5WyhuAylP/LDm2hb4ymUmSymV0EFRQcmM8BypwjhWP8F7x4i
# O88d+9GZ9MQmNh3jSDohhXXgf8rONEAyfCPVmJzM7ytsurZ9xocbuEL7+P7EkIwo
# OuMFlTF2G/zuqx1E+wANslpPqPpb8PC56BQxgJCI1LOF5lk3AePJ78OL3aw/Ndlk
# vdVl3VgBSPX4Nawt3UgUofuPn/cp9vwKKBwuIWQEFZ837GXXITshd2Mfs6oYfxXE
# tmj2SBGEhxVs7xERuWGb0cK6afy7naKkbZI2v1UqsxuZt94rn/ey2ynvunlx0R6/
# b6nNkC1rOTAfWlpsAj/QlzyM6uYTSxYZC2YWzLbbRl0lRtSz+4TdpUU/oAZSB+Y+
# s12Rqmgzi7RVxNcI2lm//sCEm6A63nCJCgYtM+LLe9pTshl/Wf8OOuPQRiA+stTs
# g89BOG9tblaz2kfeOkYf5hdH8phAbuOuDQfr6s5Ya6W+vZz6E0Zsenzi0OtMf5RC
# a2hADYVgUxD+grC8EptfWeVAWgYCaQFheNN/ZGNQMkk78V63yoPBffJEAu+B5xlT
# PYoijUdo9NXovJmoGXj6R8Tgso+QPaAGHKxCbHa1QL9ASMF3Os1jrogCHGiykfp1
# dKGnmA5wJT6Nx7BedlSDsAkCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSY8aUrsUaz
# hxByH79dhiQCL/7QdjAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAT7ss/ZAZ0bTa
# FsrsiJYd//LQ6ImKb9JZSKiRw9xs8hwk5Y/7zign9gGtweRChC2lJ8GVRHgrFkBx
# ACjuuPprSz/UYX7n522JKcudnWuIeE1p30BZrqPTOnscD98DZi6WNTAymnaS7it5
# qAgNInreAJbTU2cAosJoeXAHr50YgSGlmJM+cN6mYLAL6TTFMtFYJrpK9TM5Ryh5
# eZmm6UTJnGg0jt1pF/2u8PSdz3dDy7DF7KDJad2qHxZORvM3k9V8Yn3JI5YLPuLs
# o2J5s3fpXyCVgR/hq86g5zjd9bRRyyiC8iLIm/N95q6HWVsCeySetrqfsDyYWStw
# L96hy7DIyLL5ih8YFMd0AdmvTRoylmADuKwE2TQCTvPnjnLk7ypJW29t17Yya4V+
# Jlz54sBnPU7kIeYZsvUT+YKgykP1QB+p+uUdRH6e79Vaiz+iewWrIJZ4tXkDMmL2
# 1nh0j+58E1ecAYDvT6B4yFIeonxA/6Gl9Xs7JLciPCIC6hGdliiEBpyYeUF0ohZF
# n7NKQu80IZ0jd511WA2bq6x9aUq/zFyf8Egw+dunUj1KtNoWpq7VuJqapckYsmvm
# mYHZXCjK1Eus7V1I+aXjrBYuqyM9QpeFZU4U01YG15uWwUCaj0uZlah/RGSYMd84
# y9DCqOpfeKE6PLMk7hLnhvcOQrnxP6kwggdxMIIFWaADAgECAhMzAAAAFcXna54C
# m0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMy
# MjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
# yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY
# 6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
# cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN
# 7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDua
# Rr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74
# kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2
# K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5
# TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZk
# i1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
# BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3Pmri
# Lq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
# BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9y
# eS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/yp
# b+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
# ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM
# 9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
# OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4
# FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3Uw
# xTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPX
# fx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVX
# VAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGC
# onsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU
# 5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
# ahC0HVUzWLOhcGbyoYIDVjCCAj4CAQEwggEBoYHZpIHWMIHTMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
# Tjo2RjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaIjCgEBMAcGBSsOAwIaAxUATkEpJXOaqI2wfqBsw4NLVwqYqqqggYMw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsF
# AAIFAOsveQYwIhgPMjAyNTAxMTMxMTM1MzRaGA8yMDI1MDExNDExMzUzNFowdDA6
# BgorBgEEAYRZCgQBMSwwKjAKAgUA6y95BgIBADAHAgEAAgILDzAHAgEAAgIUUjAK
# AgUA6zDKhgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQA0+c1cGLt5UGuq
# q14rTJw7ui3qPTChBM2iKZX+10DCitalt1fNOZNxlIJ3G1JBnOUVzuhI5PvoqbX6
# Tm6dY5aKtmMEnQTGgxmj0oJKRg93fU0yp5fDjJNKy78BaSq3mOIOnnELL0Q+DEP0
# mgci6heod1BR9SzTbntJ8u4eFSH7EI60s1HDMVexdS7uAESwZRDxt7LiLFW2LGul
# gk3uL9ynpEg1pI8qruE87W0L+4bZwOfl25d2EpTHYcHUn9cOYgzvxqd0OuW8WQnK
# uf/dCoEQ2fdEf66Isht3VLAl+Vw+H7R7c4L69IlDmLLLS6ljh175LY74ood+pPGS
# H4loAzCkMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAH8GKCvzGlahzoAAQAAAfwwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqG
# SIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgqLKP/0CTxYh1
# 9XrzB9Qvm9Jk1/hy/GgcIsIA14zFjo8wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHk
# MIG9BCCVQq+Qu+/h/BOVP4wweUwbHuCUhh+T7hq3d5MCaNEtYjCBmDCBgKR+MHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB/Bigr8xpWoc6AAEAAAH8
# MCIEIPZ5xKbi0YbTiueX1xiEfNbYD9SES5kJYXZZMsBGUdKLMA0GCSqGSIb3DQEB
# CwUABIICAIMGBZYabUpb88z0MZ8Ks7uVkKHS7I4D6glgGpBojlzRqJjLMP3GGEkv
# L0IIAYgKd09k8PPkLujHJIV3nzwTeIhhl/Tl53UoAmntQ2qZ5Cwwx4iAOIyjai7n
# QphBRreTWHUO5wEEtsAzXySXpOlbKmXvjOAu9gnYatq/Cms9daCkoYu8r90mLlkV
# U/WqvgQ+CI2mPifngF7zLHlaqxUZ+5+wjRHO3f9gmGJX5/VZPzU4GUlAPnM2FXn0
# edVmircJPCOzMEaWI3dLVacSxIyNfmEm2LelnCK0gvsb103kXjaysc+WV82vt/pQ
# UVv8IHXweBg1Qsh7xnt7hORYe/GpTZTaF9ZcT1SWw4gsJDFX8wETivovYHgBvtMk
# svUvRjkOfUI6UenVjTTTft5Dw9iiS6AwPLWzZCPtgHY+fpQtWHGbr2fSouNmSCNr
# soMfWoCSJH4WEvqvTpu4dFNgvSLXSoPW36vHTnlv1xFUe2NYkt09+41XCMU/5Ebo
# 7jhgSxWwYm1yueIpVQCHnT6IHDBXcEcTUgznl7FtxqGuGhusWw3OFJz59rPX7Fja
# S4ZPjbBW/0Rmaz0+E6VXdnHb9S5nQLILv2kpAhDv4KPNqBStcbIyuFvGC7f4pPbQ
# o7bKvqwsNvs0H0mc0xIffdV6GOIpEsODVJjPGrnoT6fJD42cWBjY
# SIG # End signature block
