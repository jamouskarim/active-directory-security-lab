# Account Lockout Case Study

## Summary

This case study documents a controlled Active Directory account-lockout test in the `corp.ethetic.com` lab. The goal was to verify that the domain lockout policy worked as expected and that lockout telemetry reached the Wazuh SIEM.

## Environment

- Domain: `corp.ethetic.com`
- Domain controller: `DC01`
- Windows client: `CLIENT01`
- SIEM: `WAZUH01`
- Test account: `lockout-test`

## Symptom

The test user was unable to authenticate after repeated incorrect password attempts.

From a helpdesk perspective, the user-facing symptom would simply be:

> "My account is locked and I can't sign in."

## Investigation

The first step was to confirm that the problem was actually an account lockout rather than:

- A disabled account
- An expired password
- An incorrect password
- A workstation connectivity problem
- A DNS/domain-controller discovery problem

The domain's configured account lockout threshold was reviewed before testing so that a disposable account could be used without affecting a real administrative account.

Repeated incorrect authentication attempts were then made against `lockout-test` until the configured threshold was reached.

## Evidence

On the domain controller, Windows generated:

```text
Event ID 4740
A user account was locked out
```

The same event was visible through centralized Wazuh monitoring.

Useful fields in a 4740 event include:

- Locked account name
- Domain
- Caller computer name
- Timestamp

These fields help determine which system generated the authentication attempts responsible for the lockout.

## Root Cause

The lockout was intentionally caused by repeated invalid password attempts against the test account.

In a real environment, repeated lockouts can also be caused by stale credentials stored in:

- Windows Credential Manager
- Services
- Scheduled tasks
- Mapped drives
- Mobile devices
- Applications using an old password

The important troubleshooting lesson is that unlocking the account alone does not solve a recurring lockout. The source of the failed authentication must be identified.

## Resolution

The test account was unlocked in Active Directory after the event was verified.

Because this was a controlled exercise, no production credential source needed remediation.

## Verification

The test was considered successful when:

1. The account entered the locked-out state.
2. Event ID `4740` was generated.
3. The event was visible in Wazuh.
4. The account could be unlocked and used again.

## Security / Operational Takeaway

Account lockout events are useful both for helpdesk troubleshooting and security monitoring.

A single 4740 may represent an ordinary stale credential. Repeated lockouts across multiple users or from the same source may indicate password spraying, brute-force activity, a misconfigured service, or compromised credentials.

## Skills Demonstrated

- Active Directory account troubleshooting
- Account lockout policy validation
- Windows Security Event analysis
- Event ID 4740 investigation
- Wazuh log validation
- Safe use of disposable test accounts
