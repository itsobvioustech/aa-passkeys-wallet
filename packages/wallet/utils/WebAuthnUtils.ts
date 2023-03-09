import * as crypto from 'crypto';
import { ec as EC } from 'elliptic';
import base64url from 'base64url';
import { ECDSASigValue } from '@peculiar/asn1-ecc';
import { AsnParser } from '@peculiar/asn1-schema';
import { BigNumber } from 'ethers';

enum COSEKEYS {
    kty = 1,
    alg = 3,
    crv = -1,
    x = -2,
    y = -3,
    n = -1,
    e = -2,
}

const ec = new EC('p256');

function toHash(data: crypto.BinaryLike, algo = 'SHA-256') {
    return crypto.createHash(algo).update(data).digest();
}

function shouldRemoveLeadingZero(bytes: Uint8Array): boolean {
    return bytes[0] === 0x0 && (bytes[1] & (1 << 7)) !== 0;
}

export class WebAuthnUtils {

    static getMessageHash(authenticatorData: string, clientDataJSON: string): BigNumber {
        const authDataBuffer = base64url.toBuffer(authenticatorData);
        const clientDataHash = toHash(base64url.toBuffer(clientDataJSON));
        const signatureBase = Buffer.concat([authDataBuffer, clientDataHash]);
        return BigNumber.from(toHash(signatureBase));
    }

    static async getPublicKeyFromBytes(publicKeyBytes: string): Promise<BigNumber[]> {
        const cap = {
            name: 'ECDSA',
            namedCurve: 'P-256',
            hash: 'SHA-256',
        }
        let pkeybytes = base64url.toBuffer(publicKeyBytes);
        let pkey = await crypto.subtle.importKey('spki', pkeybytes, cap, true, ['verify']);
        let jwk = await crypto.subtle.exportKey('jwk', pkey);
        if (jwk.x && jwk.y)
            return [BigNumber.from(base64url.toBuffer(jwk.x)), BigNumber.from(base64url.toBuffer(jwk.y))];
        else
            throw new Error('Invalid public key');
    }

    static getMessageSignature(authResponseSignature: string): BigNumber[] {
        // See https://github.dev/MasterKale/SimpleWebAuthn/blob/master/packages/server/src/helpers/iso/isoCrypto/verifyEC2.ts
        // for extraction of the r and s bytes from the raw signature buffer
        const parsedSignature = AsnParser.parse(
            base64url.toBuffer(authResponseSignature),
            ECDSASigValue,
        );

        let rBytes = new Uint8Array(parsedSignature.r);
        let sBytes = new Uint8Array(parsedSignature.s);
    
        if (shouldRemoveLeadingZero(rBytes)) {
            rBytes = rBytes.slice(1);
        }
        
        if (shouldRemoveLeadingZero(sBytes)) {
            sBytes = sBytes.slice(1);
        }
    
        // r and s values
        return [
            BigNumber.from(rBytes),
            BigNumber.from(sBytes),
        ];    
    }
}

