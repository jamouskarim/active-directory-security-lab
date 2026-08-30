# Permissions Model

This document describes the permissions and access-control model used in the `corp.ethetic.com` Active Directory security lab.

## Objectives

The permissions model is designed to:

- Use groups instead of assigning permissions directly to individual users
- Separate access by department and role
- Apply least-privilege principles
- Reduce shared credential usage
- Separate administrative access from standard user access
- Provide controlled access to privileged credentials
- Demonstrate how permission mistakes can create security exposure

## Active Directory Security Groups

Core groups include:

```text
Accounting
HR
Sales
AllEmployees
Workstation Admins
LAPS Password Readers
```

Additional security groups were created during the PowerShell automation phase, including:

```text
Helpdesk-Tier2
VPN-Users
Finance-Share-RW
IT-Software-Deploy
Remote-Desktop-Users
```

## Departmental Access

Departmental groups are used to represent business roles.

Examples:

```text
Accounting users → Accounting group
HR users         → HR group
Sales users      → Sales group
```

The goal is to manage access through group membership rather than assigning NTFS or share permissions directly to individual accounts.

## File Server Permissions

`FILE01` hosts shared folders including:

```text
E:\shares\accounting
E:\shares\hr
E:\shares\company
```

### Accounting Share

Access is granted to:

```text
Accounting
```

Users outside the department are not granted Accounting access.

This was validated using the test account:

```text
amorgan
```

### HR Share

Access is granted to:

```text
HR
```

Non-HR users do not receive HR share access.

### Company Share

Access is granted through:

```text
AllEmployees
```

This provides a common location for resources intended for the broader organization.

## Permission Design Pattern

The lab follows the principle:

```text
Users
  ↓
Security Groups
  ↓
Resource Permissions
```

rather than:

```text
Individual User
  ↓
Resource Permission
```

This simplifies onboarding, offboarding, role changes, and auditing.

## Administrative Access

Administrative access is kept separate from normal departmental access.

### Workstation Admins

The group:

```text
Workstation Admins
```

is used for delegated workstation administration rather than automatically granting broad domain privileges.

The primary administrative account used in the lab is:

```text
CORP\jamousk
```

Administrative access is intended to be granted only where required.

## Windows LAPS Permissions

Windows LAPS is used to protect local administrator credentials.

Managed local administrator account:

```text
LabLocalAdmin
```

Authorized password retrieval is delegated through:

```text
LAPS Password Readers
```

This group is granted permission to read and decrypt LAPS-managed passwords for workstation computer objects.

The design prevents every administrator or standard user from automatically being able to retrieve local administrator passwords.

## Service Account Permissions

A traditional service account:

```text
svc_sql
```

was created during Kerberoasting testing.

It originally had the SPN:

```text
MSSQLSvc/FILE01.corp.ethetic.com:1433
```

The lab then replaced this model with the gMSA:

```text
gmsa_sql
```

Only the authorized host:

```text
FILE01$
```

is allowed to retrieve the gMSA-managed password.

This reduces the risk associated with long-lived, human-managed service account passwords.

## Privileged Group Membership

Membership in privileged groups is treated as a high-risk security event.

For example:

```text
Domain Admins
```

is monitored for membership changes.

A custom Wazuh rule was created to detect account additions to Domain Admins.

The lab generated and reviewed Event ID:

```text
4728
```

for this scenario.

## Deliberate DCSync Misconfiguration

To demonstrate the risk of excessive directory permissions, the test account:

```text
amorgan
```

was temporarily granted:

```text
Replicating Directory Changes
Replicating Directory Changes All
```

at the domain root.

This allowed the account to perform a DCSync-style replication request even though it was not a Domain Admin.

The permissions were removed after testing.

The exercise demonstrates an important principle:

> Effective privilege in Active Directory is determined by permissions, not only by group names.

A non-administrative account can become highly privileged if dangerous directory rights are delegated incorrectly.

## Terminated Users

The PowerShell offboarding workflow:

- Disables terminated accounts
- Moves them into a dedicated `Terminated Users` OU
- Prevents accidental processing of protected administrative accounts

This separates inactive identities from active users and makes account lifecycle management easier to review.

## Least-Privilege Principles Used

The lab attempts to follow these rules:

- Assign resource access to groups rather than directly to users
- Separate normal users from administrative identities
- Keep Domain Admin membership minimal
- Use LAPS instead of shared local administrator passwords
- Use gMSAs instead of static service-account passwords where possible
- Delegate only the permissions required for a task
- Monitor changes to sensitive groups
- Remove temporary elevated permissions immediately after testing

## Future Improvements

Potential improvements include:

- Implementing AGDLP consistently for file-server permissions
- Separating read-only and read/write resource groups
- Creating dedicated helpdesk delegation OUs
- Removing broad deny entries where cleaner allow-based ACLs are possible
- Adding formal privileged-access tiers
- Periodically reviewing stale and nested group memberships
- Exporting ACL and group-membership reports for recurring audits
