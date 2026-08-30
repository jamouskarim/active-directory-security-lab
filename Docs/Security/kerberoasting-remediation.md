# Kerberoasting Exposure and Remediation

## Summary

This document describes a controlled Kerberoasting exercise performed inside the `corp.ethetic.com` Active Directory lab.

The exercise demonstrated why traditional user-based service accounts with Service Principal Names can create password-cracking exposure and how a Group Managed Service Account (gMSA) can reduce that risk.

## Environment

- Domain: `corp.ethetic.com`
- Domain controller: `DC01`
- File/server host: `FILE01`
- Testing system: Kali Linux

## Vulnerable Service Account

A standard Active Directory user account was created:

```text
svc_sql
```

An MSSQL Service Principal Name was assigned:

```text
MSSQLSvc/FILE01.corp.ethetic.com:1433
```

The SPN represented a simulated SQL service associated with `FILE01`.

## Why the Account Was Kerberoastable

Kerberos allows authenticated domain users to request service tickets for services identified by SPNs.

The returned service ticket is protected using key material derived from the service account's credential.

This means an attacker who can request the ticket can take the ticket material offline and attempt password guesses without repeatedly contacting the domain controller.

The vulnerability is therefore not:

```text
"Having an SPN"
```

by itself.

The risk comes from combining:

```text
User-based service account
+
SPN
+
weak or human-managed password
```

## Ticket Request

Impacket `GetUserSPNs` was used from Kali to enumerate and request a service ticket.

The initial request encountered:

```text
KDC_ERR_ETYPE_NOSUPP
```

The lab was using modern Kerberos encryption behavior, so an AES-compatible authentication flow was used instead.

A Kerberos TGT was obtained first and stored in a credential cache.

The ticket request then succeeded using Kerberos authentication.

The resulting service-ticket material used:

```text
$krb5tgs$18$
```

which represents an AES256 Kerberos TGS-REP format.

## Important Distinction

The captured value was not the service account's literal NT password hash.

Instead, it was ticket material that could be tested offline against password guesses.

If the service account used a weak password, an attacker could potentially recover that password without generating another authentication request for every guess.

## Detection

Kerberos service-ticket requests generate Windows Security Event ID:

```text
4769
```

The lab enabled auditing for:

```text
Audit Kerberos Service Ticket Operations
```

and confirmed 4769 telemetry was available.

A custom Wazuh rule was also created to identify bursts of service-ticket requests from one client against multiple service names.

```xml
<group name="windows,kerberoasting,">
  <rule id="100102" level="0">
    <if_sid>60106</if_sid>
    <field name="win.system.eventID">^4769$</field>
    <group>kerberos_tgs_request,</group>
    <description>Kerberos service ticket requested</description>
  </rule>

  <rule id="100103" level="12" frequency="5" timeframe="60">
    <if_matched_sid>100102</if_matched_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <different_field>win.eventdata.serviceName</different_field>
    <description>Possible Kerberoasting: multiple Kerberos service tickets requested from one client</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
  </rule>
</group>
```

This rule was configured but not fully triggered in the lab because there were not enough distinct SPN-bearing service accounts to satisfy the correlation threshold.

## Remediation

The traditional account model was replaced with a Group Managed Service Account:

```text
gmsa_sql
```

The new gMSA was configured with the SQL SPN:

```text
MSSQLSvc/FILE01.corp.ethetic.com:1433
```

and only the authorized host was allowed to retrieve the managed password:

```text
FILE01$
```

The old `svc_sql` account was then disabled.

## gMSA Validation

The gMSA was installed on `FILE01`.

The following validation returned:

```text
True
```

for:

```powershell
Test-ADServiceAccount gmsa_sql
```

This confirmed that `FILE01` could retrieve and use the managed credential.

## Why gMSA Helps

A gMSA does not prevent Kerberos service tickets from being requested.

Instead, it removes the weak-password problem that makes Kerberoasting practical.

Active Directory:

- Generates the service account password
- Makes it long and random
- Rotates it automatically
- Controls which systems can retrieve it

This makes offline guessing against the service credential substantially less practical than attacking a human-created static password.

## Additional Hardening

Additional Kerberoasting mitigations include:

- Prefer gMSAs where supported
- Use long random service-account passwords
- Avoid unnecessary SPNs
- Minimize service-account privileges
- Do not make service accounts Domain Admins
- Monitor unusual 4769 activity
- Review stale service accounts and SPNs
- Prefer modern Kerberos encryption types

## Lessons Learned

Kerberoasting demonstrates that a credential does not need to be transmitted directly for password strength to matter.

A legitimate Kerberos feature can become an attack path when service accounts rely on weak, static passwords.

The most effective remediation is therefore often credential design rather than trying to disable normal Kerberos behavior.

## Skills Demonstrated

- Kerberos fundamentals
- Service Principal Names
- TGT and TGS behavior
- Impacket usage
- AES Kerberos tickets
- Event ID 4769
- Kerberoasting detection concepts
- gMSA deployment
- Service-account hardening
