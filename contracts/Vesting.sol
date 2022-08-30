// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
/// @title Vesting
/// @author Eldar Dryga
/// @notice this contract allows you to distribute tokens to users within a certain time

contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;


    IERC20 internal immutable _token;

    uint256 public periodOfDistributionInDays;
    uint256 public amountOfDistributionPerUser;
    uint256 public users;
    uint256 public maxUsers;

    struct UsersInfo {
        uint32 userTime;
        uint32 finalDistributionTime;
        uint128 claimedRevard;
        uint128 allClaimedRevard;
    }
    mapping(address => UsersInfo) public infoOfUser;

    event VestingStarted(uint256 _amountOfDistribution,
        uint256 _periodOfDistributionInDays,
        uint256 _amountOfDistributionPerUser,
        uint256 _maxusers);
        event UserClaimedRevard(address indexed _user, uint256 _claimedRevard, uint _allClaimedRevard);
    constructor(address token_) {
        require(token_ != address(0), "Address of token = 0");
        _token = IERC20(token_);
    }

    /// @param _amountOfDistribution total number of tokens to give away
    /// @param _periodOfDistributionInDays the number of days during which the distribution will take place
    /// @param _amountOfDistributionPerUser the amount of tokens for distribution for 1 user
    function startVesting(
        uint256 _amountOfDistribution,
        uint256 _periodOfDistributionInDays,
        uint256 _amountOfDistributionPerUser
    ) public onlyOwner {
        _token.safeTransferFrom(
            msg.sender,
            address(this),
            _amountOfDistribution
        );
        periodOfDistributionInDays = _periodOfDistributionInDays;
        amountOfDistributionPerUser = _amountOfDistributionPerUser;
        maxUsers = _amountOfDistribution / amountOfDistributionPerUser;
        emit VestingStarted(_amountOfDistribution, _periodOfDistributionInDays, _amountOfDistributionPerUser, maxUsers);
    }

    /// @notice this function can only be called by the owner of the contract
    /// @dev call this function to start vesting

    function join() public {
        users++;
        require(periodOfDistributionInDays != 0, "Vesting has not started");
        require(
            infoOfUser[msg.sender].userTime == 0,
            "You have already started vesting, use claimRevard to receive your revard"
        );
        require(
            maxUsers >= users,
            "Unfortunately, the tokens for distribution have already been distributed, or are distributing to the remaining users"
        );
        uint dayInSeconds = 86400;
        infoOfUser[msg.sender].userTime = getCurrentTime();
        infoOfUser[msg.sender].finalDistributionTime =  (getCurrentTime() +
        (periodOfDistributionInDays * dayInSeconds)).toUint32();
    }

    /// @dev Returns current timestamp
    function getCurrentTime() internal view virtual returns (uint32) {
        return  (block.timestamp).toUint32();
    }

    /// @notice call this function to receive available tokens
    function claimRevard() public  {
        require(periodOfDistributionInDays != 0, "Vesting has not started");
        require(
            infoOfUser[msg.sender].userTime > 0,
            "You have not joined the vesting"
        );
        require(
            infoOfUser[msg.sender].finalDistributionTime != 0,
            "You have received all tokens"
        );
        uint dayInSeconds = 86400;
        uint256 oneMillion = 1000000;
        uint256 tokenPerSecond = (amountOfDistributionPerUser * oneMillion) /
            (periodOfDistributionInDays * dayInSeconds);
        
 
        if (getCurrentTime() >= infoOfUser[msg.sender].finalDistributionTime) {
            infoOfUser[msg.sender].claimedRevard =
                (amountOfDistributionPerUser).toUint128() -
                infoOfUser[msg.sender].allClaimedRevard;
            _token.safeTransfer(
                msg.sender,
                infoOfUser[msg.sender].claimedRevard
            );
            infoOfUser[msg.sender].finalDistributionTime = 0;
        } else {
            infoOfUser[msg.sender].claimedRevard =
            ((getCurrentTime() - infoOfUser[msg.sender].userTime) *
            tokenPerSecond).toUint128();
            _token.safeTransfer(
                msg.sender,
                infoOfUser[msg.sender].claimedRevard / oneMillion
            );
            infoOfUser[msg.sender].userTime = getCurrentTime();
        }
        infoOfUser[msg.sender].allClaimedRevard =
            (infoOfUser[msg.sender].allClaimedRevard +
            infoOfUser[msg.sender].claimedRevard /
            oneMillion).toUint128();
            emit UserClaimedRevard(msg.sender, (infoOfUser[msg.sender].claimedRevard / oneMillion), infoOfUser[msg.sender].allClaimedRevard);
    }

    /// @notice Use this function to see, what revard you can claim
    function showRevardToClaim() public view returns (uint128 claimedRevard) {
            uint dayInSeconds = 86400;
            uint256 oneMillion = 1000000;
            if (getCurrentTime() >= infoOfUser[msg.sender].finalDistributionTime) {
            claimedRevard =
                (amountOfDistributionPerUser).toUint128() -
                infoOfUser[msg.sender].allClaimedRevard;
            
            }
            else{
            uint256 tokenPerSecond = (amountOfDistributionPerUser * oneMillion) /
                (periodOfDistributionInDays * dayInSeconds);
              claimedRevard = (((getCurrentTime() -
                infoOfUser[msg.sender].userTime) * tokenPerSecond) / oneMillion).toUint128();
            }
            
        
    }

    ///@dev call this function to stop this vesting
    function stopVesting() public onlyOwner {
        periodOfDistributionInDays = 0;
        users = 0;
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }
    
}
