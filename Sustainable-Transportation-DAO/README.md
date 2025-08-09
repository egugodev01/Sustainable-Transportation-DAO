# Sustainable Transportation DAO

A community-owned electric vehicle sharing network built on the Stacks blockchain using Clarity smart contracts.

## Overview

The Sustainable Transportation DAO enables communities to collectively own and manage a fleet of electric vehicles. Members can join the DAO, contribute vehicles, rent vehicles from the shared fleet, and participate in governance decisions that shape the network's future.

## Features

###  DAO Governance
- **Membership System**: Join with STX payment and receive governance tokens
- **Proposal Creation**: Members can create proposals for treasury spending, policy changes
- **Token-weighted Voting**: Vote on proposals with voting power based on token holdings
- **Automatic Execution**: Approved proposals are automatically executed

###  Vehicle Sharing Network
- **Vehicle Registration**: Add electric vehicles to the shared fleet
- **Hourly Rentals**: Rent vehicles by the hour with transparent pricing
- **Availability Tracking**: Real-time vehicle availability and location
- **Battery Monitoring**: Track vehicle battery levels and maintenance needs

###  Tokenomics
- **Governance Tokens**: Earned through membership, vehicle contributions, and usage
- **Revenue Sharing**: Vehicle owners earn 80% of rental fees
- **Treasury Fund**: 20% of fees go to DAO treasury for network expansion
- **Reputation System**: Build reputation through responsible vehicle usage

###  Security Features
- **Access Control**: Multi-level authorization for different actions
- **Rental Tracking**: Complete audit trail of all vehicle rentals
- **Anti-spam**: Minimum token thresholds for proposal creation
- **Time-locked Voting**: Voting periods prevent rushed decisions

## Smart Contract Functions

### Public Functions

#### Membership
- `join-dao()` - Become a DAO member (costs 1 STX)
- `get-member(principal)` - View member details and token balance

#### Vehicle Management
- `add-vehicle(model, location, rate)` - Add a vehicle to the fleet
- `get-vehicle(vehicle-id)` - Get vehicle details and availability
- `rent-vehicle(vehicle-id, duration)` - Rent a vehicle for specified hours
- `return-vehicle(rental-id)` - Return a rented vehicle

#### Governance
- `create-proposal(title, description, type, target, amount)` - Create governance proposal
- `vote-proposal(proposal-id, vote-for)` - Vote on active proposals
- `execute-proposal(proposal-id)` - Execute approved proposals
- `get-proposal(proposal-id)` - View proposal details

#### Analytics
- `get-dao-stats()` - View DAO statistics (members, vehicles, treasury)
- `get-rental(rental-id)` - View rental transaction details

## Contract Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Membership    │    │   Vehicle       │    │   Governance    │
│   Management    │    │   Sharing       │    │   System        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Treasury &    │
                    │   Token System  │
                    └─────────────────┘
```

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for membership fee and transactions
- Access to Stacks testnet/mainnet

### Deployment

1. **Deploy Contract**
```bash
clarinet deploy --testnet
```

2. **Join DAO**
```clarity
(contract-call? .sustainable-transport-dao join-dao)
```

3. **Add Vehicle** (as member)
```clarity
(contract-call? .sustainable-transport-dao add-vehicle 
  "Tesla Model 3" 
  "Downtown Station A" 
  u50000) ;; 0.05 STX per hour
```

4. **Rent Vehicle**
```clarity
(contract-call? .sustainable-transport-dao rent-vehicle u1 u2) ;; Rent vehicle #1 for 2 hours
```

## Economic Model

### Membership Tiers
- **Standard Member**: 100 governance tokens, basic voting rights
- **Vehicle Owner**: Additional 50 tokens per vehicle contributed
- **Active User**: Reputation bonuses for consistent usage

### Fee Structure
- **Membership Fee**: 1 STX (one-time)
- **Rental Rates**: Set by vehicle owners (typically 0.01-0.1 STX/hour)
- **Platform Fee**: 20% of rental fees to treasury
- **Owner Share**: 80% of rental fees to vehicle owner

### Treasury Usage
Funds are allocated through governance proposals for:
- Infrastructure expansion
- Vehicle maintenance programs
- Community incentives
- Technology upgrades

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | NOT-AUTHORIZED | Caller lacks permission |
| 101 | VEHICLE-NOT-FOUND | Vehicle ID doesn't exist |
| 102 | VEHICLE-UNAVAILABLE | Vehicle currently rented |
| 103 | INSUFFICIENT-BALANCE | Not enough tokens |
| 104 | ALREADY-MEMBER | Already joined DAO |
| 105 | NOT-MEMBER | Must join DAO first |
| 106 | PROPOSAL-NOT-FOUND | Proposal ID doesn't exist |
| 107 | ALREADY-VOTED | Already voted on proposal |
| 108 | VEHICLE-IN-USE | Cannot modify rented vehicle |
| 109 | INVALID-DURATION | Rental duration must be > 0 |

## Development

### Testing
```bash
# Run unit tests
clarinet test

# Check contract syntax
clarinet check

# Interactive console
clarinet console
```

### Local Development
```bash
# Start local testnet
clarinet integrate

# Deploy to local network
clarinet deploy --local
```

## Roadmap

### Phase 1: Core Platform 
- [x] DAO membership system
- [x] Vehicle registration and rental
- [x] Basic governance framework
- [x] Treasury management

### Phase 2: Enhanced Features 
- [ ] Mobile app integration
- [ ] IoT vehicle connectivity
- [ ] Carbon credit rewards
- [ ] Insurance integration

### Phase 3: Network Expansion 
- [ ] Multi-city deployment
- [ ] Cross-chain compatibility
- [ ] Corporate partnerships
- [ ] Sustainability metrics

## Security Considerations

- **Access Control**: All sensitive functions require membership verification
- **Reentrancy Protection**: State changes occur before external calls
- **Integer Overflow**: All arithmetic operations use safe math
- **Time-based Logic**: Voting periods prevent manipulation
- **Emergency Functions**: Admin controls for critical situations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Discord**: [Join our community](https://discord.gg/sustainable-transport-dao)
- **Twitter**: [@SustainableTransportDAO](https://twitter.com/SustainableTransportDAO)
- **Email**: dev@sustainabletransport.dao

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language team for smart contract capabilities
- Electric vehicle community for inspiration and feedback
- Open source contributors who made this possible

---

*Building the future of sustainable transportation, one block at a time.*