# DNS Failure Case Study

## Summary

This case study documents DNS troubleshooting in the `corp.ethetic.com` Active Directory lab.

Active Directory depends heavily on DNS for domain-controller discovery, Kerberos, LDAP, domain joins, and other directory services. A client using the wrong DNS server can have normal IP connectivity while still failing to locate the domain.

## Environment

- Domain: `corp.ethetic.com`
- `DC01`: `192.168.193.10`
- `DC02`: `192.168.193.11`
- VMware lab subnet: `192.168.193.0/24`

## Symptom

The affected system could reach the network but could not reliably resolve or locate Active Directory resources.

A similar failure occurred during security testing when Kali was initially using the VMware NAT DNS service instead of the Active Directory DNS server. Domain lookups failed until DNS was pointed to `DC01`.

The important distinction was:

```text
IP connectivity working
does not mean
Active Directory DNS is working
```

## Investigation

### 1. Inspect Client DNS Configuration

The client DNS configuration was checked using:

```powershell
ipconfig /all
```

The critical question was whether the system was using an Active Directory-aware DNS server.

For this lab, `DC01` provides DNS at:

```text
192.168.193.10
```

### 2. Test Hostname Resolution

Domain-controller records were tested with:

```powershell
nslookup dc01.corp.ethetic.com
nslookup dc02.corp.ethetic.com
```

Healthy results resolved:

```text
dc01.corp.ethetic.com -> 192.168.193.10
dc02.corp.ethetic.com -> 192.168.193.11
```

The domain itself also returned the domain-controller addresses.

### 3. Test Domain Controller Discovery

DC discovery was checked with:

```powershell
nltest /dsgetdc:corp.ethetic.com /force
```

A healthy result successfully located a domain controller in `corp.ethetic.com`.

### 4. Review DNS-Related Events

Diagnostic output also showed repeated name-resolution timeout events for `wpad`.

These warnings reinforced the need to distinguish general DNS noise from failures involving the actual AD namespace.

## Root Cause

The practical DNS failure in the lab was caused by a system using a non-AD DNS resolver instead of the domain DNS server.

The resolver could provide general network/DNS functionality but did not correctly provide the Active Directory DNS information required by domain-aware tools.

## Resolution

The affected system's DNS configuration was changed to use:

```text
192.168.193.10
```

as its DNS server.

After the change, Active Directory names and services could be resolved correctly.

## Verification

Resolution was verified through:

```text
nslookup dc01.corp.ethetic.com
nslookup dc02.corp.ethetic.com
nltest /dsgetdc:corp.ethetic.com /force
```

A healthy DC discovery test located a domain controller successfully.

## Troubleshooting Lesson

When an Active Directory client reports:

- "The domain cannot be contacted"
- Domain logon failure
- Kerberos errors
- Failed domain join
- GPO processing problems

DNS should be one of the first things checked.

AD clients should normally use the domain's DNS servers rather than an ISP, public, or hypervisor-provided resolver as their primary DNS source.

## Skills Demonstrated

- Active Directory DNS troubleshooting
- `ipconfig`
- `nslookup`
- `nltest`
- Domain-controller discovery
- DNS dependency analysis
- Differentiating network connectivity from application-layer name resolution
