# Password Spray Investigation

## Summary

This document describes a controlled password-spray simulation performed inside the isolated `corp.ethetic.com` Active Directory lab and the corresponding detection workflow in Wazuh.

The goal was to demonstrate how a low-volume password spray differs from a traditional brute-force attack, how Windows records the activity, and how a SIEM can correlate repeated failures from the same source against multiple accounts.

## Environment

- Domain: `corp.ethetic.com`
- Domain controller: `DC01`
- DC01 IP: `192.168.193.10`
- Kali testing VM IP: `192.168.193.128`
- SIEM: `WAZUH01`
- Wazuh server IP: `192.168.193.120`

Test accounts included:

```text
amorgan
dkim
ebrooks
mchen
spatel
ecollins
```

## Attack Simulation

A single intentionally incorrect password was tested against multiple domain accounts from Kali.

The test was deliberately low-volume:

- One password
- Multiple usernames
- One pass across the account list
- No high-speed brute forcing

This behavior is representative of a password-spray pattern because the attacker attempts the same password across many accounts rather than trying many passwords against one account.

## Windows Telemetry

The failed SMB authentication attempts generated Windows Security Event ID:

```text
4625
```

A representative event contained:

```text
Logon Type: 3
Target account: ecollins
Workstation: KALI
Source IP: 192.168.193.128
Authentication package: NTLM
Status: 0xC000006D
SubStatus: 0xC000006A
```

The event demonstrated that Windows could identify:

- The targeted account
- The source workstation
- The source IP address
- The authentication protocol
- The reason authentication failed

### Failure Codes

The observed values were:

```text
0xC000006D
```

Generic logon failure.

```text
0xC000006A
```

Incorrect password.

These fields were useful for distinguishing a bad-password condition from other authentication failures.

## Wazuh Collection

The Windows Security logs from `DC01` were forwarded to Wazuh.

The individual authentication failures appeared in Wazuh as failed authentication events, proving that the endpoint-to-SIEM collection pipeline was functioning.

## Custom Detection Rule

A custom Wazuh rule was created to identify multiple failed logons from the same source IP against different usernames.

```xml
<group name="windows,password_spray,">
  <rule id="100100" level="12" frequency="5" timeframe="60">
    <if_matched_sid>60122</if_matched_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <different_field>win.eventdata.targetUserName</different_field>
    <description>Possible password spray: multiple failed logons from the same source IP against different accounts</description>
    <mitre>
      <id>T1110.003</id>
    </mitre>
  </rule>
</group>
```

### Detection Logic

The rule looks for:

```text
At least 5 failed logons
        +
within 60 seconds
        +
same source IP
        +
different usernames
```

This better matches password-spray behavior than simply alerting on a single failed password attempt.

## Validation

The spray was repeated after the custom rule was deployed.

The result was:

```text
6 individual authentication failures
1 level-12 password_spray alert
```

The custom detection therefore successfully correlated the separate Windows events into a higher-value security alert.

## Investigation Workflow

An analyst investigating this alert would review:

1. Source IP
2. Targeted usernames
3. Number of failures
4. Time window
5. Authentication protocol
6. Whether any authentication later succeeded
7. Whether any accounts became locked
8. Whether the source system is expected to perform authentication against those users

A successful authentication immediately following several failures would significantly increase the importance of the investigation.

## Remediation / Response

In a real environment, response actions could include:

- Validate whether the source host is legitimate
- Review successful logons from the same source
- Reset credentials if compromise is suspected
- Disable or isolate a compromised account
- Block malicious source infrastructure where appropriate
- Review MFA coverage
- Review lockout and smart-lockout controls
- Search for similar activity across other endpoints

## Lessons Learned

A password spray may generate only a small number of failures for each individual user.

Looking at one `4625` event in isolation may not appear suspicious.

The useful signal appears when the SIEM correlates:

```text
one source
+
many accounts
+
short time window
```

This exercise demonstrated the value of centralized logging and correlation rather than relying only on individual Windows events.

## Skills Demonstrated

- Active Directory authentication analysis
- Windows Event ID 4625
- NTLM authentication troubleshooting
- Password-spray concepts
- Wazuh event ingestion
- Custom Wazuh correlation rules
- MITRE ATT&CK mapping
- SIEM alert validation
