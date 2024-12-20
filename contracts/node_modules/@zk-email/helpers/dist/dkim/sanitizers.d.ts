declare function revertGoogleMessageId(email: string): string;
declare const sanitizers: (typeof revertGoogleMessageId)[];
export default sanitizers;
