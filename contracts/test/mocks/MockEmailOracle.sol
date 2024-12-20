// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITheFund {
    function withdrawTo(string calldata emailAddr, uint256 amount) external;
    function transferUSDC(string calldata emailAddr, uint256 _amount) external;
}

contract MockEmailOracle {
    address private theFundContractAddr;
    ITheFund theFundContract;

    // Mapping to store the requested email addresses
    mapping(bytes32 => string) public reqIdToEmail;
    uint256 public requestCounter;

    event RequestPrice(bytes32 indexed requestId, uint256 price);

    constructor(address _theFundContractAddr) {
        theFundContract = ITheFund(_theFundContractAddr);
        theFundContractAddr = _theFundContractAddr;
    }

    function setTheFundAddress(address _theFundContractAddr) external {
        theFundContract = ITheFund(_theFundContractAddr);
        theFundContractAddr = _theFundContractAddr;
    }

    function requestPriceData(string calldata emailAddress) external returns (bytes32 requestId) {
        require(msg.sender == theFundContractAddr, "Only TheFund can call this function");

        // Simulate generating a request ID
        requestId = keccak256(abi.encodePacked(emailAddress, block.timestamp, requestCounter));
        reqIdToEmail[requestId] = emailAddress;
        requestCounter++;

        // Simulate immediate fulfillment with a mock price
        uint256 mockPrice = 100 * 10 ** 6; // 100 USDC with 6 decimals
        fulfill(requestId, mockPrice);

        return requestId;
    }

    function fulfill(bytes32 _requestId, uint256 _price) internal {
        emit RequestPrice(_requestId, _price);
        theFundContract.transferUSDC(reqIdToEmail[_requestId], _price);
    }
}
