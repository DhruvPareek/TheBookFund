pragma solidity 0.8.20;
//0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
//0x0000000000000000000000000000000000000000
import {Script} from "forge-std/Script.sol";
import {EmailOracle} from "../src/EmailOracle.sol";
import {TheFund} from "../src/TheFund.sol";
import {IERC20} from "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@zk-email/contracts/DKIMRegistry.sol";
import "@zk-email/contracts/utils/StringUtils.sol";
import { Verifier } from "../src/verifier.sol";

contract DeployContracts is Script {
    address linkTokenAddr = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address usdcTokenAddr = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    function run() external returns (EmailOracle) {
        //initializations of variables should go before startBroadcast
        vm.startBroadcast(); //everything inbetween these are transactions

        Verifier proofVerifier = new Verifier();
        DKIMRegistry dkimRegistry = new DKIMRegistry(msg.sender);

        //Set the DKIM public key hash for gmail.com
        dkimRegistry.setDKIMPublicKeyHash(
            "gmail.com",
            0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788
        );

        // Deploy EmailOracle without TheFund address
        EmailOracle emailOracle = new EmailOracle(address(0));

        // Deploy TheFund with EmailOracle address
        TheFund theFund = new TheFund(address(emailOracle), proofVerifier, dkimRegistry);

        // Update EmailOracle with TheFund address
        emailOracle.setTheFundAddress(address(theFund));

        // Fund the EmailOracle with LINK
        uint256 amountToSendLink = 0.3 ether; //0.3 LINK
        IERC20 linkToken = IERC20(linkTokenAddr);
        linkToken.transfer(address(emailOracle), amountToSendLink);

        // Fund the TheFund with USDC
        // uint256 amountToSendUSDC = 100000000; //100 USDC
        // IERC20 usdcToken = IERC20(usdcTokenAddr);
        // usdcToken.transfer(address(theFund), amountToSendUSDC);

        // vm.stopBroadcast();
        return emailOracle;
    }
}