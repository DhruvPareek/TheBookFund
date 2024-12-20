# The Book Fund
A proof of concept of a method to disperse funds to targeted recipients with ZKEmail zero knowledge proofs and a Chainlink Oracle. More specifically, a method to allow people to verify their identity onchain via a cryptographic proof generated from a received email, then disperse some amount of USDC to the verified identity based on a defined mapping of identities to values stored in a database accessed by a Chainlink Oracle.

This project uses that framework to create a platform which connects donors to UCLA students purchasing books. This works by:
   1. A UCLA student Joe Bruin (with email address joebruin@ucla.edu) purchases a book online through an online retailer for $23.94.
   2. The retailer stores the book purchase in their database as a mapping of joebruin@ucla.edu-->$23.94.
   3. The Joe Bruin generates a cyrptographic proof with a zkey generated from the circuits/src/DhruvEmailVerifier.circom circuit. The proof generation requires an eml file from an email sent to an @ucla.edu email address of a specific format. By submitting this eml file of a received email to generate a proof allows Joe Bruin to prove to others that he is a UCLA student in control of the email address joebruin@ucla.edu.
   4. Joe Bruin submits this proof to the VerifyEmail function of the smart contract contracts/src/TheFund.sol. If the proof can be verified, joebruin@ucla.edu is stored in a mapping in the smart contract which saves email addresses to the ethereum address used to verify that email address.
   5. Joe Bruin calls the claimFunds() function to claim USDC corresponding to his purchase of books from the book store.
      - claimFunds() calls requestPriceData() from the EmailOracle smart contract.
      - requestPriceData() uses Chainlink Function's AnyAPI service to make a request to the API "https://y3ugr0hill.execute-api.us-east-1.amazonaws.com/production/email?student_email=joebruin@ucla.edu" (a mockAPI I created to mimick a book store's database) with Joe Bruin's email address. This API request and corresponding oracle request will return $23.94, because that is the value in the database that the book retailer saved.
   6. Upon the oracle request returning, the function fulfill() from the EmailOracle contract will call transferUSDC() from the TheFund contract. transferUSDC() will send $23.94 to Joe Bruin's ethereum address.

All of this assumes that there are donors willing to deposit USDC into the contract for students to claim after their book purchases.

## Other ways this framework could be used
I think ZKEmail creates a very powerful ability to link Web2 and Web3 identity, allowing people to prove some sort of web2 identity (in this case email address) to programmatically send/receive moeny based on that identity.

For example, funding teachers looking to purchase school supplies from Staples (or any other retailer of that type) to stock their classrooms. Say a teacher purchases school supplies from Staples, and Staples saves her purchases alongside her school district email address in their database. Then, there could be a platform similar to this one which connects donors (depositors of USDC), to school teachers who verify their email addresses cryptographically, and uses Staples's database of purchases to verify the amount of the teachers' purchase to distribute back to them.

Additionally, the UCLA Internet Research Initiative could use a platform like this. The UCLA Internet Research Initiative gives ~10 students $7500 over the course of a school year to spend towards a research project. Every student who wins the 'research scholarship' receives a congradulatory email from Professor Leonard Kleinrock. A project with a framework similar to this one could be created where students who receive the congradulatory email generate a cryptographic proof from it, and submit the proof to a smart contract which verifies the validity of the email and disperses $7500 to every person who submits a valid email. This example does not require a Chainlink Oracle.

To Do:
- Create a frontend for proof generation.
- Create some form of limit on withdraws. You don't want a student to buy $1000 worth of books, then claim $1000 from the smart contract, and then resell all of the books online to make a proft.
- Prevent someone from claiming money twice from the same purchase (very simple lol just forgot to do this earlier).
- Get access to some online retailer's database of purchases.
- Create some type of work around for the Chainlink Functions Oracle because Functions is in Beta.
