# Replication Failure Case Study

## Summary

This case study documents the process used to diagnose suspected Active Directory replication problems between `DC01` and `DC02`.

The lab uses two domain controllers so that Active Directory and DNS are not dependent on a single server. Replication health was therefore validated as part of the domain-controller deployment and troubleshooting exercises.

## Environment

- Domain: `corp.ethetic.com`
- `DC01`: primary domain controller / DNS
- `DC02`: additional domain controller / DNS
- Replication transport: RPC
- Domain partitions include:
  - Domain
  - Configuration
  - Schema
  - DomainDnsZones
  - ForestDnsZones

## Scenario

The troubleshooting exercise was designed around a suspected replication problem caused by broken connectivity or DNS between `DC01` and `DC02`.

Rather than assuming replication itself was the problem, the investigation separated:

1. General DC health
2. Network/DNS reachability
3. AD replication state
4. SYSVOL/NETLOGON availability

## Investigation

### 1. Check Overall Domain Controller Health

```powershell
dcdiag
```

This provided a broad health check of the domain controller and Active Directory services.

### 2. Check Replication Summary

```powershell
repadmin /replsummary
```

This quickly showed whether either DC had replication failures.

The healthy lab baseline showed:

```text
DC01    0 / 5 failures
DC02    0 / 5 failures
```

### 3. Inspect Individual Replication Partners

```powershell
repadmin /showrepl
```

This displayed inbound replication status by directory partition.

Healthy results showed successful replication from `DC01` to `DC02` for the domain, configuration, schema, and DNS application partitions.

### 4. Verify SYSVOL and NETLOGON

```powershell
net share
```

The domain controller exposed both:

```text
NETLOGON
SYSVOL
```

which is an important sanity check for a functioning domain controller.

### 5. Verify DNS

Because AD replication depends on name resolution, DNS was also checked for both domain controllers.

```powershell
nslookup dc01.corp.ethetic.com
nslookup dc02.corp.ethetic.com
```

## Root Cause Approach

The intentionally designed failure condition for this exercise was connectivity or DNS between the two domain controllers.

The key troubleshooting principle was to avoid immediately forcing replication. If `repadmin` reports failures, the underlying cause should first be identified.

Common causes include:

- Incorrect DNS configuration
- Firewall/network connectivity problems
- RPC availability
- A domain controller being offline
- Time synchronization issues

## Resolution

The underlying connectivity/DNS condition is corrected first.

Replication can then be rechecked with:

```powershell
repadmin /replsummary
repadmin /showrepl
```

A manual synchronization may be used after the underlying problem is fixed, but it should not be used as a substitute for diagnosing the cause.

## Verification

The final recorded lab state showed healthy replication:

```text
0 / 5 replication failures
```

and individual inbound replication attempts reported:

```text
Last attempt ... was successful.
```

`SYSVOL` and `NETLOGON` were also present.

## Troubleshooting Lesson

Replication troubleshooting should be evidence-driven.

A reliable sequence is:

```text
DC health
   ↓
DNS / connectivity
   ↓
repadmin summary
   ↓
individual replication partners
   ↓
SYSVOL / NETLOGON
   ↓
repair underlying cause
   ↓
verify replication
```

This prevents treating replication errors as isolated AD problems when the actual cause may be DNS or network connectivity.

## Skills Demonstrated

- Multi-DC Active Directory administration
- `dcdiag`
- `repadmin /replsummary`
- `repadmin /showrepl`
- SYSVOL / NETLOGON validation
- DNS troubleshooting
- Replication health verification
