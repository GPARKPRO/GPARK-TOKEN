// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GParkToken is ERC20, ERC20Permit, ERC20Votes, Ownable {

    string public constant description = "GPARK is the token of Global Park DAO, governing participation, NFT coordinates, staking and community development in a decentralized cultural space. More info: https://globalpark.io";

    struct Vesting {
        uint256 total;       // total tokens under vesting
        uint256 claimed;     // already claimed
        uint64 cliffEnd;     // timestamp when cliff ends
        uint64 vestingEnd;   // timestamp when full vesting ends
        uint64 interval;     // step duration (customizable)
    }

    mapping(address => Vesting) public vestings;
    address public immutable daoSafe;

    event VestingAssigned(address indexed recipient, uint256 amount, uint64 cliffEnd, uint64 vestingEnd, uint64 interval);
    event VestingClaimed(address indexed recipient, uint256 amount);
    event TransferWithNote(address indexed from, address indexed to, uint256 amount, string note);

    constructor(address _daoSafe)
        ERC20("GParkToken", "GPARK")
        ERC20Permit("GParkToken")
        // Set daoSafe as owner to allow DAO-controlled ownership from deployment
        Ownable(_daoSafe)
    {
        daoSafe = _daoSafe;
    }

    function contractDescription() external pure returns (string memory) {
        return description;
    }

    // ================== Vesting ===================

    function lockVesting(address to, uint256 amount, uint64 cliffDuration, uint64 vestingDuration, uint64 interval) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(to) >= amount, "Recipient balance too low");
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
        _transfer(address(this), msg.sender, claimable);

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

    function _calculateUnlocked(Vesting memory v) internal view returns (uint256) {
        if (block.timestamp < v.cliffEnd) return 0;
        if (block.timestamp >= v.vestingEnd) return v.total;

        uint256 elapsed = block.timestamp - v.cliffEnd;
        uint256 totalIntervals = (v.vestingEnd - v.cliffEnd) / v.interval;
        uint256 completedIntervals = elapsed / v.interval;

        return (v.total * completedIntervals) / totalIntervals;
    }

    // ================== Custom Transfer with Note ===================

    function transferWithNote(address to, uint256 amount, string calldata note) external returns (bool) {
        _transfer(msg.sender, to, amount);
        emit TransferWithNote(msg.sender, to, amount, note);
        return true;
    }

    // ================== Additional Compatibility ===================

    function name() public view override returns (string memory) {
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        return super.symbol();
    }

    // ================== Overrides ===================

    function _update(address from, address to, uint256 value)
        internal override(ERC20, ERC20Votes)
    {
        if (from != address(0) && from != daoSafe) {
            Vesting memory v = vestings[from];
            if (v.total > 0) {
                require(block.timestamp >= v.cliffEnd, "Tokens are still in cliff");
                uint256 unlocked = _calculateUnlocked(v);
                require(balanceOf(from) - value >= v.total - unlocked, "Trying to transfer locked tokens");
            }
        }
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
