// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@zk-email/contracts/DKIMRegistry.sol";
import "@zk-email/contracts/utils/StringUtils.sol";
import { Verifier } from "./verifier.sol";

interface IOracleEmail {
    function requestPriceData(string memory emailAddress) external returns (bytes32 requestId);
}

contract TheFund is Ownable {
    using StringUtils for *;

    using SafeERC20 for IERC20;
    address public oracleContractAddr;
    IOracleEmail oracleEmailContract;
    IERC20 public usdcToken = IERC20(0x14196F08a4Fa0B66B7331bC40dd6bCd8A1dEeA9F);

    uint16 public constant bytesInPackedBytes = 31;
    string constant domain = "gmail.com";

    uint32 public constant pubKeyHashIndexInSignals = 0; // index of DKIM public key hash in signals array
    uint32 public constant targetEmailAddressIndexInSignals = 1; // index of packed target email address in signals array
    uint32 public constant senderAddressIndexInSignals = 2; // index of sender's email address in signals array
    uint32 public constant ethereumAddressIndexInSignals = 3; // index of user's ethereum address in signals array
    uint32 public constant emailLengthInSignals = 1; // length of packed receiver email address in signals array

    DKIMRegistry dkimRegistry;
    Verifier public immutable verifier;

    // Mapping of email addresses prooved to ethereum address
    mapping(string => address payable) public emailAddresstoEthereumAddress;

    event Payment(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event WithdrawERC20(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );
    event USDCdeposit(address indexed sender, uint256 amount);

    constructor(address _oracleEmailContractAddr, Verifier v, DKIMRegistry d) Ownable(msg.sender){
        oracleEmailContract = IOracleEmail(_oracleEmailContractAddr);
        oracleContractAddr = _oracleEmailContractAddr;

        verifier = v;
        dkimRegistry = d;
    }


    // Prove email ownership by submitting a proof of receiving an email from dhruvpareek883@gmail.com
    // @param proof ZK proof of the circuit - a[2], b[4] and c[2] encoded in series
    // @param signals Public signals of the circuit. First item is pubkey_hash, second item is target email address, 
        //third item is sender's email address, and the last one is etherum address
    function VerifyEmail(uint256[8] memory proof, uint256[4] memory signals) public returns (bool){

        // Check eth address committed to in proof matches msg.sender, to avoid replayability
        require(address(uint160(signals[ethereumAddressIndexInSignals])) == msg.sender, "Invalid address");

        //Check that the sender address is dhruvpareek883@gmail.com
        require(signals[senderAddressIndexInSignals] == 0x00000000000000006d6f632e6c69616d67403338386b65657261707675726864, "Sender address must be dhruvpareek883@gmail.com");

        // Verify the DKIM public key hash stored on-chain matches the one used in circuit
        bytes32 dkimPublicKeyHashInCircuit = bytes32(signals[pubKeyHashIndexInSignals]);
        require(dkimRegistry.isDKIMPublicKeyHashValid(domain, dkimPublicKeyHashInCircuit), "invalid dkim signature"); 

        // Veiry RSA and proof
        require(
            verifier.verifyProof(
                [proof[0], proof[1]],
                [[proof[2], proof[3]], [proof[4], proof[5]]],
                [proof[6], proof[7]],
                signals
            ),
            "Invalid Proof"
        );

        // Extract the username chunks from the signals. 
        // Note that this is not relevant now as username can fit in one signal
        uint256[] memory usernamePack = new uint256[](emailLengthInSignals);
        for (uint256 i = targetEmailAddressIndexInSignals; i < (targetEmailAddressIndexInSignals + emailLengthInSignals); i++) {
            usernamePack[i - targetEmailAddressIndexInSignals] = signals[i];
        }

        string memory messageBytes = StringUtils.convertPackedBytesToString(
            usernamePack,
            bytesInPackedBytes * emailLengthInSignals,
            bytesInPackedBytes
        );

        // Check if the email address has already been claimed
        require(emailAddresstoEthereumAddress[messageBytes] == address(0), "Email already claimed");

        // Store the email address to ethereum address mapping
        emailAddresstoEthereumAddress[messageBytes] = payable(msg.sender);
        return true;
    }


    //Set the address of the oracle contract used to retrieve price data from the database
    function setEmailOracleAddress(address _oracleContractAddr) external onlyOwner {
        oracleEmailContract = IOracleEmail(_oracleContractAddr);
        oracleContractAddr = _oracleContractAddr;
    }

    //Donate USDC to the fund for students to request funds from
    //Tbh unnecessary lol
    function depositUSDC(uint256 amount) external {
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit USDCdeposit(msg.sender, amount);
    }

    //Claim or receive funds from the donated USDC
    // - User must have already used VerifyEmail to prove ownership of the email address
    // - Oracle request is made to verify the quantity pruchased at book store by this user
    function claimFunds(string memory emailAddr) external {
        require(usdcToken.balanceOf(address(this)) > 0, "No Funds :(");
        require(emailAddresstoEthereumAddress[emailAddr] == msg.sender, "Invalid email address");
        oracleEmailContract.requestPriceData(emailAddr);
    }

    //Oracle calls this function to transfer amount of USDC to user corresponding to email address found in database
    function transferUSDC(string calldata emailAddr, uint256 _amount) external {
        require(msg.sender == oracleContractAddr, "Only oracle can grant withdraw");
        address payable _to = emailAddresstoEthereumAddress[emailAddr];
        usdcToken.safeTransfer(_to, _amount);
        emit WithdrawERC20(_to, 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, _amount);
    }
}