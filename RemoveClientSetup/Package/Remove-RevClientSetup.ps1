<# 
.SYNOPSIS 
    Uninstall OpenInsight Client 9.4 Roll Up v2 and earlier
.DESCRIPTION 
    Checks the registry and attempts to uninstall 'OpenInsight Development Suite - Client ...'
	and all known MSI packages related to OpenInsight client components.
	Applies to versions 9.3.0 and later.
.EXAMPLE
    Uninstall components and wait:
    .\Remove-RevClientSetup.ps1

    Uninstall components silently:
    .\Remove-RevClientSetup.ps1 1

.NOTES 
	Script has two primary sections. First it processes the registry uninstall branch
    and runs the uninstall program associated with any branch matching 
    "OpenInsight Development Suite - Client x" where X is the version of the 
    script supported. The second stage uses a list of all known MSI packages 
    released since OpenInsight 9.0.0 and attempts to uninstall individual 
    components based on the MSI GUID.

    The script contains an internal list of known MSI GUID’s associated with 
    OpenInsight. The script can also download a XML file containing a list of 
    MSI GUID’s from a web server. Activating this method and hosting the XML 
    file on your company server could enable you to include other MSI packages 
    that must be removed as part of your OpenInsight client release.

    Copyright Notice: 
    Originally provided under Revelation Software Knowledge Base Article KB1017 
    available for download http://www.revelation.com/o4wtrs/KB_Articles/KB1017.htm

    Updated by Jared Bratu

	Updated : 2019-02-05

.LINK 
    
#> 

[CmdletBinding()]
Param(
  	[Parameter(Mandatory=$False,HelpMessage='When true script does not pause for confirmation at end of script.')]
	[int]$SilentMode
)

$UninstallProgramNames = @(	'OpenInsight Development Suite - Client 9.2.1',
							'OpenInsight Development Suite - Client 9.3',
							'OpenInsight Development Suite - Client 9.3.0',
							'OpenInsight Development Suite - Client 9.3.1',
							'OpenInsight Development Suite - Client 9.3.2', 
							'OpenInsight Development Suite - Client 9.4.0');

$UninstallRegBranches = @(	"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
							"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"); 							

#URL of most recent guid library
$XMLStore = "https://www.example.com/files/clientsetupmsiguids.xml";

#If True the MSILibrary is accessed from the Base64 encoded $MSILibraryLocal variable
#Otherise it is downloaded at runtime from $XMLStore url.
$SkipXMLStoreDownload = $True;

$MSIExecExe = "msiexec.exe";

#Base64 Encoded XML file of client setup GUID components
$MSILibraryLocal = 'PE9ianMgVmVyc2lvbj0iMS4xLjAuMSIgeG1sbnM9Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vcG93ZXJzaGVsbC8yMDA0LzA0Ij4gCTxPYmogUmVmSWQ9IjAiPiAJCTxUTiBSZWZJZD0iMCI+IAkJCTxUPlN5c3RlbS5NYW5hZ2VtZW50LkF1dG9tYXRpb24uUFNDdXN0b21PYmplY3Q8L1Q+ICAgICAgIDxUPlN5c3RlbS5PYmplY3Q8L1Q+IAkJPC9UTj4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5pZHhzZXRzX3NldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPntDQTMyM0IxQS0yRkYwLTRCMkUtQjlBQi1FODNDQzA1RUU4Qzd9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0NCNTg0MEVCLTJFMDEtNEM5Ni1CMEMzLUFGMTE5QzY2Q0U5N308L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMSI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPm5ldGxhdW5jaGVyX3NldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC4wPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezEyN0M1OTk2LTUzMTktNEVGMi05RUQwLTZDRjZEMDZDMkE2NH08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57MTAzMDBDQzYtNjgzMC00OERELUFGRUItNkE2QkE4MDY1MTMzfTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIyIj4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+bmV0b2lzZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjg8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57MDgwMENEQTktMTdEQi00MkI0LUEyM0YtNEZFNEY5MDlBRTc2fTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntERjM0QzcyOS0zMUJELTQyNEQtODIzQS01OTM0RkQ1NjkxQzh9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjMiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5vaXBpc2V0dXA1LjUubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+NS41PC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+e0Q5ODRFRjJELUZEMjYtNDk3Ri1BQzIzLTA5MEI5QzYwMzk0Nn08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57QzNDM0FEOUMtN0MzNy00OUY3LUI4ODktMzI2MDFDMjc4MDg1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSI0Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+cmV2ZG90bmV0c2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+MS44PC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+e0EyMzE0OTZDLTdGM0MtNDZERS1BQ0RBLUNEREEzMjA5RUU5RX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57NDY5OUI0NTMtNTU2NS00ODc2LUE1RDItRDA0NjQ0MTgzQjc1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSI1Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+aWR4U2V0c19TZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjI8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57NkUxQjc1RjMtN0FBNy00OTM0LUE4M0UtMTkzQzZENjI5MTVGfTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntDQjU4NDBFQi0yRTAxLTRDOTYtQjBDMy1BRjExOUM2NkNFOTd9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjYiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5vaXBpc2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+NS4zPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezhBMDQ4MEE0LTMxODMtNDNEMS1CN0JELTVDRjNGN0VEQzNFNH08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57QzNDM0FEOUMtN0MzNy00OUY3LUI4ODktMzI2MDFDMjc4MDg1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSI3Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+cmV2ZG90bmV0c2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+MS44LjE8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57QzREQkY3RDMtRjU0Qy00QjlDLTk4NDEtMTVGODY5MTg0MjI1fTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPns0Njk5QjQ1My01NTY1LTQ4NzYtQTVEMi1EMDQ2NDQxODNCNzV9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjgiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5OZXRPSVNldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjIuMDwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnsyNTc0Q0MyNC0zQjMzLTQwRUItQUJDNy1FMzJCMzcwNEU3RDV9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RGMzRDNzI5LTMxQkQtNDI0RC04MjNBLTU5MzRGRDU2OTFDOH08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iOSI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPk9JUElTZXR1cDYuMC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj42LjA8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57OEJBQjFGQUQtMTc4Mi00M0QxLUFGNzQtRDkxMTcxRTJGQTk4fTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntDM0MzQUQ5Qy03QzM3LTQ5RjctQjg4OS0zMjYwMUMyNzgwODV9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjEwIj4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+b2l2YmdlY2tvX3NldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC4yPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezg5MUI1OEYxLTkzNjQtNDIxMS1BQ0Q4LUYyQjNCNzRGODlDRH08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57NkUwOEFGMDQtN0M1QS00NTY0LThCMUYtNkQ5MTlGRUMxQUNDfTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIxMSI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPmlkeFNldHNfU2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+MS4zPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezQyMDE0RTNFLTQwNEEtNDY0RC05QTE3LThBRjg2NDFDMjY3NX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57Q0I1ODQwRUItMkUwMS00Qzk2LUIwQzMtQUYxMTlDNjZDRTk3fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIxMiI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPm9pcGlzZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj41LjE8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57NjMyRkM3NjItOUM0NS00QkFELUIyQ0EtMkUwRDg4QUE1MDc3fTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntDM0MzQUQ5Qy03QzM3LTQ5RjctQjg4OS0zMjYwMUMyNzgwODV9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjEzIj4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+b2l2YmdlY2tvX3NldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC4zPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezlFNDkyRjg5LTE5MkQtNDIzQi05OTMxLTlDOUM0QjQ1NEExMX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57NkUwOEFGMDQtN0M1QS00NTY0LThCMUYtNkQ5MTlGRUMxQUNDfTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIxNCI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPlJldmVsYXRpb25Eb3ROZXQ0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS4zLjAyNjwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnsxNkNBOUQ1QS0zNDcwLTQ0QzUtQkE2OC04Nzg1MDQzM0RFOTN9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+ezUzRjA0ODg2LTkzQzktNDcwQi1BN0IyLUNFOTVBQUEwMjYwM308L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMTUiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5SZXZlbGF0aW9uRG90TmV0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS4zLjAzODwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnszOTVGMkMwNS0wN0M0LTQ0NTItQjk1RC1DQkNGRDE4N0Q3NUZ9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RDN0JFRkJDLUU5MDQtNDQyNS04NDA2LUZEMjBGQjk3RTMxNX08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMTYiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5SVElERVJDbGllbnRTZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjEuMzwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnswRDcxMzM0Ny1EMjAyLTQwNTktODU5OC0yRDM0MzA3QTFEQTZ9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RGMUI0NEY1LTMzQzctNEVCMi04RTQyLTc5QUU4MkZGNEE0Nn08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMTciPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5PSUJGU0hlbHBlclNldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC41PC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+e0Q2MzIxMzI1LTVEOUQtNDBBNi05MTM2LUNBMTQwOTlCNzU0MX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57REE0NDdFRTUtQUMyNi00NzUwLTgxMzctOUZFM0Q2RUNCRTU2fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIxOCI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPk9JUElTZXR1cDUuNC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj41LjQ8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57QzU5NkQ2RDgtREU1Mi00MzIzLTg1QjEtODE1NjlDNkFCNDBDfTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntDM0MzQUQ5Qy03QzM3LTQ5RjctQjg4OS0zMjYwMUMyNzgwODV9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjE5Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+UmV2ZWxhdGlvbkRvdE5ldDRTZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj45LjMuMTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnsyNzM0RDgxMC0xNzVGLTQxQTQtOEQ1OC0yQkIyQ0FFRDMwQkJ9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+ezUzRjA0ODg2LTkzQzktNDcwQi1BN0IyLUNFOTVBQUEwMjYwM308L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMjAiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5SZXZlbGF0aW9uRG90TmV0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS4zLjEwMjwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnsyRjAyMkVEOC01MjA0LTQ2MzYtQjI3Ri0xNzMzMzA5NDMxMkV9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RDN0JFRkJDLUU5MDQtNDQyNS04NDA2LUZEMjBGQjk3RTMxNX08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMjEiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5SVElERVJDbGllbnRTZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjEuMzwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnswM0NGMTE1MS1BNkY5LTQ2RTAtQjM3NS0zRDZGQTExMDhBQzl9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RGMUI0NEY1LTMzQzctNEVCMi04RTQyLTc5QUU4MkZGNEE0Nn08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMjIiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5PSUJGU0hlbHBlclNldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC42PC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezgyQjU2NTIyLTY5NEUtNDMxRC05RjM2LUI3NTcyNDgwREEzOX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57REE0NDdFRTUtQUMyNi00NzUwLTgxMzctOUZFM0Q2RUNCRTU2fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIyMyI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPlJldmVsYXRpb25Eb3ROZXQ0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS4zLjI8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57NjYyMjBEMUMtMjhFNi00MUFELUI1QjQtOEQ1MEY0Q0YyREUwfTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPns1M0YwNDg4Ni05M0M5LTQ3MEItQTdCMi1DRTk1QUFBMDI2MDN9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjI0Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+UmV2ZWxhdGlvbkRvdE5ldFNldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjkuMy4yPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezVDQkRBOUU3LTk1NjQtNDU0Qi05NEY1LUVFNDYwQkE4QjlCOH08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57REM3QkVGQkMtRTkwNC00NDI1LTg0MDYtRkQyMEZCOTdFMzE1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIyNSI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPlJldmVsYXRpb25Eb3ROZXQ0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS40LjA8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57MjJENTJDMjQtMDEzNS00MjI1LUI1RTAtMzdFM0I3NDA4NTcxfTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPns1M0YwNDg4Ni05M0M5LTQ3MEItQTdCMi1DRTk1QUFBMDI2MDN9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjI2Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+UmV2ZWxhdGlvbkRvdE5ldFNldHVwLm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjkuNC4wPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezkzNEQyNUQzLUEzRUUtNDczOC1BQTBGLTFGMUQxREQzMENCOX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57REM3QkVGQkMtRTkwNC00NDI1LTg0MDYtRkQyMEZCOTdFMzE1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIyNyI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPk9JQkZTSGVscGVyU2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+MS4wLjc8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57RjVBOUI3OEYtMUFDMi00MTU2LTk1OEEtM0U4OEI4QUIxNUU2fTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntEQTQ0N0VFNS1BQzI2LTQ3NTAtODEzNy05RkUzRDZFQ0JFNTZ9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjI4Ij4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+T0lQSVNldHVwNC42Lm1zaTwvUz4gICAgICAgPFMgTj0iUHJvZHVjdFZlcnNpb24iPjEuMC4wPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezZBQUVBMzdCLTBBRDItNDY1NC05QUM0LTI4OEQ4MjUxMTQ1Q308L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57QzNDM0FEOUMtN0MzNy00OUY3LUI4ODktMzI2MDFDMjc4MDg1fTwvUz4gCQk8L01TPiAJPC9PYmo+IAk8T2JqIFJlZklkPSIyOSI+IAkJPFROUmVmIFJlZklkPSIwIiAvPiAJCTxNUz4gCQkJPFMgTj0iRmlsZU5hbWUiPmlkeFNldHNfU2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+MS4wLjA8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RDb2RlIj57NERCMDNDM0QtQzBEMi00MTZELTkxN0ItN0RCQ0NEQzRBMzcxfTwvUz4gICAgICAgPFMgTj0iVXBncmFkZUNvZGUiPntDQjU4NDBFQi0yRTAxLTRDOTYtQjBDMy1BRjExOUM2NkNFOTd9PC9TPiAJCTwvTVM+IAk8L09iaj4gCTxPYmogUmVmSWQ9IjMwIj4gCQk8VE5SZWYgUmVmSWQ9IjAiIC8+IAkJPE1TPiAJCQk8UyBOPSJGaWxlTmFtZSI+TmV0T0lTZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjAuMDwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPns3M0IwQkU3Ri1EM0I3LTQ3NEYtQUQ3Mi1DN0RDNjdEMzY0Qjh9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+e0RGMzRDNzI5LTMxQkQtNDI0RC04MjNBLTU5MzRGRDU2OTFDOH08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMzEiPiAJCTxUTlJlZiBSZWZJZD0iMCIgLz4gCQk8TVM+IAkJCTxTIE49IkZpbGVOYW1lIj5SZXZEb3ROZXRTZXR1cC5tc2k8L1M+ICAgICAgIDxTIE49IlByb2R1Y3RWZXJzaW9uIj4xLjAuMDwvUz4gICAgICAgPFMgTj0iUHJvZHVjdENvZGUiPnsyMjgwNjFCMi1BNUM3LTQyRDItQTJEMi00OTBBRDVGNDk1MDh9PC9TPiAgICAgICA8UyBOPSJVcGdyYWRlQ29kZSI+ezQ2OTlCNDUzLTU1NjUtNDg3Ni1BNUQyLUQwNDY0NDE4M0I3NX08L1M+IAkJPC9NUz4gCTwvT2JqPiAJPE9iaiBSZWZJZD0iMzIiPiAgICAgPFROIFJlZklkPSIwIj4gICAgICAgPFQ+U3lzdGVtLk1hbmFnZW1lbnQuQXV0b21hdGlvbi5QU0N1c3RvbU9iamVjdDwvVD4gICAgICAgPFQ+U3lzdGVtLk9iamVjdDwvVD4gICAgIDwvVE4+ICAgICA8TVM+ICAgICAgIDxTIE49IkZpbGVOYW1lIj5SZXZlbGF0aW9uRG90TmV0U2V0dXAubXNpPC9TPiAgICAgICA8UyBOPSJQcm9kdWN0VmVyc2lvbiI+OS41PC9TPiAgICAgICA8UyBOPSJQcm9kdWN0Q29kZSI+ezk1Q0NBMjIwLTI3QTQtNEQ4OS1CNEM0LUVDQzJFMDgzOTdERX08L1M+ICAgICAgIDxTIE49IlVwZ3JhZGVDb2RlIj57REM3QkVGQkMtRTkwNC00NDI1LTg0MDYtRkQyMEZCOTdFMzE1fTwvUz4gICAgIDwvTVM+ICAgPC9PYmo+IDwvT2Jqcz4=';

#Cast the int back to a boolean
If($SilentMode -eq 1) {
    SilentMode = $true;
} else {
    $SilentMode = $false;
}

#Script can only run in elevated security context
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
	if (-not $SilentMode) {
		#Re-run script in new context and exit this context
		$arguments = "-ExecutionPolicy Bypass -File " + $myinvocation.mycommand.definition + ""		
		Start-Process powershell -Verb runAs -ArgumentList $arguments
		Break		
	} else {
		exit 5;
	}
}

#
# Define Required Functions - Start
#
function downloadFile($url, $targetFile)
{ 
	#Copied from
	#http://blogs.msdn.com/b/jasonn/archive/2008/06/13/downloading-files-from-the-internet-in-powershell-with-progress.aspx
	
    "Downloading $url" 
    $uri = New-Object "System.Uri" "$url" 
    $request = [System.Net.HttpWebRequest]::Create($uri) 
    $request.set_Timeout(15000) #15 second timeout 
    $response = $request.GetResponse() 
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024) 
    $responseStream = $response.GetResponseStream() 
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create 
    $buffer = new-object byte[] 10KB 
    $count = $responseStream.Read($buffer,0,$buffer.length) 
    $downloadedBytes = $count 
    while ($count -gt 0) 
    { 
        [System.Console]::CursorLeft = 0 
        [System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength) 
        $targetStream.Write($buffer, 0, $count) 
        $count = $responseStream.Read($buffer,0,$buffer.length) 
        $downloadedBytes = $downloadedBytes + $count 
    } 
    "`nFinished Download" 
    $targetStream.Flush()
    $targetStream.Close() 
    $targetStream.Dispose() 
    $responseStream.Dispose() 
}

#
# Define Required Functions - End
#

#
# Main Program Logic
#

$tempFile = [IO.Path]::GetTempFileName()

If ($SkipXMLStoreDownload -eq $False) {
    #Try to download an up-to-date list of client setup GUIDs

	$ErrorActionPreferenceOrig = $ErrorActionPreference ; $ErrorActionPreference = "stop"
	try {
		downloadFile $XMLStore $tempFile;
	} catch {
		Write-Host "Download failed. Reverting to local copy."
		$SkipXMLStoreDownload = $true;
	}
	$ErrorActionPreference = $ErrorActionPreferenceOrig ;
	
	If(	
		((Get-Item $tempFile).Length -eq 0) -and 
		($SkipXMLStoreDownload -eq $False)
		){
		Write-Host "Download failed. File contains no data. Reverting to local copy."
		$SkipXMLStoreDownload = $true;
	}
}

If ($SkipXMLStoreDownload -eq $True) {
    #Deserialize the encoded list of GUIDs to un-install

	$Bytes = [System.Convert]::FromBase64String($MSILibraryLocal);
	$MsiLibrary = [System.Text.Encoding]::UTF8.GetString($bytes); 
	$MsiLibrary | Set-Content $tempFile;
	
}

$XMLStore = $tempFile
$MsiLibrary = Import-Clixml -Path $XMLStore;

#Loop through registry and call uninstall program of ClientSetup.exe programs
ForEach ($Entry in $UninstallProgramNames) {

	#Modified from
	#http://stackoverflow.com/questions/2246768/finding-all-installed-applications-with-powershell

	$ChildItems = Get-ChildItem $UninstallRegBranches -ErrorAction SilentlyContinue

	$x = (
		$ChildItems | 
		foreach { 
			
			$PSPath = $_.PSPath;
			Try {
				Get-ItemProperty $PSPath
			} Catch [System.InvalidCastException] {
				#Cast error. Ignore this registry entry
				#Write-Host "Cast Error : $PSPath";
			}
			
		} |
		select DisplayName,UninstallString |
		where { $_.DisplayName -eq "$Entry" }
	);
	
	If (($x -ne $null ) -and ($x.UninstallString | Get-Member)){
		$exe = $($x.UninstallString);
		
		If ((Test-Path $exe -ErrorAction SilentlyContinue) -eq $False) {
			Write-Host "Program ""$Entry"" is orphaned. Program listed in registry but installer ""$exe"" doesn't exist.";
		} else {
			$args = "/S";		
			Write-Host "Running uninstall of $exe for $entry";
			Start-Process $exe $args -wait;
		}
	}
}

Write-Host "Non-MSI uninstall process Finished.";

$exe = $MSIExecExe;

$AlreadyProcessed = @();

#
#Uninstall each known MSI GUID
#This is a brute force method to ensure there aren't any lingering components left
ForEach ($Entry in $MsiLibrary) {

	if ($AlreadyProcessed -notcontains $($Entry.ProductCode)) {
		$args = "/qb- /x " + $($Entry.ProductCode) + "";
		Write-Host $exe $args;
		Start-Process $exe $args -wait;
		$AlreadyProcessed += $($Entry.ProductCode);
	}
}

if (-not $SilentMode) {
	Write-Host "Process Finished. Press <enter> to exit.";
	$x = Read-Host;
}

exit 0;