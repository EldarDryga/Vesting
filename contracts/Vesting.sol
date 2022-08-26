// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Vesting
/// @author Eldar Dryga
/// @notice this contract allows you to distribute tokens to users within a certain time

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 private immutable _token;

    uint32 public periodOfDistributionInDays;
    uint32 public amountOfDistributionPerUser;
    uint128 public users;
    uint256 public maxUsers;

    struct UsersInfo {
        uint256 userTime;
        uint256 claimedRevard;
        uint256 allClaimedRevard;
        uint256 finalDistributionTime;
    }
    mapping(address => UsersInfo) public infoOfUser;

    constructor(address token_) {
        require(token_ != address(0));
        _token = IERC20(token_);
    }

    /// @param _amountOfDistribution total number of tokens to give away
    /// @param _periodOfDistributionInDays the number of days during which the distribution will take place
    /// @param _amountOfDistributionPerUser the amount of tokens for distribution for 1 user
    function startVesting(
        uint256 _amountOfDistribution,
        uint16 _periodOfDistributionInDays,
        uint32 _amountOfDistributionPerUser
    ) public onlyOwner {
        _token.safeTransferFrom(
            msg.sender,
            address(this),
            _amountOfDistribution
        );
        periodOfDistributionInDays = _periodOfDistributionInDays;
        amountOfDistributionPerUser = _amountOfDistributionPerUser;
        maxUsers = _amountOfDistribution / amountOfDistributionPerUser;
    }

    /// @notice this function can only be called by the owner of the contract
    /// @dev call this function to start vesting

    function join() public nonReentrant {
        require(periodOfDistributionInDays != 0, "Vesting has not started");
        infoOfUser[msg.sender].userTime = getCurrentTime();
        require(
            infoOfUser[msg.sender].claimedRevard == 0,
            "You have already started vesting, use claimRevard to receive your revard"
        );
        users++;
        require(
            maxUsers >= users,
            "Unfortunately, the tokens for distribution have already been distributed, or are distributing to the remaining users"
        );
        infoOfUser[msg.sender].finalDistributionTime =
            getCurrentTime() +
            (periodOfDistributionInDays * 86400);
    }

    /// @dev Returns current timestamp
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice call this function to receive available tokens
    function claimRevard() public nonReentrant {
        require(periodOfDistributionInDays != 0, "Vesting has not started");
        require(
            infoOfUser[msg.sender].userTime > 0,
            "You have not joined the vesting"
        );
        require(
            infoOfUser[msg.sender].finalDistributionTime != 0,
            "You have received all tokens"
        );

        uint256 tokenPerSecond = (amountOfDistributionPerUser * 1000000) /
            (periodOfDistributionInDays * 86400);
        infoOfUser[msg.sender].claimedRevard =
            (getCurrentTime() - infoOfUser[msg.sender].userTime) *
            tokenPerSecond;

        if (getCurrentTime() >= infoOfUser[msg.sender].finalDistributionTime) {
            infoOfUser[msg.sender].claimedRevard =
                amountOfDistributionPerUser -
                infoOfUser[msg.sender].allClaimedRevard;
            _token.safeTransfer(
                msg.sender,
                infoOfUser[msg.sender].claimedRevard
            );
            infoOfUser[msg.sender].finalDistributionTime = 0;
        } else {
            _token.safeTransfer(
                msg.sender,
                infoOfUser[msg.sender].claimedRevard / 1000000
            );
            infoOfUser[msg.sender].userTime = getCurrentTime();
        }
        infoOfUser[msg.sender].allClaimedRevard =
            infoOfUser[msg.sender].allClaimedRevard +
            infoOfUser[msg.sender].claimedRevard /
            1000000;
    }

    /// @notice Use this function to see, what revard you can claim
    function showRevardToClaim() public view returns (uint256) {
        if (getCurrentTime() >= infoOfUser[msg.sender].finalDistributionTime) {
            revert("Time to claim all your revard!");
        } else {
            uint256 tokenPerSecond = (amountOfDistributionPerUser * 1000000) /
                (periodOfDistributionInDays * 86400);
            uint256 claimedRevard = ((getCurrentTime() -
                infoOfUser[msg.sender].userTime) * tokenPerSecond) / 1000000;
            return (claimedRevard);
        }
    }

    ///@dev call this function to stop this vesting
    function stopVesting() public onlyOwner {
        periodOfDistributionInDays = 0;
        users = 0;
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }
}
