# Broken Domain Trust Case Study

## Summary

This case study documents the troubleshooting workflow for a workstation that has lost its secure relationship with the `corp.ethetic.com` Active Directory domain.

A domain-joined Windows computer maintains its own computer account and password in Active Directory. If the workstation's local secure-channel state and the domain's copy no longer match, domain authentication can fail even though the computer object still exists.

## Environment

- Domain: `corp.ethetic.com`
- Domain controllers: `DC01`, `DC02`
- Domain-joined Windows workstations including `CLIENT01` and `ADMIN01`

## Symptom

The workstation presents an error indicating that the trust relationship between the workstation and the domain has failed.

The computer may still:

- Boot normally
- Have network connectivity
- Resolve the domain

but domain authentication fails because its secure channel is no longer valid.

## Investigation

### 1. Confirm Basic Network and DNS Health

Before treating the issue as broken trust, basic domain connectivity should be verified.

Checks include:

```text
Can the client reach the network?
Can it resolve corp.ethetic.com?
Can it resolve DC01/DC02?
Can it locate a domain controller?
```

This prevents a DNS failure from being misdiagnosed as a trust failure.

### 2. Confirm the Computer Object Exists

Active Directory Users and Computers is checked to confirm that the workstation's computer account still exists in the expected OU.

For lab workstations, the expected location is:

```text
Ethetic
└── Computers
    └── Workstations
```

### 3. Test the Secure Channel

PowerShell can directly test the relationship:

```powershell
Test-ComputerSecureChannel
```

A healthy result returns:

```text
True
```

A failed result indicates that the workstation's secure relationship with the domain needs repair.

## Root Cause

The failure class is a mismatch or break in the machine-account secure channel between the workstation and Active Directory.

This can occur after situations such as:

- Restoring an old VM snapshot
- Reverting a workstation to an earlier state
- Computer-account password mismatch
- Recreating/resetting a computer object incorrectly
- Cloning or restoring domain-joined systems improperly

This is especially relevant in virtualized labs where VM snapshots are frequently used.

## Resolution

The preferred approach is to repair the secure channel first rather than immediately removing and rejoining the computer.

If repair succeeds, this avoids unnecessary changes to the workstation's domain membership.

If the secure channel cannot be repaired, the fallback is:

1. Ensure local administrative access is available.
2. Remove the workstation from the domain.
3. Restart if required.
4. Rejoin `corp.ethetic.com`.
5. Place the computer object back into the correct Workstations OU.
6. Reapply Group Policy.

## Verification

After repair or rejoin:

```powershell
Test-ComputerSecureChannel
```

should return:

```text
True
```

The workstation should also be able to:

- Authenticate with a domain account
- Locate a domain controller
- Receive Group Policy
- Access authorized domain resources

## Troubleshooting Lesson

Do not immediately rejoin every workstation that reports a trust error.

First distinguish among:

```text
DNS problem
Network problem
Missing/incorrect computer object
Actual secure-channel failure
```

A rejoin is a valid fallback, but identifying the failure first provides a cleaner and more controlled troubleshooting process.

## Skills Demonstrated

- Domain trust troubleshooting
- Computer-account validation
- Secure-channel concepts
- `Test-ComputerSecureChannel`
- DNS/domain-controller validation
- Domain rejoin workflow
- VM snapshot/trust considerations
