export declare const uncompressGz: (arrayBuffer: ArrayBuffer) => Promise<ArrayBuffer>;
export declare function downloadFromFilename(baseUrl: string, filename: string, compressed?: boolean): Promise<void>;
export declare function downloadProofFiles(baseUrl: string, circuitName: string, onFileDownloaded: () => void): Promise<void>;
export declare function generateProof(input: any, baseUrl: string, circuitName: string): Promise<{
    proof: any;
    publicSignals: any;
}>;
export declare function verifyProof(proof: any, publicSignals: any, baseUrl: string, circuitName: string): Promise<any>;
export declare function buildInput(pubkey: string, msghash: string, sig: string): {
    r: string[];
    s: string[];
    msghash: bigint[];
    pubkey: string[][];
};
