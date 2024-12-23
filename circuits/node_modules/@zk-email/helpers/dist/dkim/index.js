"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyDKIMSignature = void 0;
const node_forge_1 = require("node-forge");
const dkim_verifier_1 = require("../lib/mailauth/dkim-verifier");
const tools_1 = require("../lib/mailauth/tools");
const sanitizers_1 = __importDefault(require("./sanitizers"));
/**
 *
 * @param email Entire email data as a string or buffer
 * @param domain Domain to verify DKIM signature for. If not provided, the domain is extracted from the `From` header
 * @param enableSanitization If true, email will be applied with various sanitization to try and pass DKIM verification
 * @returns
 */
async function verifyDKIMSignature(email, domain = '', enableSanitization = true) {
    const emailStr = email.toString();
    let dkimResult = await tryVerifyDKIM(email, domain);
    // If DKIM verification fails, try again after sanitizing email
    let appliedSanitization;
    if (dkimResult.status.comment === 'bad signature' && enableSanitization) {
        const results = await Promise.all(sanitizers_1.default.map((sanitize) => tryVerifyDKIM(sanitize(emailStr), domain).then((result) => ({
            result,
            sanitizer: sanitize.name,
        }))));
        const passed = results.find((r) => r.result.status.result === 'pass');
        if (passed) {
            console.log(`DKIM: Verification passed after applying sanitization "${passed.sanitizer}"`);
            dkimResult = passed.result;
            appliedSanitization = passed.sanitizer;
        }
    }
    const { status: { result, comment }, signingDomain, publicKey, signature, status, body, bodyHash, } = dkimResult;
    if (result !== 'pass') {
        throw new Error(`DKIM signature verification failed for domain ${signingDomain}. Reason: ${comment}`);
    }
    const pubKeyData = node_forge_1.pki.publicKeyFromPem(publicKey.toString());
    return {
        signature: BigInt(`0x${Buffer.from(signature, 'base64').toString('hex')}`),
        headers: status.signedHeaders,
        body,
        bodyHash,
        signingDomain: dkimResult.signingDomain,
        publicKey: BigInt(pubKeyData.n.toString()),
        selector: dkimResult.selector,
        algo: dkimResult.algo,
        format: dkimResult.format,
        modulusLength: dkimResult.modulusLength,
        appliedSanitization,
    };
}
exports.verifyDKIMSignature = verifyDKIMSignature;
async function tryVerifyDKIM(email, domain = '') {
    const dkimVerifier = new dkim_verifier_1.DkimVerifier({});
    await (0, tools_1.writeToStream)(dkimVerifier, email);
    let domainToVerifyDKIM = domain;
    if (!domainToVerifyDKIM) {
        if (dkimVerifier.headerFrom.length > 1) {
            throw new Error('Multiple From header in email and domain for verification not specified');
        }
        domainToVerifyDKIM = dkimVerifier.headerFrom[0].split('@')[1];
    }
    const dkimResult = dkimVerifier.results.find((d) => d.signingDomain === domainToVerifyDKIM);
    if (!dkimResult) {
        throw new Error(`DKIM signature not found for domain ${domainToVerifyDKIM}`);
    }
    dkimResult.headers = dkimVerifier.headers;
    return dkimResult;
}
