// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GParkToken - Utility & Governance Token for Global Park DAO
/// @notice Enables DAO governance, cultural NFT coordinates, staking and community contributions
contract GParkToken is ERC20, ERC20Permit, ERC20Votes, Ownable {

    // --------------------
    // State variables
    // --------------------

    string public constant description = "GPARK is the token of Global Park DAO, governing participation, NFT coordinates, staking and community development in a decentralized cultural space. More info: https://globalpark.io";

    struct Vesting {
        uint256 total;
        uint256 claimed;
        uint64 cliffEnd;
        uint64 vestingEnd;
        uint64 interval;
    }

    mapping(address => Vesting) public vestings;
    address public immutable daoSafe;

    // --------------------
    // Events
    // --------------------

    event VestingAssigned(address indexed recipient, uint256 amount, uint64 cliffEnd, uint64 vestingEnd, uint64 interval);
    event VestingClaimed(address indexed recipient, uint256 amount);
    event TransferWithNote(address indexed from, address indexed to, uint256 amount, string note);
    event InitialSupplyMinted(address indexed daoSafe, uint256 amount);

    // --------------------
    // Constructor
    // --------------------

    constructor(address _daoSafe)
        ERC20("GParkToken", "GPARK")
        ERC20Permit("GParkToken")
        Ownable(_daoSafe)
    {
        require(_daoSafe != address(0), "daoSafe cannot be zero address");
        daoSafe = _daoSafe;
        uint256 supply = 21_000_000 * 10 ** decimals();
        _mint(_daoSafe, supply);
        emit InitialSupplyMinted(_daoSafe, supply);
    }

    // --------------------
    // External functions
    // --------------------

    function contractDescription() external pure returns (string memory) {
        return description;
    }

    function lockVesting(
        address to,
        uint256 amount,
        uint64 cliffDuration,
        uint64 vestingDuration,
        uint64 interval
    ) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(vestingDuration > 0, "Vesting must have duration");
        require(interval > 0 && interval <= vestingDuration, "Invalid interval");

        Vesting storage v = vestings[to];
        require(v.total == 0, "Vesting already exists");

        v.total = amount;
        v.claimed = 0;
        v.cliffEnd = uint64(block.timestamp) + cliffDuration;
        v.vestingEnd = v.cliffEnd + vestingDuration;
        v.interval = interval;

        emit VestingAssigned(to, amount, v.cliffEnd, v.vestingEnd, v.interval);
    }

    function claimVested() external {
        Vesting storage v = vestings[msg.sender];
        require(v.total > 0, "No vesting found");
        require(block.timestamp >= v.cliffEnd, "Cliff not ended");

        uint256 unlocked = _calculateUnlocked(v);
        uint256 claimable = unlocked - v.claimed;

        if (v.claimed + claimable > v.total) {
            claimable = v.total - v.claimed;
        }

        require(claimable > 0, "No tokens to claim");
        v.claimed += claimable;
        _transfer(daoSafe, msg.sender, claimable);

        emit VestingClaimed(msg.sender, claimable);
    }

    function getVestingStatus(address user) external view returns (
        uint256 total,
        uint256 claimed,
        uint256 claimable,
        uint256 percentClaimed
    ) {
        Vesting memory v = vestings[user];
        total = v.total;
        claimed = v.claimed;
        uint256 unlocked = _calculateUnlocked(v);
        claimable = unlocked > claimed ? unlocked - claimed : 0;
        percentClaimed = v.total > 0 ? (claimed * 10000) / v.total : 0;
    }

    function transferWithNote(address to, uint256 amount, string calldata note) external returns (bool) {
        _transfer(msg.sender, to, amount);
        emit TransferWithNote(msg.sender, to, amount, note);
        return true;
    }

    // --------------------
    // Internal functions
    // --------------------

    function _calculateUnlocked(Vesting memory v) internal view returns (uint256) {
        if (block.timestamp < v.cliffEnd) return 0;
        if (block.timestamp >= v.vestingEnd) return v.total;

        uint256 elapsed = block.timestamp - v.cliffEnd;
        uint256 totalIntervals = (v.vestingEnd - v.cliffEnd) / v.interval;
        uint256 completedIntervals = elapsed / v.interval;

        return (v.total * completedIntervals) / totalIntervals;
    }

    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    // --------------------
    // Overrides
    // --------------------

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
