# GParkToken Governance Policy

## 🏛️ Introduction

GParkToken is the utility token of Global Park DAO and is fully controlled by the DAO's governance framework. This document describes how GParkToken fits into the DAO structure and how changes are managed.

## 📜 DAO Ownership

The `GParkToken` smart contract is owned by the Global Park DAO treasury, represented by a DAO-controlled multisig wallet (`daoSafe`).

* Only the DAO Safe can call privileged functions (e.g., `lockVesting`).
* There are no private admin keys or backdoors.
* All token allocations and vesting assignments must be approved by DAO proposals.

## 🎯 Governance Model

The DAO follows a progressive decentralization model:

1. **Proposals** — any token holder may suggest improvements or changes.
2. **Snapshot Voting** — proposals are voted on using GParkToken via off-chain Snapshot voting.
3. **Multisig Execution** — after community approval, the DAO multisig (`daoSafe`) executes the action.

## 💎 Key Governance Functions

### Vesting Assignments

The DAO multisig can assign token vesting schedules using:

```solidity
lockVesting(address recipient, uint256 amount, uint64 cliff, uint64 duration, uint64 interval);
```

### Voting Rights

GParkToken is integrated with ERC20Votes:

* Voting power is tied to token balances.
* Delegation of voting rights is supported.
* Fully compatible with Snapshot voting.

### No Mint / Burn

* The GParkToken has no mint or burn function.
* Total supply is fixed upon initial distribution.

## 🔒 Security & Emergency Controls

* There are no pausable functions or kill switches.
* Security is enforced through DAO multisig controls.
* Any upgrade or replacement of the contract must be approved by DAO governance.

## 🤝 Transparency Commitment

All DAO decisions, multisig transactions, and proposals will be publicly viewable on: https://www.globalpark.io/docs
