// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/TheFund.sol";
import "./mocks/MockEmailOracle.sol"; // Update the import path as necessary
import { Verifier } from "../src/verifier.sol";
import "@zk-email/contracts/DKIMRegistry.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TheFundTest is Test {
    // using StringUtils for *;

    TheFund public theFund;
    MockEmailOracle public emailOracle;
    MockERC20 public mockUSDC;
    address public userOne = address(0x1234567890123456789012345678901234567890);
    address public userTwo = address(0xDEAD);

    Verifier proofVerifier;
    DKIMRegistry dkimRegistry;

    function setUp() public {
        address owner = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);

        proofVerifier = new Verifier();
        dkimRegistry = new DKIMRegistry(owner);

        //Set the DKIM public key hash for gmail.com
        dkimRegistry.setDKIMPublicKeyHash(
            "gmail.com",
            0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788
        );


        // Deploy the mock OracleEmail contract
        emailOracle = new MockEmailOracle(address(0));

        // Deploy TheFund contract with the mock OracleEmail address
        theFund = new TheFund(address(emailOracle), proofVerifier, dkimRegistry);

        // Deploy the mock USDC token at the hardcoded address in TheFund
        vm.etch(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, type(MockERC20).runtimeCode);
        mockUSDC = MockERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);

        // Update the OracleEmail contract with TheFund address
        emailOracle.setTheFundAddress(address(theFund));

        // console.log("mockUSDC address: %s", address(mockUSDC));
        // console.log("usdcToken address in TheFund: %s", theFund.getUSDCAddress());

        // Mint some USDC to the user
        mockUSDC.mint(userOne, 1000 * 10 ** 6); // 1000 USDC with 6 decimals

        vm.startPrank(userOne);
        mockUSDC.approve(address(theFund), 100 * 10 ** 6);
        theFund.depositUSDC(100 * 10 ** 6);
        vm.stopPrank();
    }

    function testDepositUSDC(uint256 amount) public {
        // Bound the amount to be between 1 and 900 * 10 ** 6 (user's USDC balance)
        amount = bound(amount, 1, 900 * 10 ** 6);
        vm.startPrank(userOne);
        mockUSDC.approve(address(theFund), amount);
        theFund.depositUSDC(amount);
        vm.stopPrank();

        // Verify the USDC balance of TheFund contract
        assertEq(mockUSDC.balanceOf(address(theFund)), (100 * 10 ** 6) + amount);
    }

    function testVerifyEmail() public {
        vm.startPrank(userTwo);
        vm.expectRevert("Invalid address");
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);
        vm.stopPrank();

        vm.startPrank(userOne);
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);

        vm.expectRevert("Email already claimed");
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);

        vm.expectRevert("Sender address must be dhruvpareek883@gmail.com");
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d6740333838665657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);
        
        vm.expectRevert("invalid dkim signature");
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d01488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);
        
        vm.expectRevert();//testing submitting invalid proof
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704a8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);
        vm.stopPrank();
    }

    function testClaimFundsAndTransferUSDC() public {
        // Verify the USDC balance of TheFund contract
        assertEq(mockUSDC.balanceOf(address(theFund)), 100 * 10 ** 6);

        // Verify the USDC balance of userOne
        assertEq(mockUSDC.balanceOf(userOne), 900 * 10 ** 6);

        vm.prank(userOne);
        theFund.VerifyEmail([0x1bd2c68cfbc1dabff5d7464477e737847965704e8540564e61a256eed62677fc, 0x0ff5f95647ebf187fe4753c0b6a0853958f14d29cd65d7eb8acf92d9c5a44f70,0x091495c00a4ed9a9c5e99b1fe3ac3a19aacfe47ec9c842779d06f917f19a33b8, 0x13acb2755b639d11a9e7c3050fd4986f0f1ffa9a0a81d2eeadf01c5c0914f4b9, 0x2b1e183d79ee63ed049d877af3a06e83e7aef92997579e66557554c04130ffa5, 0x2754e2eb2a536339d2175b9df1e10a74477349e3dab972222e2ada03266786b0, 0x2024f4445541b9fbe106e5cba0cededb1ae1829891b56a43d7af0c8404916957, 0x27925d1f9830a6b2e58f86052991b77b40827b2be19a6363ce36235430b12fe4], [0x0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788,0x0000000000000000007564652e616c63752e6740343636386e616d68736b616c,0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864,0x0000000000000000000000001234567890123456789012345678901234567890]);

        vm.expectRevert("Invalid email address");
        theFund.claimFunds("lakshman8664@g.ucla.edu");

        uint256 userOneBalanceBefore = mockUSDC.balanceOf(userOne);
        vm.prank(userOne);
        theFund.claimFunds("lakshman8664@g.ucla.edu");//This line also tests TransferUSDC because the OracleEmail contract calls TransferUSDC

        assertEq(mockUSDC.balanceOf(userOne), userOneBalanceBefore + 100 * 10 ** 6);

        vm.expectRevert("Only oracle can grant withdraw");
        theFund.transferUSDC("dpak@gmail.com", 100 * 10 ** 6);
    }
}
