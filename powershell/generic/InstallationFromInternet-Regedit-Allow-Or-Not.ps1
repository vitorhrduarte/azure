# Allow Install from Internet
Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\.NETFramework\Security\TrustManager\
Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\Security\TrustManager\PromptingLevel' -Name 'Internet' -Value 'Enabled'
Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\.NETFramework\Security\TrustManager\

#Put back all settings was they were
#Do in the end after the APP installation:
Set-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\Security\TrustManager\PromptingLevel' -Name 'Internet' -Value 'Disabled'
Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\.NETFramework\Security\TrustManager\