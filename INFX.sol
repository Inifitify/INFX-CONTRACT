// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract INFX is ERC20, ERC20Permit, ERC20Votes, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    uint256 public constant MAX_SUPPLY = 400_000_000 * 10**18; // 400 million tokens with 18 decimals

    mapping(address => bool) public blacklist;

    event AddressBlacklisted(address indexed account, bool isBlacklisted);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor(address initialGovernor) 
        ERC20("Innovative NFT Exchange", "INFX") 
        ERC20Permit("Innovative NFT Exchange")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, initialGovernor);
        _grantRole(GOVERNANCE_ROLE, initialGovernor);
        _grantRole(MINTER_ROLE, initialGovernor);
    }

    // Mint function with blacklist check
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(!blacklist[to], "Cannot mint to blacklisted address");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // Blacklist management
    function blacklistAddress(address account, bool isBlacklisted) external onlyRole(GOVERNANCE_ROLE) {
        blacklist[account] = isBlacklisted;
        emit AddressBlacklisted(account, isBlacklisted);
    }

    // Pausing the contract
    function pause() external onlyRole(GOVERNANCE_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(GOVERNANCE_ROLE) {
        _unpause();
    }

    // Transfer restrictions based on blacklist
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        require(!blacklist[_msgSender()] && !blacklist[to], "Address is blacklisted");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        require(!blacklist[from] && !blacklist[to], "Address is blacklisted");
        return super.transferFrom(from, to, amount);
    }

    // Burn function with reentrancy protection
    function burn(uint256 amount) public nonReentrant {
        _burn(_msgSender(), amount);
        emit TokensBurned(_msgSender(), amount);
    }

    // Override required functions
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address from, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(from, amount);
    }
}
