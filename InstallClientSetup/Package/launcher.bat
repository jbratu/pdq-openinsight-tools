REM For non-domain joined workstations authenticate with the server
REM net use \\jdp4800\IPC$ %PASSWORD% /user:%USERNAME%

REM Change to the OpenInsight shared directory
pushd \\jdp4800\Revsoft\OInsight94

REM Launch the clientsetup.exe and post the results back to a file
clientsetup.exe /S /E=\\jdp4800\Purgatory\InstallClientSetup\Results\%COMPUTERNAME%.txt /G=0 /O="\\jdp4800\Revsoft\OInsight94" /A=1 /D=C:\Revsoft\OI Client

popd