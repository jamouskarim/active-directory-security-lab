# Domain Design

## Forest and Domain

- Forest: corp.ethetic.com
- Domain: corp.ethetic.com
- NetBIOS name: CORP
- Functional level: Windows Server 2025

## Domain Controllers

### DC01
- Primary domain controller
- DNS server
- IP: 192.168.193.10

### DC02
- Additional domain controller
- DNS server
- Provides AD/DNS redundancy

## Organizational Unit Structure

Ethetic
├── Users
│   ├── Accounting
│   ├── Sales
│   ├── HR
│   ├── IT
│   └── Management
├── Computers
│   └── Workstations
├── Groups
└── Service Accounts

## Security Groups

- Accounting
- HR
- Sales
- AllEmployees
- Workstation Admins
- LAPS Password Readers

## Design Goals

- Separate users by department
- Separate workstations from users
- Centralize security groups
- Isolate service accounts
- Apply Group Policy at appropriate OU levels
- Support least-privilege administration