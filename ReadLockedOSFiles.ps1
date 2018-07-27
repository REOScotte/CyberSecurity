# This all needs to run from an elevated PowerShell session
# While windows is running, the OS lockes files like the registry files located in
# C:\Windows\System32\config. Using Shadow Copies, these files can copied from a live
# system for analysis without shutting down the system. All commands used here are native
# to the OS.

# Create the ShadowCopy.
# Note the C:\ path. You can snap a different drive, but specifying
# a specific path doesn't change anything since the shadows
# are done at the volume level.

(Get-WmiObject -List Win32_ShadowCopy).Create("C:\", "ClientAccessible")

# __GENUS          : 2
# __CLASS          : __PARAMETERS
# __SUPERCLASS     :
# __DYNASTY        : __PARAMETERS
# __RELPATH        :
# __PROPERTY_COUNT : 2
# __DERIVATION     : {}
# __SERVER         :
# __NAMESPACE      :
# __PATH           :
# ReturnValue      : 0
# ShadowID         : {CC3E05D0-2981-4F6B-90D5-A329CD5E08CF}
# PSComputerName   :

# View the ShadowCopies.
# You're basically looking for the last one in the list. Note ShadowID above
# should match the Shadow Copy ID below. I'm sure this could be parsed out
# with PowerShell, but what we really want is the Shadow Copy Volume path.

vssadmin list shadows

# vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool
# (C) Copyright 2001-2013 Microsoft Corp.
#
# Contents of shadow copy set ID: {48558a2c-943c-4c64-a9cf-2e3779a4ac6a}
#    Contained 1 shadow copies at creation time: 7/16/2018 11:00:43 AM
#       Shadow Copy ID: {cc3e05d0-2981-4f6b-90d5-a329cd5e08cf}
#          Original Volume: (C:)\\?\Volume{da3d9d84-e2a1-4623-bc29-ceac0085c038}\
#          Shadow Copy Volume: \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy5
#          Originating Machine: 9S0Y6H2
#          Service Machine: 9S0Y6H2
#          Provider: 'Microsoft Software Shadow Copy provider 1.0'
#          Type: ClientAccessible
#          Attributes: Persistent, Client-accessible, No auto release, No writers, Differential

# Create a symbolic link to the ShadowCopy
# Once we have the path, set it as the target of a symbolic link, as below.
# Note that C:\Shadow doesn't have to pre-exist, and for that matter, you
# can use any path you'd like.
# Also note that mklink is built into cmd, which is why this has to be wrapped in a call to cmd.exe

cmd /c "mklink /d C:\Shadow \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy5\"

# symbolic link created for C:\Shadow <<===>> \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy5\

# You can now browse C:\Shadow as a copy of the drive that can be copied from.
# When you're done, this removes the symbolic link. Again, this has to be wrapped in a call
# to cmd since in PowerShell, rmdir is an alias to Remove-Item and will remove the contents of the
# shadow copy and not just the symbolic link.

cmd /c "rmdir C:\Shadow"
