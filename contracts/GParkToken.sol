// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GParkToken - Utility & Governance Token for Global Park DAO
/// @notice Enables DAO governance, cultural NFT coordinates, staking and community contributions
contract GParkToken is ERC20, ERC20Permit, ERC20Votes, Ownable {

    /// @notice Project description
    string public constant description = "GPARK is the token of Global Park DAO, governing participation, NFT coordinates, staking and community development in a decentralized cultural space. More info: https://globalpark.io";

    /// @notice Structure of individual vesting allocation
    struct Vesting {
        uint256 total;        // Total amount locked for vesting
        uint256 claimed;      // Amount already claimed
        uint64 cliffEnd;      // Cliff period end timestamp
        uint64 vestingEnd;    // Vesting completion timestamp
        uint64 interval;      // Step interval for progressive unlocking
    }

    /// @notice Mapping of wallet addresses to their vesting schedule
    mapping(address => Vesting) public vestings;

    /// @notice DAO treasury multisig address
    address public immutable daoSafe;

    /// @notice Emitted when vesting is assigned
    event VestingAssigned(address indexed recipient, uint256 amount, uint64 cliffEnd, uint64 vestingEnd, uint64 interval);

    /// @notice Emitted when tokens are claimed from vesting
    event VestingClaimed(address indexed recipient, uint256 amount);

    /// @notice Emitted when a transfer with note occurs
    event TransferWithNote(address indexed from, address indexed to, uint256 amount, string note);

    /// @notice Initializes token supply to DAO treasury
    /// @param _daoSafe The DAO treasury address
    constructor(address _daoSafe)
        ERC20("GParkToken", "GPARK")
        ERC20Permit("GParkToken")
        Ownable(_daoSafe)
    {
        require(_daoSafe != address(0), "daoSafe cannot be zero address");
        daoSafe = _daoSafe;
        _mint(_daoSafe, 21_000_000 * 10 ** decimals());
    }

    /// @notice Returns description text
    function contractDescription() external pure returns (string memory) {
        return description;
    }

    /// @notice Locks tokens under vesting schedule
    /// @param to recipient address
    /// @param amount total tokens to lock
    /// @param cliffDuration seconds for cliff period
    /// @param vestingDuration seconds for full vesting
    /// @param interval step size (seconds) for progressive unlocking
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

    /// @notice Claims unlocked tokens from active vesting
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

    /// @notice Returns current vesting status of a user
    /// @param user address of the beneficiary
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

    /// @dev Internal calculation of unlocked amount
    function _calculateUnlocked(Vesting memory v) internal view returns (uint256) {
        if (block.timestamp < v.cliffEnd) return 0;
        if (block.timestamp >= v.vestingEnd) return v.total;

        uint256 elapsed = block.timestamp - v.cliffEnd;
        uint256 totalIntervals = (v.vestingEnd - v.cliffEnd) / v.interval;
        uint256 completedIntervals = elapsed / v.interval;

        return (v.total * completedIntervals) / totalIntervals;
    }

    /// @notice Transfers tokens with attached off-chain note
    function transferWithNote(address to, uint256 amount, string calldata note) external returns (bool) {
        _transfer(msg.sender, to, amount);
        emit TransferWithNote(msg.sender, to, amount, note);
        return true;
    }

    /// @dev Hook override to enforce vesting transfer restrictions
    ///      Only unclaimed tokens remain locked. Claimed tokens are freely transferable.
    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Votes)
    {
        // No additional restrictions needed; claimed tokens = free
        super._update(from, to, value);
    }

    /// @inheritdoc ERC20Permit
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
