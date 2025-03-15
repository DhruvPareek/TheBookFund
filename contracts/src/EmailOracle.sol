// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Chainlink, ChainlinkClient} from "node_modules/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "node_modules/@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "node_modules/@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

interface ITheFund {
    function withdrawTo(string calldata emailAddr, uint256 amount) external;
    function transferUSDC(string calldata emailAddr, uint256 _amount) external;
}

contract EmailOracle is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => string) public reqIdToEmail;
    address private theFundContractAddr;
    ITheFund theFundContract;

    event RequestPrice(bytes32 indexed requestId, uint256 price);

    constructor(address _theFundContractAddr) ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        _setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        theFundContract = ITheFund(_theFundContractAddr);
        theFundContractAddr = _theFundContractAddr;
    }

    function setTheFundAddress(address _theFundContractAddr) external onlyOwner {
        theFundContract = ITheFund(_theFundContractAddr);
        theFundContractAddr = _theFundContractAddr;
    }

    /**
     * Create a Chainlink request to retrieve API response
     */
    function requestPriceData(string calldata emailAddress) external returns (bytes32 requestId) {
        require(msg.sender == theFundContractAddr, "Only TheFund can call this function");
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Dynamic URL construction with the input email address
        string memory baseUrl = "https://y3ugr0hill.execute-api.us-east-1.amazonaws.com/production/email?student_email=";
        string memory finalUrl = string(abi.encodePacked(baseUrl, emailAddress));
        req._add("get", finalUrl);

        // Set the path to find the desired data in the API response, assuming the response format is:
        // {"price": xxx.xx}
        req._add("path", "price");

        int256 timesAmount = 1000000;
        req._addInt("times", timesAmount);

        // Sends the request
        requestId = _sendChainlinkRequest(req, fee);
        reqIdToEmail[requestId] = emailAddress;
        return requestId;
    }

    /**
     * Receive the api response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint256 _price//in cents
    ) external recordChainlinkFulfillment(_requestId) {
        emit RequestPrice(_requestId, _price);
        theFundContract.transferUSDC(reqIdToEmail[_requestId], _price);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}