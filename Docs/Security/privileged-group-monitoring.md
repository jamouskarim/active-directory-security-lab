# Privileged Group Monitoring

## Summary

This document describes monitoring for changes to privileged Active Directory groups in the `corp.ethetic.com` lab.

The primary scenario focused on detecting when an account is added to:

```text
Domain Admins
```

Because Domain Admin membership grants extensive control over the domain, unexpected membership changes should receive high-priority monitoring.

## Environment

- Domain: `corp.ethetic.com`
- Domain controller: `DC01`
- SIEM: `WAZUH01`
- Test user: `amorgan`

## Test Scenario

The standard test account:

```text
amorgan
```

was temporarily added to:

```text
Domain Admins
```

using Active Directory Users and Computers.

This was done only as a controlled lab exercise.

## Windows Event

The membership change generated Windows Security Event ID:

```text
4728
```

This event records when a member is added to a security-enabled global group.

Useful fields include:

- Account that performed the change
- Group name
- Added member
- Domain
- Timestamp

When the account was later removed, Event ID:

```text
4729
```

was available for the corresponding removal action.

## Why This Matters

An attacker does not necessarily need to exploit a technical vulnerability if they can simply add a compromised account to a privileged group.

Monitoring group changes therefore helps detect:

- Unauthorized privilege escalation
- Compromised administrator activity
- Misconfiguration
- Accidental privilege assignment
- Persistence attempts

## Wazuh Collection

The domain controller's Security log was forwarded to Wazuh.

The lab's Advanced Audit Policy enabled:

```text
Audit Security Group Management
```

so that membership changes were recorded and available for SIEM analysis.

## Custom Detection

A Wazuh rule was created specifically for additions to Domain Admins:

```xml
<group name="windows,privileged_group_change,">
  <rule id="100101" level="12">
    <if_sid>60141</if_sid>
    <field name="win.eventdata.targetUserName">^Domain Admins$</field>
    <description>Critical: Account added to Domain Admins by $(win.eventdata.subjectUserName)</description>
    <mitre>
      <id>T1098</id>
    </mitre>
  </rule>
</group>
```

The rule assigns a high severity level because an unexpected Domain Admin addition can represent a major privilege-escalation event.

## Validation

After deploying the rule:

1. `amorgan` was added to Domain Admins.
2. Windows generated the corresponding group-management event.
3. Wazuh ingested the event.
4. Custom rule `100101` fired successfully.
5. `amorgan` was removed from Domain Admins after testing.

This provided end-to-end validation:

```text
AD change
   ↓
Windows Security event
   ↓
Wazuh agent
   ↓
Wazuh manager
   ↓
Custom high-severity alert
```

## Investigation Workflow

When this alert fires, an analyst should determine:

### Who made the change?

Review the subject/user fields to identify the account responsible.

### Who was added?

Determine whether the added account is:

- Expected administrator
- Standard user
- Service account
- Newly created account
- Previously compromised identity

### Was the change authorized?

Compare the activity against:

- Change tickets
- Administrative requests
- Maintenance windows
- Approved onboarding/access changes

### What happened afterward?

Search for:

- Privileged logons
- New service creation
- Group Policy changes
- Account creation
- Directory replication activity
- Remote logons
- Security-control changes

An unauthorized Domain Admin addition should be treated as a potentially critical incident.

## Response

A real response may include:

- Remove unauthorized membership
- Disable or contain the affected account
- Reset compromised credentials
- Review authentication activity
- Investigate the administrator that performed the change
- Search for additional persistence
- Review other privileged groups
- Preserve relevant logs

## Related Privileged Logon Monitoring

The lab also collected Event ID:

```text
4672
```

which indicates that special privileges were assigned to a new logon session.

Event 4672 is common for `SYSTEM` and legitimate administrators, so it is more useful when correlated with:

- User identity
- Logon source
- Time
- Other suspicious activity

## Security Design Principle

Membership in highly privileged groups should be:

```text
Rare
+
intentional
+
auditable
+
monitored
```

The goal is not to alert on every ordinary group change with the same severity.

High-risk groups such as Domain Admins deserve focused detection because of the level of control they provide.

## Lessons Learned

Monitoring only failed logons is insufficient.

Identity-based attacks can involve successful administrative actions that look legitimate at the protocol level.

Directory changes such as privileged-group membership modifications provide high-value telemetry for detecting privilege escalation and persistence.

## Skills Demonstrated

- Active Directory privileged-group administration
- Event IDs 4728 and 4729
- Event ID 4672
- Advanced Audit Policy
- Wazuh log collection
- Custom Wazuh rules
- Privilege-escalation monitoring
- SIEM investigation workflow
