pragma solidity ^0.5.1;

import "../CourtStake/CourtStake.sol";

contract CourtStakeMock is CourtStakeDummy {
    function suspendAccountByGovOrGur(address account, uint256 numOfDays) public onlyGovOrGur{
    }
}
