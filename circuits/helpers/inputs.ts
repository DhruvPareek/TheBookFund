import * as path from "path";
import { bytesToBigInt, fromHex } from "@zk-email/helpers";
import { generateEmailVerifierInputs } from "@zk-email/helpers/dist/input-generators";
const fs = require('fs');

export const STRING_PRESELECTOR = "Your Email Address";
export const STRING_FROM= "from:Dhruv Pareek";

// export type IExampleCircuitInputs = {
//   emailAddressIndex: string;
//   address: string;
//   emailHeader: string[];
//   emailHeaderLength: string;
//   pubkey: string[];
//   signature: string[];
//   emailBody?: string[] | undefined;
//   emailBodyLength?: string | undefined;
//   precomputedSHA?: string[] | undefined;
//   bodyHashIndex?: string | undefined;
// };

export async function generateDhruvEmailVerifierCircuitInputs(
  email: string | Buffer,
  ethereumAddress: string
)/*: Promise<ITwitterCircuitInputs> */{
  const emailVerifierInputs = await generateEmailVerifierInputs(email, {
    shaPrecomputeSelector: STRING_PRESELECTOR,
  });

  const bodyRemaining = emailVerifierInputs.emailBody!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBufferEmail = Buffer.from(STRING_PRESELECTOR);
  const emailIndex =
    Buffer.from(bodyRemaining).indexOf(selectorBufferEmail) + selectorBufferEmail.length;

  const header = emailVerifierInputs.emailHeader!.map((c) => Number(c)); // Char array to Uint8Array
  const selectorBufferFrom = Buffer.from(STRING_FROM);
  const senderEmailIndex =
    Buffer.from(header).indexOf(selectorBufferFrom) -1; //+ selectorBufferFrom.length;

  const address = bytesToBigInt(fromHex(ethereumAddress)).toString();

  const inputJson = {
    ...emailVerifierInputs,
    emailAddressIndex: emailIndex.toString(),
    dhruvSenderIndex: senderEmailIndex.toString(),
    address,
  };
  fs.writeFileSync("./inputLak.json", JSON.stringify(inputJson))
}

(async () => {
    await generateDhruvEmailVerifierCircuitInputs(fs.readFileSync(path.join(__dirname, "./emls/LakEmail.eml")), "0x1234567890123456789012345678901234567890");
}) ();