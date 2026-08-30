# Broken GPO Case Study

## Summary

This case study documents the troubleshooting process for a workstation Group Policy that was expected to apply but was missing.

The lab uses Group Policy for workstation security, mapped drives, Windows LAPS, screen locking, and advanced auditing. Because GPO behavior depends heavily on object placement and scope, troubleshooting focused on determining whether the target computer was actually eligible to receive the policy.

## Environment

- Domain: `corp.ethetic.com`
- Domain controllers: `DC01`, `DC02`
- Workstation OU:

```text
OU=Workstations,OU=Computers,OU=Ethetic,DC=corp,DC=ethetic,DC=com
```

- Domain-joined endpoints include `CLIENT01` and `ADMIN01`

## Symptom

An expected workstation policy was missing from the target computer.

Typical symptoms of this type of issue include:

- A mapped drive not appearing
- A Windows LAPS setting not taking effect
- A security setting remaining unchanged
- An audit policy not appearing on the workstation

## Troubleshooting Process

### 1. Check OU Placement

The computer object was checked in Active Directory Users and Computers to confirm that it was located inside the OU where the workstation GPO was linked.

This is important because a GPO linked to:

```text
Ethetic
└── Computers
    └── Workstations
```

will not automatically apply to a computer object placed somewhere outside that scope.

### 2. Check GPO Link and Scope

Group Policy Management was used to verify:

- The GPO was linked to the intended OU
- The link was enabled
- The relevant Computer or User Configuration section was enabled
- Security filtering had not excluded the target computer/user
- No conflicting policy was taking precedence

### 3. Force Policy Refresh

After correcting the policy scope/configuration, policy processing was refreshed:

```powershell
gpupdate /force
```

### 4. Verify Effective Policy

A Group Policy Results / `gpresult` report was used to confirm whether the target GPO appeared in the computer's applied policy list.

The key question was not simply:

> "Does the GPO exist?"

but:

> "Is this specific computer actually receiving it?"

## Root Cause

The issue was treated as a GPO targeting/scope problem: the expected policy was not reaching the workstation because the computer/GPO relationship needed to be corrected at the OU, link, filtering, or policy-section level.

The troubleshooting exercise emphasized validating scope before changing the actual policy settings.

## Resolution

The affected GPO scope/configuration was corrected and policy was refreshed on the workstation.

The relevant setting was then rechecked locally.

## Verification

The repair was validated by:

- Running `gpupdate /force`
- Reviewing Group Policy Results
- Confirming the intended GPO was listed as applied
- Verifying the expected endpoint behavior

For audit-related policies, Event Viewer and Wazuh were also used to confirm that the resulting telemetry was being generated.

## Troubleshooting Lesson

Group Policy failures are often not caused by the setting itself.

A policy can be perfectly configured and still do nothing if:

- The computer is in the wrong OU
- The GPO is linked at the wrong level
- Security filtering excludes the target
- A section of the GPO is disabled
- Another policy overrides the setting

Effective GPO troubleshooting therefore starts with scope and processing before editing the setting.

## Skills Demonstrated

- Group Policy Management
- OU/GPO scoping
- Security filtering review
- Group Policy Results
- `gpupdate`
- `gpresult`
- Endpoint policy verification
