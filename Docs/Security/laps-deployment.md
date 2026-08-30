# Windows LAPS Deployment

## Summary

This document describes the deployment and validation of Windows Local Administrator Password Solution (Windows LAPS) in the `corp.ethetic.com` Active Directory lab.

The goal was to eliminate reuse of the same local administrator password across multiple workstations and replace it with unique, automatically managed credentials.

## Environment

- Domain: `corp.ethetic.com`
- Domain controller: `DC01`
- Managed workstations:
  - `CLIENT01`
  - `ADMIN01`
- Managed local account:

```text
LabLocalAdmin
```

- Authorized retrieval group:

```text
LAPS Password Readers
```

## Initial Risk

A local administrator account named:

```text
LabLocalAdmin
```

was created on both workstations with the same initial password.

This intentionally demonstrated a common lateral-movement risk:

```text
Same local admin username
+
same password
+
multiple computers
```

If one workstation's credential is exposed, the same credential may work on another workstation.

## Active Directory Preparation

The Windows LAPS Active Directory schema was prepared using:

```powershell
Update-LapsADSchema
```

Computer objects were then granted permission to update their own LAPS attributes within:

```text
OU=Workstations,OU=Computers,OU=Ethetic,DC=corp,DC=ethetic,DC=com
```

using:

```powershell
Set-LapsADComputerSelfPermission
```

## Delegated Password Retrieval

A dedicated security group was created:

```text
LAPS Password Readers
```

The administrative account used for the lab was added to this group.

Read/decryption rights for the workstation OU were delegated to this group.

This avoids giving every user or administrator unrestricted access to managed local administrator credentials.

## Group Policy

A GPO was created:

```text
Workstation - Windows LAPS
```

and linked to:

```text
Ethetic
└── Computers
    └── Workstations
```

Configured settings included:

- Backup directory: Active Directory
- Administrator account name: `LabLocalAdmin`
- Password length: approximately 20 characters
- Password complexity enabled
- Password age / rotation interval configured
- Password encryption enabled
- Authorized decryptors: `CORP\LAPS Password Readers`

## Policy Application

Group Policy was refreshed on:

```text
CLIENT01
ADMIN01
```

The workstation computer objects were then checked in Active Directory Users and Computers using the Windows LAPS interface.

## Troubleshooting

Initially, the LAPS interface displayed a message indicating that the current user did not have permission to decrypt the password.

The issue was not with LAPS itself.

The session was logged in using:

```text
CORP\Administrator
```

while the authorized decryptor group contained:

```text
CORP\jamousk
```

After using the authorized administrative identity, password retrieval worked correctly.

This demonstrated that LAPS retrieval permissions are enforced separately from simply being an administrator.

## Validation

LAPS generated different passwords for:

```text
CLIENT01
ADMIN01
```

This confirmed that password reuse had been removed.

Password rotation was also tested by expiring the managed password and refreshing policy.

After rotation, the affected workstation received a new local administrator password.

## Security Benefit

Before LAPS:

```text
CLIENT01 LabLocalAdmin password = shared password
ADMIN01  LabLocalAdmin password = shared password
```

After LAPS:

```text
CLIENT01 LabLocalAdmin password = unique random password
ADMIN01  LabLocalAdmin password = different unique random password
```

Compromising one local administrator credential therefore no longer automatically provides the same credential for another managed workstation.

## Operational Use

The managed local account can be useful when:

- Domain authentication on a workstation is broken
- A device has temporarily lost domain connectivity
- Local recovery or troubleshooting is required
- Helpdesk staff need controlled local administrator access

LAPS does not replace domain administrative accounts.

It specifically addresses management of local administrator passwords.

## Limitations / Considerations

If Active Directory itself is unavailable, an AD-backed LAPS password may not be retrievable at that moment.

Organizations should therefore consider their recovery procedures and privileged-access design alongside LAPS.

## Lessons Learned

The main value of LAPS is not simply "random passwords."

It changes local administrator access from:

```text
One reusable secret shared across machines
```

to:

```text
Unique machine-specific credentials
+
automatic rotation
+
controlled retrieval
```

This significantly reduces credential-reuse and lateral-movement risk.

## Skills Demonstrated

- Windows LAPS
- Active Directory schema preparation
- GPO deployment
- Delegated password retrieval
- Local administrator management
- Password rotation validation
- Least-privilege access control
- Lateral-movement mitigation
