# NursingShifts - Decentralized Shift Scheduling System

A blockchain-based system for managing nursing shift assignments and scheduling on Stacks.

## Features

- Create and manage hospital shifts
- Nurse profile registration with specializations
- Automated shift assignment with capacity limits
- Shift completion tracking with hours worked
- Shift cancellation capabilities

## Contract Functions

### Public Functions
- `create-shift`: Create a new hospital shift
- `register-nurse-profile`: Register nurse with specialization details
- `assign-nurse-to-shift`: Assign nurse to available shift
- `complete-shift`: Mark shift as completed with hours worked
- `cancel-shift`: Cancel an active shift

### Read-Only Functions
- `get-shift`: Retrieve shift information
- `get-assignment`: Get assignment details
- `get-nurse-profile`: Get nurse profile information
- `get-nurse-assignment`: Check if nurse is assigned to shift
- `count-shift-assignments`: Count current assignments for shift

## Use Cases

- Hospital shift management
- Nurse scheduling and assignments
- Work hour tracking
- Capacity management

## Testing

Run tests with Clarinet:
```bash
clarinet test