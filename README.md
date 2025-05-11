# GParkToken - Global Park DAO Utility Token

![GParkToken Banner](https://www.globalpark.io/banners/1500-3.png)

**GParkToken (GPARK)** is the official utility token of the [Global Park DAO](https://globalpark.io), designed to enable participation, NFT coordinates registration, staking, voting, and cultural collaboration across decentralized physical and digital spaces.

## 🚀 Overview

GParkToken is a production-ready, DAO-owned ERC20 token with advanced governance and vesting functionality. It powers the cultural coordination layer of the Global Park DAO ecosystem.

## 💎 Features

* **ERC20** standard compliance
* **ERC20Permit** (EIP-2612) for gasless approvals
* **ERC20Votes** integration for Snapshot-compatible voting
* **Custom vesting system** with cliff, duration, and interval settings
* **transferWithNote** function to attach notes to transfers (for grants, rewards, ambassador payments)
* **DAO-controlled ownership** via Ownable pattern
* **No mint / burn functions** for maximum supply safety

## 📜 Contract Summary

* **Name:** GParkToken
* **Symbol:** GPARK
* **Standard:** ERC20 + ERC20Permit + ERC20Votes + Ownable
* **Owner:** DAO Treasury (daoSafe multisig)

## 🔐 Vesting System

The DAO can assign vesting schedules to any address:

* **Cliff:** period before any claim
* **Duration:** total vesting period
* **Interval:** customizable unlock steps
* **claimVested:** allows user to unlock tokens after cliff

## 🎨 transferWithNote

Enables DAO and users to add metadata to transfers:

```solidity
transferWithNote(address recipient, uint256 amount, string calldata note);
```

E.g. note = "Ambassador Program Q2".

## 🛡️ Security

* All privileged functions can only be executed by the DAO owner (daoSafe)
* No central minting or admin keys
* Vesting logic prevents transfer of locked tokens
* Fully audited OpenZeppelin contracts

## 📥 Installation

```bash
npm install @openzeppelin/contracts
```

## 🔧 Usage Example

```solidity
GParkToken token = new GParkToken(daoSafeAddress);
token.transferWithNote(recipient, amount, "Community Grant");
```

## 📄 License

MIT License. See [LICENSE](LICENSE).

## 🌐 Learn More

* Website: [https://globalpark.io](https://globalpark.io)
* DAO Documentation: [https://github.com/GlobalParkDAO](https://github.com/GPARKPRO)
* Community: [https://discord.gg/czb5W4UuZv](https://discord.gg/czb5W4UuZv)

---

### 🔥 Join the Movement

Help shape the cultural infrastructure of the decentralized era with GParkToken and Global Park DAO.

> "The Ethereum of Culture." - Global Park DAO Vision 2030
