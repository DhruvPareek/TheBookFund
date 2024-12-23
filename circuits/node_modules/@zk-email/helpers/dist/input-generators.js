"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateEmailVerifierInputsFromDKIMResult = exports.generateEmailVerifierInputs = void 0;
const binary_format_1 = require("./binary-format");
const constants_1 = require("./constants");
const dkim_1 = require("./dkim");
const sha_utils_1 = require("./sha-utils");
/**
 *
 * @description Generate circuit inputs for the EmailVerifier circuit from raw email content
 * @param rawEmail Full email content as a buffer or string
 * @param params Arguments to control the input generation
 * @returns Circuit inputs for the EmailVerifier circuit
 */
async function generateEmailVerifierInputs(rawEmail, params = {}) {
    const dkimResult = await (0, dkim_1.verifyDKIMSignature)(rawEmail);
    return generateEmailVerifierInputsFromDKIMResult(dkimResult, params);
}
exports.generateEmailVerifierInputs = generateEmailVerifierInputs;
/**
 *
 * @description Generate circuit inputs for the EmailVerifier circuit from DKIMVerification result
 * @param dkimResult DKIMVerificationResult containing email data and verification result
 * @param params Arguments to control the input generation
 * @returns Circuit inputs for the EmailVerifier circuit
 */
function generateEmailVerifierInputsFromDKIMResult(dkimResult, params = {}) {
    const { headers, body, bodyHash, publicKey, signature, } = dkimResult;
    // SHA add padding
    const [messagePadded, messagePaddedLen] = (0, sha_utils_1.sha256Pad)(headers, params.maxHeadersLength || constants_1.MAX_HEADER_PADDED_BYTES);
    const circuitInputs = {
        emailHeader: (0, binary_format_1.Uint8ArrayToCharArray)(messagePadded), // Packed into 1 byte signals
        emailHeaderLength: messagePaddedLen.toString(),
        pubkey: (0, binary_format_1.toCircomBigIntBytes)(publicKey),
        signature: (0, binary_format_1.toCircomBigIntBytes)(signature),
    };
    if (!params.ignoreBodyHashCheck) {
        if (!body || !bodyHash) {
            throw new Error('body and bodyHash are required when ignoreBodyHashCheck is false');
        }
        const bodyHashIndex = headers.toString().indexOf(bodyHash);
        const maxBodyLength = params.maxBodyLength || constants_1.MAX_BODY_PADDED_BYTES;
        // 65 comes from the 64 at the end and the 1 bit in the start, then 63 comes from the formula to round it up to the nearest 64.
        // see sha256algorithm.com for a more full explanation of padding length
        const bodySHALength = Math.floor((body.length + 63 + 65) / 64) * 64;
        const [bodyPadded, bodyPaddedLen] = (0, sha_utils_1.sha256Pad)(body, Math.max(maxBodyLength, bodySHALength));
        const { precomputedSha, bodyRemaining, bodyRemainingLength } = (0, sha_utils_1.generatePartialSHA)({
            body: bodyPadded,
            bodyLength: bodyPaddedLen,
            selectorString: params.shaPrecomputeSelector,
            maxRemainingBodyLength: maxBodyLength,
        });
        circuitInputs.emailBodyLength = bodyRemainingLength.toString();
        circuitInputs.precomputedSHA = (0, binary_format_1.Uint8ArrayToCharArray)(precomputedSha);
        circuitInputs.bodyHashIndex = bodyHashIndex.toString();
        circuitInputs.emailBody = (0, binary_format_1.Uint8ArrayToCharArray)(bodyRemaining);
    }
    return circuitInputs;
}
exports.generateEmailVerifierInputsFromDKIMResult = generateEmailVerifierInputsFromDKIMResult;
