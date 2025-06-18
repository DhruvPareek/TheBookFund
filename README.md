# The Book Fund
A proof of concept of a method to disperse funds to targeted recipients using zero knowledge proofs (generated with the ZKEmail library) and an oracle (Chainlink Functions). More specifically, a method to allow people to verify their identity onchain via a cryptographic proof generated from a received email, then disperse some amount of USDC to the verified identity based on a defined mapping of identities to values stored in a database accessed by a Chainlink Oracle.
<br>
<br>
Video Explanation - https://www.youtube.com/watch?v=Pt1bQCVIWGg&t=1s&ab_channel=DhruvPareek
<br>
<br>
This project implements that framework to create a platform which connects "donors" to UCLA students purchasing items from a retailer, allowing UCLA students who purchased something to redeem money equivalent to their purchases. I specified it further, by creating a pretend example where UCLA students who purchased books from a book retailer can receive money corresponding to the amount of money they spent purchasing books. The project works by:
   1. A donor "deposits" or "donates" USDC into the smart contract.
   2. Joe Bruin, a UCLA student (with email address joebruin@g.ucla.edu), purchases a book online through a retailer for $23.94 (arbitrary amount).
   3. The retailer stores the book purchase in their database as a mapping of: "joebruin@g.ucla.edu"-->$23.94.
   4. Joe Bruin generates a cryptographic proof using some email he received at joebruin@g.ucla.edu.
   5. Joe uses his ethereum account with address 0xabc to submit the cryptographic proof to a function in a smart contract. Once the proof is verified, the smart contract saves the mapping of: "joebruin@g.ucla.edu"-->0xabc.
   6. Joe then calls another function from the same smart contract to be repaid for the amount of USDC he spent at the book store.
      - This function uses an oracle to make an API call to the book retailer's database with "joebruin@g.ucla.edu" as the identifier. The oracle will return $23.94.
   8. The smart contract sends $23.94 worth of USDC to 0xabc.

#### The steps again in further detail:

   1. A donor "deposits" or "donates" USDC into the contracts/src/TheFund.sol smart contract.
   2. Joe Bruin, a UCLA student (with email address joebruin@g.ucla.edu), purchases a book online through an online retailer for $23.94 (arbitrary amount).
   3. The retailer stores the book purchase in their database as a mapping of: "joebruin@g.ucla.edu"-->$23.94.
   4. Joe Bruin generates a cryptographic proof with a zkey generated from the circuits/src/DhruvEmailVerifier.circom circuit. Joe generates the proof using values from an email he received at "joebruin@g.ucla.edu" as the inputs to the circuit. By using an email Joe received at "joebruin@g.ucla.edu" to generate inputs to the circuit allows Joe Bruin to generate a proof that proves to others that he is a UCLA student in control of the email address joebruin@g.ucla.edu.
   5. Joe Bruin submits this proof to the VerifyEmail() function of contracts/src/TheFund.sol using his ethereum address 0xabc. If the proof is verified, "joebruin@g.ucla.edu" is stored in a mapping in the smart contract as: "joebruin@g.ucla.edu"-->0xabc.
   6. Joe Bruin calls the claimFunds() function from contracts/src/TheFund.sol to redeem some amount of USDC corresponding to his purchase of books from the book store.
      - claimFunds() calls requestPriceData() from the EmailOracle smart contract.
      - requestPriceData() uses Chainlink Functions service to make a request to the API "https://y3ugr0hill.execute-api.us-east-1.amazonaws.com/production/email?student_email=joebruin@g.ucla.edu" (a mockAPI I created to mimick a book store's database). This API request and corresponding oracle request will return $23.94, because that is the value in the database that is saved corresponding to "joebruin@g.ucla.edu".
   7. Upon the oracle request returning, the function fulfill() from the EmailOracle contract will call transferUSDC() from the TheFund contract. transferUSDC() will send $23.94 to Joe Bruin's ethereum address.

#### Two assumptions:
 - The Oracle in this smart contract uses an API with access to the book retailer's database of purchases.
 - Donors are willing to donate USDC into the smart contract.

Additionally, this project has constraints on the email Joe Bruin can use to generate a proof. I constructed the circom circuits in this project so that the email that someone uses to verify his identity must be sent by dhruvpareek883@gmail.com and contain an email address in the body that matches the regex of the form: [a-zA-Z0-9._]+@g\.ucla\.edu. So Joe Bruin would have to receive an email from dhruvpareek883@gmail.com that says "joebruin@g.ucla.edu" in the body of the email to generate a valid proof for his identity. To see examples of emails that can generate a valid proof, look at circuits/helpers/emls.

## File/Code Breakdown
The circuits/src folder contains the circom circuits used to generate proofs that verify someone is a UCLA student. Essentially, someone will submit an eml file (which is simply an email that they downloaded) to generate a proof based on these circuits. To understand how ZKEmail's library of circuits works to create cryptographic proofs of the contents and metadata of emails, read more here: https://docs.zk.email/architecture/dkim-verification.
   - DhruvEmailVerifier.circom is the main circuit. It verifies the DKIM signatures of the submitted email are valid while also exposing the sender and a portion of the body of the email. In order to do those things properly, this circuit uses:
        - Dhruv_Sender_Regex.circom to verify that the submitted eml file is an email sent by dhruvpareek883@gmail.com. This circom circuit was generated by https://zkregex.com/, which converts regex to circom circuits.
        - UCLA_Email_Regex.circom to verify that there is some email address in the body of the email that matches the regex "[a-zA-Z0-9._]+@g\.ucla\.edu". This circuit was also generated by https://zkregex.com/.

The circuits/helpers/inputs.ts file can be used to generate inputs to the circom circuits from an eml file. Example eml files that can create a valid proof can be found in circuits/helpers/emls.

The contracts/src folder contains the smart contract logic. 
   - TheFund.sol is the point of interaction for users.
        - First, a user would call the VerifyEmail() function with their proof as the parameters. The VerifyEmail() function uses the verifier.sol file to do the proof verification. If the proof is verified, then the mapping from user's email address to ethereum address is saved in TheFund.sol.
        - Then, a user would call claimFunds() with their email address as the parameter to intiate the process to receive USDC from the smart contract to refund them for their book purchases (claimFunds intiates the oracle call to the book database through EmailOracle.sol to determine how much USDC the user should receive).
        - depositUSDC() is the function donors can use to donate USDC to the fund.
   - EmailOracle.sol uses Chainlink Functions to interact with the mock database of book purchases in order to determine how much money someone with the email address "XXX@g.ucla.edu" spent at the book store.
   - The verifyProof() function in verifier.sol verifies proofs generated with the circom circuits for the project.

## How to Use
#### Part 1: Generate The Proof
   Follow these steps in the circuits/src folder, these steps are analagous to the Usage Guide for ZKEmail: https://docs.zk.email/zk-email-verifier/usage-guide
   1. Follow the ZKEmail setup guide to download necessary packages: https://docs.zk.email/zk-email-verifier/setup
   2. Install Rust and Circom: https://docs.circom.io/getting-started/installation/#installing-dependencies
   3. Compile the DhruvEmailVerifier.circom circuit `circom -l node_modules DhruvEmailVerifier.circom -o --r1cs --wasm --sym --c --O0`
   4. Enter circuits/helpers and run `npx ts-node inputs.ts` to generate the inputs for the circuit. You can see at the bottom of inputs.ts that it is preset to use the LakEmail.eml file to generate inputs.

## Other Possibilities
ZKEmail creates a very powerful ability to link Web2 and Web3 identity, allowing people to prove some sort of web2 identity (in this case email address) on-chain. I built on that to programmatically send/receive money based on a web2 identity.

For example, this project could be altered to fund teachers looking to purchase school supplies from Staples (or any other retailer of that type) to stock their classrooms. First, a teacher would purchase school supplies from Staples, then Staples would save her purchase amount alongside her school district email address in their database (ex. "JDerby@millercreekmiddleschool.edu"-->$88.61). Then, the teacher would generate a proof using her school supplied email address to prove she is a teacher at Miller Creek Middle School. Finally, a smart contract with API access via an oracle to a Staples database could verify the amount of the teachers' purchase to distribute back to them.

As another example, the UCLA Internet Research Initiative could use a project like this. The UCLA Internet Research Initiative gives 10-15 students $7500 over the course of a school year to spend towards a research project. Every student who wins the 'research scholarship' receives a congradulatory email from Professor Leonard Kleinrock. A project with a framework similar to this one could be created where students who win the research scholarship use their congradulatory email to generate a cryptographic proof, then submit the proof to a smart contract which verifies the validity of the email and disperses $7500 to every person who submits a valid proof. This example would not require an Oracle.

### To Do:
- Create a frontend for proof generation.
- Create some form of limit on withdraws. You don't want a student to buy $1000 worth of books, then claim $1000 from the smart contract, and then resell all of the books online to make a proft. The amount that can be withdrawan should be limited below $100.
- Prevent someone from claiming money twice from the same purchase (very simple lol just forgot to do this earlier).
- Get access to some online retailer's database of purchases.
- Create some type of work around for the Chainlink Functions because Functions is in Beta.
