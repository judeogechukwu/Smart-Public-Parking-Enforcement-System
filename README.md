# Smart Public Parking Enforcement System

A comprehensive blockchain-based parking enforcement system built on Stacks using Clarity smart contracts.

## Overview

This system automates parking enforcement through five interconnected smart contracts that handle the complete lifecycle of parking violations - from detection to revenue distribution.

## System Architecture

### 1. Violation Detection Contract (`violation-detection.clar`)
- Processes camera and sensor data to identify parking infractions
- Records violation details with timestamps and location data
- Validates parking rules and time restrictions
- Generates unique violation IDs for tracking

### 2. Citation Issuance Contract (`citation-issuance.clar`)
- Creates formal parking tickets based on detected violations
- Manages citation lifecycle and status tracking
- Handles appeal processes and dispute resolution
- Maintains citation history and officer assignments

### 3. Payment Collection Contract (`payment-collection.clar`)
- Processes fine payments and manages payment methods
- Supports installment plans and payment scheduling
- Tracks payment status and generates receipts
- Handles late fees and penalty calculations

### 4. Towing Coordination Contract (`towing-coordination.clar`)
- Manages vehicle removal and impound procedures
- Coordinates with towing companies and impound lots
- Tracks towed vehicle status and storage fees
- Handles vehicle release processes

### 5. Revenue Distribution Contract (`revenue-distribution.clar`)
- Allocates parking fine income across city departments
- Manages budget distributions and fund transfers
- Tracks revenue streams and financial reporting
- Handles administrative fee calculations

## Key Features

- **Automated Violation Detection**: Real-time processing of parking infractions
- **Digital Citation Management**: Paperless ticket issuance and tracking
- **Flexible Payment Options**: Multiple payment methods and installment plans
- **Efficient Towing Operations**: Streamlined vehicle removal coordination
- **Transparent Revenue Allocation**: Fair distribution of parking fine income

## Contract Functions

### Violation Detection
- `detect-violation`: Record new parking violations
- `validate-parking-rules`: Check parking restrictions
- `get-violation-details`: Retrieve violation information

### Citation Issuance
- `issue-citation`: Create formal parking tickets
- `process-appeal`: Handle dispute resolution
- `update-citation-status`: Modify citation state

### Payment Collection
- `process-payment`: Handle fine payments
- `setup-installment-plan`: Create payment schedules
- `calculate-penalties`: Compute late fees

### Towing Coordination
- `initiate-towing`: Start vehicle removal process
- `update-tow-status`: Track towing progress
- `process-vehicle-release`: Handle impound releases

### Revenue Distribution
- `distribute-revenue`: Allocate fine income
- `update-distribution-rules`: Modify allocation percentages
- `generate-financial-report`: Create revenue summaries

## Data Structures

### Violation Record
- Violation ID, timestamp, location coordinates
- Vehicle information, violation type, severity level
- Evidence data, officer ID, status

### Citation Details
- Citation number, violation reference, issue date
- Fine amount, due date, payment status
- Appeal information, resolution details

### Payment Information
- Payment ID, citation reference, amount paid
- Payment method, transaction date, receipt number
- Installment plan details, remaining balance

### Towing Record
- Tow ID, vehicle information, tow company
- Impound location, storage fees, release status
- Tow date, release date, total costs

### Revenue Allocation
- Department allocations, percentage distributions
- Total revenue, distributed amounts, remaining funds
- Reporting period, administrative costs

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Use `clarinet test` to run the test suite
5. Deploy with `clarinet deploy`

## Testing

The system includes comprehensive tests covering:
- Contract deployment and initialization
- Core functionality validation
- Error handling and edge cases
- Integration between contract functions
- Data integrity and security checks

## Usage

1. Deploy all five contracts to the Stacks blockchain
2. Initialize system parameters and administrative settings
3. Configure parking rules and violation types
4. Set up payment processing and towing coordination
5. Begin automated violation detection and processing

## Security Considerations

- All contracts include proper access controls
- Input validation prevents malicious data entry
- Financial operations include audit trails
- Administrative functions require proper authorization
- Data integrity maintained through blockchain immutability

## Contributing

Please read the contribution guidelines and submit pull requests for any improvements or bug fixes.

## License

This project is licensed under the MIT License.
