export declare function findIndexInUint8Array(array: Uint8Array, selector: Uint8Array): number;
export declare function padUint8ArrayWithZeros(array: Uint8Array, length: number): Uint8Array;
export declare function generatePartialSHA({ body, bodyLength, selectorString, // String to split the body
maxRemainingBodyLength, }: {
    body: Uint8Array;
    bodyLength: number;
    selectorString?: string;
    maxRemainingBodyLength: number;
}): {
    precomputedSha: Uint8Array;
    bodyRemaining: Uint8Array;
    bodyRemainingLength: number;
};
export declare function shaHash(str: Uint8Array): Buffer;
export declare function partialSha(msg: Uint8Array, msgLen: number): Uint8Array;
export declare function sha256Pad(message: Uint8Array, maxShaBytes: number): [Uint8Array, number];
